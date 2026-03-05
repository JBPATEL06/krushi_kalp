import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

console.log("Legacy Push Webhook disabled to prevent duplicate notifications.");

serve(async (req) => {
  // Returns immediately without firing a second FCM request. 
  // All pushes are now handled explicitly by send-fcm via Dart codebase.
  return new Response(JSON.stringify({ status: "Disabled", message: "Use send-fcm instead" }), {
    headers: { "Content-Type": "application/json" },
  });
});
