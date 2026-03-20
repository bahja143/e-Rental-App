import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/min_font_text_scaler.dart';
import 'core/router/app_router.dart';
import 'core/network/api_session.dart';
import 'core/network/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode
        ? AppleProvider.debug
        : AppleProvider.appAttest,
  );
  await ApiSession.restore();
  // Ping backend on startup - shows in backend terminal to verify connectivity
  ApiClient().getJson('/ping').then((_) {}).catchError((_) {});
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const HantiRiyoApp());
}

class HantiRiyoApp extends StatelessWidget {
  const HantiRiyoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.0,
      maxScaleFactor: 2.5,
      child: MaterialApp.router(
        title: 'Hanti riyo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: createAppRouter(),
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: MinLogicalFontSizeScaler(
                mq.textScaler,
                minLogicalPixels: AppTheme.minFontSize,
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
