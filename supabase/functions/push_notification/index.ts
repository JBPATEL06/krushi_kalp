// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// JWT creation (for Google Auth)
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";

console.log("Hello from Functions!");

interface NotificationRecord {
  id: any;
  user_id: string | null; // NULL for Broadcast
  title: string;
  message: string;
  type: string; // 'broadcast' | 'personal'
}

serve(async (req) => {
  const { record } = await req.json();
  const notification: NotificationRecord = record;

  console.log("New Notification Event:", notification);

  if (!notification) {
    return new Response("No record found", { status: 400 });
  }

  // 1. Get Google Access Token (for FCM v1 API)
  const serviceAccount = JSON.parse(
    Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "{}",
  );
  
  if (!serviceAccount.project_id) {
     console.error("Missing FIREBASE_SERVICE_ACCOUNT env var");
     return new Response("Configuration Error", { status: 500 });
  }

  const jwt = await new jose.SignJWT({
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(await jose.importPKCS8(serviceAccount.private_key, "RS256"));

  // Exchange JWT for Access Token
  const tokenParams = new URLSearchParams();
  tokenParams.append("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer");
  tokenParams.append("assertion", jwt);

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: tokenParams,
  });
  
  const tokenData = await tokenRes.json();
  const accessToken = tokenData.access_token;


  // 2. Prepare FCM Message
  // https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages/send
  
  let messagePayload: any = {
    notification: {
      title: notification.title,
      body: notification.message,
    },
    data: {
      type: notification.type,
      notification_id: String(notification.id),
    },
    android: {
        priority: "high",
        notification: {
            channel_id: "high_importance_channel" 
        }
    }
  };

  if (notification.type === 'broadcast' || notification.user_id === null) {
      // TARGET: TOPIC
      messagePayload.topic = "all_users";
      console.log("Sending to TOPIC: all_users");
  } else {
      // TARGET: SINGLE USER
      // We need to fetch the User's FCM Token from Supabase
      const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
      const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
      const supabase = createClient(supabaseUrl, supabaseAnonKey);

      const { data: userData, error } = await supabase
        .from('users')
        .select('fcm_token')
        .eq('id', notification.user_id)
        .single();
      
      if (error || !userData?.fcm_token) {
          console.error("User has no FCM Token:", notification.user_id);
          return new Response("User has no token", { status: 200 });
      }

      messagePayload.token = userData.fcm_token;
      console.log("Sending to Token:", userData.fcm_token);
  }

  // 3. Send to FCM
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;
  
  const fcmRes = await fetch(fcmUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({ message: messagePayload }),
  });

  const fcmResult = await fcmRes.json();
  console.log("FCM Result:", fcmResult);

  return new Response(JSON.stringify(fcmResult), {
    headers: { "Content-Type": "application/json" },
  });
});
