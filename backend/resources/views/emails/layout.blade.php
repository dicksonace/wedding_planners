<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'WedPlan Ghana' }}</title>
</head>
<body style="margin:0;padding:0;background:#f4f1ea;font-family:Arial,Helvetica,sans-serif;color:#333;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f4f1ea;padding:24px 12px;">
        <tr>
            <td align="center">
                <table role="presentation" width="560" cellspacing="0" cellpadding="0" style="max-width:560px;width:100%;">
                    <tr>
                        <td style="background:#006b3f;color:#fff;padding:22px 24px;text-align:center;border-radius:10px 10px 0 0;">
                            <h1 style="margin:0;font-size:22px;">WedPlan Ghana</h1>
                            <p style="margin:8px 0 0;font-size:14px;">{{ $subtitle ?? 'Marriage Planning' }}</p>
                        </td>
                    </tr>
                    <tr>
                        <td style="background:#fff8ee;padding:24px;border:1px solid #e8e0d2;border-top:0;">
                            {{ $slot }}
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:16px;text-align:center;font-size:12px;color:#888;">
                            Sent from support@marriageplan.site · WedPlan Ghana
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
