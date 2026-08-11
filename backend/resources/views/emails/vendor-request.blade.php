@component('emails.layout', ['title' => 'New vendor request', 'subtitle' => 'Vendor request'])
    <p>Hello {{ $vendorRequest->vendor->business_name }},</p>
    <p><strong>{{ $vendorRequest->couple->name }}</strong> sent a planning request for <strong>{{ $vendorRequest->weddingPlan->title }}</strong>.</p>
    @if($vendorRequest->message)
        <p><strong>Message:</strong><br>{{ $vendorRequest->message }}</p>
    @endif
    @if($vendorRequest->weddingPlan->wedding_date)
        <p><strong>Wedding date:</strong> {{ $vendorRequest->weddingPlan->wedding_date->format('F j, Y') }}</p>
    @endif
    <p>Open the WedPlan Ghana app to accept or decline this request.</p>
@endcomponent
