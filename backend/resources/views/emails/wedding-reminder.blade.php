@component('emails.layout', ['title' => 'Wedding reminder', 'subtitle' => 'Reminder'])
    <p>Hi {{ $reminder->weddingPlan->user->name }},</p>
    <p>This is your reminder for <strong>{{ $reminder->weddingPlan->title }}</strong>:</p>
    <p style="font-size:18px;font-weight:bold;color:#006b3f;">{{ $reminder->title }}</p>
    @if($reminder->notes)
        <p>{{ $reminder->notes }}</p>
    @endif
    <p><strong>When:</strong> {{ $reminder->remind_at->format('F j, Y g:i A') }}</p>
    <p><strong>Category:</strong> {{ ucfirst($reminder->category) }}</p>
    <p>Open the WedPlan Ghana app to mark it done or update your schedule.</p>
@endcomponent
