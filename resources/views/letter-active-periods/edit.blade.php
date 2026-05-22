<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">Edit Surat</h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-3xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white shadow-sm sm:rounded-lg p-6">
                <form x-data="{
                    jenisSurat: '{{ old('jenis_surat', $letterActivePeriod->jenis_surat) }}',
                    startAktif: '{{ old('start_aktif', $letterActivePeriod->start_aktif->format('Y-m-d')) }}',
                    get masaAktifBerakhir() {
                        if (!this.startAktif || !this.jenisSurat) return '';
                        const start = new Date(this.startAktif);
                        const bulan = this.jenisSurat === 'SIK' ? 1 : 3;
                        start.setMonth(start.getMonth() + bulan);
                        return start.toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' });
                    }
                }" method="POST" action="{{ route('letter-active-periods.update', $letterActivePeriod) }}" class="space-y-6">
                    @csrf @method('PATCH')

                    <div>
                        <x-input-label for="nama_surat" value="Nama Surat" />
                        <x-text-input id="nama_surat" class="block mt-1 w-full" type="text" name="nama_surat" :value="old('nama_surat', $letterActivePeriod->nama_surat)" required />
                        <x-input-error :messages="$errors->get('nama_surat')" class="mt-2" />
                    </div>

                    <div>
                        <x-input-label for="start_aktif" value="Start Aktif" />
                        <input id="start_aktif" type="date" name="start_aktif" value="{{ old('start_aktif', $letterActivePeriod->start_aktif->format('Y-m-d')) }}" x-model="startAktif"
                            class="block mt-1 w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" required>
                        <x-input-error :messages="$errors->get('start_aktif')" class="mt-2" />
                    </div>

                    <div>
                        <x-input-label for="jenis_surat" value="Jenis Surat" />
                        <select id="jenis_surat" name="jenis_surat" x-model="jenisSurat"
                            class="block mt-1 w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" required>
                            <option value="" disabled>Pilih jenis surat</option>
                            <option value="SIK" {{ old('jenis_surat', $letterActivePeriod->jenis_surat) === 'SIK' ? 'selected' : '' }}>SIK</option>
                            <option value="SC" {{ old('jenis_surat', $letterActivePeriod->jenis_surat) === 'SC' ? 'selected' : '' }}>SC</option>
                        </select>
                        <x-input-error :messages="$errors->get('jenis_surat')" class="mt-2" />
                    </div>

                    <div class="p-4 bg-gray-50 rounded-md">
                        <p class="text-sm text-gray-600">
                            <span class="font-medium">Masa Aktif Berakhir:</span>
                            <span class="ml-1 font-semibold" x-text="masaAktifBerakhir || '—'"></span>
                        </p>
                        <p class="text-xs text-gray-400 mt-1" x-show="jenisSurat === 'SIK'">SIK berlaku 1 bulan sejak start aktif.</p>
                        <p class="text-xs text-gray-400 mt-1" x-show="jenisSurat === 'SC'">SC berlaku 3 bulan sejak start aktif.</p>
                    </div>

                    <div class="flex flex-wrap items-center gap-4 pt-2">
                        <button type="submit" class="inline-flex items-center px-5 py-2.5 bg-indigo-600 border border-transparent rounded-lg font-semibold text-sm text-white shadow-sm hover:bg-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:ring-offset-2 transition">
                            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"/></svg>
                            Perbarui
                        </button>
                        <a href="{{ route('letter-active-periods.index') }}" class="inline-flex items-center px-4 py-2.5 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-gray-300 focus:ring-offset-2 transition">Batal</a>
                    </div>
                </form>
            </div>
        </div>
    </div>
</x-app-layout>
