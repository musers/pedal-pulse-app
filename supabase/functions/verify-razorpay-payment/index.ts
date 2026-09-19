// ==============================================================================
// verify-razorpay-payment / index.ts
// Supabase Edge Function: HMAC-SHA256 Payment Verification & Booking Finalization
// ==============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createHmac } from "https://deno.land/std@0.168.0/node/crypto.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { orderId, paymentId, signature, bookingId } = await req.json();
    const razorpayKeySecret = Deno.env.get("RAZORPAY_KEY_SECRET") ?? "";

    let isVerified = false;

    if (!razorpayKeySecret) {
      // Mock / sandbox mode
      isVerified = true;
    } else {
      // Cryptographic HMAC-SHA256 signature verification
      const body = `${orderId}|${paymentId}`;
      const hmac = createHmac("sha256", razorpayKeySecret);
      hmac.update(body);
      const generatedSignature = hmac.digest("hex");

      isVerified = (generatedSignature === signature);
    }

    if (!isVerified) {
      return new Response(
        JSON.stringify({ verified: false, error: "Cryptographic signature verification failed" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    // Initialize Supabase Admin Client to update booking status
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (supabaseUrl && supabaseServiceKey && bookingId) {
      const supabase = createClient(supabaseUrl, supabaseServiceKey);
      await supabase
        .from("bookings")
        .update({
          status: "confirmed",
          deposit_status: "held",
          updated_at: new Date().toISOString(),
        })
        .eq("id", bookingId);
    }

    return new Response(
      JSON.stringify({ verified: true, paymentId, orderId }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ verified: false, error: error.message }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
    );
  }
});
