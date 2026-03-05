import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { JWT } from "npm:google-auth-library@9";

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
    const privateKey = serviceAccount.private_key;

    const jwtClient = new JWT({
        email: serviceAccount.client_email,
        key: privateKey,
        scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });

    const tokens = await jwtClient.authorize();
    return tokens.access_token;
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

        let tokenError: any = null;
        const accessToken = await getAccessToken(serviceAccount).catch((e) => {
            console.error("Error getting access token:", e);
            tokenError = e;
            return null;
        });

        if (!accessToken) {
            return new Response(JSON.stringify({
                error: "Failed to get Access Token from Google",
                details: tokenError ? tokenError.toString() : "Unknown Error",
                stack: tokenError?.stack || ""
            }), {
                status: 500,
                headers: { "Content-Type": "application/json" },
            });
        }

        // FCM requires all data values to be strings
        const stringifiedData: Record<string, string> = {
            title: String(title),
            body: String(body),
        };
        if (data) {
            for (const key in data) {
                stringifiedData[key] = String(data[key]);
            }
        }

        // Pure Data payload bypasses aggressive OEM background restrictions
        // and is captured by our explicit Dart _firebaseMessagingBackgroundHandler
        const messagePayload: any = {
            message: {
                android: {
                    priority: "high"
                },
                data: stringifiedData,
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
