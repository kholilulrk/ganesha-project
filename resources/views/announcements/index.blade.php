<x-app-layout>
    <x-slot name="header">
        <div class="flex flex-wrap items-center justify-between gap-2">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Pengumuman') }}</h2>
            @if (auth()->user()->hasRole('super_admin'))
            <a href="{{ route('announcements.create') }}" class="inline-flex items-center px-4 py-2 bg-gray-800 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-gray-700">
                + Buat Pengumuman
            </a>
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

            <div class="space-y-4">
                @forelse ($announcements as $a)
                    <div class="bg-white shadow-sm sm:rounded-lg p-6">
                        <div class="flex items-start justify-between gap-4">
                            <div class="min-w-0 flex-1">
                                <a href="{{ route('announcements.show', $a) }}" class="font-semibold text-gray-800 hover:text-indigo-600">
                                    {{ $a->title }}
                                </a>
                                <p class="text-sm text-gray-500 mt-1 line-clamp-2">{{ $a->content }}</p>
                                <div class="flex flex-wrap items-center gap-2 mt-2 text-xs text-gray-400">
                                    <span>{{ $a->creator?->name }}</span>
                                    <span>&middot;</span>
                                    <span>{{ $a->created_at->diffForHumans() }}</span>
                                    <span>&middot;</span>
                                    <span class="px-1.5 py-0.5 rounded bg-gray-100">
                                        {{ $a->target_type === 'all_users' ? 'Semua User' : 'User / Role Tertentu' }}
                                    </span>
                                    <span>&middot;</span>
                                    <span class="px-1.5 py-0.5 rounded
                                        @if ($a->share_status === 'active') bg-green-100 text-green-700
                                        @elseif ($a->share_status === 'scheduled') bg-yellow-100 text-yellow-700
                                        @else bg-red-100 text-red-700 @endif">
                                        @if ($a->share_status === 'active')
                                            Aktif
                                        @elseif ($a->share_status === 'scheduled')
                                            Jadwal {{ $a->scheduled_at->format('d M Y H:i') }}
                                        @else
                                            Kadaluarsa {{ $a->expired_at->format('d M Y H:i') }}
                                        @endif
                                    </span>
                                </div>
                            </div>
                            @if (auth()->user()->hasRole('super_admin'))
                            <div class="flex items-center gap-2 shrink-0">
                                <a href="{{ route('announcements.edit', $a) }}" class="text-amber-600 hover:text-amber-900 text-sm">Edit</a>
                                <form action="{{ route('announcements.destroy', $a) }}" method="POST" class="inline" x-data="{ loading: false }" x-on:submit="if(confirm('Hapus pengumuman ini?')) loading = true; else $event.preventDefault()">
                                    @csrf @method('DELETE')
                                    <button x-bind:disabled="loading" type="submit" class="text-red-600 hover:text-red-900 text-sm">Hapus</button>
                                </form>
                            </div>
                            @endif
                        </div>
                    </div>
                @empty
                    <div class="bg-white shadow-sm sm:rounded-lg p-6 text-center text-gray-500">
                        Belum ada pengumuman.
                    </div>
                @endforelse
            </div>

            <div class="mt-4">
                {{ $announcements->links() }}
            </div>
        </div>
    </div>
</x-app-layout>
