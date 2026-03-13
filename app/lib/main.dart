import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/network/api_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiSession.restore();
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
    return MaterialApp.router(
      title: 'Hanti riyo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: createAppRouter(),
    );
  }
}
