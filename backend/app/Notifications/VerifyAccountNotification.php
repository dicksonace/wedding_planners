<?php

namespace App\Notifications;

use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Notifications\Messages\MailMessage;

class VerifyAccountNotification extends VerifyEmail
{
    public function toMail(object $notifiable): MailMessage
    {
        $url = $this->verificationUrl($notifiable);

        return (new MailMessage)
            ->subject('Confirm your WedPlan Ghana account')
            ->view('emails.verify-account', [
                'user' => $notifiable,
                'url' => $url,
            ]);
    }
}
