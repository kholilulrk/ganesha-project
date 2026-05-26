@push('breadcrumbs')
    <x-breadcrumbs :items="[
        ['label' => 'Dashboard', 'url' => route('dashboard')],
        ['label' => 'Activity Log'],
    ]" />
@endpush

<x-app-layout>
    <x-slot name="header">
        <h2 class="text-xl font-semibold text-gray-800">Riwayat Aktivitas</h2>
    </x-slot>

    <div class="py-6">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            {{-- Filter & Hapus --}}
            <div class="bg-white shadow-sm rounded-lg overflow-hidden mb-6">
                <div class="p-4 flex flex-wrap items-end gap-4">
                    <form method="GET" action="{{ route('activity-logs.index') }}" class="flex flex-wrap items-end gap-4">
                        <div>
                            <label class="block text-xs font-medium text-gray-600 mb-1">Dari Tanggal</label>
                            <input type="date" name="date_from" value="{{ request('date_from') }}"
                                   class="rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">
                        </div>
                        <div>
                            <label class="block text-xs font-medium text-gray-600 mb-1">Sampai Tanggal</label>
                            <input type="date" name="date_to" value="{{ request('date_to') }}"
                                   class="rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">
                        </div>
                        <button type="submit"
                                class="px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-md hover:bg-indigo-700 transition">
                            Filter
                        </button>
                        @if(request('date_from') || request('date_to'))
                            <a href="{{ route('activity-logs.index') }}"
                               class="px-4 py-2 bg-gray-200 text-gray-700 text-sm font-medium rounded-md hover:bg-gray-300 transition">
                                Reset
                            </a>
                        @endif
                    </form>

                    <form method="POST" action="{{ route('activity-logs.destroy-before') }}"
                          class="flex items-end gap-4 ml-auto"
                          onsubmit="return confirm('Yakin ingin menghapus semua log sebelum tanggal yang dipilih? Data yang dihapus tidak dapat dikembalikan.');">
                        @csrf
                        <div>
                            <label class="block text-xs font-medium text-gray-600 mb-1">Hapus Log Sebelum Tanggal</label>
                            <input type="date" name="delete_date" required
                                   class="rounded-md border-gray-300 shadow-sm focus:border-red-500 focus:ring-red-500 text-sm">
                        </div>
                        <button type="submit"
                                class="px-4 py-2 bg-red-600 text-white text-sm font-medium rounded-md hover:bg-red-700 transition">
                            Hapus
                        </button>
                    </form>
                </div>
            </div>

            {{-- Daftar Log --}}
            <div class="bg-white shadow-sm rounded-lg overflow-hidden">
                <div class="p-4 border-b border-gray-200 text-sm text-gray-500">
                    Menampilkan aktivitas terbaru — diurutkan dari yang terbaru.
                </div>

                @if($logs->isEmpty())
                    <div class="p-6 text-center text-gray-400 text-sm">Belum ada aktivitas.</div>
                @else
                    <ul class="divide-y divide-gray-100">
                        @foreach($logs as $log)
                            <li class="px-4 py-3 flex items-start gap-3 hover:bg-gray-50 transition">
                                <div class="w-8 h-8 rounded-full bg-indigo-100 text-indigo-600 flex items-center justify-center text-xs font-bold shrink-0 mt-0.5">
                                    {{ strtoupper(substr($log->user?->name ?? 'S', 0, 1)) }}
                                </div>
                                <div class="flex-1 min-w-0">
                                    <p class="text-sm text-gray-800">
                                        <span class="font-semibold">{{ $log->user?->name ?? 'System' }}</span>
                                        {{ $log->description }}
                                    </p>
                                    <p class="text-xs text-gray-400 mt-0.5">
                                        {{ $log->created_at->timezone('Asia/Jakarta')->format('d M Y H:i') }}
                                        ·
                                        <span class="capitalize">{{ $log->log_name }}</span>
                                    </p>
                                </div>
                                @php
                                    $subjectUrl = match (true) {
                                        $log->subject instanceof \App\Models\Task => route('tasks.show', $log->subject),
                                        $log->subject instanceof \App\Models\Document => route('documents.show', $log->subject),
                                        $log->subject instanceof \App\Models\SphCalculation => route('sph.show', $log->subject),
                                        default => null,
                                    };
                                @endphp
                                @if($subjectUrl)
                                    <a href="{{ $subjectUrl }}" class="shrink-0 text-xs text-indigo-600 hover:text-indigo-800 hover:underline mt-1">
                                        Lihat
                                    </a>
                                @endif
                            </li>
                        @endforeach
                    </ul>

                    <div class="p-4 border-t border-gray-100">
                        {{ $logs->links() }}
                    </div>
                @endif
            </div>
        </div>
    </div>
</x-app-layout>
