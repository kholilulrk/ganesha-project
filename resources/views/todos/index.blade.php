<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('To-Do List') }}</h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-3xl mx-auto sm:px-6 lg:px-8">
            @if (session('success'))
                <div class="mb-4 px-4 py-2 bg-green-100 border border-green-200 text-green-700 rounded-md text-sm">
                    {{ session('success') }}
                </div>
            @endif

            <div class="bg-white shadow-sm sm:rounded-lg overflow-hidden">
                <div class="px-6 py-4 border-b border-gray-200">
                    <form x-data="{
                        loading: false,
                        submitForm() {
                            this.loading = true;
                            let form = this.$el;
                            let title = form.title.value;
                            fetch('{{ route('todos.store') }}', {
                                method: 'POST',
                                headers: { 'X-CSRF-TOKEN': '{{ csrf_token() }}', 'Accept': 'application/json', 'Content-Type': 'application/json' },
                                body: JSON.stringify({ title: title })
                            })
                            .then(r => r.json())
                            .then(data => {
                                if (data.success) {
                                    let container = document.getElementById('todos-container');
                                    let empty = document.getElementById('todos-empty');
                                    if (empty) empty.classList.add('hidden');
                                    container.insertAdjacentHTML('beforeend', data.html);
                                    Alpine.initTree(container.lastElementChild);
                                    form.title.value = '';
                                }
                                this.loading = false;
                            })
                            .catch(() => this.loading = false);
                        }
                    }" x-on:submit.prevent="submitForm" class="flex items-center gap-3">
                        @csrf
                        <input type="text" name="title" placeholder="Tambah kegiatan..." class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm" required autofocus>
                        <x-primary-button class="text-xs whitespace-nowrap" x-bind:disabled="loading">Tambah</x-primary-button>
                    </form>
                </div>

                <div id="todos-container" class="divide-y divide-gray-200">
                    @foreach ($todos as $todo)
                        @include('todos.partials._todo_item')
                    @endforeach
                </div>
                <div id="todos-empty" class="px-6 py-8 text-center text-gray-500 {{ $todos->isNotEmpty() ? 'hidden' : '' }}">Belum ada to-do. Tambahkan kegiatan di atas.</div>
            </div>
        </div>
    </div>

</x-app-layout>
