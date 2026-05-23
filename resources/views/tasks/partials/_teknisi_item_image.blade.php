<div id="teknisi-img-{{ $img->id }}" class="relative group">
    <button @click.prevent="previewUrl = '{{ $img->imageUrl() }}'" class="block w-full aspect-square rounded-md overflow-hidden border border-gray-200 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-400">
        <img src="{{ $img->imageUrl() }}" alt="Gambar" class="w-full h-full object-cover">
    </button>
    <button @click.prevent="deleteImage({{ $img->id }})" class="absolute -top-1.5 -right-1.5 w-5 h-5 bg-red-500 text-white rounded-full flex items-center justify-center text-xs md:opacity-0 md:group-hover:opacity-100 transition-opacity hover:bg-red-600 opacity-100">
        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
    </button>
</div>
