<div class="bg-gray-50 rounded-md px-4 py-3 text-sm">
    <div class="flex items-start justify-between">
        <div>
            <span class="font-semibold text-gray-800">{{ $comment->visitor_name }}</span>
            <p class="text-gray-600 mt-1">{{ $comment->comment }}</p>
        </div>
        <span class="text-xs text-gray-400 shrink-0 ml-3">{{ $comment->created_at->format('d M Y H:i') }}</span>
    </div>
    @if ($comment->relationLoaded('replies') && $comment->replies->isNotEmpty())
        <div class="mt-3 ml-6 space-y-2 border-l-2 border-gray-200 pl-4">
            @foreach ($comment->replies as $reply)
                <div>
                    <div class="flex items-start justify-between">
                        <div>
                            <span class="font-semibold text-indigo-700 text-xs uppercase">{{ $reply->visitor_name }}</span>
                            <p class="text-gray-600 mt-1">{{ $reply->comment }}</p>
                        </div>
                        <span class="text-xs text-gray-400 shrink-0 ml-3">{{ $reply->created_at->format('d M Y H:i') }}</span>
                    </div>
                </div>
            @endforeach
        </div>
    @endif
</div>