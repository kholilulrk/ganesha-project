<?php

namespace App\Http\Controllers;

use App\Models\LetterActivePeriod;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class LetterActivePeriodController extends Controller
{
    public function index(Request $request): View
    {
        $query = LetterActivePeriod::with('creator');

        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('nama_surat', 'like', "%{$search}%")
                  ->orWhere('jenis_surat', 'like', "%{$search}%");
            });
        }

        $periods = $query->latest()->paginate(10)->withQueryString();

        $expiringSoon = LetterActivePeriod::whereBetween('masa_aktif_berakhir', [
            now()->startOfDay(),
            now()->addDays(7)->endOfDay(),
        ])->count();

        return view('letter-active-periods.index', compact('periods', 'expiringSoon'));
    }

    public function create(): View
    {
        return view('letter-active-periods.create');
    }

    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'nama_surat' => ['required', 'string', 'max:255'],
            'start_aktif' => ['required', 'date'],
            'jenis_surat' => ['required', 'in:SIK,SC'],
        ]);

        $start = \Carbon\Carbon::parse($validated['start_aktif']);
        $months = $validated['jenis_surat'] === 'SIK' ? 1 : 3;
        $end = $start->copy()->addMonths($months);

        LetterActivePeriod::create([
            'nama_surat' => $validated['nama_surat'],
            'start_aktif' => $validated['start_aktif'],
            'jenis_surat' => $validated['jenis_surat'],
            'masa_aktif_berakhir' => $end->format('Y-m-d'),
            'created_by' => Auth::id(),
        ]);

        return redirect()->route('letter-active-periods.index')
            ->with('success', 'Masa aktif surat berhasil ditambahkan.');
    }

    public function edit(LetterActivePeriod $letterActivePeriod): View
    {
        return view('letter-active-periods.edit', compact('letterActivePeriod'));
    }

    public function update(Request $request, LetterActivePeriod $letterActivePeriod): RedirectResponse
    {
        $validated = $request->validate([
            'nama_surat' => ['required', 'string', 'max:255'],
            'start_aktif' => ['required', 'date'],
            'jenis_surat' => ['required', 'in:SIK,SC'],
        ]);

        $start = \Carbon\Carbon::parse($validated['start_aktif']);
        $months = $validated['jenis_surat'] === 'SIK' ? 1 : 3;
        $end = $start->copy()->addMonths($months);

        $letterActivePeriod->update([
            'nama_surat' => $validated['nama_surat'],
            'start_aktif' => $validated['start_aktif'],
            'jenis_surat' => $validated['jenis_surat'],
            'masa_aktif_berakhir' => $end->format('Y-m-d'),
        ]);

        return redirect()->route('letter-active-periods.index')
            ->with('success', 'Masa aktif surat berhasil diperbarui.');
    }

    public function destroy(LetterActivePeriod $letterActivePeriod): RedirectResponse
    {
        $letterActivePeriod->delete();

        return redirect()->route('letter-active-periods.index')
            ->with('success', 'Masa aktif surat berhasil dihapus.');
    }
}
