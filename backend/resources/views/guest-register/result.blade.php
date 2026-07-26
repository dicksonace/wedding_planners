<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registration received — WedPlan Ghana</title>
    <style>
        body { font-family: system-ui, sans-serif; background: #fff8ee; margin: 0; padding: 24px; color: #1f1f1f; }
        .card { max-width: 480px; margin: 40px auto; background: #fff; border-radius: 16px; padding: 32px; text-align: center; box-shadow: 0 4px 20px rgba(0,0,0,.08); }
        h1 { color: {{ $status === 'declined' ? '#ce1126' : '#006b3f' }}; }
        p { color: #555; line-height: 1.5; }
    </style>
</head>
<body>
    <div class="card">
        @if($status === 'confirmed')
            <h1>You're on the list!</h1>
            <p>Thank you, <strong>{{ $guest->name }}</strong>. Your attendance for <strong>{{ $plan->title }}</strong> is confirmed.</p>
        @elseif($status === 'declined')
            <h1>We've noted it</h1>
            <p>Thank you for letting us know, <strong>{{ $guest->name }}</strong>. We've recorded that you cannot attend <strong>{{ $plan->title }}</strong>.</p>
        @else
            <h1>Thanks for registering</h1>
            <p>We've saved your details, <strong>{{ $guest->name }}</strong>. The couple may follow up to confirm your RSVP for <strong>{{ $plan->title }}</strong>.</p>
        @endif
    </div>
</body>
</html>
