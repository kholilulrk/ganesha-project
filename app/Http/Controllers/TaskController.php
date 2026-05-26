<?php

namespace App\Http\Controllers;

use App\Models\Document;
use App\Models\ShoppingItem;
use App\Models\Task;
use App\Models\TaskComment;
use App\Models\TeknisiTaskItem;
use App\Models\TeknisiTaskItemImage;
use App\Models\User;
use App\Services\ActivityLogger;
use App\Services\ImageService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;

class TaskController extends Controller
{
    public function index(Request $request): View
    {
        $user = Auth::user();
        $query = Task::with(['creator', 'assignedUsers'])
            ->withCount(['shoppingItems', 'shoppingItems as unchecked_shopping_items_count' => fn($q) => $q->where('is_checked', false)]);

        if (!$user->hasAnyRole(['super_admin', 'administrasi'])) {
            if ($user->hasRole('logistic')) {
                $query->whereHas('shoppingItems');
            } else {
                $role = $user->getRoleNames()->first();
                $query->where(function ($q) use ($user, $role) {
                    $q->whereHas('assignedUsers', fn($sub) => $sub->where('user_id', $user->id))
                      ->orWhere('assigned_role', $role)
                      ->orWhere(function ($sub) {
                          $sub->whereDoesntHave('assignedUsers')->whereNull('assigned_role');
                      });
                });
            }
        }

        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        if ($status = $request->input('status')) {
            $query->where('status', $status);
        }

        if ($taskType = $request->input('task_type')) {
            $query->where('task_type', $taskType);
        }

        if ($assignedTo = $request->input('assigned_to')) {
            $query->whereHas('assignedUsers', fn($q) => $q->where('user_id', $assignedTo));
        }

        if ($shoppingStatus = $request->input('shopping_status')) {
            if ($shoppingStatus === 'incomplete') {
                $query->whereHas('shoppingItems', fn($q) => $q->where('is_checked', false));
            } elseif ($shoppingStatus === 'complete') {
                $query->whereHas('shoppingItems', fn($q) => $q->where('is_checked', true))
                      ->whereDoesntHave('shoppingItems', fn($q) => $q->where('is_checked', false));
            }
        }

        $tasks = $query->latest()->paginate(10)->withQueryString();

        return view('tasks.index', compact('tasks'));
    }

    public function create(): View
    {
        $user = Auth::user();

        abort_unless($user->hasAnyRole(['super_admin', 'administrasi']), 403);

        $users = $user->hasRole('super_admin') ? User::all() : collect();
        $roles = $user->hasRole('administrasi') ? ['teknisi' => 'Teknisi', 'logistic' => 'Logistic'] : [];
        $documents = Document::all();

        return view('tasks.create', compact('users', 'roles', 'documents'));
    }

    public function store(Request $request): RedirectResponse
    {
        $user = Auth::user();

        abort_unless($user->hasAnyRole(['super_admin', 'administrasi']), 403);

        $rules = [
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'deadline' => ['nullable', 'date'],
            'document_id' => ['nullable', 'exists:documents,id'],
        ];

        if ($user->hasRole('super_admin')) {
            $rules['assigned_users'] = ['nullable', 'array'];
            $rules['assigned_users.*'] = ['exists:users,id'];
        } elseif ($user->hasRole('administrasi')) {
            $rules['assigned_role'] = ['nullable', 'in:teknisi,logistic'];
        }

        $validated = $request->validate($rules);

        $validated['created_by'] = $user->id;
        $validated['status'] = 'pending';
        $validated['task_type'] = $validated['assigned_role'] ?? 'teknisi';
        $validated['priority'] = 'medium';

        $assignedUserIds = $request->input('assigned_users', []);
        unset($validated['assigned_users']);

        $task = Task::create($validated);

        $assignedUserNames = [];
        if (!empty($assignedUserIds)) {
            $task->assignedUsers()->sync($assignedUserIds);
            $assignedUserNames = User::whereIn('id', $assignedUserIds)->pluck('name')->toArray();
        }

        app(ActivityLogger::class)
            ->on($task)
            ->withLogName('task')
            ->withProperties(['assigned_users' => $assignedUserNames])
            ->log("membuat task \"{$task->title}\"");

        return redirect()->route('tasks.index')->with('success', 'Task created successfully.');
    }

    public function show(Task $task): View
    {
        $this->authorizeAccess($task);

        $task->load(['attachments.uploader', 'shoppingItems.checker', 'workReports.creator', 'creator', 'assignedUsers', 'teknisiTaskItems.creator', 'teknisiTaskItems.checker', 'teknisiTaskItems.images', 'document', 'comments.replies']);

        return view('tasks.show', compact('task'));
    }

