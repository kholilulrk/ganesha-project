<?php

namespace App\Http\Controllers;

use App\Models\Task;
use App\Models\WorkDocument;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class WorkDocumentController extends Controller
{
    public function index(): View|JsonResponse
    {
        $tasks = Task::with(['assignedUsers', 'creator'])
            ->latest()
            ->get();

        $documents = WorkDocument::with('task')
            ->latest()
            ->get();

        if (request()->expectsJson()) {
            return response()->json([
                'documents' => $documents,
            ]);
        }

        return view('work-documents.index', compact('tasks', 'documents'));
    }

    public function getDocument(Task $task): JsonResponse
    {
        $doc = WorkDocument::where('task_id', $task->id)->first();

        if ($doc) {
            return response()->json([
                'exists' => true,
                'document' => $doc,
            ]);
        }

        return response()->json([
            'exists' => false,
            'document' => null,
        ]);
    }

    public function store(Request $request): RedirectResponse|JsonResponse
    {
        $validated = $request->validate([
            'task_id' => ['required', 'exists:tasks,id'],
            'nilai_pekerjaan' => ['nullable', 'numeric', 'min:0'],
            'catatan' => ['nullable', 'string', 'max:5000'],
            'sik' => ['boolean'],
            'sc' => ['boolean'],
            'verifikasi_i' => ['boolean'],
            'verifikasi_ii' => ['boolean'],
            'verifikasi_iii' => ['boolean'],
            'sik_file' => ['nullable', 'file', 'max:10240', 'mimes:pdf'],
            'sph_file' => ['nullable', 'file', 'max:10240', 'mimes:pdf,xls,xlsx'],
            'spk_file' => ['nullable', 'file', 'max:10240', 'mimes:pdf,xls,xlsx,doc,docx'],
            'spektek_file' => ['nullable', 'file', 'max:10240', 'mimes:pdf,xls,xlsx'],
            'tds' => ['nullable', 'date'],
            'tdm' => ['nullable', 'date'],
        ]);

        $validated['sik'] = $request->boolean('sik');
        $validated['sc'] = $request->boolean('sc');
        $validated['verifikasi_i'] = $request->boolean('verifikasi_i');
        $validated['verifikasi_ii'] = $request->boolean('verifikasi_ii');
        $validated['verifikasi_iii'] = $request->boolean('verifikasi_iii');

        $taskId = $validated['task_id'];
        $existing = WorkDocument::where('task_id', $taskId)->first();

        $fileFields = ['sik_file', 'sph_file', 'spk_file', 'spektek_file'];
        foreach ($fileFields as $field) {
            if ($request->hasFile($field)) {
                if ($existing && $existing->$field) {
                    Storage::disk('public')->delete($existing->$field);
                }
                $validated[$field] = $request->file($field)->store('work-documents/' . $taskId, 'public');
            } else {
                unset($validated[$field]);
            }
        }

        WorkDocument::updateOrCreate(
            ['task_id' => $taskId],
            array_merge($validated, ['created_by' => Auth::id()])
        );

        $doc = WorkDocument::where('task_id', $taskId)->first();

        if ($request->expectsJson()) {
            return response()->json([
                'success' => true,
                'message' => 'Dokumen pekerjaan berhasil disimpan.',
                'document' => $doc,
            ]);
        }

        return redirect()->route('work-documents.index')
            ->with('success', 'Dokumen pekerjaan berhasil disimpan.');
    }

    public function destroyFile(Request $request, Task $task): JsonResponse
    {
        $validated = $request->validate([
            'field' => ['required', Rule::in(['sik_file', 'sph_file', 'spk_file', 'spektek_file'])],
        ]);

        $document = WorkDocument::where('task_id', $task->id)->firstOrFail();
        $field = $validated['field'];

        if ($document->$field) {
            Storage::disk('public')->delete($document->$field);
            $document->$field = null;
            $document->save();
        }

        return response()->json(['success' => true]);
    }

    public function destroy(Task $task): RedirectResponse
    {
        $document = WorkDocument::where('task_id', $task->id)->firstOrFail();

        $fileFields = ['sik_file', 'sph_file', 'spk_file', 'spektek_file'];
        foreach ($fileFields as $field) {
            if ($document->$field) {
                Storage::disk('public')->delete($document->$field);
            }
        }

        $document->delete();

        return redirect()->route('work-documents.index')
            ->with('success', 'Dokumen pekerjaan berhasil dihapus.');
    }
}
