<?php

namespace App\Http\Controllers;

use App\Models\ActivityLog;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class ActivityLogController extends Controller
{
    public function index(Request $request): View
    {
        $query = ActivityLog::with('user');

        if ($request->filled('date_from')) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }

        if ($request->filled('date_to')) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }

        $logs = $query->latest()->paginate(20)->withQueryString();

        return view('activity-logs.index', compact('logs'));
    }

    public function destroyBefore(Request $request): RedirectResponse
    {
        $request->validate([
            'delete_date' => ['required', 'date'],
        ]);

        $count = ActivityLog::whereDate('created_at', '<=', $request->delete_date)->delete();

        return redirect()->route('activity-logs.index')
            ->with('success', "Berhasil menghapus {$count} log aktivitas sebelum {$request->delete_date}.");
    }
}
