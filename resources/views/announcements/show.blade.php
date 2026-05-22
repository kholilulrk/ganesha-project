<x-app-layout>
    <x-slot name="header">
        <div class="flex flex-wrap items-center justify-between gap-2">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ $announcement->title }}</h2>
            <a href="{{ route('announcements.index') }}" class="text-sm text-indigo-600 hover:text-indigo-900">&larr; Kembali</a>
        </div>
    </x-slot>

    <div class="py-12">
        <div class="max-w-3xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white shadow-sm sm:rounded-lg p-6">
                <div class="text-xs text-gray-400 mb-4 flex flex-wrap items-center gap-2">
                    <span>Oleh: {{ $announcement->creator?->name }}</span>
                    <span>&middot;</span>
                    <span>{{ $announcement->created_at->format('d M Y H:i') }}</span>
                    <span>&middot;</span>
                    <span class="px-1.5 py-0.5 rounded bg-gray-100">
                        @if ($announcement->target_type === 'all_users')
                            Semua User
                        @else
                            User / Role Tertentu
                            @if ($announcement->specificUsers->isNotEmpty())
                                (User: {{ $announcement->specificUsers->pluck('name')->implode(', ') }})
                            @endif
                            @if ($announcement->specificRoles->isNotEmpty())
                                (Role: {{ $announcement->specificRoles->pluck('name')->implode(', ') }})
                            @endif
                        @endif
                    </span>
                    <span>&middot;</span>
                    <span class="px-1.5 py-0.5 rounded
                        @if ($announcement->share_status === 'active') bg-green-100 text-green-700
                        @elseif ($announcement->share_status === 'scheduled') bg-yellow-100 text-yellow-700
                        @else bg-red-100 text-red-700 @endif">
                        @if ($announcement->share_status === 'active')
                            Aktif
                        @elseif ($announcement->share_status === 'scheduled')
                            Jadwal {{ $announcement->scheduled_at->format('d M Y H:i') }}
                        @else
                            Kadaluarsa {{ $announcement->expired_at->format('d M Y H:i') }}
                        @endif
                    </span>
                </div>
                <div class="prose prose-sm max-w-none text-gray-700 whitespace-pre-wrap">
                    {{ $announcement->content }}
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
