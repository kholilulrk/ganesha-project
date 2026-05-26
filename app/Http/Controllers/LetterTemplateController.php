<?php

namespace App\Http\Controllers;

use App\Models\LetterTemplate;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;
use ZipArchive;

class LetterTemplateController extends Controller
{
    public function index(): View
    {
        $templates = LetterTemplate::latest()->paginate(10);
        return view('letter-templates.index', compact('templates'));
    }

    public function create(): View
    {
        return view('letter-templates.create');
    }

    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'file' => ['required', 'file', 'mimes:docx', 'max:10240'],
        ]);

        $path = $request->file('file')->store('letter-templates', 'public');

        $placeholders = $this->detectPlaceholders(Storage::disk('public')->path($path));

        LetterTemplate::create([
            'name' => $request->name,
            'file_path' => $path,
            'placeholders' => $placeholders,
        ]);

        return redirect()->route('letter-templates.index')
            ->with('success', 'Template surat berhasil diupload. ' . count($placeholders) . ' placeholder ditemukan.');
    }

    public function destroy(LetterTemplate $letterTemplate): RedirectResponse
    {
        Storage::disk('public')->delete($letterTemplate->file_path);
        $letterTemplate->delete();

        return redirect()->route('letter-templates.index')
            ->with('success', 'Template surat berhasil dihapus.');
    }

    public function generate(LetterTemplate $letterTemplate): View
    {
        return view('letter-templates.generate', compact('letterTemplate'));
    }

    public function download(Request $request, LetterTemplate $letterTemplate): RedirectResponse|\Symfony\Component\HttpFoundation\BinaryFileResponse
    {
        $request->validate([
            'values' => ['required', 'array'],
        ]);

        $values = $request->input('values');
        $templatePath = Storage::disk('public')->path($letterTemplate->file_path);
        $outputPath = tempnam(sys_get_temp_dir(), 'letter_') . '.docx';

        try {
            copy($templatePath, $outputPath);

            $zip = new ZipArchive;
            if ($zip->open($outputPath) !== true) {
                throw new \Exception('Tidak dapat membuka file DOCX');
            }

            $xml = $zip->getFromName('word/document.xml');
            if ($xml === false) {
                $zip->close();
                throw new \Exception('Tidak dapat membaca konten document.xml');
            }

            $xml = $this->mergeRuns($xml);

            foreach ($values as $placeholder => $value) {
                $xml = str_replace('[' . $placeholder . ']', htmlspecialchars($value ?? '', ENT_XML1, 'UTF-8'), $xml);
            }

            $zip->addFromString('word/document.xml', $xml);
            $zip->close();

            $filename = $letterTemplate->name . '_' . now()->format('Ymd_His') . '.docx';

            return response()->download($outputPath, $filename)->deleteFileAfterSend(true);
        } catch (\Exception $e) {
            if (file_exists($outputPath)) {
                unlink($outputPath);
            }
            return redirect()->back()->with('error', 'Gagal memproses surat: ' . $e->getMessage());
        }
    }

    private function detectPlaceholders(string $filePath): array
    {
        $placeholders = [];
        $zip = new ZipArchive;

        if ($zip->open($filePath) === true) {
            $content = $zip->getFromName('word/document.xml');
            $zip->close();

            if ($content !== false) {
                $content = $this->mergeRuns($content);
                preg_match_all('/\[([^\]]+)\]/', $content, $matches);
                $placeholders = array_values(array_unique($matches[1]));
                sort($placeholders);
            }
        }

        return $placeholders;
    }

    private function mergeRuns(string $xml): string
    {
        do {
            $xml = preg_replace_callback(
                '/(<w:r\b[^>]*>)(.*?<w:t\b[^>]*>)(.*?)(<\/w:t>)\s*(<\/w:r>)\s*(<w:r\b[^>]*>.*?<w:t\b[^>]*>)(.*?)(<\/w:t>\s*<\/w:r>)/s',
                fn($m) => $m[1] . $m[2] . $m[3] . $m[7] . $m[8],
                $xml,
                -1,
                $count
            );
        } while ($count > 0);

        return $xml;
    }
}
