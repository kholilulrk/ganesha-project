<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Edit Document') }}</h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-3xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white shadow-sm sm:rounded-lg p-6">
                <form x-data="{ loading: false }" method="POST" action="{{ route('documents.update', $document) }}" enctype="multipart/form-data" class="space-y-6">
                    @csrf @method('PATCH')

                    <div>
                        <x-input-label for="title" :value="__('Title')" />
                        <x-text-input id="title" class="block mt-1 w-full" type="text" name="title" :value="old('title', $document->title)" required />
                        <x-input-error :messages="$errors->get('title')" class="mt-2" />
                    </div>

                    <div>
                        <x-input-label for="document_type" :value="__('Document Type')" />
                        <select id="document_type" name="document_type" class="block mt-1 w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" required>
                            <option value="application/pdf" {{ old('document_type', $document->document_type) == 'application/pdf' ? 'selected' : '' }}>PDF</option>
                            <option value="image/jpeg" {{ old('document_type', $document->document_type) == 'image/jpeg' ? 'selected' : '' }}>Image</option>
                            <option value="image/png" {{ old('document_type', $document->document_type) == 'image/png' ? 'selected' : '' }}>PNG</option>
                            <option value="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" {{ old('document_type', $document->document_type) == 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ? 'selected' : '' }}>Excel</option>
                            <option value="application/vnd.openxmlformats-officedocument.wordprocessingml.document" {{ old('document_type', $document->document_type) == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' ? 'selected' : '' }}>Word</option>
                            <option value="text/csv" {{ old('document_type', $document->document_type) == 'text/csv' ? 'selected' : '' }}>CSV</option>
                            <option value="text/plain" {{ old('document_type', $document->document_type) == 'text/plain' ? 'selected' : '' }}>Text</option>
                            <option value="other" {{ old('document_type', $document->document_type) == 'other' ? 'selected' : '' }}>Other</option>
                        </select>
                        <x-input-error :messages="$errors->get('document_type')" class="mt-2" />
                    </div>

                    <div>
                        <x-input-label for="file" :value="__('File (leave empty to keep current)')" />
                        <input type="file" id="file" name="file" class="block mt-1 w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-indigo-50 file:text-indigo-700 hover:file:bg-indigo-100">
                        <p class="text-xs text-gray-400 mt-1">Current: {{ basename($document->file) }}</p>
                        <x-input-error :messages="$errors->get('file')" class="mt-2" />
                    </div>

                    <div>
                        <x-input-label for="description" :value="__('Description (optional)')" />
                        <textarea id="description" name="description" rows="3" class="block mt-1 w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">{{ old('description', $document->description) }}</textarea>
                        <x-input-error :messages="$errors->get('description')" class="mt-2" />
                    </div>

                    <div>
                        <x-input-label for="visibility" :value="__('Dibagikan Ke')" />
                        <select id="visibility" name="visibility" class="block mt-1 w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" required
                            x-on:change="document.getElementById('shared_roles_wrapper').style.display = $el.value === 'roles' ? 'block' : 'none'">
                            <option value="all" {{ old('visibility', $document->visibility) == 'all' ? 'selected' : '' }}>Semua Role</option>
                            <option value="roles" {{ old('visibility', $document->visibility) == 'roles' ? 'selected' : '' }}>Role Tertentu</option>
                        </select>
                        <x-input-error :messages="$errors->get('visibility')" class="mt-2" />
                    </div>

                    <div id="shared_roles_wrapper" style="display: {{ old('visibility', $document->visibility) == 'roles' ? 'block' : 'none' }}">
                        <x-input-label for="shared_roles" :value="__('Pilih Role')" />
                        <select id="shared_roles" name="shared_roles[]" multiple class="block mt-1 w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" size="5">
                            @foreach ($roles as $r)
                                <option value="{{ $r->id }}" {{ in_array($r->id, old('shared_roles', $document->sharedRoles->pluck('id')->toArray())) ? 'selected' : '' }}>
                                    {{ $r->name }}
                                </option>
                            @endforeach
                        </select>
                        <p class="text-xs text-gray-400 mt-1">Tahan Ctrl untuk memilih lebih dari satu.</p>
                        <x-input-error :messages="$errors->get('shared_roles')" class="mt-2" />
                    </div>

                    <div class="flex flex-wrap items-center gap-4">
                        <x-primary-button>{{ __('Update') }}</x-primary-button>
                        <a href="{{ route('documents.index') }}" class="text-sm text-gray-600 hover:text-gray-900">Cancel</a>
                    </div>
                </form>
            </div>
        </div>
    </div>
</x-app-layout>
