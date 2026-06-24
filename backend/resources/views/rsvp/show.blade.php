<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Wedding Invitation — WedPlan Ghana</title>
    <style>
        body { font-family: system-ui, sans-serif; background: #fff8ee; margin: 0; padding: 24px; color: #1f1f1f; }
        .card { max-width: 520px; margin: 40px auto; background: #fff; border-radius: 16px; padding: 32px; box-shadow: 0 4px 20px rgba(0,0,0,.08); }
        h1 { color: #006b3f; margin-top: 0; }
        .meta { color: #555; margin-bottom: 24px; }
        .status { display: inline-block; padding: 6px 12px; border-radius: 20px; font-size: 14px; background: #f0f0f0; }
        .actions { display: flex; gap: 12px; margin-top: 28px; flex-wrap: wrap; }
        .btn { display: inline-block; padding: 14px 28px; border-radius: 12px; text-decoration: none; font-weight: 600; color: #fff; }
        .accept { background: #006b3f; }
        .decline { background: #ce1126; }
        .footer { text-align: center; margin-top: 32px; font-size: 13px; color: #888; }
    </style>
</head>
<body>
    <div class="card">
        <h1>You're invited!</h1>
        <p>Hello <strong>{{ $guest->name }}</strong>,</p>
        <p class="meta">
            You are invited to <strong>{{ $plan->title }}</strong><br>
            @if($plan->bride_name && $plan->groom_name)
                {{ $plan->bride_name }} & {{ $plan->groom_name }}<br>
            @endif
            @if($plan->wedding_date)
                Date: {{ $plan->wedding_date->format('F j, Y') }}<br>
            @endif
            @if($plan->location)
                Venue: {{ $plan->location }}
            @endif
        </p>
        <p>Current RSVP: <span class="status">{{ ucfirst($guest->rsvp_status) }}</span></p>
        <div class="actions">
            <a class="btn accept" href="{{ $acceptUrl }}">Accept invitation</a>
            <a class="btn decline" href="{{ $declineUrl }}">Decline</a>
        </div>
    </div>
    <p class="footer">WedPlan Ghana — Marriage Planning Service</p>
</body>
</html>
