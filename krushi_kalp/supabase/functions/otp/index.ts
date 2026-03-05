// Supabase Edge Function: otp/index.ts
// Handles MSG91 OTP send and verify on behalf of the Flutter app.
// The MSG91 API key is stored as a Supabase secret (MSG91_API_KEY).
// This function is completely isolated from push_notification and send-fcm.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const MSG91_BASE = "https://api.msg91.com/api/v5/otp";
const CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Content-Type": "application/json",
};

serve(async (req) => {
    // Handle CORS preflight
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: CORS_HEADERS });
    }

    try {
        const authkey = Deno.env.get("MSG91_API_KEY");
        const templateId = Deno.env.get("MSG91_TEMPLATE_ID") ?? "";

        if (!authkey) {
            return new Response(
                JSON.stringify({ error: "MSG91_API_KEY secret is not configured." }),
                { status: 500, headers: CORS_HEADERS }
            );
        }

        const body = await req.json() as {
            action: "send" | "resend" | "verify";
            phone: string;
            otp?: string;
        };

        const { action, phone, otp } = body;

        // Validate phone
        const cleanPhone = phone.replace(/\D/g, "");
        if (cleanPhone.length !== 10) {
            return new Response(
                JSON.stringify({ error: "Invalid phone number. Must be 10 digits." }),
                { status: 400, headers: CORS_HEADERS }
            );
        }

        const mobile = `91${cleanPhone}`;

        let url: string;

        if (action === "send") {
            // Send OTP — MSG91 manages rate limiting and 5-min expiry
            url = `${MSG91_BASE}?template_id=${templateId}&authkey=${authkey}&mobile=${mobile}&otp_length=6&otp_expiry=5`;
        } else if (action === "resend") {
            // Resend OTP via text
            url = `${MSG91_BASE}/retry?authkey=${authkey}&mobile=${mobile}&retrytype=text`;
        } else if (action === "verify") {
            // Verify OTP
            if (!otp || otp.trim().length !== 6) {
                return new Response(
                    JSON.stringify({ error: "OTP must be 6 digits." }),
                    { status: 400, headers: CORS_HEADERS }
                );
            }
            url = `${MSG91_BASE}/verify?authkey=${authkey}&mobile=${mobile}&otp=${otp.trim()}`;
        } else {
            return new Response(
                JSON.stringify({ error: "Invalid action. Use: send, resend, verify" }),
                { status: 400, headers: CORS_HEADERS }
            );
        }

        // Call MSG91
        const msg91Response = await fetch(url, { method: "GET" });
        const msg91Body = await msg91Response.json();

        console.log(`OTP [${action}] for ${mobile}:`, msg91Body);

        const success = msg91Body?.type === "success";
        const message = msg91Body?.message ?? "Unknown error from MSG91";

        if (!success) {
            const lowerMsg = message.toLowerCase();
            let clientError = "OTP request failed.";
            if (lowerMsg.includes("rate") || lowerMsg.includes("limit")) {
                clientError = "Too many requests. Please wait before retrying.";
            } else if (lowerMsg.includes("expir")) {
                clientError = "OTP has expired. Please request a new one.";
            } else if (lowerMsg.includes("invalid") || lowerMsg.includes("wrong")) {
                clientError = "Invalid OTP. Please try again.";
            }
            return new Response(
                JSON.stringify({ success: false, error: clientError }),
                { status: 400, headers: CORS_HEADERS }
            );
        }

        return new Response(
            JSON.stringify({ success: true }),
            { status: 200, headers: CORS_HEADERS }
        );

    } catch (e) {
        console.error("OTP Edge Function error:", e);
        return new Response(
            JSON.stringify({ error: "Internal server error." }),
            { status: 500, headers: CORS_HEADERS }
        );
    }
});
