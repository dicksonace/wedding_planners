<?php

namespace App\Mail;

use App\Models\Guest;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;

class GuestInvitationMail extends Mailable
{

    public function __construct(
        public Guest $guest,
        public string $rsvpUrl,
        public string $acceptUrl,
        public string $declineUrl,
    ) {}

    public function envelope(): Envelope
    {
        $plan = $this->guest->weddingPlan;

        return new Envelope(
            subject: "Wedding invitation: {$plan->title}",
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.guest-invitation',
        );
    }
}
