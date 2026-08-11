<?php

namespace App\Support;

use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Throwable;

class AppMail
{
    public static function send(?string $to, object $mailable): bool
    {
        $to = trim((string) $to);

        if ($to === '') {
            return false;
        }

        try {
            Mail::to($to)->send($mailable);

            return true;
        } catch (Throwable $e) {
            Log::error('Failed to send email.', [
                'to' => $to,
                'mailable' => $mailable::class,
                'error' => $e->getMessage(),
            ]);

            return false;
        }
    }
}
