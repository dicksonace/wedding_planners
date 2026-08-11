@php
    $accepted = $vendorRequest->status === 'accepted';
    $vendorName = $vendorRequest->vendor->business_name;
@endphp
@component('emails.layout', ['title' => 'Vendor response', 'subtitle' => $accepted ? 'Request accepted' : 'Request declined'])
    <p>Hi {{ $vendorRequest->couple->name }},</p>
    <p>
        <strong>{{ $vendorName }}</strong>
        {{ $accepted ? 'accepted' : 'declined' }}
        your request for <strong>{{ $vendorRequest->weddingPlan->title }}</strong>.
    </p>
    @if($vendorRequest->response_message)
        <p><strong>Vendor message:</strong><br>{{ $vendorRequest->response_message }}</p>
    @endif
    @if($accepted && $vendorRequest->quoted_amount)
        <p><strong>Quoted amount:</strong> GHS {{ number_format((float) $vendorRequest->quoted_amount, 2) }}</p>
        <p>This vendor has been added to your wedding budget.</p>
    @endif
    <p>Open the WedPlan Ghana app to continue planning.</p>
@endcomponent
