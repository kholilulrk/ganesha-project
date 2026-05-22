<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('Buat Pengumuman') }}</h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-3xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white shadow-sm sm:rounded-lg p-6">
                <form x-data="{ loading: false }" method="POST" action="{{ route('announcements.store') }}" class="space-y-6">
                    @csrf

                    <div>
                        <x-input-label for="title" :value="__('Judul')" />
                        <x-text-input id="title" class="block mt-1 w-full" type="text" name="title" :value="old('title')" required />
                        <x-input-error :messages="$errors->get('title')" class="mt-2" />
                    </div>

                    <div>
                        <x-input-label for="content" :value="__('Isi Pengumuman')" />
                        <textarea id="content" name="content" rows="6" class="block mt-1 w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" required>{{ old('content') }}</textarea>
                        <x-input-error :messages="$errors->get('content')" class="mt-2" />
                    </div>

                    <div>
                        <x-input-label for="target_type" :value="__('Target')" />
                        <select id="target_type" name="target_type" class="block mt-1 w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" required
                            x-on:change="document.getElementById('target_specific').style.display = $el.value === 'specific' ? 'block' : 'none'">
                            <option value="all_users" {{ old('target_type') == 'all_users' ? 'selected' : '' }}>Semua User</option>
                            <option value="specific" {{ old('target_type') == 'specific' ? 'selected' : '' }}>User / Role Tertentu</option>
                        </select>
                        <x-input-error :messages="$errors->get('target_type')" class="mt-2" />
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <x-input-label for="scheduled_date" :value="__('Jadwal Mulai')" />
                            <x-text-input id="scheduled_date" class="block mt-1 w-full" type="date" name="scheduled_date" :value="old('scheduled_date')" />
                            <x-input-error :messages="$errors->get('scheduled_date')" class="mt-2" />
                        </div>
                        <div>
                            <x-input-label for="scheduled_time" :value="__('Jam Mulai')" />
                            <x-text-input id="scheduled_time" class="block mt-1 w-full" type="time" name="scheduled_time" :value="old('scheduled_time', '08:00')" />
                            <x-input-error :messages="$errors->get('scheduled_time')" class="mt-2" />
                        </div>
                    </div>
                    <p class="text-xs text-gray-400 -mt-4">Kosongkan tanggal jika ingin langsung tampil.</p>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <x-input-label for="expired_date" :value="__('Jadwal Berakhir')" />
                            <x-text-input id="expired_date" class="block mt-1 w-full" type="date" name="expired_date" :value="old('expired_date')" />
                            <x-input-error :messages="$errors->get('expired_date')" class="mt-2" />
                        </div>
                        <div>
                            <x-input-label for="expired_time" :value="__('Jam Berakhir')" />
                            <x-text-input id="expired_time" class="block mt-1 w-full" type="time" name="expired_time" :value="old('expired_time', '17:00')" />
                            <x-input-error :messages="$errors->get('expired_time')" class="mt-2" />
                        </div>
                    </div>
                    <p class="text-xs text-gray-400 -mt-4">Kosongkan tanggal jika tidak ada batas waktu. Pengumuman akan otomatis terhapus setelah jadwal berakhir.</p>

                    <div id="target_specific" style="display: {{ old('target_type') == 'specific' ? 'block' : 'none' }}">
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <x-input-label for="target_users" :value="__('Pilih User')" />
                                <select id="target_users" name="target_users[]" multiple class="block mt-1 w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" size="6">
                                    @foreach ($users as $u)
                                        <option value="{{ $u->id }}" {{ in_array($u->id, old('target_users', [])) ? 'selected' : '' }}>
                                            {{ $u->name }} ({{ $u->getRoleNames()->implode(', ') }})
                                        </option>
                                    @endforeach
                                </select>
                                <p class="text-xs text-gray-400 mt-1">Tahan Ctrl untuk memilih lebih dari satu.</p>
                                <x-input-error :messages="$errors->get('target_users')" class="mt-2" />
                            </div>

                            <div>
                                <x-input-label for="target_roles" :value="__('Pilih Role')" />
                                <select id="target_roles" name="target_roles[]" multiple class="block mt-1 w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" size="6">
                                    @foreach ($roles as $r)
                                        <option value="{{ $r->id }}" {{ in_array($r->id, old('target_roles', [])) ? 'selected' : '' }}>
                                            {{ $r->name }}
                                        </option>
                                    @endforeach
                                </select>
                                <p class="text-xs text-gray-400 mt-1">Tahan Ctrl untuk memilih lebih dari satu.</p>
                                <x-input-error :messages="$errors->get('target_roles')" class="mt-2" />
                            </div>
                        </div>
                    </div>

                    <div class="flex items-center gap-4">
                        <x-primary-button>{{ __('Buat') }}</x-primary-button>
                        <a href="{{ route('announcements.index') }}" class="text-sm text-gray-600 hover:text-gray-900">Batal</a>
                    </div>
                </form>
            </div>
        </div>
    </div>
</x-app-layout>