    public function edit(Task $task): View
    {
        $user = Auth::user();

        if (!$user->hasAnyRole(['super_admin', 'administrasi'])) {
            abort(403);
        }

        $this->authorizeAccess($task);

        $users = $user->hasRole('super_admin') ? User::all() : collect();
        $roles = $user->hasRole('administrasi') ? ['teknisi' => 'Teknisi', 'logistic' => 'Logistic'] : [];
        $documents = Document::all();

        return view('tasks.edit', compact('task', 'users', 'roles', 'documents'));
    }

    public function update(Request $request, Task $task): RedirectResponse
    {
        $user = $request->user();

        if (!$user->hasAnyRole(['super_admin', 'administrasi'])) {
            abort(403);
        }

        $this->authorizeAccess($task);

        $rules = [
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'status' => ['required', 'in:pending,progress,done,cancelled'],
            'deadline' => ['nullable', 'date'],
            'document_id' => ['nullable', 'exists:documents,id'],
        ];

        if ($user->hasRole('super_admin')) {
            $rules['assigned_users'] = ['nullable', 'array'];
            $rules['assigned_users.*'] = ['exists:users,id'];
        } elseif ($user->hasRole('administrasi')) {
            $rules['assigned_role'] = ['nullable', 'in:teknisi,logistic'];
        }

        $validated = $request->validate($rules);

        $assignedUserIds = $request->input('assigned_users', []);
        unset($validated['assigned_users']);

        $task->update($validated);

        if ($user->hasRole('super_admin')) {
            $task->assignedUsers()->sync($assignedUserIds);
        }

        app(ActivityLogger::class)
            ->on($task)
            ->withLogName('task')
            ->log("memperbarui task \"{$task->title}\"");

        return redirect()->route('tasks.index')->with('success', 'Task updated successfully.');
    }

    public function updateStatus(Request $request, Task $task): RedirectResponse
    {
        $this->authorizeAccess($task);

        $validated = $request->validate([
            'status' => ['required', 'in:pending,progress,done'],
        ]);

        $oldStatus = $task->status;
        $task->update($validated);

        if ($oldStatus !== $validated['status']) {
            app(ActivityLogger::class)
                ->on($task)
                ->withLogName('task')
                ->withProperties(['old_status' => $oldStatus, 'new_status' => $validated['status']])
                ->log("mengubah status task \"{$task->title}\" dari {$oldStatus} ke {$validated['status']}");
        }

        $message = match ($validated['status']) {
            'progress' => 'Status diubah menjadi Progress.',
            'done' => 'Status diubah menjadi Selesai.',
            default => 'Status diubah menjadi Pending.',
        };

        return redirect()->route('tasks.show', $task)->with('success', $message);
    }

    public function destroy(Request $request, Task $task)
    {
        if (!Auth::user()->hasAnyRole(['super_admin', 'administrasi'])) {
            abort(403);
        }

        $this->authorizeAccess($task);

        $title = $task->title;
        $task->delete();

        app(ActivityLogger::class)
            ->withLogName('task')
            ->log("menghapus task \"{$title}\"");

        if ($request->ajax() || $request->wantsJson()) {
            return response()->json(['success' => true]);
        }

        return redirect()->route('tasks.index')->with('success', 'Task deleted successfully.');
    }

