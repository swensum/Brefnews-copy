import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../language/app_localizations.dart';
import '../provider/language_provider.dart';
import '../provider/news_provider.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
            size: screenWidth * 0.06,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          localizations.language, // Now using localized text
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.045,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          Text(
            'Select Language:', // You can add this to your localizations if needed
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16),

          // Restart required banner
          if (languageProvider.needsAppRestart)
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Restart app for full language change',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              itemCount: languageProvider.supportedLanguageNames.length,
              itemBuilder: (context, index) {
                final languageName =
                    languageProvider.supportedLanguageNames[index];
                final languageCode =
                    languageProvider.supportedLanguageCodes[index];

                return GestureDetector(
                  onTap: () async {
                    final currentContext = context;
                    final scaffoldMessenger = ScaffoldMessenger.of(
                      currentContext,
                    );
                    final currentLanguageProvider = languageProvider;
                    final currentNewsProvider = Provider.of<NewsProvider>(
                      currentContext,
                      listen: false,
                    );

                    await currentLanguageProvider.setLanguage(languageCode);
                    await currentNewsProvider.setLanguage(languageCode);
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Language changed to $languageName. Some text may require app restart.',
                        ),
                        duration: Duration(seconds: 3),
                      ),
                    );

                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            languageName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),

                        // Checkmark for current language
                        if (languageProvider.currentLanguage == languageCode)
                          Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
