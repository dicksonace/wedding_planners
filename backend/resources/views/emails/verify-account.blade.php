@component('emails.layout', ['title' => 'Confirm your account', 'subtitle' => 'Email confirmation'])
    <p>Hi {{ $user->name }},</p>
    <p>Thank you for registering on WedPlan Ghana. Please confirm your email so you can sign in and start planning.</p>
    <p style="text-align:center;margin:28px 0;">
        <a href="{{ $url }}" style="display:inline-block;background:#006b3f;color:#fff;text-decoration:none;padding:12px 24px;border-radius:8px;font-weight:bold;">
            Confirm email
        </a>
    </p>
    <p>If the button does not work, open this link:</p>
    <p style="word-break:break-all;font-size:13px;"><a href="{{ $url }}">{{ $url }}</a></p>
    <p>This link expires in 60 minutes. If you did not create an account, you can ignore this email.</p>
@endcomponent