    public function storeShoppingItem(Request $request, Task $task)
    {
        $this->authorizeAccess($task);

        $validated = $request->validate([
            'item_name' => ['required', 'string', 'max:255'],
            'qty' => ['required', 'integer', 'min:1'],
            'unit' => ['nullable', 'string', 'max:50'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'price' => ['nullable', 'integer', 'min:0'],
        ]);

        $item = $task->shoppingItems()->create($validated);

        app(ActivityLogger::class)
            ->on($task)
            ->withLogName('shopping_item')
            ->log("menambahkan item belanja \"{$item->item_name}\" di task \"{$task->title}\"");

        if ($request->expectsJson()) {
            $item->load('checker');
            $total = $task->shoppingItems()->count();
            $checked = $task->shoppingItems()->where('is_checked', true)->count();
            $totalPrice = $task->shoppingItems()->get()->sum(fn($i) => ($i->price ?? 0) * $i->qty);
            $html = view('tasks.partials._shopping_item', compact('item', 'task'))->render();
            return response()->json(['success' => true, 'html' => $html, 'total' => $total, 'checked' => $checked, 'total_price' => $totalPrice]);
        }

        return redirect()->route('tasks.show', $task)->with('success', 'Item added to shopping list.');
    }

    public function toggleShoppingItem(Request $request, Task $task, ShoppingItem $item)
    {
        $this->authorizeAccess($task);

        $newChecked = ! $item->is_checked;
        $item->update([
            'is_checked' => $newChecked,
            'checked_by' => $newChecked ? Auth::id() : null,
        ]);

        app(ActivityLogger::class)
            ->on($task)
            ->withLogName('shopping_item')
            ->log(($newChecked ? 'mencentang' : 'batal centang') . " item belanja \"{$item->item_name}\" di task \"{$task->title}\"");

        if ($request->expectsJson()) {
            $item->refresh();
            $item->load('checker');
            $total = $task->shoppingItems()->count();
            $checked = $task->shoppingItems()->where('is_checked', true)->count();
            $totalPrice = $task->shoppingItems()->get()->sum(fn($i) => ($i->price ?? 0) * $i->qty);
            return response()->json([
                'success' => true,
                'is_checked' => $item->is_checked,
                'checked_by' => $item->checker?->name,
                'total' => $total,
                'checked' => $checked,
                'total_price' => $totalPrice,
            ]);
        }

        return redirect()->route('tasks.show', $task);
    }

    public function updateShoppingItem(Request $request, Task $task, ShoppingItem $item)
    {
        $this->authorizeAccess($task);

        $validated = $request->validate([
            'item_name' => ['required', 'string', 'max:255'],
            'qty' => ['required', 'integer', 'min:1'],
            'unit' => ['nullable', 'string', 'max:50'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'price' => ['nullable', 'integer', 'min:0'],
        ]);

        $item->update($validated);

        if ($request->expectsJson()) {
            $item->load('checker');
            $totalPrice = $task->shoppingItems()->get()->sum(fn($i) => ($i->price ?? 0) * $i->qty);
            $html = view('tasks.partials._shopping_item', compact('item', 'task'))->render();
            return response()->json(['success' => true, 'html' => $html, 'total_price' => $totalPrice]);
        }

        return redirect()->route('tasks.show', $task)->with('success', 'Shopping item updated.');
    }

    public function destroyShoppingItem(Request $request, Task $task, ShoppingItem $item)
    {
        $user = Auth::user();

        if ($user->hasRole('logistic')) {
            if ($request->expectsJson()) {
                return response()->json(['success' => false, 'message' => 'Logistic tidak bisa menghapus item.'], 403);
            }
            abort(403, 'Logistic tidak bisa menghapus item.');
        }

        $this->authorizeAccess($task);

        $item->delete();

        if ($request->expectsJson()) {
            $total = $task->shoppingItems()->count();
            $checked = $task->shoppingItems()->where('is_checked', true)->count();
            $totalPrice = $task->shoppingItems()->get()->sum(fn($i) => ($i->price ?? 0) * $i->qty);
            return response()->json(['success' => true, 'total' => $total, 'checked' => $checked, 'total_price' => $totalPrice]);
        }

        return redirect()->route('tasks.show', $task)->with('success', 'Shopping item removed.');
    }

    public function destroyShoppingItemImage(Request $request, Task $task, ShoppingItem $item)
    {
        $this->authorizeAccess($task);

        if ($item->image) {
            Storage::disk('public')->delete($item->image);
            $item->update(['image' => null]);
        }

        if ($request->expectsJson()) {
            return response()->json(['success' => true]);
        }

        return redirect()->route('tasks.show', $task)->with('success', 'Gambar berhasil dihapus.');
    }

    public function uploadShoppingItemImage(Request $request, Task $task, ShoppingItem $item)
    {
        $this->authorizeAccess($task);

        $request->validate([
            'image' => ['required', 'image', 'max:2048'],
        ]);

        if ($item->image) {
            Storage::disk('public')->delete($item->image);
        }

        $service = app(ImageService::class);
        $path = $service->compressAndStore($request->file('image'), 'shopping-items/' . $task->id);
        $item->update(['image' => $path]);

        if ($request->expectsJson()) {
            return response()->json([
                'success' => true,
                'has_image' => true,
                'image_url' => Storage::url($path),
            ]);
        }

        return redirect()->route('tasks.show', $task)->with('success', 'Gambar barang berhasil diupload.');
    }

    public function storeTeknisiTaskItem(Request $request, Task $task)
    {
        $user = Auth::user();

        $this->authorizeAccess($task);

        $validated = $request->validate([
            'item_name' => ['required', 'string', 'max:255'],
        ]);

        $item = $task->teknisiTaskItems()->create([
            'item_name' => $validated['item_name'],
            'created_by' => $user->id,
        ]);

        app(ActivityLogger::class)
            ->on($task)
            ->withLogName('teknisi_item')
            ->log("menambahkan item teknisi \"{$item->item_name}\" di task \"{$task->title}\"");

        if ($request->expectsJson()) {
            $item->load('checker', 'creator', 'images');
            $total = $task->teknisiTaskItems()->count();
            $checked = $task->teknisiTaskItems()->where('is_checked', true)->count();
            $html = view('tasks.partials._teknisi_item', compact('item', 'task'))->render();
            return response()->json(['success' => true, 'html' => $html, 'total' => $total, 'checked' => $checked]);
        }

        return redirect()->route('tasks.show', $task)->with('success', 'Checklist item added.');
    }

    public function toggleTeknisiTaskItem(Request $request, Task $task, TeknisiTaskItem $item)
    {
        $user = $request->user();

        if (!$user->hasAnyRole(['super_admin', 'administrasi', 'teknisi'])) {
            abort(403);
        }

        $this->authorizeAccess($task);

        $newChecked = !$item->is_checked;
        $item->update([
            'is_checked' => $newChecked,
            'checked_by' => $newChecked ? $user->id : null,
        ]);

        app(ActivityLogger::class)
            ->on($task)
            ->withLogName('teknisi_item')
            ->log(($newChecked ? 'mencentang' : 'batal centang') . " item teknisi \"{$item->item_name}\" di task \"{$task->title}\"");

        if ($request->expectsJson()) {
            $item->refresh();
            $total = $task->teknisiTaskItems()->count();
            $checked = $task->teknisiTaskItems()->where('is_checked', true)->count();
            return response()->json([
                'is_checked' => $item->is_checked,
                'checked_by' => $item->checker?->name,
                'total' => $total,
                'checked' => $checked,
            ]);
        }

        return redirect()->route('tasks.show', $task);
    }

    public function updateTeknisiTaskItem(Request $request, Task $task, TeknisiTaskItem $item)
    {
        $user = Auth::user();

        if (!$user->hasAnyRole(['super_admin', 'administrasi', 'teknisi'])) {
            abort(403);
        }

        $this->authorizeAccess($task);

        $validated = $request->validate([
            'item_name' => ['required', 'string', 'max:255'],
        ]);

        $item->update($validated);

        if ($request->expectsJson()) {
            $item->load('checker', 'creator');
            return response()->json(['success' => true]);
        }

        return redirect()->route('tasks.show', $task)->with('success', 'Checklist item updated.');
    }

    public function destroyTeknisiTaskItem(Request $request, Task $task, TeknisiTaskItem $item)
    {
        $this->authorizeAccess($task);

        $item->delete();

        if ($request->expectsJson()) {
            $total = $task->teknisiTaskItems()->count();
            $checked = $task->teknisiTaskItems()->where('is_checked', true)->count();
            return response()->json(['success' => true, 'total' => $total, 'checked' => $checked]);
        }

        return redirect()->route('tasks.show', $task)->with('success', 'Checklist item removed.');
    }

    public function uploadTeknisiTaskItemImage(Request $request, Task $task, TeknisiTaskItem $item)
    {
        $this->authorizeAccess($task);

        $request->validate([
            'images' => ['required', 'array'],
            'images.*' => ['required', 'image', 'max:5120'],
        ]);

        $currentCount = $item->images()->count();
        $uploadCount = count($request->file('images', []));

        if ($currentCount + $uploadCount > 2) {
            $allowed = max(0, 2 - $currentCount);
            if ($request->expectsJson()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Maksimal 2 gambar per item. Hanya ' . $allowed . ' gambar lagi yang bisa ditambahkan.',
                ], 422);
            }
            return redirect()->route('tasks.show', $task)
                ->with('error', 'Maksimal 2 gambar per item. Hanya ' . $allowed . ' gambar lagi yang bisa ditambahkan.');
        }

        $images = [];
        $service = app(ImageService::class);
        foreach ($request->file('images', []) as $file) {
            $path = $service->compressAndStore($file, 'teknisi-items/' . $task->id);
            $images[] = $item->images()->create(['image' => $path]);
        }

        if ($request->expectsJson()) {
            $html = '';
            foreach ($images as $img) {
                $html .= view('tasks.partials._teknisi_item_image', compact('img', 'item', 'task'))->render();
            }
            return response()->json([
                'success' => true,
                'count' => count($images),
                'total' => $item->images()->count(),
                'html' => $html,
            ]);
        }

        return redirect()->route('tasks.show', $task)->with('success', count($images) . ' gambar berhasil diupload.');
    }

