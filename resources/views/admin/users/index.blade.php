<x-app-layout>
    <x-slot name="header">
        <div class="flex flex-wrap items-center justify-between gap-2">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Users') }}</h2>
            <a href="{{ route('admin.users.create') }}" class="inline-flex items-center px-4 py-2 bg-gray-800 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-gray-700">+ New User</a>
        </div>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            @if (session('success'))
                <div class="mb-4 px-4 py-2 bg-green-100 border border-green-200 text-green-700 rounded-md text-sm">{{ session('success') }}</div>
            @endif
            @if (session('error'))
                <div class="mb-4 px-4 py-2 bg-red-100 border border-red-200 text-red-700 rounded-md text-sm">{{ session('error') }}</div>
            @endif

            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6">
                    <div class="overflow-x-auto -mx-6 sm:mx-0 px-6">
                    <table class="min-w-full w-full text-sm whitespace-nowrap">
                        <thead>
                            <tr class="border-b text-left">
                                <th class="pb-3 font-medium">Name</th>
                                <th class="pb-3 font-medium">Email</th>
                                <th class="pb-3 font-medium">Role</th>
                                <th class="pb-3 font-medium">Created</th>
                                <th class="pb-3 font-medium"></th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse ($users as $u)
                                <tr class="border-b last:border-0">
                                    <td class="py-3">{{ $u->name }}</td>
                                    <td class="py-3">{{ $u->email }}</td>
                                    <td class="py-3">
                                        @foreach ($u->roles as $role)
                                            <span class="px-2 py-0.5 text-xs rounded-full
                                                @if($role->name === 'super_admin') bg-purple-100 text-purple-700
                                                @elseif($role->name === 'administrasi') bg-blue-100 text-blue-700
                                                @elseif($role->name === 'teknisi') bg-green-100 text-green-700
                                                @else bg-amber-100 text-amber-700 @endif">
                                                {{ $role->name }}
                                            </span>
                                        @endforeach
                                    </td>
                                    <td class="py-3">{{ $u->created_at->format('d M Y') }}</td>
                                    <td class="py-3 text-right">
                                        <a href="{{ route('admin.users.edit', $u) }}" class="text-amber-600 hover:text-amber-900 mr-2">Edit</a>
                                        <form action="{{ route('admin.users.destroy', $u) }}" method="POST" class="inline" x-data="{ loading: false }" x-on:submit="if(confirm('Delete this user?')) loading = true; else $event.preventDefault()">
                                            @csrf @method('DELETE')
                                            <button x-bind:disabled="loading" type="submit" class="text-red-600 hover:text-red-900">Delete</button>
                                        </form>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="5" class="py-6 text-center text-gray-500">No users found.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                    </div>
                    <div class="mt-4">{{ $users->links() }}</div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
