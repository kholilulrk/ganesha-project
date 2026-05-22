<x-app-layout>
    <x-slot name="header">
        <div class="flex flex-wrap items-center justify-between gap-2">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Documents') }}</h2>
            @if (auth()->user()->hasAnyRole(['super_admin', 'administrasi']))
            <a href="{{ route('documents.create') }}" class="inline-flex items-center px-4 py-2 bg-gray-800 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-gray-700">+ Upload Document</a>
            @endif
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
                            <label class="text-xs text-gray-500 block mb-1">Tipe Dokumen</label>
                            <select name="document_type" class="rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">
                                <option value="">Semua Tipe</option>
                                @php $types = \App\Models\Document::distinct()->pluck('document_type'); @endphp
                                @foreach ($types as $type)
                                    <option value="{{ $type }}" {{ request('document_type') === $type ? 'selected' : '' }}>{{ ucfirst($type) }}</option>
                                @endforeach
                            </select>
                        </div>
                        @if(auth()->user()->hasRole('super_admin'))
                        <div>
                            <label class="text-xs text-gray-500 block mb-1">Visibilitas</label>
                            <select name="visibility" class="rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">
                                <option value="">Semua</option>
                                <option value="all" {{ request('visibility') === 'all' ? 'selected' : '' }}>Semua Role</option>
                                <option value="roles" {{ request('visibility') === 'roles' ? 'selected' : '' }}>Role Tertentu</option>
                            </select>
                        </div>
                        @endif
                        <div class="flex items-center gap-2">
                            <button type="submit" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-500">Filter</button>
                            @if(request()->anyFilled(['search', 'document_type', 'visibility']))
                                <a href="{{ route('documents.index') }}" class="inline-flex items-center px-4 py-2 bg-gray-200 border border-transparent rounded-md font-semibold text-xs text-gray-700 uppercase tracking-widest hover:bg-gray-300">Reset</a>
                            @endif
                        </div>
                    </form>

                    <div class="overflow-x-auto -mx-6 sm:mx-0 px-6">
                    <table class="min-w-full w-full text-sm whitespace-nowrap">
                        <thead>
                            <tr class="border-b text-left">
                                <th class="pb-3 font-medium">Title</th>
                                <th class="pb-3 font-medium">Type</th>
                                <th class="pb-3 font-medium">Uploaded By</th>
                                @if(auth()->user()->hasAnyRole(['super_admin', 'administrasi']))
                                <th class="pb-3 font-medium">Date</th>
                                <th class="pb-3 font-medium">Dibagikan Ke</th>
                                @endif
                                <th class="pb-3 font-medium"></th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse ($documents as $doc)
                                <tr class="border-b last:border-0">
                                    <td class="py-3">{{ $doc->title }}</td>
                                    <td class="py-3">
                                        <span class="px-2 py-0.5 text-xs rounded-full bg-gray-100 text-gray-600">
                                            {{ $doc->document_type }}
                                        </span>
                                    </td>
                                    <td class="py-3">{{ $doc->uploader?->name }}</td>
                                    @if(auth()->user()->hasAnyRole(['super_admin', 'administrasi']))
                                    <td class="py-3">{{ $doc->created_at->format('d M Y') }}</td>
                                    <td class="py-3">
                                        @if ($doc->visibility === 'all')
                                            <span class="text-xs text-gray-500">Semua Role</span>
                                        @else
                                            <span class="text-xs text-indigo-600">Role Tertentu</span>
                                        @endif
                                    </td>
                                    @endif
                                    <td class="py-3 text-right">
                                        <a href="{{ route('documents.show', $doc) }}" class="text-indigo-600 hover:text-indigo-900 mr-2">View</a>
                                        @if (auth()->user()->hasAnyRole(['super_admin', 'administrasi']))
                                        <a href="{{ route('documents.edit', $doc) }}" class="text-amber-600 hover:text-amber-900 mr-2">Edit</a>
                                        <form action="{{ route('documents.destroy', $doc) }}" method="POST" class="inline" x-data="{ loading: false }" x-on:submit="if(confirm('Delete this document?')) loading = true; else $event.preventDefault()">
                                            @csrf @method('DELETE')
                                            <button x-bind:disabled="loading" type="submit" class="text-red-600 hover:text-red-900">Delete</button>
                                        </form>
                                        @endif
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="10" class="py-6 text-center text-gray-500">No documents found.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                    </div>
                    <div class="mt-4">
                        {{ $documents->links() }}
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
