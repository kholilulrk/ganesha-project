<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Role & Permission Management') }}</h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            @if (session('success'))
                <div class="mb-4 px-4 py-2 bg-green-100 border border-green-200 text-green-700 rounded-md text-sm">{{ session('success') }}</div>
            @endif

            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                @foreach ($roles as $role)
                @continue($role->name === 'super_admin')
                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                    <div class="p-6">
                        <div class="flex items-center justify-between mb-4">
                            <h3 class="text-lg font-semibold capitalize">{{ str_replace('_', ' ', $role->name) }}</h3>
                            <form x-data="{ loading: false }" x-on:submit="if(confirm('Delete this role?')) loading = true; else $event.preventDefault()" action="{{ route('admin.roles.destroy', $role) }}" method="POST">
                                @csrf @method('DELETE')
                                <button x-bind:disabled="loading" type="submit" class="text-red-500 hover:text-red-700 text-xs">Delete</button>
                            </form>
                        </div>

                        <div class="mb-4">
                            <p class="text-xs text-gray-500 mb-2">Users with this role: {{ $role->users_count }}</p>
                        </div>

                        <form x-data="{ loading: false }" x-on:submit="loading = true" method="POST" action="{{ route('admin.roles.permissions.update', $role) }}">
                            @csrf @method('PATCH')
                            <p class="text-xs font-medium text-gray-500 mb-2">Permissions:</p>
                            <div class="space-y-1">
                                @php
                                    $allPermissions = \Spatie\Permission\Models\Permission::all();
                                @endphp
                                @foreach ($allPermissions as $perm)
                                    <label class="flex items-center gap-2 text-sm">
                                        <input type="checkbox" name="permissions[]" value="{{ $perm->name }}"
                                            {{ $role->hasPermissionTo($perm->name) ? 'checked' : '' }}
                                            class="rounded border-gray-300 text-indigo-600 shadow-sm focus:ring-indigo-500">
                                        {{ $perm->name }}
                                    </label>
                                @endforeach
                            </div>
                            <button x-bind:disabled="loading" type="submit" class="mt-3 text-xs px-3 py-1 bg-indigo-600 text-white rounded-md hover:bg-indigo-700">
                                <span x-show="!loading">Update Permissions</span>
                                <span x-show="loading" class="inline-flex items-center">
                                    <svg class="animate-spin -ml-1 mr-2 h-3 w-3 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                    </svg>
                                    Update Permissions
                                </span>
                            </button>
                        </form>
                    </div>
                </div>
                @endforeach

                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg lg:col-span-2">
                    <div class="p-6">
                        <h3 class="text-lg font-semibold mb-4">Create New Role</h3>
                        <form x-data="{ loading: false }" x-on:submit="loading = true" method="POST" action="{{ route('admin.roles.store') }}" class="flex flex-wrap items-center gap-3">
                            @csrf
                            <input type="text" name="name" placeholder="Role name" class="block min-w-0 w-full sm:w-auto sm:flex-1 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm" required>
                            <x-primary-button class="w-full sm:w-auto">Create</x-primary-button>
                        </form>
                        <x-input-error :messages="$errors->get('name')" class="mt-2" />
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
