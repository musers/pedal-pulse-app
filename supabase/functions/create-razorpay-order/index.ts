// ==============================================================================
// create-razorpay-order / index.ts
// Supabase Edge Function: Server-authoritative Razorpay Order Creation
// ==============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
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
    const { bookingId, amount, customerPhone, customerEmail } = await req.json();

    const razorpayKeyId = Deno.env.get("RAZORPAY_KEY_ID") ?? "";
    const razorpayKeySecret = Deno.env.get("RAZORPAY_KEY_SECRET") ?? "";

    if (!razorpayKeyId || !razorpayKeySecret) {
      // Return mock order for sandbox / local development
      return new Response(
        JSON.stringify({
          orderId: `order_mock_${Date.now()}`,
          amount: amount,
          currency: "INR",
          keyId: "rzp_test_mock_key",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    // Convert amount in INR to Paise (e.g. ₹100 = 10000 paise)
    const amountPaise = Math.round(amount * 100);

    const basicAuth = btoa(`${razorpayKeyId}:${razorpayKeySecret}`);
    const rzpResponse = await fetch("https://api.razorpay.com/v1/orders", {
      method: "POST",
      headers: {
        Authorization: `Basic ${basicAuth}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        amount: amountPaise,
        currency: "INR",
        receipt: `rcpt_${bookingId.substring(0, 14)}`,
        notes: {
          bookingId: bookingId,
          customerPhone: customerPhone ?? "",
          customerEmail: customerEmail ?? "",
        },
      }),
    });

    const orderData = await rzpResponse.json();

    return new Response(
      JSON.stringify({
        orderId: orderData.id,
        amount: amount,
        currency: "INR",
        keyId: razorpayKeyId,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
    );
  }
});
