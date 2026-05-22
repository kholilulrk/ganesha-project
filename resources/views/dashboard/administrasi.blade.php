<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Dashboard Administrasi') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
                <a href="{{ route('tasks.index', ['status' => 'pending']) }}" class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6 hover:bg-gray-50 transition block">
                    <p class="text-sm text-gray-500">Task Pending</p>
                    <p class="text-3xl font-bold mt-1 text-yellow-600">{{ $stats['task_pending'] }}</p>
                </a>
                <a href="{{ route('tasks.index') }}" class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6 hover:bg-gray-50 transition block">
                    <p class="text-sm text-gray-500">Barang Belum Dibeli</p>
                    <p class="text-3xl font-bold mt-1 text-red-600">{{ $stats['barang_belum_dibeli'] }}</p>
                </a>
                <a href="{{ route('letter-active-periods.index') }}" class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6 hover:bg-amber-50 transition block">
                    <p class="text-sm text-gray-500">M. Aktif Surat</p>
                    <p class="text-3xl font-bold mt-1 {{ $expiringLetters->count() > 0 ? 'text-red-600' : '' }}">{{ $expiringLetters->count() }}</p>
                    <p class="text-xs text-gray-400 mt-1">akan berakhir dalam 7 hari</p>
                </a>
            </div>

            @if ($expiringLetters->isNotEmpty())
                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6 mb-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-lg font-semibold flex items-center gap-2">
                            <svg class="w-5 h-5 text-amber-500" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/></svg>
                            Surat Akan Berakhir
                        </h3>
                        <a href="{{ route('letter-active-periods.index') }}" class="text-sm text-indigo-600 hover:text-indigo-900">Lihat Semua &rarr;</a>
                    </div>
                    <div class="space-y-3">
                        @foreach ($expiringLetters as $letter)
                            <div class="flex items-center justify-between text-sm border-b pb-2 last:border-0">
                                <div>
                                    <span class="font-medium">{{ $letter->nama_surat }}</span>
                                    <span class="ml-2 px-1.5 py-0.5 text-xs rounded-full {{ $letter->jenis_surat === 'SIK' ? 'bg-blue-100 text-blue-700' : 'bg-purple-100 text-purple-700' }}">{{ $letter->jenis_surat }}</span>
                                </div>
                                <div class="flex items-center gap-3">
                                    <span class="text-xs text-gray-400">Berakhir {{ $letter->masa_aktif_berakhir->format('d M Y') }}</span>
                                    @php $daysLeft = now()->startOfDay()->diffInDays($letter->masa_aktif_berakhir, false); @endphp
                                    <span class="px-2 py-0.5 text-xs font-medium rounded-full {{ $daysLeft < 0 ? 'bg-gray-200 text-gray-600' : 'bg-red-100 text-red-700' }}">
                                        {{ $daysLeft < 0 ? 'Expired' : $daysLeft . ' hr lagi' }}
                                    </span>
                                </div>
                            </div>
                        @endforeach
                    </div>
                </div>
            @endif

            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-lg font-semibold">Task Terbaru</h3>
                        <a href="{{ route('tasks.index') }}" class="text-sm text-indigo-600 hover:text-indigo-900">Lihat Semua</a>
                    </div>
                    @if ($recentTasks->isNotEmpty())
                        <div class="space-y-3">
                            @foreach ($recentTasks as $task)
                                <div class="flex items-center justify-between text-sm border-b pb-2 last:border-0">
                                    <div class="min-w-0 flex-1">
                                        <a href="{{ route('tasks.show', $task) }}" class="font-medium text-gray-800 hover:text-indigo-600">{{ $task->title }}</a>
                                        <div class="flex items-center gap-2 mt-0.5 text-xs text-gray-400">
                                            <span>{{ ucfirst($task->task_type) }}</span>
                                            <span>&middot;</span>
                                            <span>{{ $task->assignedUsers->pluck('name')->implode(', ') ?: 'Unassigned' }}</span>
                                        </div>
                                    </div>
                                    <span class="px-2 py-0.5 text-xs rounded-full shrink-0 ml-3
                                        @if($task->status === 'pending') bg-gray-100 text-gray-600
                                        @elseif($task->status === 'progress') bg-yellow-100 text-yellow-700
                                        @elseif($task->status === 'done') bg-green-100 text-green-700
                                        @else bg-red-100 text-red-700 @endif">
                                        {{ ucfirst($task->status) }}
                                    </span>
                                </div>
                            @endforeach
                        </div>
                    @else
                        <p class="text-sm text-gray-400">Belum ada task.</p>
                    @endif
                </div>

                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6">
                    <h3 class="text-lg font-semibold mb-4">Aksi Cepat</h3>
                    <div class="grid grid-cols-2 gap-3">
                        <a href="{{ route('tasks.create') }}" class="block p-4 bg-indigo-50 rounded-lg hover:bg-indigo-100 transition">
                            <p class="font-medium text-indigo-700">+ Buat Task</p>
                            <p class="text-xs text-indigo-500 mt-1">Buat tugas baru untuk teknisi atau logistic</p>
                        </a>
                        <a href="{{ route('documents.create') }}" class="block p-4 bg-green-50 rounded-lg hover:bg-green-100 transition">
                            <p class="font-medium text-green-700">+ Upload Dokumen</p>
                            <p class="text-xs text-green-500 mt-1">Upload dokumen pengadaan atau teknis</p>
                        </a>
                        <a href="{{ route('tasks.index') }}" class="block p-4 bg-amber-50 rounded-lg hover:bg-amber-100 transition">
                            <p class="font-medium text-amber-700">Lihat Tasks</p>
                            <p class="text-xs text-amber-500 mt-1">Monitoring seluruh task</p>
                        </a>
                        <a href="{{ route('documents.index') }}" class="block p-4 bg-cyan-50 rounded-lg hover:bg-cyan-100 transition">
                            <p class="font-medium text-cyan-700">Lihat Dokumen</p>
                            <p class="text-xs text-cyan-500 mt-1">Kelola dokumen tersimpan</p>
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