    public function destroyTeknisiTaskItemImage(Request $request, TeknisiTaskItemImage $image)
    {
        $item = $image->teknisiTaskItem;
        $task = $item->task;

        $this->authorizeAccess($task);

        Storage::disk('public')->delete($image->image);
        $image->delete();

        if ($request->expectsJson()) {
            return response()->json([
                'success' => true,
                'total' => $item->images()->count(),
            ]);
        }

        return redirect()->route('tasks.show', $task)->with('success', 'Gambar berhasil dihapus.');
    }

    public function showShared(string $token): View
    {
        $task = Task::where('share_token', $token)
            ->with(['attachments', 'teknisiTaskItems.images', 'shoppingItems', 'comments.replies', 'document', 'assignedUsers', 'creator'])
            ->firstOrFail();

        $contacts = collect();
        foreach ($task->assignedUsers as $u) {
            if (!$u->hasRole('super_admin') && $u->whatsapp) {
                $contacts->push($u);
            }
        }
        if ($task->creator && !$task->creator->hasRole('super_admin') && $task->creator->whatsapp) {
            if ($contacts->doesntContain('id', $task->creator->id)) {
                $contacts->push($task->creator);
            }
        }

        return view('tasks.shared.show', compact('task', 'contacts'));
    }

    public function generateShareLink(Request $request, Task $task): RedirectResponse
    {
        $user = Auth::user();

        if (!$user->hasAnyRole(['super_admin', 'administrasi', 'teknisi', 'logistic'])) {
            abort(403);
        }

        $this->authorizeAccess($task);

        $token = $task->generateShareToken();
        $url = route('tasks.shared.show', $token);

        return redirect()->route('tasks.show', $task)->with([
            'success' => 'Link berbagi berhasil dibuat.',
            'share_url' => $url,
        ]);
    }

