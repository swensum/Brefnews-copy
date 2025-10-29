import { serve } from "https://deno.land/std@0.177.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const supportedLanguages = {
  'en': 'English',
  'hi': 'Hindi', 
  'es': 'Spanish',
  'fr': 'French',
  'de': 'German',
  'zh': 'Chinese',
  'ar': 'Arabic',
  'ja': 'Japanese',
  'ko': 'Korean',
  'ru': 'Russian'
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { text, target_language } = await req.json()
    
    if (!text || !target_language) {
      return new Response(
        JSON.stringify({ error: 'Text and target_language are required' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    if (!supportedLanguages[target_language]) {
      return new Response(
        JSON.stringify({ error: 'Unsupported language' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    // If target is English, return original
    if (target_language === 'en') {
      return new Response(
        JSON.stringify({ 
          translated_text: text,
          original_text: text,
          target_language: target_language
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Google Translate API
    const response = await fetch(
      `https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=${target_language}&dt=t&q=${encodeURIComponent(text)}`
    )

    if (response.ok) {
      const data = await response.json()
      let translated = ''
      
      if (data[0] && data[0].length > 0) {
        for (const item of data[0]) {
          if (item[0]) {
            translated += item[0]
          }
        }
      }
      
      return new Response(
        JSON.stringify({ 
          translated_text: translated || text,
          original_text: text,
          target_language: target_language
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    } else {
      // Fallback to original text
      return new Response(
        JSON.stringify({ 
          translated_text: text,
          original_text: text,
          target_language: target_language
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
  } catch (error) {
    console.error('Translation error:', error)
    return new Response(
      JSON.stringify({ 
        translated_text: text,
        original_text: text,
        target_language: target_language,
        error: 'Translation failed'
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})