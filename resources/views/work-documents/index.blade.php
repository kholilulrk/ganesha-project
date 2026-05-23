<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">Dokumen Pekerjaan</h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-4xl mx-auto sm:px-6 lg:px-8 space-y-6">
            @if (session('success'))
                <div class="px-4 py-2 bg-green-100 border border-green-200 text-green-700 rounded-md text-sm">
                    {{ session('success') }}
                </div>
            @endif

            <div
                x-data="workDocsComponent()"
                data-base-url="{{ url('work-documents') }}"
                data-csrf="{{ csrf_token() }}"
                data-storage-url="{{ Storage::url('') }}"
                class="space-y-6"
            >
                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6">
                    <div class="mb-6">
                        <label class="block text-sm font-medium text-gray-700 mb-1">Pilih Pekerjaan</label>
                        <select x-model="taskId" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">
                            <option value="">-- Pilih Pekerjaan --</option>
                            @foreach ($tasks as $task)
                            <option value="{{ $task->id }}">{{ $task->title }} ({{ ucfirst($task->task_type) }})</option>
                            @endforeach
                        </select>
                    </div>

                    <template x-if="loading">
                        <div class="text-center py-4 text-sm text-gray-500">Memuat...</div>
                    </template>

                    <template x-if="!loading && taskId">
                        <form method="POST" enctype="multipart/form-data" action="{{ route('work-documents.store') }}" @submit.prevent="saveForm($event)" class="space-y-6">
                            @csrf
                            <input type="hidden" name="task_id" x-model="taskId">

                            <div class="border rounded-lg p-4 space-y-4">
                                <h3 class="font-semibold text-gray-800 text-sm border-b pb-2">Kelengkapan Dokumen</h3>

                                <div>
                                    <x-input-label for="nilai_pekerjaan" value="Nilai Pekerjaan" />
                                    <input id="nilai_pekerjaan" type="text" x-model="nilaiPekerjaanDisplay" @input="updateNilaiPekerjaan($event.target.value)" placeholder="Rp 0" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm" />
                                    <input type="hidden" name="nilai_pekerjaan" x-model="form.nilai_pekerjaan">
                                    <x-input-error :messages="$errors->get('nilai_pekerjaan')" class="mt-2" />
                                </div>

                                <div>
                                    <x-input-label for="catatan" value="Catatan" />
                                    <textarea id="catatan" name="catatan" rows="3" x-model="form.catatan" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm"></textarea>
                                    <x-input-error :messages="$errors->get('catatan')" class="mt-2" />
                                </div>

                                {{-- File uploads --}}
                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                    <div>
                                        <x-input-label for="sik_file" value="SIK (PDF)" />
                                        <input id="sik_file" type="file" name="sik_file" accept=".pdf" class="block w-full text-sm file:mr-3 file:py-1.5 file:px-3 file:rounded-md file:border-0 file:text-xs file:font-semibold file:bg-indigo-50 file:text-indigo-700 hover:file:bg-indigo-100" />
                                        <template x-if="form.sik_file">
                                            <div class="mt-1.5 flex items-center gap-2">
                                                <a x-bind:href="storageUrl + form.sik_file" target="_blank" class="inline-flex items-center px-2 py-1 text-xs font-medium rounded bg-indigo-50 text-indigo-700 hover:bg-indigo-100 transition">Lihat</a>
                                                <a x-bind:href="storageUrl + form.sik_file" download class="inline-flex items-center px-2 py-1 text-xs font-medium rounded bg-green-50 text-green-700 hover:bg-green-100 transition">Download</a>
                                                <button type="button" @click="deleteFile('sik_file')" class="inline-flex items-center px-2 py-1 text-xs font-medium rounded bg-red-50 text-red-700 hover:bg-red-100 transition">Hapus</button>
                                            </div>
                                        </template>
                                        <x-input-error :messages="$errors->get('sik_file')" class="mt-2" />
                                    </div>

                                    <div>
                                        <x-input-label for="sph_file" value="SPH (PDF/Excel)" />
                                        <input id="sph_file" type="file" name="sph_file" accept=".pdf,.xls,.xlsx" class="block w-full text-sm file:mr-3 file:py-1.5 file:px-3 file:rounded-md file:border-0 file:text-xs file:font-semibold file:bg-indigo-50 file:text-indigo-700 hover:file:bg-indigo-100" />
                                        <template x-if="form.sph_file">
                                            <div class="mt-1.5 flex items-center gap-2">
                                                <a x-bind:href="storageUrl + form.sph_file" target="_blank" class="inline-flex items-center px-2 py-1 text-xs font-medium rounded bg-indigo-50 text-indigo-700 hover:bg-indigo-100 transition">Lihat</a>
                                                <a x-bind:href="storageUrl + form.sph_file" download class="inline-flex items-center px-2 py-1 text-xs font-medium rounded bg-green-50 text-green-700 hover:bg-green-100 transition">Download</a>
                                                <button type="button" @click="deleteFile('sph_file')" class="inline-flex items-center px-2 py-1 text-xs font-medium rounded bg-red-50 text-red-700 hover:bg-red-100 transition">Hapus</button>
                                            </div>
                                        </template>
                                        <x-input-error :messages="$errors->get('sph_file')" class="mt-2" />
                                    </div>

                                    <div>
                                        <x-input-label for="spk_file" value="SPK (PDF/Excel/Word)" />
                                        <input id="spk_file" type="file" name="spk_file" accept=".pdf,.xls,.xlsx,.doc,.docx" class="block w-full text-sm file:mr-3 file:py-1.5 file:px-3 file:rounded-md file:border-0 file:text-xs file:font-semibold file:bg-indigo-50 file:text-indigo-700 hover:file:bg-indigo-100" />
                                        <template x-if="form.spk_file">
                                            <div class="mt-1.5 flex items-center gap-2">
                                                <a x-bind:href="storageUrl + form.spk_file" target="_blank" class="inline-flex items-center px-2 py-1 text-xs font-medium rounded bg-indigo-50 text-indigo-700 hover:bg-indigo-100 transition">Lihat</a>
                                                <a x-bind:href="storageUrl + form.spk_file" download class="inline-flex items-center px-2 py-1 text-xs font-medium rounded bg-green-50 text-green-700 hover:bg-green-100 transition">Download</a>
                                                <button type="button" @click="deleteFile('spk_file')" class="inline-flex items-center px-2 py-1 text-xs font-medium rounded bg-red-50 text-red-700 hover:bg-red-100 transition">Hapus</button>
                                            </div>
                                        </template>
                                        <x-input-error :messages="$errors->get('spk_file')" class="mt-2" />
                                    </div>

                                    <div>
                                        <x-input-label for="spektek_file" value="SPEKTEK (PDF/Excel)" />
                                        <input id="spektek_file" type="file" name="spektek_file" accept=".pdf,.xls,.xlsx" class="block w-full text-sm file:mr-3 file:py-1.5 file:px-3 file:rounded-md file:border-0 file:text-xs file:font-semibold file:bg-indigo-50 file:text-indigo-700 hover:file:bg-indigo-100" />
                                        <template x-if="form.spektek_file">
                                            <div class="mt-1.5 flex items-center gap-2">
                                                <a x-bind:href="storageUrl + form.spektek_file" target="_blank" class="inline-flex items-center px-2 py-1 text-xs font-medium rounded bg-indigo-50 text-indigo-700 hover:bg-indigo-100 transition">Lihat</a>
                                                <a x-bind:href="storageUrl + form.spektek_file" download class="inline-flex items-center px-2 py-1 text-xs font-medium rounded bg-green-50 text-green-700 hover:bg-green-100 transition">Download</a>
                                                <button type="button" @click="deleteFile('spektek_file')" class="inline-flex items-center px-2 py-1 text-xs font-medium rounded bg-red-50 text-red-700 hover:bg-red-100 transition">Hapus</button>
                                            </div>
                                        </template>
                                        <x-input-error :messages="$errors->get('spektek_file')" class="mt-2" />
                                    </div>
                                </div>

                                <div>
                                    <span class="block text-sm font-medium text-gray-700 mb-2">Checklist</span>
                                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                        <label class="flex items-center gap-2 text-sm">
                                            <input type="checkbox" name="sik" value="1" x-model="form.sik" class="rounded border-gray-300 text-indigo-600 shadow-sm focus:ring-indigo-500">
                                            Surat Izin Kerja (SIK)
                                        </label>
                                        <label class="flex items-center gap-2 text-sm">
                                            <input type="checkbox" name="sc" value="1" x-model="form.sc" class="rounded border-gray-300 text-indigo-600 shadow-sm focus:ring-indigo-500">
                                            SC
                                        </label>
                                        <label class="flex items-center gap-2 text-sm">
                                            <input type="checkbox" name="verifikasi_i" value="1" x-model="form.verifikasi_i" class="rounded border-gray-300 text-indigo-600 shadow-sm focus:ring-indigo-500">
                                            Verifikasi I
                                        </label>
                                        <label class="flex items-center gap-2 text-sm">
                                            <input type="checkbox" name="verifikasi_ii" value="1" x-model="form.verifikasi_ii" class="rounded border-gray-300 text-indigo-600 shadow-sm focus:ring-indigo-500">
                                            Verifikasi II
                                        </label>
                                        <label class="flex items-center gap-2 text-sm">
                                            <input type="checkbox" name="verifikasi_iii" value="1" x-model="form.verifikasi_iii" class="rounded border-gray-300 text-indigo-600 shadow-sm focus:ring-indigo-500">
                                            Verifikasi III
                                        </label>
                                    </div>
                                </div>

                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                    <div>
                                        <x-input-label for="tds" value="TDS" />
                                        <x-text-input id="tds" type="date" name="tds" x-model="form.tds" class="block w-full" />
                                        <x-input-error :messages="$errors->get('tds')" class="mt-2" />
                                    </div>
                                    <div>
                                        <x-input-label for="tdm" value="TDM" />
                                        <x-text-input id="tdm" type="date" name="tdm" x-model="form.tdm" class="block w-full" />
                                        <x-input-error :messages="$errors->get('tdm')" class="mt-2" />
                                    </div>
                                </div>

                                <div class="flex items-center gap-3 pt-2">
                                    <button type="submit" :disabled="saving" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition disabled:opacity-50">
                                        <span x-show="saving" class="mr-2">
                                            <svg class="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path></svg>
                                        </span>
                                        <span x-text="saving ? 'Menyimpan...' : 'Simpan'"></span>
                                    </button>
                                    <template x-if="exists">
                                        <button type="button" @click="if(confirm('Hapus dokumen ini?')) { document.getElementById('delete-form').submit(); }" class="inline-flex items-center px-4 py-2 bg-red-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-red-500">
                                            Hapus
                                        </button>
                                    </template>
                                </div>
                                <template x-if="successMessage">
                                    <div class="px-3 py-2 bg-green-100 border border-green-200 text-green-700 rounded-md text-sm" x-text="successMessage"></div>
                                </template>
                            </div>
                        </form>

                        <template x-if="exists">
                            <form id="delete-form" method="POST" x-bind:action="baseUrl + '/' + taskId" class="hidden">
                                @csrf @method('DELETE')
                            </form>
                        </template>
                    </template>
                </div>

                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6">
                    <h3 class="font-semibold text-gray-800 mb-4">Riwayat Dokumen Pekerjaan</h3>
                <template x-if="documents.length === 0">
                    <p class="text-sm text-gray-400">Belum ada dokumen pekerjaan.</p>
                </template>
                <template x-if="documents.length > 0">
                    <div class="overflow-x-auto">
                        <table class="min-w-full w-full text-sm whitespace-nowrap">
                            <thead>
                                <tr class="border-b text-left">
                                    <th class="pb-3 pr-3 font-medium">Pekerjaan</th>
                                    <th class="pb-3 pr-3 font-medium">Nilai</th>
                                    <th class="pb-3 pr-3 font-medium">SIK</th>
                                    <th class="pb-3 pr-3 font-medium">SC</th>
                                    <th class="pb-3 pr-3 font-medium">Ver I</th>
                                    <th class="pb-3 pr-3 font-medium">Ver II</th>
                                    <th class="pb-3 pr-3 font-medium">Ver III</th>
                                    <th class="pb-3 pr-3 font-medium">TDS</th>
                                    <th class="pb-3 pr-3 font-medium">TDM</th>
                                </tr>
                            </thead>
                            <tbody>
                                <template x-for="doc in documents" :key="doc.id">
                                    <tr class="border-b last:border-0">
                                        <td class="py-3 pr-3" x-text="doc.task?.title ?? '-'"></td>
                                        <td class="py-3 pr-3"><span x-text="doc.nilai_pekerjaan ? 'Rp ' + new Intl.NumberFormat('id-ID').format(doc.nilai_pekerjaan) : '-'"></span></td>
                                        <td class="py-3 pr-3" x-html="doc.sik ? checkHtml : crossHtml"></td>
                                        <td class="py-3 pr-3" x-html="doc.sc ? checkHtml : crossHtml"></td>
                                        <td class="py-3 pr-3" x-html="doc.verifikasi_i ? checkHtml : crossHtml"></td>
                                        <td class="py-3 pr-3" x-html="doc.verifikasi_ii ? checkHtml : crossHtml"></td>
                                        <td class="py-3 pr-3" x-html="doc.verifikasi_iii ? checkHtml : crossHtml"></td>
                                        <td class="py-3 pr-3" x-text="doc.tds ?? '-'"></td>
                                        <td class="py-3 pr-3" x-text="doc.tdm ?? '-'"></td>
                                    </tr>
                                </template>
                            </tbody>
                        </table>
                    </div>
                </template>
                </div>
            </div>
        </div>
    </div>

    <script>
    function workDocsComponent() {
        return {
            taskId: '',
            loading: false,
            exists: false,
            documents: [],
            checkHtml: '<span class="text-green-600 font-bold">\u2713</span>',
            crossHtml: '<span class="text-red-400">\u2717</span>',
            form: {
                nilai_pekerjaan: '',
                catatan: '',
                sik: false,
                sc: false,
                verifikasi_i: false,
                verifikasi_ii: false,
                verifikasi_iii: false,
                sik_file: '',
                sph_file: '',
                spk_file: '',
                spektek_file: '',
                tds: '',
                tdm: '',
            },
            nilaiPekerjaanDisplay: '',
            saving: false,
            successMessage: '',
            baseUrl: '',
            csrfToken: '',
            storageUrl: '',
            init() {
                var el = this.$el;
                this.baseUrl = el.getAttribute('data-base-url');
                this.csrfToken = el.getAttribute('data-csrf');
                this.storageUrl = el.getAttribute('data-storage-url');
                this.loadDocuments();
                this.$watch('taskId', (id) => {
                    if (!id) return;
                    this.loadData(id);
                });
            },
            formatRupiah(value) {
                if (!value && value !== 0) return '';
                var num = parseFloat(value);
                if (isNaN(num)) return '';
                return 'Rp ' + num.toLocaleString('id-ID');
            },
            updateNilaiPekerjaan(value) {
                var cleaned = value.replace(/[^0-9]/g, '');
                var num = parseInt(cleaned, 10);
                if (isNaN(num)) {
                    this.form.nilai_pekerjaan = '';
                    this.nilaiPekerjaanDisplay = '';
                } else {
                    this.form.nilai_pekerjaan = num;
                    this.nilaiPekerjaanDisplay = this.formatRupiah(num);
                }
            },
            deleteFile(field) {
                if (!confirm('Hapus file ini?')) return;
                var self = this;
                fetch(this.baseUrl + '/' + this.taskId + '/file', {
                    method: 'DELETE',
                    headers: {
                        'Accept': 'application/json',
                        'X-CSRF-TOKEN': this.csrfToken,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ field: field })
                })
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.success) {
                        self.form[field] = '';
                    }
                });
            },
            loadDocuments() {
                fetch(this.baseUrl, {
                    headers: { 'Accept': 'application/json', 'X-CSRF-TOKEN': this.csrfToken }
                })
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.documents) {
                        this.documents = data.documents;
                    }
                }.bind(this));
            },
            saveForm(event) {
                this.saving = true;
                this.successMessage = '';
                var self = this;
                var formData = new FormData(event.target);
                fetch(this.baseUrl, {
                    method: 'POST',
                    headers: {
                        'Accept': 'application/json',
                        'X-CSRF-TOKEN': this.csrfToken
                    },
                    body: formData
                })
                .then(function(r) {
                    if (!r.ok) throw new Error('Gagal menyimpan');
                    return r.json();
                })
                .then(function(data) {
                    self.successMessage = data.message;
                    self.loadData(self.taskId);
                    self.loadDocuments();
                    setTimeout(function() { self.successMessage = ''; }, 3000);
                })
                .catch(function() {
                    self.successMessage = 'Gagal menyimpan dokumen.';
                    setTimeout(function() { self.successMessage = ''; }, 3000);
                })
                .finally(function() {
                    self.saving = false;
                });
            },
            loadData(id) {
                this.loading = true;
                fetch(this.baseUrl + '/' + id + '/document', {
                    headers: {
                        'Accept': 'application/json',
                        'X-CSRF-TOKEN': this.csrfToken
                    }
                })
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.exists && data.document) {
                        this.exists = true;
                        var d = data.document;
                        this.form.nilai_pekerjaan = d.nilai_pekerjaan ?? '';
                        this.nilaiPekerjaanDisplay = this.formatRupiah(d.nilai_pekerjaan);
                        this.form.catatan = d.catatan ?? '';
                        this.form.sik = d.sik;
                        this.form.sc = d.sc;
                        this.form.verifikasi_i = d.verifikasi_i;
                        this.form.verifikasi_ii = d.verifikasi_ii;
                        this.form.verifikasi_iii = d.verifikasi_iii;
                        this.form.sik_file = d.sik_file ?? '';
                        this.form.sph_file = d.sph_file ?? '';
                        this.form.spk_file = d.spk_file ?? '';
                        this.form.spektek_file = d.spektek_file ?? '';
                        this.form.tds = d.tds ?? '';
                        this.form.tdm = d.tdm ?? '';
                    } else {
                        this.exists = false;
                        this.form.nilai_pekerjaan = '';
                        this.nilaiPekerjaanDisplay = '';
                        this.form.catatan = '';
                        this.form.sik = false;
                        this.form.sc = false;
                        this.form.verifikasi_i = false;
                        this.form.verifikasi_ii = false;
                        this.form.verifikasi_iii = false;
                        this.form.sik_file = '';
                        this.form.sph_file = '';
                        this.form.spk_file = '';
                        this.form.spektek_file = '';
                        this.form.tds = '';
                        this.form.tdm = '';
                    }
                    this.loading = false;
                }.bind(this))
                .catch(function() {
                    this.loading = false;
                }.bind(this));
            }
        };
    }
    </script>
</x-app-layout>
