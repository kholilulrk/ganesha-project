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
    hasImage: {{ $item->image ? 'true' : 'false' }},
    imageUrl: {!! $item->image ? json_encode($item->imageUrl(), JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_AMP | JSON_HEX_QUOT) : 'null' !!},
    imgLoading: false,
    uploadImage(e) {
        e.preventDefault();
        const form = e.currentTarget.closest("form") || this.$el.querySelector("form");
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
                let progress = document.getElementById("shopping-progress");
                if (data.total === 0) {
                    progress.classList.add("hidden");
                } else {
                    if (progress.classList.contains("hidden")) progress.classList.remove("hidden");
                    progress.querySelector("#shopping-progress-bar").style.width = Math.round((data.checked / data.total) * 100) + "%";
                    document.getElementById("shopping-progress-text").textContent = data.checked + " of " + data.total + " items checked (" + Math.round((data.checked / data.total) * 100) + "%)";
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
                this.hasImage = false;
            }
        })
        .catch(() => location.reload());
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
                <form method="POST" action="{{ route('tasks.shopping-items.image', [$task, $item]) }}" enctype="multipart/form-data" class="flex flex-wrap items-center gap-2">
                    @csrf
                    <input type="file" name="image" accept="image/*" class="block text-xs text-gray-500 file:mr-2 file:py-1.5 file:px-3 file:rounded file:border-0 file:text-xs file:font-semibold file:bg-gray-100 file:text-gray-700 hover:file:bg-gray-200">
                    <button type="button" @click.prevent="uploadImage($event)" x-bind:disabled="imgLoading" class="inline-flex items-center px-3 py-1.5 bg-amber-50 border border-amber-200 rounded-md text-xs font-semibold text-amber-700 hover:bg-amber-100">
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
