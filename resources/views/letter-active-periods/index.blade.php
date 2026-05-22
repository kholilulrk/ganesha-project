<x-app-layout>
    <x-slot name="header">
        <div class="flex flex-wrap items-center justify-between gap-2">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">Masa Aktif Surat</h2>
            <a href="{{ route('letter-active-periods.create') }}" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-500 shadow-sm">
                <svg class="w-4 h-4 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                Buat Surat
            </a>
        </div>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            @if (session('success'))
                <div class="mb-4 px-4 py-2 bg-green-100 border border-green-200 text-green-700 rounded-md text-sm">
                    {{ session('success') }}
                </div>
            @endif

            @if ($expiringSoon > 0)
                <div class="mb-4 px-4 py-3 bg-amber-50 border border-amber-200 text-amber-800 rounded-md text-sm flex items-center gap-2">
                    <svg class="w-5 h-5 shrink-0 text-amber-500" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/></svg>
                    <span><span class="font-semibold">{{ $expiringSoon }}</span> surat akan berakhir dalam 7 hari. Segera lakukan perpanjangan.</span>
                </div>
            @endif

            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6">
                    <form method="GET" class="mb-4 flex flex-wrap items-end gap-3">
                        <div class="flex-1 min-w-[200px]">
                            <label class="text-xs text-gray-500 block mb-1">Cari</label>
                            <input type="text" name="search" value="{{ request('search') }}" placeholder="Cari nama surat..." class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">
                        </div>
                        <div class="flex items-center gap-2">
                            <button type="submit" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-500">Filter</button>
                            @if(request()->filled('search'))
                                <a href="{{ route('letter-active-periods.index') }}" class="inline-flex items-center px-4 py-2 bg-gray-200 border border-transparent rounded-md font-semibold text-xs text-gray-700 uppercase tracking-widest hover:bg-gray-300">Reset</a>
                            @endif
                        </div>
                    </form>

                    <div class="overflow-x-auto -mx-6 sm:mx-0 px-6">
                    <table class="min-w-full w-full text-sm whitespace-nowrap">
                        <thead>
                            <tr class="border-b text-left">
                                <th class="pb-3 font-medium">Nama Surat</th>
                                <th class="pb-3 font-medium">Jenis</th>
                                <th class="pb-3 font-medium">Start Aktif</th>
                                <th class="pb-3 font-medium">Masa Aktif Berakhir</th>
                                <th class="pb-3 font-medium">Dibuat Oleh</th>
                                <th class="pb-3 font-medium"></th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse ($periods as $period)
                                <tr class="border-b last:border-0">
                                    <td class="py-3">{{ $period->nama_surat }}</td>
                                    <td class="py-3">
                                        <span class="px-2 py-0.5 text-xs rounded-full {{ $period->jenis_surat === 'SIK' ? 'bg-blue-100 text-blue-700' : 'bg-purple-100 text-purple-700' }}">
                                            {{ $period->jenis_surat }}
                                        </span>
                                    </td>
                                    <td class="py-3">{{ $period->start_aktif->format('d M Y') }}</td>
                                    <td class="py-3">
                                        <div class="flex items-center gap-2">
                                            {{ $period->masa_aktif_berakhir->format('d M Y') }}
                                            @php $daysLeft = now()->startOfDay()->diffInDays($period->masa_aktif_berakhir, false); @endphp
                                            @if ($daysLeft >= 0 && $daysLeft <= 7)
                                                <span class="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-red-100 text-red-700">
                                                    <svg class="w-3 h-3 mr-0.5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/></svg>
                                                    {{ $daysLeft }} hr
                                                </span>
                                            @elseif ($daysLeft < 0)
                                                <span class="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-gray-200 text-gray-600">Expired</span>
                                            @endif
                                        </div>
                                    </td>
                                    <td class="py-3">{{ $period->creator?->name }}</td>
                                    <td class="py-3 text-right">
                                        <a href="{{ route('letter-active-periods.edit', $period) }}" class="text-amber-600 hover:text-amber-900 mr-2">Edit</a>
                                        <form action="{{ route('letter-active-periods.destroy', $period) }}" method="POST" class="inline" x-data="{ loading: false }" x-on:submit="if(confirm('Hapus data ini?')) loading = true; else $event.preventDefault()">
                                            @csrf @method('DELETE')
                                            <button x-bind:disabled="loading" type="submit" class="text-red-600 hover:text-red-900">Delete</button>
                                        </form>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="10" class="py-6 text-center text-gray-500">Belum ada data.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                    </div>
                    <div class="mt-4">
                        {{ $periods->links() }}
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
