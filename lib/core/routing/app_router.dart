// lib/core/routing/app_router.dart
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qatrah/core/auth/session_notifier.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/routing/route_guards/auth_guard.dart';
import 'package:qatrah/core/routing/routes.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/features/auth/presentation/pages/app_pin/app_lock_page.dart';
import 'package:qatrah/features/auth/presentation/pages/app_pin/biometric_setup_page.dart';
import 'package:qatrah/features/auth/presentation/pages/app_pin/change_pin_page.dart';
import 'package:qatrah/features/auth/presentation/pages/app_pin/create_pin_page.dart';
import 'package:qatrah/features/auth/presentation/pages/app_pin/verify_pin_page.dart';
import 'package:qatrah/features/auth/presentation/pages/login/login_page.dart';
import 'package:qatrah/features/auth/presentation/pages/login/register_citizen_page.dart';
import 'package:qatrah/features/auth/presentation/pages/login/login_page_employee.dart';
import 'package:qatrah/features/auth/presentation/pages/otp/otp_page.dart';
import 'package:qatrah/features/employee/presentation/pages/dashboard_page.dart';
import 'package:qatrah/features/home/presentation/pages/home_page.dart';
import 'package:qatrah/features/maintenance/presentation/pages/maintenance_page.dart';
import 'package:qatrah/features/navbar/presentation/pages/navbar_page.dart';
import 'package:qatrah/features/notifications/presentation/pages/notifications_page.dart';
import 'package:qatrah/features/profile/presentation/pages/about_page.dart';
import 'package:qatrah/features/profile/presentation/pages/complete_profile_page.dart';
import 'package:qatrah/features/profile/presentation/pages/contact_us_page.dart';
import 'package:qatrah/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:qatrah/features/profile/presentation/pages/my_addresses_page.dart';
import 'package:qatrah/features/profile/presentation/pages/profile_page.dart';
import 'package:qatrah/features/profile/presentation/pages/security_page.dart';
import 'package:qatrah/features/settings/presentation/pages/settings_page.dart';
import 'package:qatrah/features/splash/presentation/pages/force_update_page.dart';
import 'package:qatrah/features/splash/presentation/pages/splash_page.dart';
import 'package:qatrah/features/water_feedback/presentation/pages/my_feedback_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    redirect: AuthGuard.redirect,
    // Wakes the redirect guard whenever the session ends out-of-band (e.g. a
    // background 401 the silent refresh couldn't recover). Without this the
    // guard would only re-run on the next manual navigation, leaving the user
    // stranded on a protected screen after their tokens were wiped.
    refreshListenable: getIt<SessionNotifier>(),
    // BotToastNavigatorObserver must be registered on the root GoRouter so that
    // bot_toast can manage overlay entry lifecycles across GoRouter's internal
    // navigation stack.  Without this, toasts may linger or disappear too early
    // after a route transition.
    observers: [BotToastNavigatorObserver()],

    routes: [
      // ===== Splash Page =====
      GoRoute(
        path: Routes.splash,
        name: Routes.splash,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const SplashPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Special animation: slow fade (as it's a splash page)
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    ),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 800),
          );
        },
      ),

      GoRoute(
        path: Routes.forceUpdate,
        name: Routes.forceUpdate,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ForceUpdatePage(
            storeUrl: extra?['storeUrl'] as String?,
            apkUrl: extra?['apkUrl'] as String?,
          );
        },
      ),

      GoRoute(
        path: Routes.maintenance,
        name: Routes.maintenance,
        builder: (context, state) {
          final extra = state.extra is Map
              ? state.extra! as Map<String, dynamic>
              : const <String, dynamic>{};
          return MaintenancePage(
            onRetry: () => context.goNamed(Routes.splash),
            message: extra['message'] as String?,
            retryAfterSeconds: extra['retryAfterSeconds'] as int?,
          );
        },
      ),

      // ===== Login Page =====
      GoRoute(
        path: Routes.login,
        name: Routes.login,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const LoginPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Slide from bottom (as if rising to the screen)
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 1), // from bottom
                          end: Offset.zero, // to center
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 400),
          );
        },
      ),

      GoRoute(
        path: Routes.registerCitizen,
        name: Routes.registerCitizen,
        builder: (context, state) => const RegisterCitizenPage(),
      ),
      // ===== Login Employee Page =====
      GoRoute(
        path: Routes.loginPageEmployee,
        name: Routes.loginPageEmployee,
        builder: (context, state) => const LoginPageEmployee(),
      ),

      // ===== Complete Profile Page =====
      GoRoute(
        path: Routes.completeProfile,
        name: Routes.completeProfile,
        builder: (context, state) => const CompleteProfilePage(),
      ),

      // ===== My Water Feedback Page =====
      GoRoute(
        path: Routes.myWaterFeedback,
        name: Routes.myWaterFeedback,
        builder: (context, state) => const MyFeedbackPage(),
      ),

      GoRoute(
        path: Routes.myAddresses,
        name: Routes.myAddresses,
        builder: (context, state) => const MyAddressesPage(),
      ),

      // ===== OTP Page =====
      GoRoute(
        path: Routes.otp,
        name: Routes.otp,
        pageBuilder: (context, state) {
          // extra can be either String (phoneNumber) or Map {phoneNumber, alreadySent}
          final extra = state.extra;
          final String phoneNumber;
          final bool alreadySent;

          if (extra is Map) {
            phoneNumber = extra['phoneNumber'] as String;
            alreadySent = extra['alreadySent'] as bool? ?? false;
          } else {
            phoneNumber = extra! as String;
            alreadySent = false;
          }

          return CustomTransitionPage(
            key: state.pageKey,
            child: OtpPage(
              phoneNumber: phoneNumber,
              alreadySent: alreadySent,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.elasticOut,
                      ),
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
            transitionDuration: const Duration(milliseconds: 500),
          );
        },
      ),

      // ===== App-lock flow (PIN/biometric sessions) =====
      GoRoute(
        path: Routes.createPin,
        name: Routes.createPin,
        builder: (context, state) {
          final fromSettings =
              (state.extra as Map<String, dynamic>?)?['fromSettings']
                  as bool? ??
              false;
          return CreatePinPage(fromSettings: fromSettings);
        },
      ),
      GoRoute(
        path: Routes.biometricSetup,
        name: Routes.biometricSetup,
        builder: (context, state) => const BiometricSetupPage(),
      ),
      GoRoute(
        path: Routes.appLock,
        name: Routes.appLock,
        builder: (context, state) => const AppLockPage(),
      ),
      GoRoute(
        path: Routes.changePin,
        name: Routes.changePin,
        builder: (context, state) => const ChangePinPage(),
      ),
      GoRoute(
        path: Routes.verifyPin,
        name: Routes.verifyPin,
        builder: (context, state) => const VerifyPinPage(),
      ),

      // ===== Navbar Page =====
      GoRoute(
        path: Routes.navbar,
        name: Routes.navbar,
        builder: (context, state) {
          final extra = state.extra;
          final notificationExtra = extra is Map
              ? Map<String, dynamic>.from(extra)
              : null;
          return NavbarPage(
            notificationExtra: notificationExtra,
            forceIsEmployee: notificationExtra?['forceIsEmployee'] as bool?,
          );
        },
        pageBuilder: (context, state) {
          final extra = state.extra;
          final notificationExtra = extra is Map
              ? Map<String, dynamic>.from(extra)
              : null;
          return CustomTransitionPage(
            key: state.pageKey,
            child: NavbarPage(
              notificationExtra: notificationExtra,
              forceIsEmployee: notificationExtra?['forceIsEmployee'] as bool?,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Smooth animation: fade with slight slide
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05), // very slight slide
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
          );
        },
      ),

      // ===== Home Page =====
      GoRoute(
        path: Routes.home,
        name: Routes.home,
        pageBuilder: (context, state) {
          final notificationExtra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: HomePage(notificationExtra: notificationExtra),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Smooth animation: fade with slight slide
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05), // very slight slide
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
          );
        },
      ),

      // ===== Schedules Page =====
      GoRoute(
        path: Routes.schedules,
        name: Routes.schedules,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const _SchedulesPagePlaceholder(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Menu-like animation: slide from bottom
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOutBack,
                          ),
                        ),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 350),
          );
        },
      ),

      // ===== Schedule Details =====
      GoRoute(
        path: Routes.scheduleDetails,
        name: Routes.scheduleDetails,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: _ScheduleDetailsPagePlaceholder(id: id),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Focus animation for details (from center)
                  return ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.95,
                      end: 1,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
          );
        },
      ),

      // ===== Complaints Page =====
      GoRoute(
        path: Routes.complaints,
        name: Routes.complaints,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const _ComplaintsPagePlaceholder(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(-0.5, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutQuart,
                          ),
                        ),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 400),
          );
        },
      ),

      // ===== Complaint Details =====
      GoRoute(
        path: Routes.complaintDetails,
        name: Routes.complaintDetails,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: _ComplaintDetailsPagePlaceholder(id: id),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Similar animation to schedule details for consistency
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
          );
        },
      ),

      // ===== New Complaint =====
      GoRoute(
        path: Routes.newComplaint,
        name: Routes.newComplaint,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const _NewComplaintPagePlaceholder(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Full slide from bottom (like a form appearing)
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOutBack,
                          ),
                        ),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 500),
          );
        },
      ),

      // ===== Notifications =====
      GoRoute(
        path: Routes.notifications,
        name: Routes.notifications,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const NotificationsPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Slide from top (like a notification list)
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, -0.5),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          ),
                        ),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 350),
          );
        },
      ),

      // ===== Profile =====
      GoRoute(
        path: Routes.profile,
        name: Routes.profile,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const ProfilePage(),

            // child: const _ProfilePagePlaceholder(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Smooth animation with slight rotation
                  return RotationTransition(
                    turns: Tween<double>(
                      begin: -0.01, // very slight rotation
                      end: 0,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 400),
          );
        },
      ),
      GoRoute(
        path: Routes.about,
        name: Routes.about,
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: Routes.security,
        name: Routes.security,
        builder: (context, state) => const SecurityPage(),
      ),
      GoRoute(
        path: Routes.contactUs,
        name: Routes.contactUs,
        builder: (context, state) => const ContactUsPage(),
      ),
      // ===== Setting =====
      GoRoute(
        path: Routes.setting,
        name: Routes.setting,
        pageBuilder: (context, state) {
          final isEmployee = state.extra as bool? ?? false;
          return CustomTransitionPage(
            key: state.pageKey,
            child: SettingsPage(
              isEmployee: isEmployee,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Smooth animation with slight rotation
                  return RotationTransition(
                    turns: Tween<double>(
                      begin: -0.01, // very slight rotation
                      end: 0,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 400),
          );
        },
      ),

      // ===== Edit Profile =====
      GoRoute(
        path: Routes.editProfile,
        name: Routes.editProfile,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const EditProfilePage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Zoom animation (focus on editing)
                  return ScaleTransition(
                    scale:
                        Tween<double>(
                          begin: 0.98,
                          end: 1,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.elasticOut,
                          ),
                        ),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 450),
          );
        },
      ),

      // ===== Location =====
      GoRoute(
        path: Routes.dashboard,
        name: Routes.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
    ],

    // ===== Error Page =====
    errorPageBuilder: (context, state) {
      final l10n = context.l10n;
      return CustomTransitionPage(
        key: state.pageKey,
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                Text(l10n.pageNotFound, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => context.go(Routes.home),
                  child: Text(l10n.returnToHome),
                ),
              ],
            ),
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Shake animation for error
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.02, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.elasticOut,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      );
    },
  );
}

