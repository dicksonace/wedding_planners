<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Email Verified — WedPlan Ghana</title>
    <style>
        body { font-family: system-ui, sans-serif; background: #fff8ee; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; }
        .card { background: #fff; border-radius: 20px; padding: 40px; max-width: 420px; text-align: center; box-shadow: 0 10px 40px rgba(0,0,0,.08); }
        h1 { color: #006B3F; margin-bottom: 8px; }
        p { color: #555; line-height: 1.6; }
        .badge { display: inline-block; background: #E8F5EE; color: #006B3F; padding: 8px 16px; border-radius: 999px; font-weight: 600; margin-top: 16px; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Email verified</h1>
        <p>Your account <strong>{{ $email }}</strong> is confirmed. You can now sign in to WedPlan Ghana on your phone.</p>
        <div class="badge">You may close this page</div>
    </div>
</body>
</html>
