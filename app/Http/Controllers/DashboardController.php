<?php

namespace App\Http\Controllers;

use App\Models\Document;
use App\Models\LetterActivePeriod;
use App\Models\ShoppingItem;
use App\Models\Task;
use App\Models\User;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index()
    {
        $user = auth()->user();

        if ($user->hasRole('super_admin')) {
            $stats = [
                'total_users' => User::count(),
                'total_tasks' => Task::count(),
                'tasks_pending' => Task::where('status', 'pending')->count(),
                'tasks_progress' => Task::where('status', 'progress')->count(),
                'tasks_done' => Task::where('status', 'done')->count(),
                'total_documents' => Document::count(),
            ];

            $recentTasks = Task::with(['creator', 'assignedUsers'])
                ->latest()
                ->take(5)
                ->get();

            $expiringLetters = LetterActivePeriod::whereBetween('masa_aktif_berakhir', [
                now()->startOfDay(),
                now()->addDays(7)->endOfDay(),
            ])->get();

            return view('dashboard.super-admin', compact('stats', 'recentTasks', 'expiringLetters'));
        }
        if ($user->hasRole('administrasi')) {
            $stats = [
                'total_pekerjaan' => Task::count(),
                'task_pending' => Task::where('status', 'pending')->count(),
                'task_selesai' => Task::where('status', 'done')->count(),
                'barang_belum_dibeli' => ShoppingItem::where('is_checked', false)->count(),
            ];

            $recentTasks = Task::with(['creator', 'assignedUsers'])
                ->latest()
                ->take(5)
                ->get();

            $expiringLetters = LetterActivePeriod::whereBetween('masa_aktif_berakhir', [
                now()->startOfDay(),
                now()->addDays(7)->endOfDay(),
            ])->get();

            return view('dashboard.administrasi', compact('stats', 'recentTasks', 'expiringLetters'));
        }
        if ($user->hasRole('teknisi')) {
            $stats = [
                'tugas_pending' => Task::where('task_type', 'teknisi')->where('status', 'pending')->count(),
                'tugas_progress' => Task::where('task_type', 'teknisi')->where('status', 'progress')->count(),
                'tugas_selesai' => Task::where('task_type', 'teknisi')->where('status', 'done')->count(),
            ];

            $tasks = Task::with(['creator'])
                ->where('task_type', 'teknisi')
                ->whereHas('assignedUsers', fn($q) => $q->where('user_id', $user->id))
                ->latest()
                ->take(5)
                ->get();

            return view('dashboard.teknisi', compact('stats', 'tasks'));
        }
        if ($user->hasRole('logistic')) {
            $taskIds = Task::whereHas('shoppingItems')->pluck('id');

            $stats = [
                'total_tugas' => $taskIds->count(),
                'pekerjaan_perlu_dibeli' => Task::whereIn('id', $taskIds)->whereHas('shoppingItems', fn($q) => $q->where('is_checked', false))->count(),
                'barang_belum_dibeli' => ShoppingItem::whereIn('task_id', $taskIds)->where('is_checked', false)->count(),
                'barang_selesai_dibeli' => ShoppingItem::whereIn('task_id', $taskIds)->where('is_checked', true)->count(),
            ];

            $tasks = Task::with(['creator', 'shoppingItems'])
                ->whereIn('id', $taskIds)
                ->latest()
                ->take(10)
                ->get();

            return view('dashboard.logistic', compact('stats', 'tasks'));
        }

        abort(403);
    }

    public function monitoringLogistic(): View
    {
        $tasks = Task::with(['assignedUsers', 'shoppingItems'])
            ->has('shoppingItems')
            ->withCount(['shoppingItems', 'shoppingItems as checked_count' => fn($q) => $q->where('is_checked', true)])
            ->latest()
            ->paginate(10);

        $total = Task::has('shoppingItems')->count();
        $progress = Task::has('shoppingItems')
            ->whereHas('shoppingItems', fn($q) => $q->where('is_checked', false))->count();
        $done = Task::has('shoppingItems')
            ->whereDoesntHave('shoppingItems', fn($q) => $q->where('is_checked', false))->count();

        return view('admin.monitoring.logistic', compact('tasks', 'total', 'progress', 'done'));
    }

    public function monitoringTeknisi(): View
    {
        $tasks = Task::with(['assignedUsers', 'teknisiTaskItems'])
            ->where('task_type', 'teknisi')
            ->withCount(['teknisiTaskItems', 'teknisiTaskItems as checked_count' => fn($q) => $q->where('is_checked', true)])
            ->latest()
            ->paginate(10);

        $total = Task::where('task_type', 'teknisi')->count();
        $progress = Task::where('task_type', 'teknisi')->has('teknisiTaskItems')
            ->whereHas('teknisiTaskItems', fn($q) => $q->where('is_checked', false))->count();
        $done = Task::where('task_type', 'teknisi')->has('teknisiTaskItems')
            ->whereDoesntHave('teknisiTaskItems', fn($q) => $q->where('is_checked', false))->count();

        return view('admin.monitoring.teknisi', compact('tasks', 'total', 'progress', 'done'));
    }
}
