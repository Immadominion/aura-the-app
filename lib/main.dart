import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rive/rive.dart';
import 'package:sage/core/router/app_router.dart';
import 'package:sage/core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Rive before first graphic loads.
  await RiveNative.init();
  runApp(const ProviderScope(child: SageApp()));
}

class SageApp extends ConsumerWidget {
  const SageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 375x812 is standard iPhone X/11/12/13/Mini design size
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final router = ref.watch(goRouterProvider);
        final themeState = ref.watch(themeNotifierProvider);

        return MaterialApp.router(
          title: 'Sage',
          debugShowCheckedModeBanner: false,
          theme: themeState.lightTheme,
          darkTheme: themeState.darkTheme,
          themeMode: themeState.themeMode,
          routerConfig: router,
        );
      },
      child:
          const SizedBox.shrink(), // required by ScreenUtilInit latest versions if builder is used
    );
  }
}
