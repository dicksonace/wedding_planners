<?php

namespace App\Mail;

use App\Models\VendorRequest;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;

class VendorRequestRespondedMail extends Mailable
{
    public function __construct(public VendorRequest $vendorRequest) {}

    public function envelope(): Envelope
    {
        $accepted = $this->vendorRequest->status === 'accepted';

        return new Envelope(
            subject: $accepted
                ? 'A vendor accepted your wedding request'
                : 'A vendor declined your wedding request',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.vendor-response',
        );
    }
}
