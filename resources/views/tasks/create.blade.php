<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Create Task') }}</h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-3xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white shadow-sm sm:rounded-lg p-6">
                <form x-data="{ loading: false }" method="POST" action="{{ route('tasks.store') }}" class="space-y-6">
                    @csrf

                    <div>
                        <x-input-label for="title" :value="__('Title')" />
                        <x-text-input id="title" class="block mt-1 w-full" type="text" name="title" :value="old('title')" required />
                        <x-input-error :messages="$errors->get('title')" class="mt-2" />
                    </div>

                    <div>
                        <x-input-label for="description" :value="__('Description')" />
                        <textarea id="description" name="description" rows="4" class="block mt-1 w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">{{ old('description') }}</textarea>
                        <x-input-error :messages="$errors->get('description')" class="mt-2" />
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <x-input-label for="deadline" :value="__('Deadline')" />
                            <input id="deadline" type="date" name="deadline" value="{{ old('deadline') }}" class="block mt-1 w-full border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm" />
                            <x-input-error :messages="$errors->get('deadline')" class="mt-2" />
                        </div>
                    </div>

                    @if ($users->isNotEmpty())
                        <div>
                            <x-input-label :value="__('Assign To')" />
                            <div class="mt-1 space-y-1.5 max-h-48 overflow-y-auto border border-gray-300 rounded-md p-3">
                                @foreach ($users as $u)
                                    <label class="flex items-center gap-2 text-sm cursor-pointer hover:bg-gray-50 px-1 py-0.5 rounded">
                                        <input type="checkbox" name="assigned_users[]" value="{{ $u->id }}"
                                            {{ in_array($u->id, old('assigned_users', [])) ? 'checked' : '' }}
                                            class="rounded border-gray-300 text-indigo-600 shadow-sm focus:ring-indigo-500">
                                        <span>{{ $u->name }} ({{ $u->getRoleNames()->implode(', ') }})</span>
                                    </label>
                                @endforeach
                            </div>
                            <x-input-error :messages="$errors->get('assigned_users')" class="mt-2" />
                        </div>
                    @elseif (!empty($roles))
                        <div>
                            <x-input-label for="assigned_role" :value="__('Assign To Role')" />
                            <select id="assigned_role" name="assigned_role" class="block mt-1 w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                                <option value="">Unassigned</option>
                                @foreach ($roles as $value => $label)
                                    <option value="{{ $value }}" {{ old('assigned_role') == $value ? 'selected' : '' }}>{{ $label }}</option>
                                @endforeach
                            </select>
                            <x-input-error :messages="$errors->get('assigned_role')" class="mt-2" />
                        </div>
                    @endif

                    <div>
                        <x-input-label for="document_id" :value="__('Referensi Dokumen (PDF)')" />
                        <select id="document_id" name="document_id" class="block mt-1 w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                            <option value="">Tidak ada</option>
                            @foreach ($documents as $doc)
                                <option value="{{ $doc->id }}" {{ old('document_id') == $doc->id ? 'selected' : '' }}>{{ $doc->title }}</option>
                            @endforeach
                        </select>
                        <x-input-error :messages="$errors->get('document_id')" class="mt-2" />
                    </div>

                    <div class="flex items-center gap-4">
                        <x-primary-button>{{ __('Create') }}</x-primary-button>
                        <a href="{{ route('tasks.index') }}" class="text-sm text-gray-600 hover:text-gray-900">Cancel</a>
                    </div>
                </form>
            </div>
        </div>
    </div>
</x-app-layout>
