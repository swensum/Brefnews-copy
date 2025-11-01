import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Calculate date 7 days ago
    const oneWeekAgo = new Date()
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7)
    
    const oneWeekAgoISO = oneWeekAgo.toISOString()

    console.log(`Deleting news articles older than: ${oneWeekAgoISO}`)

    // Delete news articles older than 1 week
    const { data, error, count } = await supabaseClient
      .from('news_articles')
      .delete()
      .lt('published_at', oneWeekAgoISO)
      .select('*', { count: 'exact' })

    if (error) {
      console.error('Error deleting old news:', error)
      throw error
    }

    console.log(`Successfully deleted ${count} old news articles`)

    return new Response(
      JSON.stringify({
        success: true,
        message: `Deleted ${count} news articles older than 1 week`,
        deleted_count: count,
        cutoff_date: oneWeekAgoISO,
        deleted_articles: data
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('Error in delete-old-news function:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})