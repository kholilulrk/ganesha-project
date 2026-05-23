<div x-data='{
    checked: @json($item->is_checked),
    checkedBy: @json($item->checker?->name),
    itemName: @json($item->item_name),
    editOpen: false,
    previewUrl: null,
    showImages: false,
    loading: false,
    imgLoading: false,
    imageCount: {{ $item->images->count() }},
    maxImages: 2,
    toggle() {
        this.loading = true;
        fetch("{{ route("tasks.teknisi-items.toggle", [$task, $item]) }}", {
            method: "PATCH",
            headers: { "X-CSRF-TOKEN": "{{ csrf_token() }}", "Accept": "application/json", "Content-Type": "application/json" }
        })
        .then(r => r.json())
        .then(data => {
            if (data.success !== false) {
                this.checked = data.is_checked;
                this.checkedBy = data.checked_by;
                let pct = data.total > 0 ? Math.round((data.checked / data.total) * 100) : 0;
                document.getElementById("teknisi-progress-bar").style.width = pct + "%";
                document.getElementById("teknisi-progress-text").textContent = data.checked + " of " + data.total + " items checked (" + pct + "%)";
                document.getElementById("teknisi-heading").textContent = document.getElementById("teknisi-heading").textContent.replace(/\(\d+\)/, "(" + data.total + ")");
            }
            this.loading = false;
        })
        .catch(() => this.loading = false);
    },
    remove($event) {
        if (!confirm("Hapus item ini?")) return;
        this.loading = true;
        fetch("{{ route("tasks.teknisi-items.destroy", [$task, $item]) }}", {
            method: "POST",
            headers: { "X-CSRF-TOKEN": "{{ csrf_token() }}", "Accept": "application/json", "Content-Type": "application/json" },
            body: JSON.stringify({ _method: "DELETE" })
        })
        .then(r => r.json())
        .then(data => {
            if (data.success) {
                ($event.target.closest("[x-data]") || $event.target.closest(".bg-gray-50")).remove();
                let pct = data.total > 0 ? Math.round((data.checked / data.total) * 100) : 0;
                let progress = document.getElementById("teknisi-progress");
                if (data.total === 0) {
                    progress.classList.add("hidden");
                } else {
                    if (progress.classList.contains("hidden")) progress.classList.remove("hidden");
                    document.getElementById("teknisi-progress-bar").style.width = pct + "%";
                    document.getElementById("teknisi-progress-text").textContent = data.checked + " of " + data.total + " items checked (" + pct + "%)";
                }
                document.getElementById("teknisi-heading").textContent = document.getElementById("teknisi-heading").textContent.replace(/\(\d+\)/, "(" + data.total + ")");
            }
            this.loading = false;
        })
        .catch(() => { this.loading = false; location.reload(); });
    },
    save() {
        this.loading = true;
        fetch("{{ route("tasks.teknisi-items.update", [$task, $item]) }}", {
            method: "POST",
            headers: { "X-CSRF-TOKEN": "{{ csrf_token() }}", "Accept": "application/json", "Content-Type": "application/json" },
            body: JSON.stringify({ _method: "PATCH", item_name: this.itemName })
        })
        .then(r => r.json())
        .then(data => {
            if (data.success) {
                this.editOpen = false;
            }
            this.loading = false;
        })
        .catch(() => this.loading = false);
    },
    uploadImages(e) {
        let files = e.target.files;
        if (!files.length) return;
        if (this.imageCount >= this.maxImages) {
            alert("Maksimal " + this.maxImages + " gambar per item.");
            e.target.value = "";
            return;
        }
        this.imgLoading = true;
        let formData = new FormData();
        for (let f of files) formData.append("images[]", f);
        formData.append("_token", "{{ csrf_token() }}");
        fetch("{{ route("tasks.teknisi-items.images.upload", [$task, $item]) }}", {
            method: "POST",
            headers: { "Accept": "application/json" },
            body: formData
        })
        .then(r => r.json().then(body => ({ status: r.status, body })))
        .then(({ status, body }) => {
            if (body.success) {
                let grid = document.getElementById("img-grid-" + {{ $item->id }});
                if (grid) {
                    grid.insertAdjacentHTML("beforeend", body.html);
                    if (typeof Alpine !== "undefined") Alpine.initTree(grid.lastElementChild);
                }
                this.imageCount = body.total;
                let btn = document.getElementById("img-btn-" + {{ $item->id }});
                if (btn) {
                    btn.dataset.count = body.total;
                    btn.querySelector("span").textContent = "Lihat Gambar (" + body.total + ")";
                } else {
                    let container = document.getElementById("img-actions-" + {{ $item->id }});
                    if (container) {
                        let newBtn = document.createElement("button");
                        newBtn.id = "img-btn-" + {{ $item->id }};
                        newBtn.dataset.count = body.total;
                        newBtn.className = "inline-flex items-center gap-1.5 px-3 py-1.5 bg-gray-100 hover:bg-gray-200 rounded-md text-xs font-medium text-gray-700 transition";
                        newBtn.innerHTML = `<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg><span>Lihat Gambar (` + body.total + `)</span><svg class="w-3 h-3 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>`;
                        newBtn.addEventListener("click", () => { this.showImages = !this.showImages; });
                        container.insertBefore(newBtn, container.firstChild);
                    }
                }
                if (!this.showImages) this.showImages = true;
            } else if (body.message) {
                alert(body.message);
            }
            this.imgLoading = false;
        })
        .catch(() => this.imgLoading = false);
        e.target.value = "";
    },
    deleteImage(imageId) {
        if (!confirm("Hapus gambar ini?")) return;
        let url = "{{ url('tasks/teknisi-items/images') }}" + "/" + imageId;
        fetch(url, {
            method: "POST",
            headers: { "X-CSRF-TOKEN": "{{ csrf_token() }}", "Accept": "application/json", "Content-Type": "application/json" },
            body: JSON.stringify({ _method: "DELETE" })
        })
        .then(r => r.json())
        .then(data => {
            if (data.success) {
                let el = document.getElementById("teknisi-img-" + imageId);
                if (el) el.remove();
                this.imageCount = data.total;
                let grid = document.getElementById("img-grid-" + {{ $item->id }});
                let btn = document.getElementById("img-btn-" + {{ $item->id }});
                if (grid && grid.children.length === 0) {
                    this.showImages = false;
                    if (btn) btn.remove();
                } else if (btn) {
                    btn.dataset.count = data.total;
                    btn.querySelector("span").textContent = "Lihat Gambar (" + data.total + ")";
                }
            }
        })
        .catch(() => location.reload());
    }
}' class="bg-gray-50 rounded-md px-4 py-2 text-sm" x-bind:class="checked ? 'opacity-60' : ''">
    <div class="flex items-center justify-between">
        <div class="flex items-center gap-3 min-w-0 flex-1">
            <button @click.prevent="toggle()" x-bind:disabled="loading" class="shrink-0">
                <svg x-show="checked" class="w-5 h-5 text-blue-600" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
                </svg>
                <svg x-show="!checked" class="w-5 h-5 text-gray-300 hover:text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <rect x="3" y="3" width="18" height="18" rx="3" stroke-width="2"/>
                </svg>
            </button>
            <span class="font-medium" x-bind:class="checked ? 'line-through text-gray-400' : ''" x-text="itemName"></span>
            <template x-if="checked && checkedBy">
                <span class="text-xs text-blue-600 ml-1" x-text="'by ' + checkedBy"></span>
            </template>
        </div>
        @if (auth()->user()->hasAnyRole(['super_admin', 'administrasi', 'teknisi']))
        <div class="flex items-center gap-2 shrink-0 ml-3">
            <button type="button" @click.prevent="editOpen = !editOpen" class="text-indigo-500 hover:text-indigo-700 text-xs">Edit</button>
            <button @click.prevent="remove($event)" x-bind:disabled="loading" class="text-red-500 hover:text-red-700 text-xs">Remove</button>
        </div>
        @endif
    </div>
    @if (auth()->user()->hasAnyRole(['super_admin', 'administrasi', 'teknisi']))
    <div x-show="editOpen" class="mt-2 pt-2 border-t border-gray-200">
        <form x-on:submit.prevent="save()" class="flex flex-wrap items-center gap-2">
            @csrf @method('PATCH')
            <input type="text" name="item_name" x-model="itemName" class="block min-w-0 w-full sm:w-auto sm:flex-1 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm" required>
            <x-primary-button class="text-xs w-full sm:w-auto">Save</x-primary-button>
        </form>
    </div>
    @endif

    @if ($item->images->isNotEmpty() || auth()->user()->hasAnyRole(['super_admin', 'administrasi', 'teknisi']))
    <div class="mt-2 pt-2 border-t border-gray-200">
        <div id="img-actions-{{ $item->id }}" class="flex flex-wrap items-center gap-2">
            @if ($item->images->isNotEmpty())
            <button id="img-btn-{{ $item->id }}" data-count="{{ $item->images->count() }}" @click.prevent="showImages = !showImages" class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-gray-100 hover:bg-gray-200 rounded-md text-xs font-medium text-gray-700 transition">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
                <span>Lihat Gambar ({{ $item->images->count() }})</span>
                <svg class="w-3 h-3 transition-transform" x-bind:class="showImages ? 'rotate-180' : ''" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
            </button>
            @endif
            @if (auth()->user()->hasAnyRole(['super_admin', 'administrasi', 'teknisi']))
            <label x-show="imageCount < maxImages" class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-indigo-50 hover:bg-indigo-100 rounded-md text-xs font-semibold text-indigo-700 cursor-pointer transition">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                <span x-show="!imgLoading">Tambah Gambar</span>
                <span x-show="imgLoading" class="inline-flex items-center gap-1">
                    <svg class="animate-spin h-3 w-3" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                    Upload
                </span>
                <input type="file" name="images[]" accept="image/*" multiple class="hidden" x-on:change="uploadImages($event)">
            </label>
            <span x-show="imageCount >= maxImages" class="inline-flex items-center gap-1 px-3 py-1.5 bg-gray-100 rounded-md text-xs font-medium text-gray-400 cursor-not-allowed">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                Maksimal 2 gambar
            </span>
            @endif
        </div>

        <div x-show="showImages" x-collapse.duration.200ms class="mt-3">
            <div id="img-grid-{{ $item->id }}" class="grid grid-cols-8 sm:grid-cols-10 md:grid-cols-12 lg:grid-cols-14 gap-1">
                @foreach ($item->images as $img)
                <div id="teknisi-img-{{ $img->id }}" class="relative group">
                    <button @click.prevent="previewUrl = '{{ $img->imageUrl() }}'" class="block w-full aspect-square rounded-md overflow-hidden border border-gray-200 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-400">
                        <img src="{{ $img->imageUrl() }}" alt="Gambar" class="w-full h-full object-cover">
                    </button>
                    @if (auth()->user()->hasAnyRole(['super_admin', 'administrasi', 'teknisi']))
                    <button @click.prevent="deleteImage({{ $img->id }})" class="absolute -top-1.5 -right-1.5 w-5 h-5 bg-red-500 text-white rounded-full flex items-center justify-center text-xs md:opacity-0 md:group-hover:opacity-100 transition-opacity hover:bg-red-600 opacity-100">
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                    </button>
                    @endif
                </div>
                @endforeach
            </div>
        </div>
    </div>
    @endif

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
