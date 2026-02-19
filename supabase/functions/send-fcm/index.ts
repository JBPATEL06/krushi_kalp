import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { create } from "https://deno.land/x/djwt@v2.8/mod.ts";

console.log("Hello from Functions!");

interface ServiceAccount {
    type: string;
    project_id: string;
    private_key_id: string;
    private_key: string;
    client_email: string;
    client_id: string;
    auth_uri: string;
    token_uri: string;
    auth_provider_x509_cert_url: string;
    client_x509_cert_url: string;
}

const getAccessToken = async (serviceAccount: ServiceAccount) => {
    const now = Math.floor(Date.now() / 1000);

    // FIX: Ensure private key has correct line breaks
    const privateKey = serviceAccount.private_key.replace(/\\n/g, '\n');

    const claim = {
        iss: serviceAccount.client_email,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
        aud: "https://oauth2.googleapis.com/token",
        exp: now + 3600,
        iat: now,
    };

    const jwt = await create(
        { alg: "RS256", typ: "JWT" },
        claim,
        {
            key: privateKey,
        }
    );

    const res = await fetch("https://oauth2.googleapis.com/token", {
        method: "POST",
        headers: {
            "Content-Type": "application/x-www-form-urlencoded",
        },
        body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    });

    const data = await res.json();
    return data.access_token;
};

serve(async (req) => {
    // Handle CORS
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type', } })
    }

    try {
        const { title, body, topic, data, token } = await req.json();

        // Retrieve FIREBASE_SERVICE_ACCOUNT from environment secrets
        const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
        if (!serviceAccountJson) {
            console.error("Firebase Service Account Missing");
            return new Response(JSON.stringify({ error: "Firebase Service Account Missing" }), {
                status: 500,
                headers: { "Content-Type": "application/json" },
            });
        }

        let serviceAccount: ServiceAccount;
        try {
            serviceAccount = JSON.parse(serviceAccountJson);
            // DEBUG LOGGING
            console.log(`Service Account Parsed. Project: ${serviceAccount.project_id}, Email: ${serviceAccount.client_email}`);
        } catch (e) {
            console.error("Error parsing service account JSON:", e);
            return new Response(JSON.stringify({ error: "Invalid Service Account JSON format" }), { status: 500 });
        }

        const accessToken = await getAccessToken(serviceAccount).catch((e) => {
            console.error("Error getting access token:", e);
            return null;
        });

        if (!accessToken) {
            return new Response(JSON.stringify({ error: "Failed to get Access Token from Google" }), {
                status: 500,
                headers: { "Content-Type": "application/json" },
            });
        }

        const messagePayload: any = {
            message: {
                notification: {
                    title: title,
                    body: body,
                },
                android: {
                    priority: "high",
                    notification: { channel_id: "high_importance_channel" },
                },
                data: data || {}, // Optional data payload
            },
        };

        if (topic) {
            messagePayload.message.topic = topic;
        } else if (token) {
            messagePayload.message.token = token;
        } else {
            return new Response(JSON.stringify({ error: "Missing token or topic" }), {
                status: 400,
                headers: { "Content-Type": "application/json" },
            });
        }

        const res = await fetch(
            `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${accessToken}`,
                },
                body: JSON.stringify(messagePayload),
            }
        );

        const responseData = await res.json();
        console.log("FCM Response:", responseData);

        return new Response(JSON.stringify(responseData), {
            headers: { "Content-Type": "application/json" },
        });
    } catch (err) {
        console.error(err);
        return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: { "Content-Type": "application/json" } });
    }
});
