<x-app-layout>
    @push('breadcrumbs')
        <x-breadcrumbs :items="[
            ['label' => 'Dashboard', 'url' => route('dashboard')],
            ['label' => 'Kalkulasi SPH', 'url' => route('sph.index')],
            ['label' => 'Detail'],
        ]" />
    @endpush
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">Detail Kalkulasi SPH</h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-4xl mx-auto sm:px-6 lg:px-8 space-y-6">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6">
                <div class="print-header">
                    <div class="flex items-center justify-between mb-2">
                        <h3 class="font-semibold text-gray-800">Detail Kalkulasi SPH</h3>
                    </div>
                    <div class="border-2 border-indigo-200 rounded-xl p-4 bg-indigo-50/50 mb-4">
                        <div class="flex items-center justify-between gap-4">
                            <div class="min-w-0">
                                <span class="text-xs text-gray-500 font-medium uppercase tracking-wider">Nama Kapal</span>
                                <p class="text-lg font-bold text-gray-900 mt-0.5">{{ $sph->task->title }}</p>
                            </div>
                            <span class="inline-flex items-center px-4 py-1.5 rounded-full text-sm font-bold whitespace-nowrap {{ $sph->tipe === 'dalam_kota' ? 'bg-indigo-100 text-indigo-700' : 'bg-amber-100 text-amber-700' }}">
                                {{ $sph->tipe === 'dalam_kota' ? 'Dalam Kota' : 'Luar Kota' }}
                            </span>
                        </div>
                    </div>

                @if ($sph->nomor_sph || $sph->tanggal_sph)
                <div class="grid grid-cols-2 gap-4 mb-4 p-3 bg-gray-50 rounded-lg">
                    @if ($sph->nomor_sph)
                    <div>
                        <span class="text-xs text-gray-500">Nomor SPH</span>
                        <p class="text-sm font-medium">{{ $sph->nomor_sph }}</p>
                    </div>
                    @endif
                    @if ($sph->tanggal_sph)
                    <div>
                        <span class="text-xs text-gray-500">Tanggal SPH</span>
                        <p class="text-sm font-medium">{{ $sph->tanggal_sph->format('d/m/Y') }}</p>
                    </div>
                    @endif
                </div>
                @endif

                <div class="overflow-x-auto">
                    <table class="w-full text-sm">
                        <thead>
                            <tr class="border-b">
                                <th class="text-left py-2 pr-4 font-medium text-gray-600">Komponen Biaya</th>
                                <th class="text-right py-2 font-medium text-gray-600">Jumlah</th>
                            </tr>
                        </thead>
                        <tbody>
                            @php $jmlTeknisi = count($sph->teknisi_assignments ?? []) ?: 1; @endphp
                            @foreach ([
                                'Jasa' => $sph->honorarium,
                                'Material' => $sph->material,
                                'Transport' => $sph->transport * 5 * ($sph->jumlah_minggu_transport ?? 4) * $jmlTeknisi,
                                'Uang Makan' => $sph->uang_harian * 5 * ($sph->jumlah_minggu_harian ?? 4) * $jmlTeknisi,
                                'Akomodasi' => $sph->akomodasi,
                                'Biaya Lain' => $sph->biaya_lain,
                            ] as $label => $value)
                            @if ($value > 0 || ($label === 'Akomodasi' && $sph->tipe === 'luar_kota'))
                            <tr class="border-b last:border-0">
                                <td class="py-2 pr-4 text-gray-700">{{ $label }}
                                    @if ($label === 'Transport')
                                    <span class="text-gray-400">(Rp {{ number_format($sph->transport, 0, ',', '.') }} &times; {{ 5 * ($sph->jumlah_minggu_transport ?? 4) }} Hari &times; {{ $jmlTeknisi }} Teknisi)</span>
                                    @endif
                                    @if ($label === 'Uang Makan')
                                    <span class="text-gray-400">(Rp {{ number_format($sph->uang_harian, 0, ',', '.') }} &times; {{ 5 * ($sph->jumlah_minggu_harian ?? 4) }} Hari &times; {{ $jmlTeknisi }} Teknisi)</span>
                                    @endif
                                    @if ($label === 'Biaya Lain' && $sph->biaya_lain_keterangan)
                                    <span class="text-gray-400">({{ $sph->biaya_lain_keterangan }})</span>
                                    @endif
                                </td>
                                <td class="py-2 text-right font-medium">Rp {{ number_format($value, 0, ',', '.') }}</td>
                            </tr>
                            @endif
                            @endforeach
                            <tr class="border-b">
                                <td class="py-2 pr-4 text-gray-700">Overhead</td>
                                <td class="py-2 text-right font-medium">Rp {{ number_format($sph->overhead, 0, ',', '.') }}</td>
                            </tr>
                        </tbody>
                        <tfoot>
                            @php
                                $totalKomponenBiaya = $sph->honorarium
                                    + $sph->material
                                    + ($sph->transport * 5 * ($sph->jumlah_minggu_transport ?? 4) * $jmlTeknisi)
                                    + ($sph->uang_harian * 5 * ($sph->jumlah_minggu_harian ?? 4) * $jmlTeknisi)
                                    + ($sph->akomodasi ?? 0)
                                    + $sph->biaya_lain
                                    + $sph->overhead;
                            @endphp
                            <tr class="border-t-2 border-indigo-200">
                                <td class="py-2 pr-4 font-semibold text-indigo-800">Total Komponen Biaya</td>
                                <td class="py-2 text-right font-bold text-indigo-700">Rp {{ number_format($totalKomponenBiaya, 0, ',', '.') }}</td>
                            </tr>
                        </tfoot>
                    </table>
                </div>

                @if ($sph->teknisi_assignments && count($sph->teknisi_assignments) > 0)
                <div class="mt-4">
                    <h4 class="text-sm font-semibold text-gray-700 mb-2">Upah Teknisi Assign</h4>
                    <div class="overflow-x-auto">
                        <table class="w-full text-sm">
                            <thead>
                                <tr class="border-b text-left">
                                    <th class="py-2 pr-4 font-medium text-gray-600">Teknisi</th>
                                    <th class="py-2 pr-4 font-medium text-gray-600">Upah/Bulan</th>
                                    <th class="py-2 pr-4 font-medium text-gray-600">Jumlah Bulan</th>
                                    <th class="py-2 text-right font-medium text-gray-600">Total</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach ($sph->teknisi_assignments as $t)
                                <tr class="border-b last:border-0">
                                    <td class="py-2 pr-4">{{ $t['nama'] }}</td>
                                    <td class="py-2 pr-4">Rp {{ number_format($t['upah_per_bulan'], 0, ',', '.') }}</td>
                                    <td class="py-2 pr-4">{{ $t['jumlah_bulan'] }}</td>
                                    <td class="py-2 text-right font-medium">Rp {{ number_format($t['total'], 0, ',', '.') }}</td>
                                </tr>
                                @endforeach
                            </tbody>
                            <tfoot>
                                <tr class="border-t-2 border-indigo-200">
                                    <td colspan="3" class="py-2 pr-4 font-semibold text-indigo-800">Total Upah Teknisi</td>
                                    <td class="py-2 text-right font-bold text-indigo-700">Rp {{ number_format($sph->total_teknisi_upah, 0, ',', '.') }}</td>
                                </tr>
                            </tfoot>
                        </table>
                    </div>
                </div>
                @endif

                <div class="border-t-2 border-gray-300 pt-4 mt-4 space-y-1">
                    <div class="flex justify-between items-center">
                        <span class="font-semibold text-gray-800">Total Biaya</span>
                        <span class="font-bold text-lg">Rp {{ number_format($sph->total_biaya, 0, ',', '.') }}</span>
                    </div>
                    <div class="flex justify-between items-center text-sm text-gray-500">
                        <span>Margin Keuntungan</span>
                        <span>{{ number_format($sph->margin_keuntungan, 0) }}%</span>
                    </div>
                    <div class="flex justify-between items-center border-t-2 border-indigo-300 pt-2">
                        <span class="font-semibold text-indigo-800">Harga Penawaran</span>
                        <span class="font-bold text-lg text-indigo-700">Rp {{ number_format($sph->harga_penawaran, 0, ',', '.') }}</span>
                    </div>
                </div>

                @if ($sph->catatan)
                <div class="mt-4 p-3 bg-gray-50 rounded-lg">
                    <span class="text-xs text-gray-500">Catatan</span>
                    <p class="text-sm text-gray-700">{{ $sph->catatan }}</p>
                </div>
                @endif

                <div class="mt-4 text-xs text-gray-400">
                    Dibuat oleh: {{ $sph->creator->name }} | {{ $sph->created_at->format('d/m/Y H:i') }}
                </div>

                <div class="flex items-center gap-3 mt-6 pt-4 border-t no-print">
                    <a href="{{ route('sph.edit', $sph) }}" class="inline-flex items-center px-4 py-2 bg-amber-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-amber-500 transition">Edit</a>
                    <button onclick="window.print()" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-500 transition">Download / Cetak PDF</button>
                    <a href="{{ route('sph.index') }}" class="inline-flex items-center px-4 py-2 bg-gray-200 border border-transparent rounded-md font-semibold text-xs text-gray-700 uppercase tracking-widest hover:bg-gray-300 transition">Kembali</a>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>

