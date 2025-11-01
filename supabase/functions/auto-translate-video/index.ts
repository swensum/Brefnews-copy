import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};

const supportedLanguages = ['hi', 'es', 'ur', 'zh', 'fr', 'ja'];

async function translateText(text: string, targetLanguage: string): Promise<string> {
  if (!text || text.trim() === '') return text;
  
  try {
    const response = await fetch(
      `https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=${targetLanguage}&dt=t&q=${encodeURIComponent(text)}`
    );
    
    if (response.ok) {
      const data = await response.json();
      if (data[0] && data[0].length > 0) {
        return data[0].map((item: any[]) => item[0]).join('');
      }
    }
  } catch (error) {
    console.error(`Translation failed for ${targetLanguage}:`, error);
  }
  
  return text;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Parse the webhook payload
    const payload = await req.json();
    console.log('📥 Full webhook payload received for video article');

    const record = payload.record;
    if (!record) {
      console.error('❌ No record found in webhook payload');
      return new Response(JSON.stringify({ error: 'No record data received' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      });
    }

    const video_id = record.id;
    const title = record.title;
    const source_name = record.source_name;
    const platform_name = record.platform_name;

    console.log('🔍 Extracted video article data:', { 
      video_id, 
      title: title ? `"${title.substring(0, 50)}..."` : 'NULL',
      source_name: source_name ? `"${source_name}"` : 'NULL',
      platform_name: platform_name ? `"${platform_name}"` : 'NULL'
    });

    if (!video_id) {
      return new Response(JSON.stringify({ error: 'Video ID is required' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      });
    }

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    console.log('✅ Starting translation for video article fields...');

    const results = [];
    let successCount = 0;

    // Translate to all supported languages
    for (const target_language of supportedLanguages) {
      try {
        console.log(`\n🔄 Translating video article to ${target_language}...`);

        // 1. TRANSLATE TITLE
        let translatedTitle = title;
        if (title && title.trim() !== '') {
          translatedTitle = await translateText(title, target_language);
          console.log(`   📝 Title: ${title !== translatedTitle ? 'TRANSLATED' : 'SAME'}`);
        }

        // 2. TRANSLATE SOURCE NAME (if needed)
        let translatedSourceName = source_name;
        if (source_name && source_name.trim() !== '') {
          translatedSourceName = await translateText(source_name, target_language);
          console.log(`   🏢 Source Name: ${source_name !== translatedSourceName ? 'TRANSLATED' : 'SAME'}`);
        }

        // 3. TRANSLATE PLATFORM NAME (if needed)
        let translatedPlatformName = platform_name;
        if (platform_name && platform_name.trim() !== '') {
          translatedPlatformName = await translateText(platform_name, target_language);
          console.log(`   📱 Platform Name: ${platform_name !== translatedPlatformName ? 'TRANSLATED' : 'SAME'}`);
        }

        console.log(`✅ Completed translation for ${target_language}`);

        // Save to database - create a new table for video translations
        const { error } = await supabaseClient
          .from('video_translations')
          .upsert({
            video_article_id: video_id,
            language_code: target_language,
            translated_title: translatedTitle,
            translated_source_name: translatedSourceName,
            translated_platform_name: translatedPlatformName,
            updated_at: new Date().toISOString()
          }, {
            onConflict: 'video_article_id,language_code'
          });

        if (error) {
          console.error(`❌ Database error for ${target_language}:`, error);
        } else {
          console.log(`💾 Successfully saved ${target_language} translation to database`);
          successCount++;
        }

        results.push({
          language: target_language,
          success: !error,
          title_translated: title !== translatedTitle,
          source_name_translated: source_name !== translatedSourceName,
          platform_name_translated: platform_name !== translatedPlatformName
        });

        // Small delay to avoid rate limiting
        await new Promise((resolve) => setTimeout(resolve, 500));

      } catch (error) {
        console.error(`❌ Translation failed for ${target_language}:`, error);
        
        // Create fallback entry with original text
        try {
          await supabaseClient
            .from('video_translations')
            .upsert({
              video_article_id: video_id,
              language_code: target_language,
              translated_title: title,
              translated_source_name: source_name,
              translated_platform_name: platform_name,
              updated_at: new Date().toISOString()
            }, {
              onConflict: 'video_article_id,language_code'
            });
          console.log(`🛟 Created fallback entry for ${target_language}`);
        } catch (dbError) {
          console.error(`💥 Failed to create fallback for ${target_language}:`, dbError);
        }
      }
    }

    console.log(`\n🎉 VIDEO TRANSLATION SUMMARY: ${successCount}/${supportedLanguages.length} languages succeeded`);

    // Final verification
    const { data: translations } = await supabaseClient
      .from('video_translations')
      .select('language_code, translated_title, translated_source_name, translated_platform_name')
      .eq('video_article_id', video_id);

    console.log(`📊 Created ${translations?.length || 0} translation records`);

    return new Response(JSON.stringify({
      success: true,
      video_id: video_id,
      translations_created: successCount,
      total_languages: supportedLanguages.length,
      results: results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('💥 Video webhook processing error:', error);
    return new Response(JSON.stringify({ 
      error: 'Video webhook processing failed',
      details: error.message 
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500
    });
  }
});