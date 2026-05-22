<div class="relative group">
    <button @click.prevent="previewUrl = '{{ $img->imageUrl() }}'" class="block w-full aspect-square rounded-md overflow-hidden border border-gray-200 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-400">
        <img src="{{ $img->imageUrl() }}" alt="Gambar" class="w-full h-full object-cover">
    </button>
</div>
