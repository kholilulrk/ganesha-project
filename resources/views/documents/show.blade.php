<x-app-layout>
    <x-slot name="header">
        <div class="flex flex-wrap items-center justify-between gap-2">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight break-words">{{ $document->title }}</h2>
            @if (auth()->user()->hasAnyRole(['super_admin', 'administrasi']))
            <a href="{{ route('documents.edit', $document) }}" class="inline-flex items-center px-4 py-2 bg-gray-800 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-gray-700">Edit</a>
            @endif
        </div>
    </x-slot>

    <div class="py-12">
        <div class="max-w-3xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6 space-y-6">
                @if ($document->isImage() || $document->isPdf())
                <div class="border rounded-lg overflow-hidden bg-gray-50">
                    @if ($document->isImage())
                        <img src="{{ $document->url() }}" alt="{{ $document->title }}" class="max-h-[500px] w-full object-contain mx-auto">
                    @elseif ($document->isPdf())
                        <iframe src="{{ $document->url() }}" class="w-full h-[300px] sm:h-[500px]" frameborder="0"></iframe>
                    @endif
                </div>
                @endif

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm">
                    <div>
                        <span class="text-gray-500">Type</span>
                        <p class="font-medium">{{ $document->document_type }}</p>
                    </div>
                    <div>
                        <span class="text-gray-500">Uploaded By</span>
                        <p class="font-medium">{{ $document->uploader?->name ?? '-' }}</p>
                    </div>
                    <div>
                        <span class="text-gray-500">Uploaded At</span>
                        <p class="font-medium">{{ $document->created_at->format('d M Y H:i') }}</p>
                    </div>
                    <div>
                        <span class="text-gray-500">Last Updated</span>
                        <p class="font-medium">{{ $document->updated_at->format('d M Y H:i') }}</p>
                    </div>
                    <div>
                        <span class="text-gray-500">Dibagikan Ke</span>
                        <p class="font-medium">
                            @if ($document->visibility === 'all')
                                Semua Role
                            @else
                                {{ $document->sharedRoles->pluck('name')->implode(', ') ?: 'Role Tertentu' }}
                            @endif
                        </p>
                    </div>
                </div>

                @if ($document->description)
                <div>
                    <span class="text-sm text-gray-500">Description</span>
                    <p class="mt-1 text-gray-800">{{ $document->description }}</p>
                </div>
                @endif

                <div class="pt-4 border-t flex flex-wrap items-center gap-4">
                    <a href="{{ $document->url() }}" target="_blank" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-700">Download</a>
                    @if (!$document->isImage() && !$document->isPdf())
                        <span class="text-xs text-gray-400">(File ini tidak bisa ditampilkan langsung, silakan download)</span>
                    @endif
                    <a href="{{ route('documents.index') }}" class="text-sm text-gray-600 hover:text-gray-900">&larr; Back to Documents</a>
                    @if (auth()->user()->hasAnyRole(['super_admin', 'administrasi']))
                    <form x-data="{ loading: false }" x-on:submit="if(confirm('Delete this document?')) loading = true; else $event.preventDefault()" action="{{ route('documents.destroy', $document) }}" method="POST" class="inline">
                        @csrf @method('DELETE')
                        <button x-bind:disabled="loading" type="submit" class="text-red-600 hover:text-red-900 text-sm">Delete</button>
                    </form>
                    @endif
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