<style>
    @media print {
        @page {
            size: A4;
            margin: 20mm 15mm;
        }
        body { background: #fff !important; font-size: 11px !important; }
        .text-sm { font-size: 10px !important; }
        .text-xs { font-size: 9px !important; }
        .text-lg { font-size: 13px !important; }
        .text-xl { font-size: 14px !important; }
        nav, header, .no-print, [x-cloak] { display: none !important; }
        .min-h-screen, .flex-1, .lg\:ml-64, .min-w-0 { min-height: 0 !important; margin-left: 0 !important; max-width: 100% !important; }
        .min-h-screen { display: block !important; }
        .py-12 { padding-top: 0 !important; padding-bottom: 0 !important; }
        .p-6 { padding: 12px !important; }
        .max-w-4xl { max-width: 100% !important; margin: 0 !important; }
        .sm\:px-6, .lg\:px-8, .px-4 { padding-left: 0 !important; padding-right: 0 !important; }
        .space-y-6 > :not([hidden]) ~ :not([hidden]) { margin-top: 8px !important; }
        .mb-4 { margin-bottom: 8px !important; }
        .mb-2 { margin-bottom: 4px !important; }
        .mt-4 { margin-top: 8px !important; }
        .mt-6 { margin-top: 12px !important; }
        .gap-4 { gap: 8px !important; }
        .space-y-1 > :not([hidden]) ~ :not([hidden]) { margin-top: 2px !important; }
        .py-2 { padding-top: 4px !important; padding-bottom: 4px !important; }
        .p-3 { padding: 6px !important; }
        .pt-4 { padding-top: 6px !important; }
        .shadow-sm, .shadow { box-shadow: none !important; }
        .rounded-lg, .sm\:rounded-lg { border-radius: 0 !important; }
        .overflow-hidden { overflow: visible !important; }
        .bg-white, .bg-gray-100 { background: #fff !important; }
        th { color: #4338ca !important; border-bottom-color: #6366f1 !important; }
        h3, h4 { color: #4338ca !important; }
        .bg-indigo-100.text-indigo-700, .bg-amber-100.text-amber-700 { padding: 2px 10px !important; border-radius: 999px !important; font-weight: 600 !important; }
        .bg-indigo-100.text-indigo-700 { background: #e0e7ff !important; color: #4338ca !important; }
        .bg-amber-100.text-amber-700 { background: #fef3c7 !important; color: #d97706 !important; }
        .print-header .border-2 { border-color: #6366f1 !important; }
        .print-header .bg-indigo-50\/50 { background: #eef2ff !important; }
        .print-header .p-4 { padding: 8px 12px !important; }
        .print-header .rounded-xl { border-radius: 8px !important; }
        .print-header .text-lg { font-size: 14px !important; }
        .print-header .px-4 { padding-left: 8px !important; padding-right: 8px !important; }
        .print-header .py-1\.5 { padding-top: 2px !important; padding-bottom: 2px !important; }
        .space-y-6 > :not([hidden]) ~ :not([hidden]) { margin-top: 0 !important; }
        .border-t-2 { border-top-color: #6366f1 !important; }
        .text-indigo-800 { color: #4338ca !important; }
        .text-indigo-700 { color: #4338ca !important; }
        .border-indigo-300 { border-color: #6366f1 !important; }
        .bg-indigo-50 { background: #eef2ff !important; }
        .text-indigo-600 { color: #4f46e5 !important; }
        .bg-indigo-100 { background: #e0e7ff !important; }
        table { page-break-inside: auto; width: 100% !important; }
        tr { page-break-inside: avoid; }
    }
</style>