// ===== Page Placeholders =====

class _HomePagePlaceholder extends StatelessWidget {
  const _HomePagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: const Center(child: Text('Home Page - Under Development')),
    );
  }
}

class _SchedulesPagePlaceholder extends StatelessWidget {
  const _SchedulesPagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedules')),
      body: const Center(child: Text('Schedules Page - Under Development')),
    );
  }
}

class _ScheduleDetailsPagePlaceholder extends StatelessWidget {
  const _ScheduleDetailsPagePlaceholder({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Details')),
      body: Center(child: Text('Schedule Details for ID: $id')),
    );
  }
}

class _ComplaintsPagePlaceholder extends StatelessWidget {
  const _ComplaintsPagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaints')),
      body: const Center(child: Text('Complaints Page - Under Development')),
    );
  }
}

class _ComplaintDetailsPagePlaceholder extends StatelessWidget {
  const _ComplaintDetailsPagePlaceholder({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Details')),
      body: Center(child: Text('Complaint Details for ID: $id')),
    );
  }
}

class _NewComplaintPagePlaceholder extends StatelessWidget {
  const _NewComplaintPagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Complaint')),
      body: const Center(child: Text('New Complaint Page - Under Development')),
    );
  }
}

class _NotificationsPagePlaceholder extends StatelessWidget {
  const _NotificationsPagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('Notifications Page - Under Development')),
    );
  }
}

class _ProfilePagePlaceholder extends StatelessWidget {
  const _ProfilePagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile Page - Under Development')),
    );
  }
}

class _EditProfilePagePlaceholder extends StatelessWidget {
  const _EditProfilePagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: const Center(child: Text('Edit Profile Page - Under Development')),
    );
  }
}
