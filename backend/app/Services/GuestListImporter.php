<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;
use ZipArchive;

class GuestListImporter
{
    /**
     * @return array{rows: list<list<string>>, error: ?string}
     */
    public function extractRows(UploadedFile $file): array
    {
        $extension = strtolower($file->getClientOriginalExtension());
        $path = $file->getRealPath();

        if ($path === false) {
            return ['rows' => [], 'error' => 'Could not read uploaded file.'];
        }

        return match ($extension) {
            'csv', 'txt' => $this->fromCsv($path),
            'xlsx' => $this->fromXlsx($path),
            'xls' => ['rows' => [], 'error' => 'Old Excel .xls is not supported. Please save as .xlsx (Excel Workbook) and upload again.'],
            'docx' => $this->fromDocx($path),
            'doc' => ['rows' => [], 'error' => 'Old Word .doc is not supported. Please save as .docx and upload again.'],
            default => ['rows' => [], 'error' => 'Unsupported file type. Upload CSV, Excel (.xlsx), or Word (.docx).'],
        };
    }

    /**
     * @param  list<list<string>>  $rows
     * @return array{created: int, skipped: int, errors: list<string>, guests: list<array<string, mixed>>}
     */
    public function mapGuests(array $rows): array
    {
        $created = 0;
        $skipped = 0;
        $errors = [];
        $guests = [];
        $header = null;

        foreach ($rows as $rowNum => $cells) {
            $cells = array_map(fn ($c) => trim((string) $c), $cells);
            if ($this->rowIsEmpty($cells)) {
                continue;
            }

            $line = $rowNum + 1;

            if ($header === null) {
                $normalized = array_map(fn ($h) => Str::of($h)->lower()->replace(' ', '_')->toString(), $cells);
                $joined = implode(',', $normalized);

                if (! str_contains($joined, 'name') && ! str_contains($joined, 'email') && ! str_contains($joined, 'phone')) {
                    $mapped = $this->mapImportRow(['name', 'email', 'phone', 'side'], $cells);
                    if ($mapped) {
                        $guests[] = $mapped;
                        $created++;
                    } else {
                        $skipped++;
                        $errors[] = "Row {$line}: missing name";
                    }
                    $header = ['name', 'email', 'phone', 'side'];
                } else {
                    $header = $normalized;
                }

                continue;
            }

            $mapped = $this->mapImportRow($header, $cells);
            if (! $mapped) {
                $skipped++;
                $errors[] = "Row {$line}: missing name";
                continue;
            }

            $guests[] = $mapped;
            $created++;
        }

        return [
            'created' => $created,
            'skipped' => $skipped,
            'errors' => array_slice($errors, 0, 10),
            'guests' => $guests,
        ];
    }

    /**
     * @return array{rows: list<list<string>>, error: ?string}
     */
    private function fromCsv(string $path): array
    {
        $handle = fopen($path, 'r');
        if ($handle === false) {
            return ['rows' => [], 'error' => 'Could not read CSV file.'];
        }

        $rows = [];
        while (($row = fgetcsv($handle)) !== false) {
            if ($row === [null]) {
                continue;
            }
            $rows[] = array_map(fn ($c) => (string) $c, $row);
        }
        fclose($handle);

        return ['rows' => $rows, 'error' => null];
    }

    /**
     * @return array{rows: list<list<string>>, error: ?string}
     */
    private function fromXlsx(string $path): array
    {
        $zip = new ZipArchive;
        if ($zip->open($path) !== true) {
            return ['rows' => [], 'error' => 'Could not open Excel file. Make sure it is a valid .xlsx workbook.'];
        }

        $sharedStrings = [];
        $sharedXml = $zip->getFromName('xl/sharedStrings.xml');
        if ($sharedXml !== false) {
            $sharedXml = preg_replace('/(<\/?)(\w+):([^>]*>)/', '$1$3', $sharedXml) ?? $sharedXml;
            $shared = @simplexml_load_string($sharedXml);
            if ($shared !== false) {
                foreach ($shared->si as $si) {
                    if (isset($si->t)) {
                        $sharedStrings[] = (string) $si->t;
                    } else {
                        $text = '';
                        foreach ($si->r as $run) {
                            $text .= (string) ($run->t ?? '');
                        }
                        $sharedStrings[] = $text;
                    }
                }
            }
        }

        $sheetXml = $zip->getFromName('xl/worksheets/sheet1.xml');
        if ($sheetXml === false) {
            // Try first worksheet path from workbook
            foreach (['xl/worksheets/sheet1.xml', 'xl/worksheets/sheet.xml'] as $candidate) {
                $sheetXml = $zip->getFromName($candidate);
                if ($sheetXml !== false) {
                    break;
                }
            }
        }
        $zip->close();

        if ($sheetXml === false) {
            return ['rows' => [], 'error' => 'Excel sheet not found in the workbook.'];
        }

        // Strip OOXML namespaces so SimpleXML can read cells without prefixes.
        $sheetXml = preg_replace('/(<\/?)(\w+):([^>]*>)/', '$1$3', $sheetXml) ?? $sheetXml;
        $sheet = @simplexml_load_string($sheetXml);
        if ($sheet === false) {
            return ['rows' => [], 'error' => 'Could not parse Excel sheet.'];
        }

        $rows = [];

        foreach ($sheet->sheetData->row as $row) {
            $cells = [];
            $maxIndex = -1;
            $indexed = [];

            foreach ($row->c as $cell) {
                $ref = (string) ($cell['r'] ?? '');
                $colIndex = $this->columnIndexFromRef($ref);
                $type = (string) ($cell['t'] ?? '');
                $raw = (string) ($cell->v ?? '');

                if ($type === 's') {
                    $value = $sharedStrings[(int) $raw] ?? '';
                } elseif ($type === 'inlineStr') {
                    $value = (string) ($cell->is->t ?? '');
                } else {
                    $value = $raw;
                }

                $indexed[$colIndex] = $value;
                $maxIndex = max($maxIndex, $colIndex);
            }

            for ($i = 0; $i <= $maxIndex; $i++) {
                $cells[] = $indexed[$i] ?? '';
            }

            if (! $this->rowIsEmpty($cells)) {
                $rows[] = $cells;
            }
        }

        if ($rows === []) {
            return ['rows' => [], 'error' => 'No guest rows found in the Excel file.'];
        }

        return ['rows' => $rows, 'error' => null];
    }

