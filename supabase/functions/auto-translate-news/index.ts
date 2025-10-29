import { serve } from "https://deno.land/std@0.177.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const supportedLanguages = ['hi', 'es', 'ur', 'zh', 'fr', 'ja'];

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { article_id, title, summary, headline } = await req.json()
    
    if (!article_id) {
      return new Response(
        JSON.stringify({ error: 'Article ID is required' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    const results = [];

    // Translate to all supported languages
    for (const target_language of supportedLanguages) {
      try {
        // Translate title
        const titleResponse = await fetch(
          `https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=${target_language}&dt=t&q=${encodeURIComponent(title)}`
        );
        
        let translatedTitle = title;
        if (titleResponse.ok) {
          const data = await titleResponse.json();
          if (data[0] && data[0].length > 0) {
            translatedTitle = data[0].map((item: any[]) => item[0]).join('');
          }
        }

        // Translate summary
        let translatedSummary = summary;
        if (summary) {
          const summaryResponse = await fetch(
            `https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=${target_language}&dt=t&q=${encodeURIComponent(summary)}`
          );
          
          if (summaryResponse.ok) {
            const data = await summaryResponse.json();
            if (data[0] && data[0].length > 0) {
              translatedSummary = data[0].map((item: any[]) => item[0]).join('');
            }
          }
        }

        // Translate headline if exists
        let translatedHeadline = headline;
        if (headline && typeof headline === 'object') {
          const translatedHeadlineObj = { ...headline };
          
          if (headline.headline) {
            const headlineResponse = await fetch(
              `https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=${target_language}&dt=t&q=${encodeURIComponent(headline.headline)}`
            );
            
            if (headlineResponse.ok) {
              const data = await headlineResponse.json();
              if (data[0] && data[0].length > 0) {
                translatedHeadlineObj.headline = data[0].map((item: any[]) => item[0]).join('');
              }
            }
          }

          if (headline.subheadline) {
            const subheadlineResponse = await fetch(
              `https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=${target_language}&dt=t&q=${encodeURIComponent(headline.subheadline)}`
            );
            
            if (subheadlineResponse.ok) {
              const data = await subheadlineResponse.json();
              if (data[0] && data[0].length > 0) {
                translatedHeadlineObj.subheadline = data[0].map((item: any[]) => item[0]).join('');
              }
            }
          }
          
          translatedHeadline = translatedHeadlineObj;
        }

        results.push({
          language: target_language,
          translated_title: translatedTitle,
          translated_summary: translatedSummary,
          translated_headline: translatedHeadline
        });

        // Small delay to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 500));
        
      } catch (error) {
        console.error(`Translation failed for ${target_language}:`, error);
        // Continue with other languages even if one fails
      }
    }

    return new Response(
      JSON.stringify({ 
        success: true,
        article_id: article_id,
        translations: results
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
    
  } catch (error) {
    console.error('Auto translation error:', error);
    return new Response(
      JSON.stringify({ error: 'Auto translation failed' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    );
  }
});