<x-app-layout>
    <x-slot name="header">
        <div class="flex flex-wrap items-center justify-between gap-2">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Pekerjaan') }}</h2>
            @can('task-create')
            <a href="{{ route('tasks.create') }}" class="inline-flex items-center px-4 py-2 bg-gray-800 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-gray-700">
                + New Task
            </a>
            @endcan
        </div>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            @if (session('success'))
                <div class="mb-4 px-4 py-2 bg-green-100 border border-green-200 text-green-700 rounded-md text-sm">
                    {{ session('success') }}
                </div>
            @endif

            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6">
                    <form method="GET" class="mb-4 flex flex-wrap items-end gap-3">
                        <div class="flex-1 min-w-[200px]">
                            <label class="text-xs text-gray-500 block mb-1">Cari</label>
                            <input type="text" name="search" value="{{ request('search') }}" placeholder="Cari judul atau deskripsi..." class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">
                        </div>
                        <div>
                            <label class="text-xs text-gray-500 block mb-1">Status</label>
                            <select name="status" class="rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">
                                <option value="">Semua Status</option>
                                <option value="pending" {{ request('status') === 'pending' ? 'selected' : '' }}>Pending</option>
                                <option value="progress" {{ request('status') === 'progress' ? 'selected' : '' }}>Progress</option>
                                <option value="done" {{ request('status') === 'done' ? 'selected' : '' }}>Done</option>
                                <option value="cancelled" {{ request('status') === 'cancelled' ? 'selected' : '' }}>Cancelled</option>
                            </select>
                        </div>
                        @if(auth()->user()->hasRole('super_admin'))
                        <div>
                            <label class="text-xs text-gray-500 block mb-1">Assign To</label>
                            <select name="assigned_to" class="rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">
                                <option value="">Semua User</option>
                                @foreach (\App\Models\User::all() as $u)
                                    <option value="{{ $u->id }}" {{ request('assigned_to') == $u->id ? 'selected' : '' }}>{{ $u->name }}</option>
                                @endforeach
                            </select>
                        </div>
                        @endif
                        @if(auth()->user()->hasRole('logistic'))
                        <div>
                            <label class="text-xs text-gray-500 block mb-1">Status Belanja</label>
                            <select name="shopping_status" class="rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">
                                <option value="">Semua</option>
                                <option value="incomplete" {{ request('shopping_status') === 'incomplete' ? 'selected' : '' }}>Belum Lengkap</option>
                                <option value="complete" {{ request('shopping_status') === 'complete' ? 'selected' : '' }}>Selesai</option>
                            </select>
                        </div>
                        @endif
                        <div class="flex items-center gap-2">
                            <button type="submit" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-500">Filter</button>
                            @if(request()->anyFilled(['search', 'status', 'task_type', 'assigned_to', 'shopping_status']))
                                <a href="{{ route('tasks.index') }}" class="inline-flex items-center px-4 py-2 bg-gray-200 border border-transparent rounded-md font-semibold text-xs text-gray-700 uppercase tracking-widest hover:bg-gray-300">Reset</a>
                            @endif
                        </div>
                    </form>

                    @php $isLogistic = auth()->user()->hasRole('logistic'); @endphp
                    <div class="overflow-x-auto -mx-6 sm:mx-0 px-6">
                    <table class="min-w-full w-full text-sm whitespace-nowrap">
                        <thead>
                            <tr class="border-b text-left">
                                <th class="pb-3 font-medium">Title</th>
                                @if (!$isLogistic)
                                <th class="pb-3 font-medium">Status</th>
                                @endif
                                @if ($isLogistic)
                                <th class="pb-3 font-medium">Shopping</th>
                                @endif
                                @if (!$isLogistic)
                                <th class="pb-3 font-medium">Deadline</th>
                                @endif
                                @if (auth()->user()->hasRole('super_admin'))
                                <th class="pb-3 font-medium">Assigned To</th>
                                @endif
                                <th class="pb-3 font-medium"></th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse ($tasks as $task)
                                <tr class="border-b last:border-0">
                                    <td class="py-3">
                                        <div class="font-medium">{{ $task->title }}</div>
                                        @if($task->description)
                                            <div class="text-xs text-gray-400 mt-0.5 truncate max-w-[250px] lg:max-w-[350px]">{{ $task->description }}</div>
                                        @endif
                                    </td>
                                    @if (!$isLogistic)
                                    <td class="py-3">
                                        <span class="px-2 py-0.5 text-xs rounded-full 
                                            @if($task->status === 'pending') bg-gray-100 text-gray-600
                                            @elseif($task->status === 'progress') bg-yellow-100 text-yellow-700
                                            @elseif($task->status === 'done') bg-green-100 text-green-700
                                            @else bg-red-100 text-red-700 @endif">
                                            {{ ucfirst($task->status) }}
                                        </span>
                                    </td>
                                    @endif
                                    @if ($isLogistic)
                                    <td class="py-3">
                                        <span class="text-sm {{ $task->unchecked_shopping_items_count > 0 ? 'text-red-600 font-semibold' : 'text-green-600' }}">
                                            {{ $task->unchecked_shopping_items_count }}/{{ $task->shopping_items_count }} items
                                        </span>
                                    </td>
                                    @endif
                                    @if (!$isLogistic)
                                    <td class="py-3">{{ $task->deadline?->format('d M Y') ?? '-' }}</td>
                                    @endif
                                    @if (auth()->user()->hasRole('super_admin'))
                                    <td class="py-3">
                                        @if($task->assignedUsers->isNotEmpty())
                                            <div class="flex flex-wrap gap-1">
                                                @foreach($task->assignedUsers as $u)
                                                    <span class="text-xs px-1.5 py-0.5 bg-gray-100 rounded">{{ $u->name }}</span>
                                                @endforeach
                                            </div>
                                        @else
                                            <span class="text-gray-400">-</span>
                                        @endif
                                    </td>
                                    @endif
                                    <td class="py-3 text-right">
                                        <a href="{{ route('tasks.show', $task) }}" class="text-indigo-600 hover:text-indigo-900 mr-2">View</a>
                                        @can('task-edit')
                                        <a href="{{ route('tasks.edit', $task) }}" class="text-amber-600 hover:text-amber-900 mr-2">Edit</a>
                                        @endcan
                                        @can('task-delete')
                                        <form action="{{ route('tasks.destroy', $task) }}" class="inline" x-data="{ loading: false }">
                                            @csrf @method('DELETE')
                                            <button @click.prevent="
                                                if (!confirm('Delete this task?')) return;
                                                loading = true;
                                                fetch($event.target.closest('form').action, {
                                                    method: 'POST',
                                                    body: new FormData($event.target.closest('form')),
                                                    headers: { 'X-Requested-With': 'XMLHttpRequest' }
                                                })
                                                .then(r => r.json())
                                                .then(data => {
                                                    if (data.success) {
                                                        $event.target.closest('tr').remove();
                                                    } else {
                                                        location.reload();
                                                    }
                                                    loading = false;
                                                })
                                                .catch(() => { loading = false; location.reload(); });
                                            " x-bind:disabled="loading" type="button" class="text-red-600 hover:text-red-900">Delete</button>
                                        </form>
                                        @endcan
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="10" class="py-6 text-center text-gray-500">No tasks found.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                    </div>

                    <div class="mt-4">
                        {{ $tasks->links() }}
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
