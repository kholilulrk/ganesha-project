@if($announcement)
    <div class="bg-indigo-600 border-l-4 border-indigo-300 overflow-hidden shadow-md sm:rounded-lg mb-8">
        <div class="p-5">
            <div class="flex items-start gap-3">
                <svg class="w-6 h-6 shrink-0 text-indigo-200 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M18 3a1 1 0 00-1.447-.894L8.763 6H5a3 3 0 000 6h.28l1.771 5.316A1 1 0 008 18h1a1 1 0 001-1v-4.382l6.553 3.276A1 1 0 0018 15V3z" clip-rule="evenodd"/>
                </svg>
                <div class="flex-1 min-w-0">
                    <p class="text-xs font-semibold text-indigo-200 uppercase tracking-wider">Pengumuman</p>
                    <h3 class="text-lg font-bold text-white mt-1">{{ $announcement->title }}</h3>
                    <p class="text-sm text-indigo-100 mt-1 leading-relaxed">{{ Str::limit($announcement->content, 300) }}</p>
                    <div class="flex items-center gap-3 mt-3 text-indigo-200">
                        <span class="text-xs">{{ $announcement->creator?->name }}</span>
                        @if($announcement->scheduled_at)
                            <span class="text-xs text-indigo-300">|</span>
                            <span class="text-xs">{{ $announcement->scheduled_at->format('d M Y') }}</span>
                        @endif
                    </div>
                </div>
            </div>
        </div>
    </div>
@endif
