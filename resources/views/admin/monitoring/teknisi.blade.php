<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Monitoring Teknisi') }}</h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-4">
                    <p class="text-sm text-gray-500">Total Teknisi Task</p>
                    <p class="text-2xl font-bold mt-1">{{ $total }}</p>
                </div>
                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-4 border-l-4 border-yellow-400">
                    <p class="text-sm text-gray-500">Progres</p>
                    <p class="text-2xl font-bold mt-1">{{ $progress }}</p>
                </div>
                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-4 border-l-4 border-green-400">
                    <p class="text-sm text-gray-500">Selesai (Checklist Tercheck Semua)</p>
                    <p class="text-2xl font-bold mt-1">{{ $done }}</p>
                </div>
            </div>

            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6">
                    <div class="overflow-x-auto -mx-6 sm:mx-0 px-6">
                    <table class="min-w-full w-full text-sm whitespace-nowrap">
                        <thead>
                            <tr class="border-b text-left">
                                <th class="pb-3 font-medium">Title</th>
                                <th class="pb-3 font-medium">Status</th>
                                <th class="pb-3 font-medium">Checklist</th>
                                <th class="pb-3 font-medium">Assigned To</th>
                                <th class="pb-3 font-medium">Deadline</th>
                                <th class="pb-3 font-medium"></th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse ($tasks as $task)
                                <tr class="border-b last:border-0">
                                    <td class="py-3">{{ $task->title }}</td>
                                    <td class="py-3">
                                        <span class="px-2 py-0.5 text-xs rounded-full 
                                            @if($task->status === 'pending') bg-gray-100 text-gray-600
                                            @elseif($task->status === 'progress') bg-yellow-100 text-yellow-700
                                            @elseif($task->status === 'done') bg-green-100 text-green-700
                                            @else bg-red-100 text-red-700 @endif">{{ ucfirst($task->status) }}</span>
                                    </td>
                                    <td class="py-3">
                                        @if ($task->teknisi_task_items_count > 0)
                                            <div class="flex items-center gap-2">
                                                <span class="text-xs {{ $task->checked_count === $task->teknisi_task_items_count ? 'text-green-600 font-medium' : 'text-yellow-600' }}">
                                                    {{ $task->checked_count }}/{{ $task->teknisi_task_items_count }}
                                                </span>
                                                <div class="w-16 bg-gray-200 rounded-full h-1.5">
                                                    <div class="h-1.5 rounded-full {{ $task->checked_count === $task->teknisi_task_items_count ? 'bg-green-500' : 'bg-yellow-500' }}" style="width: {{ ($task->checked_count / $task->teknisi_task_items_count) * 100 }}%"></div>
                                                </div>
                                            </div>
                                        @else
                                            <span class="text-xs text-gray-400">-</span>
                                        @endif
                                    </td>
                                    <td class="py-3">{{ $task->assignedUsers->pluck('name')->implode(', ') ?: '-' }}</td>
                                    <td class="py-3">{{ $task->deadline?->format('d M Y') ?? '-' }}</td>
                                    <td class="py-3 text-right">
                                        <a href="{{ route('tasks.show', $task) }}" class="text-indigo-600 hover:text-indigo-900">View</a>
                                    </td>
                                </tr>
                            @empty
                                <tr><td colspan="6" class="py-6 text-center text-gray-500">No teknisi tasks found.</td></tr>
                            @endforelse
                        </tbody>
                    </table>
                    </div>
                    <div class="mt-4">{{ $tasks->links() }}</div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
