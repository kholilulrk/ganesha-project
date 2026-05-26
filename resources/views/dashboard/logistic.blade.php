<x-app-layout>
    @push('breadcrumbs')
        <x-breadcrumbs :items="[
            ['label' => 'Dashboard'],
        ]" />
    @endpush
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Dashboard Logistic / Purchasing') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            @include('dashboard.partials._announcement', ['announcement' => $latestAnnouncement])

            <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
                <a href="{{ route('tasks.index') }}" class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6 hover:bg-gray-50 transition block">
                    <p class="text-sm text-gray-500">Total Tugas Pembelian</p>
                    <p class="text-3xl font-bold mt-1">{{ $stats['total_tugas'] }}</p>
                </a>
                <a href="{{ route('tasks.index', ['shopping_status' => 'incomplete']) }}" class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6 hover:bg-gray-50 transition block">
                    <p class="text-sm text-gray-500">Pekerjaan Perlu Dibeli</p>
                    <p class="text-3xl font-bold mt-1 text-red-600">{{ $stats['pekerjaan_perlu_dibeli'] }}</p>
                </a>
                <a href="{{ route('tasks.index', ['shopping_status' => 'incomplete']) }}" class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6 hover:bg-gray-50 transition block">
                    <p class="text-sm text-gray-500">Barang Belum Dibeli</p>
                    <p class="text-3xl font-bold mt-1 text-yellow-600">{{ $stats['barang_belum_dibeli'] }}</p>
                </a>
                <a href="{{ route('tasks.index', ['shopping_status' => 'complete']) }}" class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6 hover:bg-gray-50 transition block">
                    <p class="text-sm text-gray-500">Barang Selesai Dibeli</p>
                    <p class="text-3xl font-bold mt-1 text-green-600">{{ $stats['barang_selesai_dibeli'] }}</p>
                </a>
            </div>

            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6">
                <div class="flex items-center justify-between mb-4">
                    <h3 class="text-lg font-semibold">Tugas Pembelian Saya</h3>
                    <a href="{{ route('tasks.index') }}" class="text-sm text-indigo-600 hover:text-indigo-900">Lihat Semua</a>
                </div>
                @if ($tasks->isNotEmpty())
                    <div class="space-y-3">
                        @foreach ($tasks as $task)
                            @php
                                $totalItems = $task->shoppingItems->count();
                                $checkedItems = $task->shoppingItems->where('is_checked', true)->count();
                                $shoppingStatus = $totalItems === 0 || $checkedItems === 0 ? 'pending' : ($checkedItems === $totalItems ? 'done' : 'progress');
                            @endphp
                            <div class="flex items-center justify-between text-sm border-b pb-2 last:border-0">
                                <div class="min-w-0 flex-1">
                                    <a href="{{ route('tasks.show', $task) }}" class="font-medium text-gray-800 hover:text-indigo-600">{{ $task->title }}</a>
                                    <div class="flex items-center gap-2 mt-0.5 text-xs text-gray-400">
                                        <span>Shopping: {{ $checkedItems }}/{{ $totalItems }} item</span>
                                        <span>&middot;</span>
                                        <span>Deadline: {{ $task->deadline?->format('d M Y') ?? '-' }}</span>
                                    </div>
                                </div>
                                <span class="px-2 py-0.5 text-xs rounded-full shrink-0 ml-3
                                    @if($shoppingStatus === 'pending') bg-gray-100 text-gray-600
                                    @elseif($shoppingStatus === 'progress') bg-yellow-100 text-yellow-700
                                    @elseif($shoppingStatus === 'done') bg-green-100 text-green-700
                                    @else bg-red-100 text-red-700 @endif">
                                    @if($shoppingStatus === 'pending') {{ $checkedItems === 0 && $totalItems > 0 ? 'Belanja' : 'Pending' }}
                                    @elseif($shoppingStatus === 'progress') Proses
                                    @else Selesai @endif
                                </span>
                            </div>
                        @endforeach
                    </div>
                @else
                    <p class="text-sm text-gray-400">Belum ada tugas pembelian yang ditugaskan kepada Anda.</p>
                @endif
            </div>
        </div>
    </div>
</x-app-layout>
