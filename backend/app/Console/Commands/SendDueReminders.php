<?php

namespace App\Console\Commands;

use App\Mail\WeddingReminderMail;
use App\Models\WeddingReminder;
use App\Support\AppMail;
use Illuminate\Console\Command;

class SendDueReminders extends Command
{
    protected $signature = 'reminders:send';

    protected $description = 'Email couples when a wedding reminder is due';

    public function handle(): int
    {
        $due = WeddingReminder::query()
            ->with(['weddingPlan.user'])
            ->where('is_done', false)
            ->whereNull('email_sent_at')
            ->where('remind_at', '<=', now())
            ->get();

        $sent = 0;

        foreach ($due as $reminder) {
            $email = $reminder->weddingPlan?->user?->email;

            if (! $email) {
                continue;
            }

            if (AppMail::send($email, new WeddingReminderMail($reminder))) {
                $reminder->update(['email_sent_at' => now()]);
                $sent++;
            }
        }

        $this->info("Sent {$sent} reminder email(s).");

        return self::SUCCESS;
    }
}
