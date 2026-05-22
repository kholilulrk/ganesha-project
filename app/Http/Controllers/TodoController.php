<?php

namespace App\Http\Controllers;

use App\Models\TodoItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class TodoController extends Controller
{
    public function index(): View
    {
        $user = Auth::user();
        $todos = TodoItem::where('user_id', $user->id)->latest()->get();

        return view('todos.index', compact('todos'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
        ]);

        $todo = TodoItem::create([
            'user_id' => Auth::id(),
            'title' => $validated['title'],
            'status' => 'pending',
        ]);

        if ($request->expectsJson()) {
            $html = view('todos.partials._todo_item', compact('todo'))->render();
            return response()->json(['success' => true, 'html' => $html]);
        }

        return redirect()->route('todos.index')->with('success', 'To-do berhasil ditambahkan.');
    }

    public function toggleStatus(Request $request, TodoItem $todo)
    {
        abort_unless($todo->user_id === Auth::id(), 403);

        $nextStatus = match ($todo->status) {
            'pending' => 'progress',
            'progress' => 'done',
            'done' => 'pending',
        };

        $todo->update(['status' => $nextStatus]);

        if ($request->expectsJson()) {
            $todo->refresh();
            $html = view('todos.partials._todo_item', compact('todo'))->render();
            return response()->json(['success' => true, 'html' => $html, 'status' => $todo->status]);
        }

        return redirect()->route('todos.index');
    }

    public function destroy(Request $request, TodoItem $todo)
    {
        abort_unless($todo->user_id === Auth::id(), 403);

        $todo->delete();

        if ($request->expectsJson()) {
            return response()->json(['success' => true]);
        }

        return redirect()->route('todos.index')->with('success', 'To-do berhasil dihapus.');
    }
}
