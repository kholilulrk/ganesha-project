<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ config('app.name', 'Ganesha Project') }} - {{ $task->title }}</title>
    <link rel="preconnect" href="https://fonts.bunny.net">
    <link href="https://fonts.bunny.net/css?family=figtree:400,500,600&display=swap" rel="stylesheet" />
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="font-sans antialiased bg-gray-100">
    <div class="min-h-screen">
        <header class="bg-white shadow">
            <div class="max-w-3xl mx-auto py-4 px-4 sm:px-6 lg:px-8">
                <div class="flex items-center gap-3">
                    <x-application-logo class="block h-8 w-auto fill-current text-gray-800" />
                    <span class="text-lg font-semibold text-gray-800">{{ config('app.name', 'Ganesha Project') }}</span>
                </div>
            </div>
        </header>

        <div class="py-8">
            <div class="max-w-3xl mx-auto sm:px-6 lg:px-8 space-y-6">
                @if (session('success'))
                    <div class="mb-4 px-4 py-2 bg-green-100 border border-green-200 text-green-700 rounded-md text-sm">
                        {{ session('success') }}
                    </div>
                @endif

                @if ($errors->any())
                    <div class="mb-4 px-4 py-2 bg-red-100 border border-red-200 text-red-700 rounded-md text-sm">
                        <ul class="list-disc list-inside">
                            @foreach ($errors->all() as $error)
                                <li>{{ $error }}</li>
                            @endforeach
                        </ul>
                    </div>
                @endif

                {{-- Card 1: Informasi Task --}}
                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6">
                    <div>
                        <h1 class="text-xl font-bold text-gray-900">{{ $task->title }}</h1>
                        <div class="flex flex-wrap items-center gap-2 mt-2">
                            <span class="px-3 py-1 text-sm rounded-full font-medium
                                @if($task->status === 'pending') bg-gray-200 text-gray-800
                                @elseif($task->status === 'progress') bg-yellow-200 text-yellow-800
                                @elseif($task->status === 'done') bg-green-200 text-green-800
                                @else bg-red-200 text-red-800 @endif">
                                {{ ucfirst($task->status) }}
                            </span>
                            @if($task->deadline)
                                <span class="text-sm text-gray-500">Deadline: {{ $task->deadline->format('d M Y') }}</span>
                            @endif
                        </div>
                    </div>

                    @if ($contacts->isNotEmpty())
                    <div class="pt-4 border-t mt-4">
                        <h3 class="text-sm font-semibold text-gray-500 mb-3">Kontak yang dapat dihubungi</h3>
                        <div class="flex flex-wrap gap-3">
                            @foreach ($contacts as $contact)
                                <a href="https://wa.me/{{ preg_replace('/[^0-9]/', '', $contact->whatsapp) }}" target="_blank"
                                   class="inline-flex items-center gap-2 px-4 py-2.5 bg-green-50 border border-green-200 rounded-lg hover:bg-green-100 transition text-sm">
                                    <svg class="w-5 h-5 text-green-600 shrink-0" fill="currentColor" viewBox="0 0 24 24">
                                        <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                                    </svg>
                                    <div>
                                        <span class="font-medium text-green-800">{{ $contact->name }}</span>
                                        <span class="text-xs text-green-600 block">{{ $contact->whatsapp }}</span>
                                    </div>
                                </a>
                            @endforeach
                        </div>
                    </div>
                    @endif

                    @if($task->description)
                        <div class="pt-4 border-t mt-4">
                            <h3 class="text-sm font-semibold text-gray-500 mb-2">Deskripsi</h3>
                            <p class="text-gray-800">{{ $task->description }}</p>
                        </div>
                    @endif

                    @if ($task->document)
                    <div class="pt-4 border-t mt-4">
                        <h3 class="text-sm font-semibold text-gray-500 mb-3">Dokumen Referensi</h3>
                        <div class="border rounded-lg overflow-hidden bg-gray-50">
                            @if ($task->document->isImage())
                                <img src="{{ $task->document->url() }}" alt="{{ $task->document->title }}" class="max-h-[400px] w-full object-contain mx-auto">
                            @elseif ($task->document->isPdf())
                                <iframe src="{{ $task->document->url() }}" class="w-full h-[400px]" frameborder="0"></iframe>
                            @else
                                <div class="p-4 text-sm text-gray-500">
                                    <a href="{{ $task->document->url() }}" target="_blank" class="text-indigo-600 hover:text-indigo-900">Lihat Dokumen &rarr;</a>
                                </div>
                            @endif
                        </div>
                        <p class="mt-1 text-xs text-gray-400">{{ $task->document->title }}</p>
                    </div>
                    @endif

                </div>

                {{-- Card 2: Checklist Pekerjaan Teknisi --}}
                @if ($task->teknisiTaskItems->isNotEmpty())
                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6" x-data="{
                    previewUrl: null,
                    showImages: {},
                    toggleImages(itemId) {
                        this.showImages[itemId] = !this.showImages[itemId];
                    }
                }">
                    <h3 class="text-lg font-semibold text-gray-800 mb-4">Checklist Pekerjaan Teknisi ({{ $task->teknisiTaskItems->count() }})</h3>
                    @php
                        $totalTeknisi = $task->teknisiTaskItems->count();
                        $checkedTeknisi = $task->teknisiTaskItems->where('is_checked', true)->count();
                        $progressTeknisi = $totalTeknisi > 0 ? round(($checkedTeknisi / $totalTeknisi) * 100) : 0;
                    @endphp
                    <div class="w-full bg-gray-200 rounded-full h-2 mb-2">
                        <div class="bg-blue-500 h-2 rounded-full transition-all duration-300" style="width: {{ $progressTeknisi }}%"></div>
                    </div>
                    <div class="text-xs text-gray-500 mb-4">{{ $checkedTeknisi }} dari {{ $totalTeknisi }} item selesai ({{ $progressTeknisi }}%)</div>

                    <div class="space-y-1">
                        @foreach ($task->teknisiTaskItems as $item)
                            <div class="flex flex-col px-4 py-2 text-sm @if(!$loop->last) border-b border-gray-100 @endif">
                                <div class="flex items-center gap-3">
                                    @if ($item->is_checked)
                                        <svg class="w-5 h-5 text-green-600 shrink-0" fill="currentColor" viewBox="0 0 20 20">
                                            <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
                                        </svg>
                                        <span class="text-gray-500 line-through">{{ $item->item_name }}</span>
                                    @else
                                        <svg class="w-5 h-5 text-gray-300 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <rect x="3" y="3" width="18" height="18" rx="3" stroke-width="2"/>
                                        </svg>
                                        <span class="text-gray-800">{{ $item->item_name }}</span>
                                    @endif
                                </div>

                                @if ($item->images->isNotEmpty())
                                    <div class="ml-8 mt-2">
                                        <button @click.prevent="toggleImages({{ $item->id }})" class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-gray-100 hover:bg-gray-200 rounded-md text-xs font-medium text-gray-700 transition">
                                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
                                            <span>Lihat Gambar ({{ $item->images->count() }})</span>
                                            <svg class="w-3 h-3 transition-transform" x-bind:class="showImages[{{ $item->id }}] ? 'rotate-180' : ''" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
                                        </button>

                                        <div x-show="showImages[{{ $item->id }}]" x-collapse.duration.200ms class="mt-2">
                                            <div class="flex flex-wrap gap-2">
                                                @foreach ($item->images as $img)
                                                <div class="relative group">
                                                    <button @click.prevent="previewUrl = '{{ $img->imageUrl() }}'" class="block w-20 h-20 rounded-md overflow-hidden border border-gray-200 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-400">
                                                        <img src="{{ $img->imageUrl() }}" alt="Gambar" class="w-full h-full object-cover">
                                                    </button>
                                                </div>
                                                @endforeach
                                            </div>
                                        </div>
                                    </div>
                                @endif
                            </div>
                        @endforeach
                    </div>

                    {{-- Preview Lightbox --}}
                    <template x-teleport="body">
                        <div x-show="previewUrl" x-transition.opacity.duration.200ms class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-85 p-4" @click.self="previewUrl = null" @keydown.escape.window="previewUrl = null">
                            <div class="relative flex flex-col items-center">
                                <div class="flex items-center gap-3 mb-3">
                                    <a :href="previewUrl" download target="_blank" class="inline-flex items-center gap-2 px-5 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg shadow-lg transition-colors text-sm">
                                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                                        Download Gambar
                                    </a>
                                    <button @click="previewUrl = null" class="inline-flex items-center gap-2 px-5 py-2.5 bg-gray-700 hover:bg-gray-600 text-white font-semibold rounded-lg shadow-lg transition-colors text-sm">
                                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                                        Tutup
                                    </button>
                                </div>
                                <img :src="previewUrl" alt="Preview" class="max-h-[65vh] max-w-xs sm:max-w-sm md:max-w-md rounded-lg shadow-2xl object-contain bg-white p-1">
                            </div>
                        </div>
                    </template>
                </div>
                @endif

                {{-- Card 3: Komentar --}}
                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6">
                    <h3 class="text-lg font-semibold text-gray-800 mb-4">Komentar ({{ $task->comments->where('parent_id', null)->count() }})</h3>

                    @php $topComments = $task->comments->where('parent_id', null); @endphp

                    <div id="shared-comments-container" class="space-y-3 mb-4">
                        @if ($topComments->isNotEmpty())
                            @foreach ($topComments as $comment)
                                <div class="bg-gray-50 rounded-md px-4 py-3 text-sm">
                                    <div class="flex items-start justify-between">
                                        <div>
                                            <span class="font-semibold text-gray-800">{{ $comment->visitor_name }}</span>
                                            <p class="text-gray-600 mt-1">{{ $comment->comment }}</p>
                                        </div>
                                        <span class="text-xs text-gray-400 shrink-0 ml-3">{{ $comment->created_at->format('d M Y H:i') }}</span>
                                    </div>
                                    @if ($comment->replies->isNotEmpty())
                                        <div class="mt-3 ml-6 space-y-2 border-l-2 border-gray-200 pl-4">
                                            @foreach ($comment->replies as $reply)
                                                <div>
                                                    <div class="flex items-start justify-between">
                                                        <div>
                                                            <span class="font-semibold text-indigo-700 text-xs uppercase">{{ $reply->visitor_name }}</span>
                                                            <p class="text-gray-600 mt-1">{{ $reply->comment }}</p>
                                                        </div>
                                                        <span class="text-xs text-gray-400 shrink-0 ml-3">{{ $reply->created_at->format('d M Y H:i') }}</span>
                                                    </div>
                                                </div>
                                            @endforeach
                                        </div>
                                    @endif
                                </div>
                            @endforeach
                        @else
                            <p id="shared-comments-empty" class="text-sm text-gray-400">Belum ada komentar.</p>
                        @endif
                    </div>

                    <div x-data="{ sending: false, errors: {} }">
                        <form x-on:submit.prevent="
                            sending = true; errors = {};
                            const fd = new FormData($event.target);
                            fetch($event.target.action, {
                                method: 'POST',
                                body: fd,
                                headers: { 'X-Requested-With': 'XMLHttpRequest', 'Accept': 'application/json' }
                            })
                            .then(r => r.json())
                            .then(data => {
                                sending = false;
                                if (data.errors) {
                                    errors = data.errors;
                                } else if (data.html) {
                                    const container = document.getElementById('shared-comments-container');
                                    const empty = document.getElementById('shared-comments-empty');
                                    if (empty) empty.remove();
                                    container.insertAdjacentHTML('afterbegin', data.html);
                                    $event.target.reset();
                                    const countEl = document.querySelector('#shared-comments-container').closest('.p-6').querySelector('h3');
                                    if (countEl) {
                                        const m = countEl.textContent.match(/(\d+)/);
                                        countEl.textContent = 'Komentar (' + (m ? parseInt(m[1]) + 1 : 1) + ')';
                                    }
                                }
                            })
                            .catch(() => { sending = false; });
                        " method="POST" action="{{ route('tasks.shared.comments', $task->share_token) }}" class="space-y-3">
                            @csrf
                            <div>
                                <input type="text" name="visitor_name" placeholder="Nama Anda" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm" required maxlength="255">
                                <template x-if="errors.visitor_name">
                                    <p class="text-sm text-red-600 mt-1" x-text="errors.visitor_name.join(', ')"></p>
                                </template>
                            </div>
                            <div>
                                <textarea name="comment" rows="3" placeholder="Tulis komentar..." class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm" required maxlength="5000"></textarea>
                                <template x-if="errors.comment">
                                    <p class="text-sm text-red-600 mt-1" x-text="errors.comment.join(', ')"></p>
                                </template>
                            </div>
                            <div>
                                <button type="submit" x-bind:disabled="sending" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-500">
                                    <span x-show="!sending">Kirim Komentar</span>
                                    <span x-show="sending" class="flex items-center gap-1">
                                        <svg class="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/></svg>
                                        Mengirim...
                                    </span>
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
