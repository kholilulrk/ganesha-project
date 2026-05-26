<?php

namespace App\Http\Controllers;

use App\Models\SphCalculation;
use App\Models\Task;
use App\Services\ActivityLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class SphController extends Controller
{
    public function index(): View
    {
        $user = Auth::user();
        $calculations = SphCalculation::with(['task', 'creator'])
            ->latest()
            ->paginate(10);

        return view('sph.index', compact('calculations'));
    }

    public function create(Request $request): View
    {
        $tipe = $request->query('tipe', 'dalam_kota');

        if (!in_array($tipe, ['dalam_kota', 'luar_kota'])) {
            abort(404);
        }

        $tasks = Task::orderBy('created_at', 'desc')->get();

        return view('sph.create', compact('tipe', 'tasks'));
    }

    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'task_id' => ['required', 'exists:tasks,id'],
            'tipe' => ['required', 'in:dalam_kota,luar_kota'],
            'nomor_sph' => ['nullable', 'string', 'max:255'],
            'tanggal_sph' => ['nullable', 'date'],
            'honorarium' => ['nullable', 'numeric', 'min:0'],
            'material' => ['nullable', 'numeric', 'min:0'],
            'transport' => ['nullable', 'numeric', 'min:0'],
            'jumlah_minggu_transport' => ['nullable', 'numeric', 'min:0'],
            'uang_harian' => ['nullable', 'numeric', 'min:0'],
            'jumlah_minggu_harian' => ['nullable', 'numeric', 'min:0'],
            'akomodasi' => ['nullable', 'numeric', 'min:0'],
            'biaya_lain' => ['nullable', 'numeric', 'min:0'],
            'biaya_lain_keterangan' => ['nullable', 'string', 'max:500'],
            'overhead' => ['nullable', 'numeric', 'min:0'],
            'margin_keuntungan' => ['nullable', 'numeric', 'min:0'],
            'catatan' => ['nullable', 'string', 'max:5000'],
            'teknisi_assignments' => ['nullable', 'array'],
            'teknisi_assignments.*.nama' => ['required', 'string', 'max:255'],
            'teknisi_assignments.*.upah_per_bulan' => ['required', 'numeric', 'min:0'],
            'teknisi_assignments.*.jumlah_bulan' => ['required', 'numeric', 'min:0'],
        ]);

        $validated['honorarium'] = (float) ($validated['honorarium'] ?? 0);
        $validated['material'] = (float) ($validated['material'] ?? 0);

        $totalTeknisiUpah = 0;
        $assignments = $request->input('teknisi_assignments', []);
        foreach ($assignments as &$a) {
            $a['upah_per_bulan'] = (float) ($a['upah_per_bulan'] ?? 0);
            $a['jumlah_bulan'] = (float) ($a['jumlah_bulan'] ?? 0);
            $a['total'] = $a['upah_per_bulan'] * $a['jumlah_bulan'];
            $totalTeknisiUpah += $a['total'];
        }
        $validated['teknisi_assignments'] = $assignments;
        $validated['total_teknisi_upah'] = $totalTeknisiUpah;

        $jumlahTeknisi = count($assignments) > 0 ? count($assignments) : 1;
        $validated['transport'] = (float) ($validated['transport'] ?? 0);
        $validated['jumlah_minggu_transport'] = (float) ($validated['jumlah_minggu_transport'] ?? 4);
        $totalTransport = $validated['transport'] * 5 * $validated['jumlah_minggu_transport'] * $jumlahTeknisi;
        $validated['uang_harian'] = (float) ($validated['uang_harian'] ?? 0);
        $validated['jumlah_minggu_harian'] = (float) ($validated['jumlah_minggu_harian'] ?? 4);
        $totalUangHarian = $validated['uang_harian'] * 5 * $validated['jumlah_minggu_harian'] * $jumlahTeknisi;
        $validated['akomodasi'] = (float) ($validated['akomodasi'] ?? 0);
        $validated['biaya_lain'] = (float) ($validated['biaya_lain'] ?? 0);
        $validated['overhead'] = (float) ($validated['overhead'] ?? 0);
        $validated['margin_keuntungan'] = (float) ($validated['margin_keuntungan'] ?? 0);

        $subtotal = $validated['honorarium'] + $validated['material']
            + $totalTransport + $totalUangHarian
            + $validated['akomodasi'] + $validated['biaya_lain'] + $totalTeknisiUpah;

        $validated['total_biaya'] = $subtotal + $validated['overhead'];
        $validated['harga_penawaran'] = $validated['total_biaya'] * (1 + $validated['margin_keuntungan'] / 100);
        $validated['created_by'] = Auth::id();

        $sph = SphCalculation::create($validated);

        app(ActivityLogger::class)
            ->on($sph)
            ->withLogName('sph')
            ->log("membuat kalkulasi SPH #{$sph->id}");

        return redirect()->route('sph.index')
            ->with('success', 'Kalkulasi SPH berhasil disimpan.');
    }

    public function show(SphCalculation $sph): View
    {
        $sph->load(['task', 'creator']);
        return view('sph.show', compact('sph'));
    }

    public function edit(SphCalculation $sph): View
    {
        $tipe = $sph->tipe;
        $tasks = Task::orderBy('created_at', 'desc')->get();
        return view('sph.create', compact('sph', 'tipe', 'tasks'));
    }

    public function update(Request $request, SphCalculation $sph): RedirectResponse
    {
        $validated = $request->validate([
            'task_id' => ['required', 'exists:tasks,id'],
            'tipe' => ['required', 'in:dalam_kota,luar_kota'],
            'nomor_sph' => ['nullable', 'string', 'max:255'],
            'tanggal_sph' => ['nullable', 'date'],
            'honorarium' => ['nullable', 'numeric', 'min:0'],
            'material' => ['nullable', 'numeric', 'min:0'],
            'transport' => ['nullable', 'numeric', 'min:0'],
            'jumlah_minggu_transport' => ['nullable', 'numeric', 'min:0'],
            'uang_harian' => ['nullable', 'numeric', 'min:0'],
            'jumlah_minggu_harian' => ['nullable', 'numeric', 'min:0'],
            'akomodasi' => ['nullable', 'numeric', 'min:0'],
            'biaya_lain' => ['nullable', 'numeric', 'min:0'],
            'biaya_lain_keterangan' => ['nullable', 'string', 'max:500'],
            'overhead' => ['nullable', 'numeric', 'min:0'],
            'margin_keuntungan' => ['nullable', 'numeric', 'min:0'],
            'catatan' => ['nullable', 'string', 'max:5000'],
            'teknisi_assignments' => ['nullable', 'array'],
            'teknisi_assignments.*.nama' => ['required', 'string', 'max:255'],
            'teknisi_assignments.*.upah_per_bulan' => ['required', 'numeric', 'min:0'],
            'teknisi_assignments.*.jumlah_bulan' => ['required', 'numeric', 'min:0'],
        ]);

        $validated['honorarium'] = (float) ($validated['honorarium'] ?? 0);
        $validated['material'] = (float) ($validated['material'] ?? 0);

        $totalTeknisiUpah = 0;
        $assignments = $request->input('teknisi_assignments', []);
        foreach ($assignments as &$a) {
            $a['upah_per_bulan'] = (float) ($a['upah_per_bulan'] ?? 0);
            $a['jumlah_bulan'] = (float) ($a['jumlah_bulan'] ?? 0);
            $a['total'] = $a['upah_per_bulan'] * $a['jumlah_bulan'];
            $totalTeknisiUpah += $a['total'];
        }
        $validated['teknisi_assignments'] = $assignments;
        $validated['total_teknisi_upah'] = $totalTeknisiUpah;

        $jumlahTeknisi = count($assignments) > 0 ? count($assignments) : 1;
        $validated['transport'] = (float) ($validated['transport'] ?? 0);
        $validated['jumlah_minggu_transport'] = (float) ($validated['jumlah_minggu_transport'] ?? 4);
        $totalTransport = $validated['transport'] * 5 * $validated['jumlah_minggu_transport'] * $jumlahTeknisi;
        $validated['uang_harian'] = (float) ($validated['uang_harian'] ?? 0);
        $validated['jumlah_minggu_harian'] = (float) ($validated['jumlah_minggu_harian'] ?? 4);
        $totalUangHarian = $validated['uang_harian'] * 5 * $validated['jumlah_minggu_harian'] * $jumlahTeknisi;
        $validated['akomodasi'] = (float) ($validated['akomodasi'] ?? 0);
        $validated['biaya_lain'] = (float) ($validated['biaya_lain'] ?? 0);
        $validated['overhead'] = (float) ($validated['overhead'] ?? 0);
        $validated['margin_keuntungan'] = (float) ($validated['margin_keuntungan'] ?? 0);

        $subtotal = $validated['honorarium'] + $validated['material']
            + $totalTransport + $totalUangHarian
            + $validated['akomodasi'] + $validated['biaya_lain'] + $totalTeknisiUpah;

        $validated['total_biaya'] = $subtotal + $validated['overhead'];
        $validated['harga_penawaran'] = $validated['total_biaya'] * (1 + $validated['margin_keuntungan'] / 100);

        $sph->update($validated);

        app(ActivityLogger::class)
            ->on($sph)
            ->withLogName('sph')
            ->log("memperbarui kalkulasi SPH #{$sph->id}");

        return redirect()->route('sph.index')
            ->with('success', 'Kalkulasi SPH berhasil diperbarui.');
    }

    public function destroy(SphCalculation $sph): RedirectResponse
    {
        $id = $sph->id;
        $sph->delete();

        app(ActivityLogger::class)
            ->withLogName('sph')
            ->log("menghapus kalkulasi SPH #{$id}");

        return redirect()->route('sph.index')
            ->with('success', 'Kalkulasi SPH berhasil dihapus.');
    }
}
