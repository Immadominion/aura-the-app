import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/providers/connectivity_provider.dart';

/// A slim banner that slides in from the top when the device loses
/// network connectivity, and slides out when it reconnects.
///
/// Place this inside a [Stack] above the main content (e.g. in AppShell).
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);

    final isOffline = connectivity.when(
      data: (online) => !online,
      loading: () => false,
      error: (_, _) => false,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
      child: isOffline
          ? Container(
              key: const ValueKey('offline'),
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 6.h),
              color: Colors.red.shade700,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'No Internet Connection',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('online')),
    );
  }
}
