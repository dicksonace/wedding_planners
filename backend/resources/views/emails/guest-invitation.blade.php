<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .wrap { max-width: 560px; margin: 0 auto; padding: 24px; }
        .header { background: #006b3f; color: #fff; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
        .body { background: #fff8ee; padding: 24px; border: 1px solid #e8e8e8; }
        .btn { display: inline-block; margin: 8px 4px; padding: 12px 24px; text-decoration: none; border-radius: 8px; font-weight: bold; color: #fff; }
        .accept { background: #006b3f; }
        .decline { background: #ce1126; }
        .footer { font-size: 12px; color: #888; text-align: center; margin-top: 16px; }
    </style>
</head>
<body>
    <div class="wrap">
        <div class="header">
            <h2 style="margin:0;">WedPlan Ghana</h2>
            <p style="margin:8px 0 0;">Wedding Invitation</p>
        </div>
        <div class="body">
            <p>Dear {{ $guest->name }},</p>
            <p>You are warmly invited to celebrate with us at <strong>{{ $guest->weddingPlan->title }}</strong>.</p>
            @if($guest->weddingPlan->bride_name && $guest->weddingPlan->groom_name)
                <p><strong>{{ $guest->weddingPlan->bride_name }}</strong> & <strong>{{ $guest->weddingPlan->groom_name }}</strong></p>
            @endif
            @if($guest->weddingPlan->wedding_date)
                <p><strong>Date:</strong> {{ $guest->weddingPlan->wedding_date->format('F j, Y') }}</p>
            @endif
            @if($guest->weddingPlan->location)
                <p><strong>Venue:</strong> {{ $guest->weddingPlan->location }}</p>
            @endif
            <p>Please let us know if you will attend:</p>
            <p>
                <a class="btn accept" href="{{ $acceptUrl }}">Accept invitation</a>
                <a class="btn decline" href="{{ $declineUrl }}">Decline</a>
            </p>
            <p>Or view your invitation: <a href="{{ $rsvpUrl }}">{{ $rsvpUrl }}</a></p>
        </div>
        <p class="footer">Sent via WedPlan Ghana Marriage Planning System</p>
    </div>
</body>
</html>
