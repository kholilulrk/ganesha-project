<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Intervention\Image\ImageManager;

class ImageService
{
    private ImageManager $manager;

    const MAX_FILE_SIZE = 1048576;
    const DEFAULT_QUALITY = 75;

    public function __construct()
    {
        $this->manager = ImageManager::gd();
    }

    public function compressAndStore(UploadedFile $file, string $path, string $disk = 'public'): string
    {
        $image = $this->manager->read($file);
        $ext = strtolower($file->getClientOriginalExtension());

        if ($ext === 'gif') {
            return $file->store($path, $disk);
        }

        $quality = self::DEFAULT_QUALITY;
        $outputExt = $ext;
        $encoded = null;

        do {
            $encoded = match ($ext) {
                'png' => $image->toJpeg(quality: $quality),
                'webp' => $image->toWebp(quality: $quality),
                default => $image->toJpeg(quality: $quality),
            };

            if ($ext === 'png') {
                $outputExt = 'jpg';
            }

            $size = strlen((string) $encoded);

            if ($size <= self::MAX_FILE_SIZE) {
                break;
            }

            $quality -= 5;
        } while ($quality >= 10);

        $filename = uniqid('img_', true) . '.' . $outputExt;
        $fullPath = $path . '/' . $filename;

        Storage::disk($disk)->put($fullPath, (string) $encoded);

        return $fullPath;
    }

    public static function isImage(UploadedFile $file): bool
    {
        return in_array($file->getClientMimeType(), [
            'image/jpeg',
            'image/png',
            'image/gif',
            'image/webp',
            'image/bmp',
            'image/avif',
        ]);
    }
}
