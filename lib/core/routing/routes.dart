// lib/core/routing/routes.dart
class Routes {
  // Auth Routes
  static const String splash = '/splash';
  static const String forceUpdate = '/force_update';
  static const String maintenance = '/maintenance';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String loginPageEmployee = '/login_employee';
  static const String registerCitizen = '/register_citizen';

  // App-lock flow (PIN/biometric sessions)
  static const String createPin = '/auth/create_pin';
  static const String biometricSetup = '/auth/biometric_setup';
  static const String appLock = '/auth/app_lock';
  static const String changePin = '/auth/change_pin';
  static const String verifyPin = '/auth/verify_pin';

  // Main App Routes
  static const String home = '/home';
  static const String schedules = '/schedules';
  static const String scheduleDetails = '/schedules/:id';
  static const String complaints = '/complaints';
  static const String complaintDetails = '/complaints/:id';
  static const String newComplaint = '/complaints/new';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/edit_profile';
  static const String setting = '/setting';
  static const String navbar = '/navbar';
  static const String settings = '/settings';

  // Helper methods
  static String getScheduleDetailsPath(String id) => '/schedules/$id';
  static String getComplaintDetailsPath(String id) => '/complaints/$id';
  static const String dashboard = '/dashboard';
  static const String completeProfile = '/complete_profile';
  static const String myWaterFeedback = '/my_water_feedback';
  static const String myAddresses = '/my_addresses';
  static const String about = '/about';
  static const String security = '/security';
  static const String contactUs = '/contact_us';
}
