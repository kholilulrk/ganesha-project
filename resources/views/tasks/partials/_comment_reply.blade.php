<div>
    <div class="flex items-start justify-between">
        <div>
            <span class="font-semibold text-indigo-700 text-xs uppercase">{{ $reply->visitor_name }}</span>
            <p class="text-gray-600 mt-1">{{ $reply->comment }}</p>
        </div>
        <span class="text-xs text-gray-400 shrink-0 ml-3">{{ $reply->created_at->format('d M Y H:i') }}</span>
    </div>
</div>