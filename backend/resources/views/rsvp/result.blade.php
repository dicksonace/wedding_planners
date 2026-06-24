<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RSVP Updated — WedPlan Ghana</title>
    <style>
        body { font-family: system-ui, sans-serif; background: #fff8ee; margin: 0; padding: 24px; color: #1f1f1f; }
        .card { max-width: 480px; margin: 40px auto; background: #fff; border-radius: 16px; padding: 32px; text-align: center; box-shadow: 0 4px 20px rgba(0,0,0,.08); }
        h1 { color: {{ $status === 'confirmed' ? '#006b3f' : '#ce1126' }}; }
        p { color: #555; }
    </style>
</head>
<body>
    <div class="card">
        @if($status === 'confirmed')
            <h1>Thank you!</h1>
            <p>Your RSVP for <strong>{{ $plan->title }}</strong> is confirmed. We look forward to celebrating with you, {{ $guest->name }}.</p>
        @else
            <h1>RSVP updated</h1>
            <p>We've recorded that you cannot attend <strong>{{ $plan->title }}</strong>. Thank you for letting us know, {{ $guest->name }}.</p>
        @endif
    </div>
</body>
</html>
