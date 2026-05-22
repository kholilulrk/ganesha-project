<?php

namespace App\Http\Controllers;

use App\Models\Announcement;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;
use Spatie\Permission\Models\Role;

class AnnouncementController extends Controller
{
    public function index(): View
    {
        $user = Auth::user();

        Announcement::where('expired_at', '<=', now())->delete();

        if ($user->hasRole('super_admin')) {
            $announcements = Announcement::with('creator')->latest()->paginate(10);
        } else {
            $announcements = Announcement::with('creator')
                ->scheduled()
                ->visibleTo($user)
                ->latest()
                ->paginate(10);
        }

        return view('announcements.index', compact('announcements'));
    }

    public function create(): View
    {
        $users = User::all();
        $roles = Role::all();

        return view('announcements.create', compact('users', 'roles'));
    }

    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'content' => ['required', 'string'],
            'target_type' => ['required', 'in:all_users,specific'],
            'target_users' => ['nullable', 'array', 'exists:users,id'],
            'target_roles' => ['nullable', 'array', 'exists:roles,id'],
            'scheduled_date' => ['nullable', 'date'],
            'scheduled_time' => ['nullable', 'date_format:H:i'],
            'expired_date' => ['nullable', 'date'],
            'expired_time' => ['nullable', 'date_format:H:i'],
        ]);

        $scheduledAt = $validated['scheduled_date']
            ? $validated['scheduled_date'] . ' ' . ($validated['scheduled_time'] ?? '08:00')
            : null;

        $expiredAt = $validated['expired_date']
            ? $validated['expired_date'] . ' ' . ($validated['expired_time'] ?? '17:00')
            : null;

        if ($scheduledAt && $expiredAt && $expiredAt < $scheduledAt) {
            return back()->withErrors(['expired_date' => 'Jadwal berakhir harus setelah atau sama dengan jadwal mulai.'])->withInput();
        }

        $announcement = Announcement::create([
            'title' => $validated['title'],
            'content' => $validated['content'],
            'created_by' => Auth::id(),
            'target_type' => $validated['target_type'],
            'scheduled_at' => $scheduledAt,
            'expired_at' => $expiredAt,
        ]);

        if ($validated['target_type'] === 'specific') {
            if (!empty($validated['target_users'])) {
                $announcement->specificUsers()->attach($validated['target_users']);
            }
            if (!empty($validated['target_roles'])) {
                $announcement->specificRoles()->attach($validated['target_roles']);
            }
        }

        return redirect()->route('announcements.index')->with('success', 'Pengumuman berhasil dibuat.');
    }

    public function show(Announcement $announcement): View
    {
        $announcement->load('creator', 'specificUsers', 'specificRoles');

        return view('announcements.show', compact('announcement'));
    }

    public function edit(Announcement $announcement): View
    {
        $announcement->load('specificUsers', 'specificRoles');
        $users = User::all();
        $roles = Role::all();

        return view('announcements.edit', compact('announcement', 'users', 'roles'));
    }

    public function update(Request $request, Announcement $announcement): RedirectResponse
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'content' => ['required', 'string'],
            'target_type' => ['required', 'in:all_users,specific'],
            'target_users' => ['nullable', 'array', 'exists:users,id'],
            'target_roles' => ['nullable', 'array', 'exists:roles,id'],
            'scheduled_date' => ['nullable', 'date'],
            'scheduled_time' => ['nullable', 'date_format:H:i'],
            'expired_date' => ['nullable', 'date'],
            'expired_time' => ['nullable', 'date_format:H:i'],
        ]);

        $scheduledAt = $validated['scheduled_date']
            ? $validated['scheduled_date'] . ' ' . ($validated['scheduled_time'] ?? '08:00')
            : null;

        $expiredAt = $validated['expired_date']
            ? $validated['expired_date'] . ' ' . ($validated['expired_time'] ?? '17:00')
            : null;

        if ($scheduledAt && $expiredAt && $expiredAt < $scheduledAt) {
            return back()->withErrors(['expired_date' => 'Jadwal berakhir harus setelah atau sama dengan jadwal mulai.'])->withInput();
        }

        $announcement->update([
            'title' => $validated['title'],
            'content' => $validated['content'],
            'target_type' => $validated['target_type'],
            'scheduled_at' => $scheduledAt,
            'expired_at' => $expiredAt,
        ]);

        $announcement->specificUsers()->sync($validated['target_users'] ?? []);
        $announcement->specificRoles()->sync($validated['target_roles'] ?? []);

        return redirect()->route('announcements.index')->with('success', 'Pengumuman berhasil diperbarui.');
    }

    public function destroy(Announcement $announcement): RedirectResponse
    {
        $announcement->delete();

        return redirect()->route('announcements.index')->with('success', 'Pengumuman berhasil dihapus.');
    }
}
