<div x-data='{
    status: @json($todo->status),
    loading: false,
    toggleStatus() {
        this.loading = true;
        fetch("{{ route('todos.toggle-status', $todo) }}", {
            method: "PATCH",
            headers: { "X-CSRF-TOKEN": "{{ csrf_token() }}", "Accept": "application/json", "Content-Type": "application/json" }
        })
        .then(r => r.json())
        .then(data => {
            if (data.success) {
                this.status = data.status;
            }
            this.loading = false;
        })
        .catch(() => this.loading = false);
    },
    removeItem() {
        if (!confirm("Hapus to-do ini?")) return;
        this.loading = true;
        fetch("{{ route('todos.destroy', $todo) }}", {
            method: "POST",
            headers: { "X-CSRF-TOKEN": "{{ csrf_token() }}", "Accept": "application/json", "Content-Type": "application/json" },
            body: JSON.stringify({ _method: "DELETE" })
        })
        .then(r => r.json())
        .then(data => {
            if (data.success) {
                this.$el.remove();
                let container = document.getElementById("todos-container");
                if (container.children.length === 0) {
                    document.getElementById("todos-empty").classList.remove("hidden");
                }
            }
            this.loading = false;
        })
        .catch(() => this.loading = false);
    }
}' class="todo-item" x-bind:class="status === 'done' ? 'opacity-60' : ''">
    <div class="flex items-center justify-between px-6 py-4">
        <div class="flex items-center gap-3 min-w-0 flex-1">
            <span class="font-medium" x-bind:class="status === 'done' ? 'line-through text-gray-400' : 'text-gray-800'">{{ $todo->title }}</span>
        </div>
        <div class="flex items-center gap-2 shrink-0 ml-3">
            <button x-show="status === 'pending'" @click.prevent="toggleStatus()" x-bind:disabled="loading" class="inline-flex items-center px-3 py-1 rounded-md text-xs font-semibold uppercase tracking-widest bg-blue-100 text-blue-700 hover:bg-blue-200">Kerjakan</button>
            <button x-show="status === 'progress'" @click.prevent="toggleStatus()" x-bind:disabled="loading" class="inline-flex items-center px-3 py-1 rounded-md text-xs font-semibold uppercase tracking-widest bg-green-100 text-green-700 hover:bg-green-200">Selesaikan</button>
            <button x-show="status === 'done'" @click.prevent="toggleStatus()" x-bind:disabled="loading" class="inline-flex items-center px-3 py-1 rounded-md text-xs font-semibold uppercase tracking-widest bg-gray-100 text-gray-500 hover:bg-gray-200">Selesai</button>
            <button @click.prevent="removeItem()" x-bind:disabled="loading" class="text-red-500 hover:text-red-700 text-xs">Remove</button>
        </div>
    </div>
</div>
