// ==============================================================================
// razorpay-webhook / index.ts
// Supabase Edge Function: Razorpay Webhook Event Listener (Redundant Fail-Safe)
// ==============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createHmac } from "https://deno.land/std@0.168.0/node/crypto.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  try {
    const rawBody = await req.text();
    const signature = req.headers.get("x-razorpay-signature") ?? "";
    const webhookSecret = Deno.env.get("RAZORPAY_WEBHOOK_SECRET") ?? "";

    if (webhookSecret) {
      const hmac = createHmac("sha256", webhookSecret);
      hmac.update(rawBody);
      const expectedSignature = hmac.digest("hex");

      if (expectedSignature !== signature) {
        return new Response("Invalid webhook signature", { status: 400 });
      }
    }

    const event = JSON.parse(rawBody);
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (supabaseUrl && supabaseServiceKey) {
      const supabase = createClient(supabaseUrl, supabaseServiceKey);

      if (event.event === "payment.captured") {
        const payment = event.payload.payment.entity;
        const bookingId = payment.notes?.bookingId;

        if (bookingId) {
          await supabase
            .from("bookings")
            .update({
              status: "confirmed",
              deposit_status: "held",
              updated_at: new Date().toISOString(),
            })
            .eq("id", bookingId);
        }
      } else if (event.event === "refund.processed") {
        const refund = event.payload.refund.entity;
        const payment = event.payload.payment.entity;
        const bookingId = payment.notes?.bookingId;

        if (bookingId) {
          await supabase
            .from("bookings")
            .update({
              deposit_status: "refunded",
              updated_at: new Date().toISOString(),
            })
            .eq("id", bookingId);
        }
      }
    }

    return new Response(JSON.stringify({ status: "received" }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});
