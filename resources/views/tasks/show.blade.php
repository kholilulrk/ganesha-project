<x-app-layout>
    <x-slot name="header">
        <div class="flex items-center justify-between gap-4">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight min-w-0 truncate">{{ $task->title }}</h2>
            <div class="flex items-center gap-2 shrink-0">
                <form action="{{ route('tasks.share-link', $task) }}" method="POST" x-data="{ loading: false }" x-on:submit="loading = true">
                    @csrf
                    <button x-bind:disabled="loading" type="submit" class="inline-flex items-center px-4 py-2 bg-blue-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-blue-500">
                        <span x-show="!loading">Share</span>
                        <span x-show="loading">
                            <svg class="animate-spin h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                        </span>
                    </button>
                </form>
                @can('task-edit')
                    <a href="{{ route('tasks.edit', $task) }}" class="inline-flex items-center px-4 py-2 bg-gray-800 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-gray-700">Edit</a>
                @endcan
            </div>
        </div>
    </x-slot>

    <div class="py-12">
        <div class="max-w-3xl mx-auto sm:px-6 lg:px-8 space-y-6">
            @if (session('success'))
                <div class="mb-4 px-4 py-2 bg-green-100 border border-green-200 text-green-700 rounded-md text-sm">
                    {{ session('success') }}
                </div>
            @endif

            @if (session('share_url'))
                <div class="mb-4 px-4 py-3 bg-blue-50 border border-blue-200 text-blue-800 rounded-md text-sm">
                    <div class="flex items-center justify-between gap-3">
                        <span class="truncate">{{ session('share_url') }}</span>
                        <button onclick="navigator.clipboard.writeText('{{ session('share_url') }}').then(() => { this.textContent = 'Tersalin!'; setTimeout(() => this.textContent = 'Salin', 2000); })" class="shrink-0 inline-flex items-center px-3 py-1 bg-blue-600 text-white rounded text-xs font-semibold hover:bg-blue-500">Salin</button>
                    </div>
                </div>
            @endif

            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6 space-y-6">
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm">
                    <div>
                        <span class="text-gray-500">Type</span>
                        <p class="font-medium">{{ ucfirst($task->task_type) }}</p>
                    </div>
                    <div>
                        <span class="text-gray-500">Status</span>
                        <p class="font-medium">{{ ucfirst($task->status) }}</p>
                    </div>
                    <div>
                        <span class="text-gray-500">Deadline</span>
                        <p class="font-medium">{{ $task->deadline?->format('d M Y') ?? '-' }}</p>
                    </div>
                    <div>
                        <span class="text-gray-500">Created By</span>
                        <p class="font-medium">{{ $task->creator?->name ?? '-' }}</p>
                    </div>
                    <div>
                        <span class="text-gray-500">Assigned To</span>
                        <p class="font-medium">
                            @if($task->assignedUsers->isNotEmpty())
                                {{ $task->assignedUsers->pluck('name')->implode(', ') }}
                            @else
                                -
                            @endif
                        </p>
                    </div>
                </div>

                <div>
                    <span class="text-sm text-gray-500">Description</span>
                    <p class="mt-1 text-gray-800">{{ $task->description ?? 'No description.' }}</p>
                </div>

                @if ($task->document)
                <div class="pt-4 border-t">
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

                <div class="pt-4 border-t">
                    <h3 class="text-sm font-semibold text-gray-500 mb-3">Update Status</h3>
                    <div class="flex items-center gap-3">
                        <span class="px-3 py-1 text-sm rounded-full font-medium
                            @if($task->status === 'pending') bg-gray-200 text-gray-800
                            @elseif($task->status === 'progress') bg-yellow-200 text-yellow-800
                            @elseif($task->status === 'done') bg-green-200 text-green-800
                            @else bg-red-200 text-red-800 @endif">
                            {{ ucfirst($task->status) }}
                        </span>

                        @if ($task->status === 'pending')
                            <form x-data="{ loading: false }" x-on:submit="loading = true" action="{{ route('tasks.status.update', $task) }}" method="POST">
                                @csrf @method('PATCH')
                                <input type="hidden" name="status" value="progress">
                                <button x-bind:disabled="loading" type="submit" class="inline-flex items-center px-4 py-2 bg-blue-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-blue-500">
                                    <span x-show="!loading">Mulai Pekerjaan</span>
                                    <span x-show="loading" class="inline-flex items-center">
                                        <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                        </svg>
                                        Mulai Pekerjaan
                                    </span>
                                </button>
                            </form>
                        @endif

                        @if ($task->status === 'progress')
                            <form x-data="{ loading: false }" x-on:submit="if(confirm('Yakin ingin menyelesaikan pekerjaan ini?')) loading = true; else $event.preventDefault()" action="{{ route('tasks.status.update', $task) }}" method="POST">
                                @csrf @method('PATCH')
                                <input type="hidden" name="status" value="done">
                                <button x-bind:disabled="loading" type="submit" class="inline-flex items-center px-4 py-2 bg-green-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-green-500">
                                    <span x-show="!loading">Selesaikan Pekerjaan</span>
                                    <span x-show="loading" class="inline-flex items-center">
                                        <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                        </svg>
                                        Selesaikan Pekerjaan
                                    </span>
                                </button>
                            </form>
                            <form x-data="{ loading: false }" x-on:submit="loading = true" action="{{ route('tasks.status.update', $task) }}" method="POST">
                                @csrf @method('PATCH')
                                <input type="hidden" name="status" value="pending">
                                <button x-bind:disabled="loading" type="submit" class="inline-flex items-center px-4 py-2 bg-gray-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-gray-500">
                                    <span x-show="!loading">Kembali ke Pending</span>
                                    <span x-show="loading" class="inline-flex items-center">
                                        <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                        </svg>
                                        Kembali ke Pending
                                    </span>
                                </button>
                            </form>
                        @endif

                        @if ($task->status === 'done')
                            <span class="text-sm text-green-600 font-medium">Pekerjaan selesai</span>
                        @endif
                    </div>
                    </div>
                </div>

                <div class="space-y-6">

                @if (auth()->user()->hasAnyRole(['super_admin', 'administrasi', 'teknisi']) && $task->task_type === 'teknisi')
                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6">
                    <h3 id="teknisi-heading" class="text-lg font-semibold text-gray-800 mb-3">Checklist Pekerjaan Teknisi ({{ $task->teknisiTaskItems->count() }})</h3>

                    @php
                        $totalTeknisi = $task->teknisiTaskItems->count();
                        $checkedTeknisi = $task->teknisiTaskItems->where('is_checked', true)->count();
                        $progressTeknisi = $totalTeknisi > 0 ? round(($checkedTeknisi / $totalTeknisi) * 100) : 0;
                    @endphp

                    <div id="teknisi-progress" class="{{ $totalTeknisi > 0 ? '' : 'hidden' }}">
                        <div class="w-full bg-gray-200 rounded-full h-2 mb-3">
                            <div id="teknisi-progress-bar" class="bg-blue-500 h-2 rounded-full transition-all duration-300" style="width: {{ $progressTeknisi }}%"></div>
                        </div>
                        <div id="teknisi-progress-text" class="text-xs text-gray-500 mb-4">{{ $checkedTeknisi }} of {{ $totalTeknisi }} items checked ({{ $progressTeknisi }}%)</div>
                    </div>

                    <div id="teknisi-items-container" class="space-y-2 mb-4">
                        @foreach ($task->teknisiTaskItems as $item)
                            @include('tasks.partials._teknisi_item', ['item' => $item, 'task' => $task])
                        @endforeach
                    </div>

                    @if (auth()->user()->hasAnyRole(['super_admin', 'administrasi', 'teknisi']))
                        <form x-data="{
                            loading: false,
                            submitForm() {
                                this.loading = true;
                                let form = this.$el;
                                let name = form.item_name.value;
                                fetch('{{ route('tasks.teknisi-items.store', $task) }}', {
                                    method: 'POST',
                                    headers: { 'X-CSRF-TOKEN': '{{ csrf_token() }}', 'Accept': 'application/json', 'Content-Type': 'application/json' },
                                    body: JSON.stringify({ item_name: name })
                                })
                                .then(r => r.json())
                                .then(data => {
                                    if (data.success) {
                                        let container = document.getElementById('teknisi-items-container');
                                        container.insertAdjacentHTML('beforeend', data.html);
                                        Alpine.initTree(container.lastElementChild);
                                        form.item_name.value = '';
                                        let h3 = document.getElementById('teknisi-heading');
                                        h3.textContent = h3.textContent.replace(/\(\d+\)/, '(' + data.total + ')');
                                        let progress = document.getElementById('teknisi-progress');
                                        let bar = document.getElementById('teknisi-progress-bar');
                                        let text = document.getElementById('teknisi-progress-text');
                                        let pct = data.total > 0 ? Math.round((data.checked / data.total) * 100) : 0;
                                        if (progress.classList.contains('hidden')) progress.classList.remove('hidden');
                                        bar.style.width = pct + '%';
                                        text.textContent = data.checked + ' of ' + data.total + ' items checked (' + pct + '%)';
                                    }
                                    this.loading = false;
                                })
                                .catch(() => this.loading = false);
                            }
                        }" x-on:submit.prevent="submitForm" class="flex flex-wrap items-center gap-2">
                            @csrf
                            <input type="text" name="item_name" placeholder="Nama pekerjaan" class="block min-w-0 w-full sm:w-auto sm:flex-1 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm" required>
                            <x-primary-button class="text-xs w-full sm:w-auto">Tambah Item</x-primary-button>
                        </form>
                    @endif
                </div>
                @endif

                @if (auth()->user()->hasAnyRole(['super_admin', 'administrasi', 'logistic', 'teknisi']))
                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6">
                    <h3 id="shopping-heading" class="text-lg font-semibold text-gray-800 mb-3">Shopping List ({{ $task->shoppingItems->count() }})</h3>

                    @php
                        $total = $task->shoppingItems->count();
                        $checked = $task->shoppingItems->where('is_checked', true)->count();
                        $progress = $total > 0 ? round(($checked / $total) * 100) : 0;
                    @endphp

                    <div id="shopping-progress" class="{{ $total > 0 ? '' : 'hidden' }}">
                        <div class="w-full bg-gray-200 rounded-full h-2">
                            <div id="shopping-progress-bar" class="bg-green-500 h-2 rounded-full transition-all duration-300" style="width: {{ $progress }}%"></div>
                        </div>
                        <div id="shopping-progress-text" class="text-xs text-gray-500 my-2">{{ $checked }} of {{ $total }} items checked ({{ $progress }}%)</div>
                        @php $totalPrice = $task->shoppingItems->sum(fn($i) => ($i->price ?? 0) * $i->qty); @endphp
                        <div id="shopping-total" class="text-xs text-gray-600 mb-2 {{ $totalPrice > 0 ? '' : 'hidden' }}">
                            Total Biaya: <span id="shopping-total-value" class="font-semibold text-gray-800">Rp {{ number_format($totalPrice, 0, ',', '.') }}</span>
                        </div>
                    </div>

                    <div id="shopping-items-container" class="space-y-2 mb-4">
                        @foreach ($task->shoppingItems as $item)
                            <div x-data='{
                                checked: @json($item->is_checked),
                                checkedBy: @json($item->checker?->name),
                                itemName: @json($item->item_name),
                                itemQty: @json($item->qty),
                                itemUnit: @json($item->unit),
                                itemNotes: @json($item->notes),
                                itemPrice: @json($item->price),
                                editOpen: false,
                                showImages: false,
                                loading: false,
                                imageUrl: {!! $item->image ? json_encode($item->imageUrl(), JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_AMP | JSON_HEX_QUOT) : 'null' !!},
                                hasImage: {{ $item->image ? 'true' : 'false' }},
                                imgLoading: false,
                                uploadImage(e) {
                                    e.preventDefault();
                                    const form = e.currentTarget;
                                    if (!form) return;
                                    this.imgLoading = true;
                                    const fd = new FormData(form);
                                    fetch(form.action, {
                                        method: "POST",
                                        headers: { "Accept": "application/json" },
                                        body: fd
                                    })
                                    .then(r => r.json())
                                    .then(res => {
                                        if (res.success) {
                                            this.imageUrl = res.image_url;
                                            this.hasImage = res.has_image;
                                            form.querySelector('input[type="file"]').value = '';
                                        }
                                        this.imgLoading = false;
                                    })
                                    .catch(() => { this.imgLoading = false; });
                                },
                                deleteImage() {
                                    if (!confirm("Hapus gambar ini?")) return;
                                    fetch("{{ route("tasks.shopping-items.image.destroy", [$task, $item]) }}", {
                                        method: "POST",
                                        headers: { "X-CSRF-TOKEN": "{{ csrf_token() }}", "Accept": "application/json", "Content-Type": "application/json" },
                                        body: JSON.stringify({ _method: "DELETE" })
                                    })
                                    .then(r => r.json())
                                    .then(data => {
                                        if (data.success) {
                                            this.imageUrl = null;
                                            this.hasImage = false;
                                        }
                                    })
                                    .catch(() => location.reload());
                                },
                                toggle() {
                                    this.loading = true;
                                    fetch("{{ route("tasks.shopping-items.toggle", [$task, $item]) }}", {
                                        method: "PATCH",
                                        headers: { "X-CSRF-TOKEN": "{{ csrf_token() }}", "Accept": "application/json", "Content-Type": "application/json" }
                                    })
                                    .then(r => r.json())
                                    .then(data => {
                                        if (data.success) {
                                            this.checked = data.is_checked;
                                            this.checkedBy = data.checked_by;
                                            let pct = data.total > 0 ? Math.round((data.checked / data.total) * 100) : 0;
                                            document.getElementById("shopping-progress-bar").style.width = pct + "%";
                                            document.getElementById("shopping-progress-text").textContent = data.checked + " of " + data.total + " items checked (" + pct + "%)";
                                            document.getElementById("shopping-heading").textContent = document.getElementById("shopping-heading").textContent.replace(/\(\d+\)/, "(" + data.total + ")");
                                            let totalVal = document.getElementById("shopping-total-value");
                                            if (totalVal) {
                                                totalVal.textContent = "Rp " + Number(data.total_price).toLocaleString("id-ID");
                                                let totalEl = document.getElementById("shopping-total");
                                                if (data.total_price > 0) { totalEl.classList.remove("hidden"); } else { totalEl.classList.add("hidden"); }
                                            }
                                        }
                                        this.loading = false;
                                    })
                                    .catch(() => this.loading = false);
                                },
                                remove($event) {
                                    if (!confirm("Remove this item?")) return;
                                    this.loading = true;
                                    fetch("{{ route("tasks.shopping-items.destroy", [$task, $item]) }}", {
                                        method: "POST",
                                        headers: { "X-CSRF-TOKEN": "{{ csrf_token() }}", "Accept": "application/json", "Content-Type": "application/json" },
                                        body: JSON.stringify({ _method: "DELETE" })
                                    })
                                    .then(r => r.json())
                                    .then(data => {
                                        if (data.success) {
                                            ($event.target.closest("[x-data]") || $event.target.closest(".bg-gray-50")).remove();
                                            let pct = data.total > 0 ? Math.round((data.checked / data.total) * 100) : 0;
                                            let progress = document.getElementById("shopping-progress");
                                            if (data.total === 0) {
                                                progress.classList.add("hidden");
                                            } else {
                                                if (progress.classList.contains("hidden")) progress.classList.remove("hidden");
                                                document.getElementById("shopping-progress-bar").style.width = pct + "%";
                                                document.getElementById("shopping-progress-text").textContent = data.checked + " of " + data.total + " items checked (" + pct + "%)";
                                            }
                                            document.getElementById("shopping-heading").textContent = document.getElementById("shopping-heading").textContent.replace(/\(\d+\)/, "(" + data.total + ")");
                                            let totalVal = document.getElementById("shopping-total-value");
                                            if (totalVal) {
                                                totalVal.textContent = "Rp " + Number(data.total_price).toLocaleString("id-ID");
                                                let totalEl = document.getElementById("shopping-total");
                                                if (data.total_price > 0) { totalEl.classList.remove("hidden"); } else { totalEl.classList.add("hidden"); }
                                            }
                                        }
                                        this.loading = false;
                                    })
                                    .catch(() => { this.loading = false; location.reload(); });
                                },
                                save() {
                                    this.loading = true;
                                    fetch("{{ route("tasks.shopping-items.update", [$task, $item]) }}", {
                                        method: "POST",
                                        headers: { "X-CSRF-TOKEN": "{{ csrf_token() }}", "Accept": "application/json", "Content-Type": "application/json" },
                                        body: JSON.stringify({ _method: "PATCH", item_name: this.itemName, qty: this.itemQty, unit: this.itemUnit, notes: this.itemNotes, price: this.itemPrice })
                                    })
                                    .then(r => r.json())
                                    .then(data => {
                                        if (data.success) {
                                            this.editOpen = false;
                                            let totalVal = document.getElementById("shopping-total-value");
                                            if (totalVal) {
                                                totalVal.textContent = "Rp " + Number(data.total_price).toLocaleString("id-ID");
                                                let totalEl = document.getElementById("shopping-total");
                                                if (data.total_price > 0) { totalEl.classList.remove("hidden"); } else { totalEl.classList.add("hidden"); }
                                            }
                                        }
                                        this.loading = false;
                                    })
                                    .catch(() => this.loading = false);
                                }
                            }' class="bg-gray-50 rounded-md px-4 py-2 text-sm" x-bind:class="checked ? 'opacity-60' : ''">
                                <div class="flex items-center justify-between">
                                    <div class="flex items-center gap-3 min-w-0 flex-1">
                                        <button @click.prevent="toggle()" x-bind:disabled="loading" class="shrink-0">
                                            <svg x-show="checked" class="w-5 h-5 text-green-600" fill="currentColor" viewBox="0 0 20 20">
                                                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
                                            </svg>
                                            <svg x-show="!checked" class="w-5 h-5 text-gray-300 hover:text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <rect x="3" y="3" width="18" height="18" rx="3" stroke-width="2"/>
                                            </svg>
                                        </button>
                                        <span class="font-medium" x-bind:class="checked ? 'line-through text-gray-400' : ''" x-text="itemName"></span>
                                        <span class="text-xs text-gray-400" x-text="'(' + itemQty + (itemUnit ? ' ' + itemUnit : '') + ')'"></span>
                                        <span class="text-xs text-gray-400" x-show="itemNotes" x-text="'- ' + itemNotes"></span>
                                        <span class="text-xs text-gray-500 font-medium" x-show="itemPrice" x-text="'@ Rp ' + Number(itemPrice).toLocaleString('id-ID')"></span>
                                        <template x-if="checked && checkedBy">
                                            <span class="text-xs text-green-600 ml-1" x-text="'by ' + checkedBy"></span>
                                        </template>
                                    </div>
                                    <div class="flex items-center gap-2 shrink-0 ml-3">
                                        @if (auth()->user()->hasAnyRole(['super_admin', 'administrasi', 'logistic', 'teknisi']))
                                            <button type="button" @click.prevent="editOpen = !editOpen" class="text-indigo-500 hover:text-indigo-700 text-xs">Edit</button>
                                        @endif
                                        @if (!auth()->user()->hasRole('logistic'))
                                        <button @click.prevent="remove($event)" x-bind:disabled="loading" class="text-red-500 hover:text-red-700 text-xs">Remove</button>
                                        @endif
                                    </div>
                                </div>
                                @if (auth()->user()->hasAnyRole(['super_admin', 'administrasi', 'logistic', 'teknisi']))
                                <div x-show="editOpen" class="mt-2 pt-2 border-t border-gray-200">
                                    <form x-on:submit.prevent="save()" class="flex flex-wrap items-center gap-2">
                                        @csrf @method('PATCH')
                                        <input type="text" name="item_name" x-model="itemName" class="block min-w-0 w-full sm:w-auto sm:flex-1 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm" required>
                                        <input type="number" name="qty" x-model="itemQty" min="1" class="block w-16 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">
                                        <input type="text" name="unit" x-model="itemUnit" placeholder="Unit" class="block w-20 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">
                                        <input type="number" name="price" x-model="itemPrice" min="0" placeholder="Harga" class="block w-28 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">
                                        <x-primary-button class="text-xs w-full sm:w-auto">Save</x-primary-button>
                                    </form>
                                </div>
                                @endif
                                <div class="mt-2 pt-2 border-t border-gray-100">
                                    <button @click.prevent="showImages = !showImages" class="inline-flex items-center gap-1 px-2 py-1 rounded-md text-xs font-medium text-indigo-600 hover:bg-indigo-50 transition-colors">
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
                                        <span x-text="showImages ? 'Sembunyikan Gambar' : (hasImage ? 'Lihat Gambar' : 'Tambah Gambar')"></span>
                                    </button>
                                    <div x-show="showImages" x-collapse.duration.200ms class="mt-3">
                                        <div class="flex flex-wrap items-start gap-3">
                                            <div x-show="hasImage" class="relative group w-20 h-20 shrink-0">
                                                <button @click="$dispatch('preview-image', { url: imageUrl })" class="block w-full h-full rounded-md overflow-hidden border border-gray-200 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-400">
                                                    <img :src="imageUrl" alt="Gambar" class="w-full h-full object-cover">
                                                </button>
                                                <button @click.prevent="deleteImage()" class="absolute -top-1.5 -right-1.5 w-5 h-5 bg-red-500 text-white rounded-full flex items-center justify-center text-xs md:opacity-0 md:group-hover:opacity-100 transition-opacity hover:bg-red-600 opacity-100">
                                                    <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                                                </button>
                                            </div>
                                            <form @submit.prevent="uploadImage" method="POST" action="{{ route('tasks.shopping-items.image', [$task, $item]) }}" enctype="multipart/form-data" class="flex flex-wrap items-center gap-2">
                                                @csrf
                                                <input type="file" name="image" accept="image/*" class="block text-xs text-gray-500 file:mr-2 file:py-1.5 file:px-3 file:rounded file:border-0 file:text-xs file:font-semibold file:bg-gray-100 file:text-gray-700 hover:file:bg-gray-200">
                                                <button type="submit" x-bind:disabled="imgLoading" class="inline-flex items-center px-3 py-1.5 bg-amber-50 border border-amber-200 rounded-md text-xs font-semibold text-amber-700 hover:bg-amber-100">
                                                    <span x-show="!imgLoading" x-text="hasImage ? 'Ganti Gambar' : 'Upload Gambar'"></span>
                                                    <span x-show="imgLoading" class="inline-flex items-center gap-1">
                                                        <svg class="animate-spin h-3 w-3 text-amber-700" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                                                        ...
                                                    </span>
                                                </button>
                                            </form>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        @endforeach
                    </div>

                    <form x-data="{
                        loading: false,
                        submitForm() {
                            this.loading = true;
                            let form = this.$el;
                            let data = new FormData(form);
                            fetch('{{ route('tasks.shopping-items.store', $task) }}', {
                                method: 'POST',
                                headers: { 'X-CSRF-TOKEN': '{{ csrf_token() }}', 'Accept': 'application/json' },
                                body: data
                            })
                            .then(r => r.json())
                            .then(data => {
                                if (data.success) {
                                    let container = document.getElementById('shopping-items-container');
                                    container.insertAdjacentHTML('beforeend', data.html);
                                    Alpine.initTree(container.lastElementChild);
                                    form.item_name.value = '';
                                    form.qty.value = '1';
                                    form.unit.value = '';
                                    form.notes.value = '';
                                    form.price.value = '';
                                    let h3 = document.getElementById('shopping-heading');
                                    h3.textContent = h3.textContent.replace(/\(\d+\)/, '(' + data.total + ')');
                                    let progress = document.getElementById('shopping-progress');
                                    let bar = document.getElementById('shopping-progress-bar');
                                    let text = document.getElementById('shopping-progress-text');
                                    let pct = data.total > 0 ? Math.round((data.checked / data.total) * 100) : 0;
                                    if (progress.classList.contains('hidden')) progress.classList.remove('hidden');
                                    bar.style.width = pct + '%';
                                    text.textContent = data.checked + ' of ' + data.total + ' items checked (' + pct + '%)';
                                    let totalEl = document.getElementById('shopping-total');
                                    let totalVal = document.getElementById('shopping-total-value');
                                    if (totalVal) {
                                        totalVal.textContent = 'Rp ' + Number(data.total_price).toLocaleString('id-ID');
                                        if (data.total_price > 0) { totalEl.classList.remove('hidden'); } else { totalEl.classList.add('hidden'); }
                                    }
                                }
                                this.loading = false;
                            })
                            .catch(() => this.loading = false);
                        }
                    }" x-on:submit.prevent="submitForm" class="flex flex-wrap items-center gap-2">
                        @csrf
                        <input type="text" name="item_name" placeholder="Item name" class="block min-w-0 w-full sm:w-auto sm:flex-1 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm" required>
                        <input type="number" name="qty" value="1" min="1" class="block w-16 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">
                        <input type="text" name="unit" placeholder="Unit" class="block w-20 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">
                        <input type="text" name="notes" placeholder="Notes" class="block w-full sm:w-32 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">
                        <input type="number" name="price" placeholder="Harga" min="0" class="block w-28 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">
                        <x-primary-button class="text-xs w-full sm:w-auto">Add</x-primary-button>
                    </form>
                    <x-input-error :messages="$errors->get('item_name')" class="mt-2" />
                </div>
                @endif

                {{-- Global Preview Lightbox --}}
                <div x-data="{ previewUrl: null }" @preview-image.window="previewUrl = $event.detail.url">
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

                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6 space-y-6">

                @php $topComments = $task->comments->where('parent_id', null); @endphp
                <div class="pt-4 border-t">
                    <h3 class="text-sm font-semibold text-gray-500 mb-3">Komentar Customer ({{ $topComments->count() }})</h3>
                    <div id="comments-container" class="space-y-3">
                        @foreach ($topComments as $comment)
                            <div class="bg-gray-50 rounded-md px-4 py-3 text-sm">
                                <div class="flex items-start justify-between">
                                    <div>
                                        <span class="font-semibold text-gray-800">{{ $comment->visitor_name }}</span>
                                        <p class="text-gray-600 mt-1">{{ $comment->comment }}</p>
                                    </div>
                                    <span class="text-xs text-gray-400 shrink-0 ml-3">{{ $comment->created_at->format('d M Y H:i') }}</span>
                                </div>
                                <div data-replies="{{ $comment->id }}" class="mt-3 ml-6 space-y-2 border-l-2 border-gray-200 pl-4">
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
                                <div class="mt-2">
                                    <form x-data="{ open: false, sending: false }" x-on:submit.prevent="
                                        sending = true;
                                        const fd = new FormData($event.target);
                                        fetch($event.target.action, {
                                            method: 'POST',
                                            body: fd,
                                            headers: { 'X-Requested-With': 'XMLHttpRequest', 'Accept': 'application/json' }
                                        })
                                        .then(r => r.json())
                                        .then(data => {
                                            sending = false;
                                            if (data.html) {
                                                const container = $event.target.closest('[data-replies]') || $event.target.closest('.bg-gray-50').querySelector('[data-replies]');
                                                if (container) container.insertAdjacentHTML('beforeend', data.html);
                                                $event.target.querySelector('[name=&quot;comment&quot;]').value = '';
                                                open = false;
                                            }
                                        })
                                        .catch(() => { sending = false; });
                                    " method="POST" action="{{ route('tasks.comments.reply', [$task, $comment]) }}" class="inline">
                                        @csrf
                                        <button type="button" @click.prevent="open = !open" class="text-xs text-indigo-600 hover:text-indigo-900">Balas</button>
                                        <div x-show="open" class="mt-2 flex items-center gap-2">
                                            <input type="text" name="comment" placeholder="Tulis balasan..." class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm" required maxlength="5000">
                                            <button type="submit" x-bind:disabled="sending" class="inline-flex items-center px-3 py-1.5 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-500 shrink-0">
                                                <span x-show="!sending">Kirim</span>
                                                <span x-show="sending" class="flex items-center gap-1">
                                                    <svg class="animate-spin h-3 w-3" viewBox="0 0 24 24" fill="none"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/></svg>
                                                    Kirim
                                                </span>
                                            </button>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        @endforeach
                    </div>
                </div>

                <div class="pt-4 border-t flex items-center gap-4 text-sm">
                    <a href="{{ route('tasks.index') }}" class="text-indigo-600 hover:text-indigo-900">&larr; Back to Tasks</a>
                    @can('task-delete')
                    <form x-data="{ loading: false }" x-on:submit="if(confirm('Delete this task?')) loading = true; else $event.preventDefault()" action="{{ route('tasks.destroy', $task) }}" method="POST" class="inline">
                        @csrf @method('DELETE')
                        <button x-bind:disabled="loading" type="submit" class="text-red-600 hover:text-red-900">Delete</button>
                    </form>
                    @endcan
                </div>
            </div>
        </div>
        </div>
    </div>
</x-app-layout>
