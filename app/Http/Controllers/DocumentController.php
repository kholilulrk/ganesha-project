<?php

namespace App\Http\Controllers;

use App\Models\Document;
use App\Services\ActivityLogger;
use App\Services\ImageService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;

class DocumentController extends Controller
{
    public function index(Request $request): View
    {
        $user = Auth::user();
        $query = Document::with('uploader');

        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        if ($docType = $request->input('document_type')) {
            $query->where('document_type', $docType);
        }

        if ($visibility = $request->input('visibility')) {
            $query->where('visibility', $visibility);
        }

        if (!$user->hasAnyRole(['super_admin', 'administrasi'])) {
            $query->visibleTo($user);
        }

        $documents = $query->latest()->paginate(10)->withQueryString();

        return view('documents.index', compact('documents'));
    }

    public function create(): View
    {
        $roles = \Spatie\Permission\Models\Role::all();
        return view('documents.create', compact('roles'));
    }

    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'document_type' => ['required', 'string', 'max:50'],
            'file' => ['required', 'file', 'max:20480', 'mimes:jpg,jpeg,png,gif,pdf,xls,xlsx,doc,docx,csv,txt'],
            'description' => ['nullable', 'string'],
            'visibility' => ['required', 'in:all,roles'],
            'shared_roles' => ['nullable', 'array', 'exists:roles,id'],
        ]);

        $file = $request->file('file');
        if (ImageService::isImage($file)) {
            $path = app(ImageService::class)->compressAndStore($file, 'documents');
        } else {
            $path = $file->store('documents', 'public');
        }

        $document = Document::create([
            'title' => $validated['title'],
            'document_type' => $validated['document_type'],
            'file' => $path,
            'description' => $validated['description'],
            'uploaded_by' => Auth::id(),
            'visibility' => $validated['visibility'],
        ]);

        if ($validated['visibility'] === 'roles' && !empty($validated['shared_roles'])) {
            $document->sharedRoles()->attach($validated['shared_roles']);
        }

        app(ActivityLogger::class)
            ->on($document)
            ->withLogName('document')
            ->log("mengupload dokumen \"{$document->title}\"");

        return redirect()->route('documents.index')->with('success', 'Document uploaded successfully.');
    }

    public function show(Document $document): View
    {
        $user = Auth::user();
        if (!$user->hasAnyRole(['super_admin', 'administrasi'])) {
            abort_unless(Document::where('id', $document->id)->visibleTo($user)->exists(), 403);
        }

        $document->load('sharedRoles');
        return view('documents.show', compact('document'));
    }

    public function edit(Document $document): View
    {
        $document->load('sharedRoles');
        $roles = \Spatie\Permission\Models\Role::all();
        return view('documents.edit', compact('document', 'roles'));
    }

    public function update(Request $request, Document $document): RedirectResponse
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'document_type' => ['required', 'string', 'max:50'],
            'file' => ['nullable', 'file', 'max:20480', 'mimes:jpg,jpeg,png,gif,pdf,xls,xlsx,doc,docx,csv,txt'],
            'description' => ['nullable', 'string'],
            'visibility' => ['required', 'in:all,roles'],
            'shared_roles' => ['nullable', 'array', 'exists:roles,id'],
        ]);

        if ($request->hasFile('file')) {
            Storage::disk('public')->delete($document->file);
            $file = $request->file('file');
            if (ImageService::isImage($file)) {
                $validated['file'] = app(ImageService::class)->compressAndStore($file, 'documents');
            } else {
                $validated['file'] = $file->store('documents', 'public');
            }
        }

        $document->update($validated);

        $document->sharedRoles()->sync($validated['visibility'] === 'roles' ? ($validated['shared_roles'] ?? []) : []);

        app(ActivityLogger::class)
            ->on($document)
            ->withLogName('document')
            ->log("memperbarui dokumen \"{$document->title}\"");

        return redirect()->route('documents.index')->with('success', 'Document updated successfully.');
    }

    public function destroy(Document $document): RedirectResponse
    {
        $title = $document->title;
        Storage::disk('public')->delete($document->file);
        $document->delete();

        app(ActivityLogger::class)
            ->withLogName('document')
            ->log("menghapus dokumen \"{$title}\"");

        return redirect()->route('documents.index')->with('success', 'Document deleted successfully.');
    }
}
