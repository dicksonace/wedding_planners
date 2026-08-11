<?php

namespace App\Mail;

use App\Models\VendorRequest;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;

class VendorRequestReceivedMail extends Mailable
{
    public function __construct(public VendorRequest $vendorRequest) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'New wedding planning request — '.$this->vendorRequest->weddingPlan->title,
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.vendor-request',
        );
    }
}
