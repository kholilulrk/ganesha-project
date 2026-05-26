<x-app-layout>
    @push('breadcrumbs')
        <x-breadcrumbs :items="[
            ['label' => 'Dashboard'],
        ]" />
    @endpush
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Dashboard Super Admin') }}
        </h2>
    </x-slot>

    @if($expiringLetters->count() > 0)
        <style>
            @keyframes card-alert {
                0%, 100% { transform: scale(1); box-shadow: 0 0 0 0 rgba(239,68,68,0.4); }
                50% { transform: scale(1.02); box-shadow: 0 0 0 8px rgba(239,68,68,0); }
            }
            @keyframes icon-alert {
                0%, 100% { transform: rotate(0deg); }
                25% { transform: rotate(-12deg); }
                75% { transform: rotate(12deg); }
            }
            .animate-card-alert { animation: card-alert 1.5s ease-in-out infinite; }
            .animate-icon-alert { animation: icon-alert 0.6s ease-in-out infinite; }
        </style>
    @endif

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            @include('dashboard.partials._announcement', ['announcement' => $latestAnnouncement])

            <div class="mb-8">
                <a href="{{ route('letter-active-periods.index') }}"
                   class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6 hover:bg-amber-50 transition block max-w-sm
                          {{ $expiringLetters->count() > 0 ? 'animate-card-alert ring-2 ring-red-300' : '' }}">
                    <div class="flex items-center gap-3">
                        @if($expiringLetters->count() > 0)
                            <svg class="w-7 h-7 text-red-500 animate-icon-alert shrink-0" fill="currentColor" viewBox="0 0 20 20">
                                <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
                            </svg>
                        @else
                            <svg class="w-7 h-7 text-gray-400 shrink-0" fill="currentColor" viewBox="0 0 20 20">
                                <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
                            </svg>
                        @endif
                        <div>
                            <p class="text-sm text-gray-500">M. Aktif Surat</p>
                            <p class="text-3xl font-bold mt-1 {{ $expiringLetters->count() > 0 ? 'text-red-600' : '' }}">{{ $expiringLetters->count() }}</p>
                            <p class="text-xs text-gray-400 mt-1">akan berakhir dalam 7 hari</p>
                        </div>
                    </div>
                </a>
            </div>

            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6 mb-8">
                <h3 class="text-sm font-semibold text-gray-500 mb-4">Data Pekerjaan</h3>
                <div class="flex gap-4">
                    <a href="{{ route('tasks.index', ['status' => 'pending']) }}" class="flex-1 p-4 bg-gray-50 rounded-lg border-l-4 border-yellow-400 hover:bg-gray-100 transition block">
                        <p class="text-sm text-gray-500">Pending</p>
                        <p class="text-2xl font-bold mt-1">{{ $stats['tasks_pending'] }}</p>
                    </a>
                    <a href="{{ route('tasks.index', ['status' => 'progress']) }}" class="flex-1 p-4 bg-gray-50 rounded-lg border-l-4 border-blue-400 hover:bg-gray-100 transition block">
                        <p class="text-sm text-gray-500">In Progress</p>
                        <p class="text-2xl font-bold mt-1">{{ $stats['tasks_progress'] }}</p>
                    </a>
                    <a href="{{ route('tasks.index', ['status' => 'done']) }}" class="flex-1 p-4 bg-gray-50 rounded-lg border-l-4 border-green-400 hover:bg-gray-100 transition block">
                        <p class="text-sm text-gray-500">Completed</p>
                        <p class="text-2xl font-bold mt-1">{{ $stats['tasks_done'] }}</p>
                    </a>
                </div>
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
                    <h3 class="text-lg font-semibold mb-4">Recent Tasks</h3>
                    @if ($recentTasks->isNotEmpty())
                        <div class="space-y-3">
                            @foreach ($recentTasks as $t)
                                <div class="flex items-center justify-between text-sm border-b pb-2 last:border-0">
                                    <div>
                                        <a href="{{ route('tasks.show', $t) }}" class="text-indigo-600 hover:text-indigo-900 font-medium">{{ $t->title }}</a>
                                        <p class="text-xs text-gray-400 mt-0.5">
                                            {{ $t->task_type }} | {{ $t->creator?->name }}
                                        </p>
                                    </div>
                                    <span class="px-2 py-0.5 text-xs rounded-full
                                        @if($t->status === 'pending') bg-gray-100 text-gray-600
                                        @elseif($t->status === 'progress') bg-yellow-100 text-yellow-700
                                        @elseif($t->status === 'done') bg-green-100 text-green-700
                                        @else bg-red-100 text-red-700 @endif">
                                        {{ ucfirst($t->status) }}
                                    </span>
                                </div>
                            @endforeach
                        </div>
                        <a href="{{ route('tasks.index') }}" class="mt-3 inline-block text-sm text-indigo-600 hover:text-indigo-900">View all tasks &rarr;</a>
                    @else
                        <p class="text-gray-500 text-sm">No tasks yet.</p>
                    @endif
                </div>

                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6">
                    <h3 class="text-lg font-semibold mb-4">Quick Actions</h3>
                    <div class="grid grid-cols-2 gap-3">
                        <a href="{{ route('admin.users.index') }}" class="p-4 bg-gray-50 rounded-lg hover:bg-gray-100 text-sm font-medium text-center">👥 Kelola Users</a>
                        <a href="{{ route('tasks.create') }}" class="p-4 bg-gray-50 rounded-lg hover:bg-gray-100 text-sm font-medium text-center">📝 Buat Task</a>
                        <a href="{{ route('admin.monitoring.logistic') }}" class="p-4 bg-gray-50 rounded-lg hover:bg-gray-100 text-sm font-medium text-center">📦 Monitoring Logistic</a>
                        <a href="{{ route('admin.monitoring.teknisi') }}" class="p-4 bg-gray-50 rounded-lg hover:bg-gray-100 text-sm font-medium text-center">🔧 Monitoring Teknisi</a>
                        <a href="{{ route('admin.roles.index') }}" class="p-4 bg-gray-50 rounded-lg hover:bg-gray-100 text-sm font-medium text-center">🔐 Role & Permission</a>
                        <a href="{{ route('documents.index') }}" class="p-4 bg-gray-50 rounded-lg hover:bg-gray-100 text-sm font-medium text-center">📄 Dokumen</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
