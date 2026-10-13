import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:receyta/core/supabase_config.dart';
import 'package:receyta/features/recipes/screens/global_timers_bar.dart';
import 'package:receyta/features/settings/controllers/app_settings.dart';
import 'package:receyta/router.dart';
import 'package:receyta/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: kSupabaseUrl,
      publishableKey: kSupabasePublishableKey,
    );
  } catch (e) {
    debugPrint('Supabase.initialize: $e');
  }
  final settings = await loadAppSettings();
  runApp(
    ProviderScope(
      overrides: [initialAppSettingsProvider.overrideWithValue(settings)],
      child: const ReceytaApp(),
    ),
  );
}

class ReceytaApp extends ConsumerWidget {
  const ReceytaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final contrast = settings.highContrast;
    return MaterialApp.router(
      title: 'Receyta',
      theme: contrast ? AppTheme.highContrast() : AppTheme.light(),
      darkTheme: contrast ? AppTheme.highContrast() : AppTheme.dark(),
      themeMode: contrast ? ThemeMode.light : settings.themeMode,
      routerConfig: router,
      // Faixa de timers fixa no topo de qualquer tela (G1).
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final scale = (media.textScaler.scale(1) * settings.textSize.factor)
            .clamp(0.8, 2.0);
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: dark ? SystemBars.onDark : SystemBars.onLight,
          child: MediaQuery(
            data: media.copyWith(textScaler: TextScaler.linear(scale)),
            child: GlobalTimersBar(
              onOpenRecipe: (id) => router.push('/recipe/$id/cook'),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
    );
  }
}
