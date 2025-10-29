import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { initializeApp, cert } from 'npm:firebase-admin/app';
import { getMessaging } from 'npm:firebase-admin/messaging';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Initialize Firebase Admin
const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
if (!serviceAccountJson) {
  throw new Error('Missing FIREBASE_SERVICE_ACCOUNT environment variable');
}
const serviceAccount = JSON.parse(serviceAccountJson);

initializeApp({
  credential: cert(serviceAccount)
});

const messaging = getMessaging();

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    console.log('🚀 START: Notification function triggered');
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Fetch articles not yet notified
    console.log('📰 STEP 1: Checking for new articles...');
    const { data: newArticles, error: articlesError } = await supabase
      .from('news_articles')
      .select('*')
      .eq('notified', false)
      .order('published_at', { ascending: false })
      .limit(5);

    if (articlesError) throw articlesError;

    console.log(`📊 Found ${newArticles?.length || 0} new articles`);
    
    if (!newArticles?.length) {
      console.log('❌ No new articles found - exiting');
      return new Response(JSON.stringify({ message: 'No new articles' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Log article details
    newArticles.forEach((article, index) => {
      console.log(`   ${index + 1}. ${article.title} (ID: ${article.id})`);
    });

    // Get FCM tokens
    console.log('👥 STEP 2: Fetching user FCM tokens...');
    const { data: userTokens, error: tokensError } = await supabase
      .from('users_tokens')
      .select('fcm_token, platform');

    if (tokensError) throw tokensError;
    
    console.log(`📱 Found ${userTokens?.length || 0} user tokens`);
    
    if (!userTokens?.length) {
      console.log('❌ No user tokens found - exiting');
      return new Response(JSON.stringify({ message: 'No user tokens found' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Log token details
    userTokens.forEach((token, index) => {
      console.log(`   ${index + 1}. ${token.fcm_token?.substring(0, 20)}... (${token.platform})`);
    });

    // Send notifications for each article to all users
    console.log('📤 STEP 3: Sending notifications...');
    let successCount = 0;
    let errorCount = 0;

    for (const article of newArticles) {
      console.log(`\n📨 Processing article: "${article.title}"`);
      
      for (const { fcm_token, platform } of userTokens) {
        if (!fcm_token) {
          console.log('   ⚠️  Skipping empty token');
          continue;
        }

        try {
          console.log(`   📲 Sending to ${platform} device: ${fcm_token.substring(0, 15)}...`);
          
          const message = {
            token: fcm_token,
            notification: {
              title: article.title,
              body: (article.summary || 'New news update').substring(0, 100) + '...',
            },
            data: {
              article_id: article.id,
              type: 'new_news',
              click_action: 'FLUTTER_NOTIFICATION_CLICK'
            },
            android: {
              priority: 'high'
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1,
                  alert: {
                    title: article.title,
                    body: (article.summary || 'New news update').substring(0, 100) + '...'
                  }
                }
              },
              headers: {
                'apns-priority': '10'
              }
            }
          };

          const result = await messaging.send(message);
          successCount++;
          console.log(`   ✅ SUCCESS: Notification sent to ${platform} device`);
          console.log(`   🆔 FCM Message ID: ${result}`);

        } catch (error) {
          errorCount++;
          console.log(`   ❌ FAILED: ${platform} device - ${error.message}`);
          console.log(`   🔍 Error details:`, error);
        }
      }
    }

    // Mark articles as notified
    console.log('\n✅ STEP 4: Marking articles as notified...');
    const articleIds = newArticles.map(article => article.id);
    const { error: updateError } = await supabase
      .from('news_articles')
      .update({ notified: true })
      .in('id', articleIds);

    if (updateError) throw updateError;
    console.log(`   ✅ Marked ${articleIds.length} articles as notified`);

    console.log(`\n🎉 COMPLETED: ${successCount} successful, ${errorCount} failed`);
    console.log('🏁 END: Function completed successfully');

    return new Response(
      JSON.stringify({ 
        message: `✅ Notifications sent for ${newArticles.length} articles - ${successCount} successful, ${errorCount} failed` 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    console.error('💥 CRITICAL ERROR:', err.message);
    console.error('🔍 Stack trace:', err.stack);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});