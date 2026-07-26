<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Guest Registration — {{ $plan->title }}</title>
    <style>
        body { font-family: system-ui, sans-serif; background: #fff8ee; margin: 0; padding: 24px; color: #1f1f1f; }
        .card { max-width: 520px; margin: 40px auto; background: #fff; border-radius: 16px; padding: 32px; box-shadow: 0 4px 20px rgba(0,0,0,.08); }
        h1 { color: #006b3f; margin-top: 0; font-size: 1.6rem; }
        .meta { color: #555; margin-bottom: 24px; line-height: 1.5; }
        label { display: block; font-weight: 600; margin: 14px 0 6px; font-size: 14px; }
        input, select { width: 100%; padding: 12px 14px; border: 1px solid #ddd; border-radius: 10px; font-size: 16px; box-sizing: border-box; }
        .row { display: flex; gap: 12px; flex-wrap: wrap; }
        .row > * { flex: 1; min-width: 140px; }
        .check { display: flex; align-items: center; gap: 8px; margin-top: 16px; }
        .check input { width: auto; }
        .btn { display: block; width: 100%; margin-top: 24px; padding: 14px; border: none; border-radius: 12px; background: #006b3f; color: #fff; font-weight: 700; font-size: 16px; cursor: pointer; }
        .errors { background: #fde8ea; color: #ce1126; padding: 12px; border-radius: 10px; margin-bottom: 16px; font-size: 14px; }
        .footer { text-align: center; margin-top: 32px; font-size: 13px; color: #888; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Confirm your attendance</h1>
        <p class="meta">
            You're registering for <strong>{{ $plan->title }}</strong><br>
            @if($plan->bride_name && $plan->groom_name)
                {{ $plan->bride_name }} &amp; {{ $plan->groom_name }}<br>
            @endif
            @if($plan->wedding_date)
                Date: {{ $plan->wedding_date->format('F j, Y') }}<br>
            @endif
            @if($plan->location)
                Venue: {{ $plan->location }}
            @endif
        </p>

        @if($errors->any())
            <div class="errors">
                <ul style="margin:0;padding-left:18px;">
                    @foreach($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form method="POST" action="{{ url('/guest-register/'.$token) }}">
            @csrf
            <label for="name">Full name *</label>
            <input id="name" name="name" value="{{ old('name') }}" required maxlength="255">

            <div class="row">
                <div>
                    <label for="email">Email</label>
                    <input id="email" type="email" name="email" value="{{ old('email') }}">
                </div>
                <div>
                    <label for="phone">Phone</label>
                    <input id="phone" name="phone" value="{{ old('phone') }}">
                </div>
            </div>

            <label for="side">Which side?</label>
            <select id="side" name="side">
                <option value="both" @selected(old('side', 'both') === 'both')>Both / Family friend</option>
                <option value="bride" @selected(old('side') === 'bride')>Bride's side</option>
                <option value="groom" @selected(old('side') === 'groom')>Groom's side</option>
            </select>

            <label for="attending">Will you attend? *</label>
            <select id="attending" name="attending" required>
                <option value="yes" @selected(old('attending', 'yes') === 'yes')>Yes, I'll be there</option>
                <option value="maybe" @selected(old('attending') === 'maybe')>Maybe / Not sure yet</option>
                <option value="no" @selected(old('attending') === 'no')>Sorry, I can't make it</option>
            </select>

            <label class="check">
                <input type="checkbox" name="plus_one" value="1" @checked(old('plus_one'))>
                I'll bring a plus one
            </label>

            <button class="btn" type="submit">Submit registration</button>
        </form>
    </div>
    <p class="footer">WedPlan Ghana — Marriage Planning Service</p>
</body>
</html>
