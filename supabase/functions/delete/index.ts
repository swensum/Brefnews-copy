import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    console.log('🚀 Delete old news function triggered at:', new Date().toISOString());

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Call the PostgreSQL function instead of direct deletion
    const { data, error } = await supabaseClient.rpc('cleanup_old_news_articles');

    if (error) {
      console.error('❌ Error calling cleanup function:', error);
      throw error;
    }

    console.log('✅ Cleanup function executed successfully:', data);

    return new Response(JSON.stringify({
      success: data?.success || false,
      message: data?.message || 'Cleanup completed',
      deleted_count: data?.deleted_count || 0,
      cutoff_date: data?.cutoff_date,
      error: data?.error || null
    }), {
      headers: { 
        ...corsHeaders, 
        'Content-Type': 'application/json' 
      },
      status: data?.success ? 200 : 500
    });

  } catch (error) {
    console.error('💥 Error in delete-old-news function:', error);
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      headers: { 
        ...corsHeaders, 
        'Content-Type': 'application/json' 
      },
      status: 500
    });
  }
});