    public function storeComment(Request $request, string $token)
    {
        $task = Task::where('share_token', $token)->firstOrFail();

        $validated = $request->validate([
            'visitor_name' => ['required', 'string', 'max:255'],
            'comment' => ['required', 'string', 'max:5000'],
        ]);

        $comment = $task->comments()->create($validated);

        if ($request->ajax() || $request->wantsJson()) {
            $html = view('tasks.partials._comment', ['comment' => $comment])->render();
            return response()->json(['success' => true, 'html' => $html]);
        }

        return redirect()->route('tasks.shared.show', $token)
            ->with('success', 'Komentar berhasil ditambahkan.');
    }

    public function replyComment(Request $request, Task $task, TaskComment $comment)
    {
        $this->authorizeAccess($task);

        $user = Auth::user();

        $validated = $request->validate([
            'comment' => ['required', 'string', 'max:5000'],
        ]);

        $reply = $comment->replies()->create([
            'task_id' => $task->id,
            'user_id' => $user->id,
            'visitor_name' => $user->getRoleNames()->first(),
            'comment' => $validated['comment'],
        ]);

        if ($request->ajax() || $request->wantsJson()) {
            $html = view('tasks.partials._comment_reply', ['reply' => $reply])->render();
            return response()->json(['success' => true, 'html' => $html]);
        }

        return redirect()->route('tasks.show', $task)->with('success', 'Balasan berhasil dikirim.');
    }

    private function authorizeAccess(Task $task): void
    {
        $user = Auth::user();

        if ($user->hasAnyRole(['super_admin', 'administrasi'])) {
            return;
        }

        if ($user->hasRole('teknisi')) {
            $role = $user->getRoleNames()->first();
            $accessible = Task::where('id', $task->id)->where(function ($q) use ($user, $role) {
                $q->whereHas('assignedUsers', fn($sub) => $sub->where('user_id', $user->id))
                  ->orWhere('assigned_role', $role)
                  ->orWhere(function ($sub) {
                      $sub->whereDoesntHave('assignedUsers')->whereNull('assigned_role');
                  });
            })->exists();

            if ($accessible) {
                return;
            }
        }

        if ($user->hasRole('logistic')) {
            if ($task->shoppingItems()->exists()) {
                return;
            }
        }

        abort(403);
    }
}
