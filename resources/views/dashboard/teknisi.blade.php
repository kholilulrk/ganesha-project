<x-app-layout>
    @push('breadcrumbs')
        <x-breadcrumbs :items="[
            ['label' => 'Dashboard'],
        ]" />
    @endpush
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Dashboard Teknisi') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            @include('dashboard.partials._announcement', ['announcement' => $latestAnnouncement])

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
                <a href="{{ route('tasks.index', ['status' => 'pending']) }}" class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6 hover:bg-gray-50 transition block">
                    <p class="text-sm text-gray-500">Tugas Pending</p>
                    <p class="text-3xl font-bold mt-1 text-yellow-600">{{ $stats['tugas_pending'] }}</p>
                </a>
                <a href="{{ route('tasks.index', ['status' => 'progress']) }}" class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6 hover:bg-gray-50 transition block">
                    <p class="text-sm text-gray-500">Tugas Progress</p>
                    <p class="text-3xl font-bold mt-1 text-blue-600">{{ $stats['tugas_progress'] }}</p>
                </a>
                <a href="{{ route('tasks.index', ['status' => 'done']) }}" class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6 hover:bg-gray-50 transition block">
                    <p class="text-sm text-gray-500">Tugas Selesai</p>
                    <p class="text-3xl font-bold mt-1 text-green-600">{{ $stats['tugas_selesai'] }}</p>
                </a>
            </div>

            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6">
                <div class="flex items-center justify-between mb-4">
                    <h3 class="text-lg font-semibold">Tugas Saya</h3>
                    <a href="{{ route('tasks.index') }}" class="text-sm text-indigo-600 hover:text-indigo-900">Lihat Semua</a>
                </div>
                @if ($tasks->isNotEmpty())
                    <div class="space-y-3">
                        @foreach ($tasks as $task)
                            <div class="flex items-center justify-between text-sm border-b pb-2 last:border-0">
                                <div class="min-w-0 flex-1">
                                    <a href="{{ route('tasks.show', $task) }}" class="font-medium text-gray-800 hover:text-indigo-600">{{ $task->title }}</a>
                                    <div class="flex items-center gap-2 mt-0.5 text-xs text-gray-400">
                                        <span>Deadline: {{ $task->deadline?->format('d M Y') ?? '-' }}</span>
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
                    <p class="text-sm text-gray-400">Belum ada tugas yang ditugaskan kepada Anda.</p>
                @endif
            </div>
        </div>
    </div>
</x-app-layout>
