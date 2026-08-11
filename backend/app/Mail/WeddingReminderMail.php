<?php

namespace App\Mail;

use App\Models\WeddingReminder;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;

class WeddingReminderMail extends Mailable
{
    public function __construct(public WeddingReminder $reminder) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Wedding reminder: '.$this->reminder->title,
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.wedding-reminder',
        );
    }
}