    /**
     * @return array{rows: list<list<string>>, error: ?string}
     */
    private function fromDocx(string $path): array
    {
        $zip = new ZipArchive;
        if ($zip->open($path) !== true) {
            return ['rows' => [], 'error' => 'Could not open Word file. Make sure it is a valid .docx document.'];
        }

        $documentXml = $zip->getFromName('word/document.xml');
        $zip->close();

        if ($documentXml === false) {
            return ['rows' => [], 'error' => 'Word document content not found.'];
        }

        $dom = new \DOMDocument;
        $previous = libxml_use_internal_errors(true);
        $loaded = $dom->loadXML($documentXml);
        libxml_clear_errors();
        libxml_use_internal_errors($previous);

        if (! $loaded) {
            return ['rows' => [], 'error' => 'Could not parse Word document.'];
        }

        $xpath = new \DOMXPath($dom);
        $xpath->registerNamespace('w', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main');

        $rows = [];
        $tables = $xpath->query('//w:tbl');
        if ($tables !== false && $tables->length > 0) {
            foreach ($tables as $table) {
                $trs = $xpath->query('.//w:tr', $table);
                if ($trs === false) {
                    continue;
                }
                foreach ($trs as $tr) {
                    $cells = [];
                    $tcs = $xpath->query('./w:tc', $tr);
                    if ($tcs === false) {
                        continue;
                    }
                    foreach ($tcs as $tc) {
                        $texts = $xpath->query('.//w:t', $tc);
                        $value = '';
                        if ($texts !== false) {
                            foreach ($texts as $t) {
                                $value .= $t->textContent;
                            }
                        }
                        $cells[] = trim($value);
                    }
                    if (! $this->rowIsEmpty($cells)) {
                        $rows[] = $cells;
                    }
                }
            }
        }

        if ($rows === []) {
            // Fallback: one guest name per paragraph / line
            $paragraphs = $xpath->query('//w:p');
            if ($paragraphs !== false) {
                foreach ($paragraphs as $p) {
                    $texts = $xpath->query('.//w:t', $p);
                    $value = '';
                    if ($texts !== false) {
                        foreach ($texts as $t) {
                            $value .= $t->textContent;
                        }
                    }
                    $value = trim($value);
                    if ($value !== '') {
                        // Support "Name, email, phone" lines
                        if (str_contains($value, ',')) {
                            $rows[] = array_map('trim', explode(',', $value));
                        } else {
                            $rows[] = [$value];
                        }
                    }
                }
            }
        }

        if ($rows === []) {
            return ['rows' => [], 'error' => 'No guest names found in the Word file. Use a table or one name per line.'];
        }

        return ['rows' => $rows, 'error' => null];
    }

    /**
     * @param  list<string>  $header
     * @param  list<string>  $cells
     * @return array<string, mixed>|null
     */
    private function mapImportRow(array $header, array $cells): ?array
    {
        $assoc = [];
        foreach ($header as $i => $key) {
            $assoc[$key] = $cells[$i] ?? '';
        }

        $name = $assoc['name'] ?? $assoc['full_name'] ?? $assoc['guest_name'] ?? ($cells[0] ?? '');
        $name = trim((string) $name);
        if ($name === '' || in_array(Str::lower($name), ['name', 'full_name', 'guest_name', 'guest'], true)) {
            return null;
        }

        $side = strtolower((string) ($assoc['side'] ?? 'both'));
        if (! in_array($side, ['bride', 'groom', 'both'], true)) {
            $side = 'both';
        }

        $rsvp = strtolower((string) ($assoc['rsvp'] ?? $assoc['rsvp_status'] ?? 'pending'));
        if (! in_array($rsvp, ['pending', 'confirmed', 'declined'], true)) {
            $rsvp = 'pending';
        }

        $email = trim((string) ($assoc['email'] ?? ''));
        $phone = trim((string) ($assoc['phone'] ?? $assoc['mobile'] ?? ''));

        return [
            'name' => $name,
            'email' => $email !== '' ? $email : null,
            'phone' => $phone !== '' ? $phone : null,
            'side' => $side,
            'rsvp_status' => $rsvp,
            'plus_one' => in_array(strtolower((string) ($assoc['plus_one'] ?? '')), ['1', 'yes', 'true', 'y'], true),
        ];
    }

    /**
     * @param  list<string>  $cells
     */
    private function rowIsEmpty(array $cells): bool
    {
        foreach ($cells as $cell) {
            if (trim((string) $cell) !== '') {
                return false;
            }
        }

        return true;
    }

    private function columnIndexFromRef(string $ref): int
    {
        if ($ref === '') {
            return 0;
        }

        preg_match('/^([A-Z]+)/i', $ref, $matches);
        $letters = strtoupper($matches[1] ?? 'A');
        $index = 0;
        for ($i = 0; $i < strlen($letters); $i++) {
            $index = ($index * 26) + (ord($letters[$i]) - 64);
        }

        return max(0, $index - 1);
    }
}
