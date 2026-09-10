// lib/features/navbar/presentation/pages/navbar_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/utils/jwt_decoder.dart';
import 'package:qatrah/core/widgets/app_loading_widget.dart';
import 'package:qatrah/core/widgets/appdialog/dynamic_confirm_dialog.dart';
import 'package:qatrah/features/complaints/presentation/pages/complaints_page.dart';
import 'package:qatrah/features/employee/presentation/pages/dashboard_page.dart';
import 'package:qatrah/features/employee/presentation/pages/statistics_page.dart';
import 'package:qatrah/features/home/presentation/pages/home_page.dart';
import 'package:qatrah/features/navbar/presentation/bloc/navbar_bloc.dart';
import 'package:qatrah/features/navbar/presentation/bloc/navbar_event.dart';
import 'package:qatrah/features/navbar/presentation/bloc/navbar_state.dart';
import 'package:qatrah/features/navbar/presentation/widgets/custom_bottom_nav_bar_widget.dart';
import 'package:qatrah/features/notifications/presentation/pages/notifications_page.dart';
import 'package:qatrah/features/settings/presentation/pages/settings_page.dart';

class NavbarPage extends StatefulWidget {
  const NavbarPage({
    this.notificationExtra,
    this.forceIsEmployee,
    super.key,
  });

  /// Optional deep link payload from notification tap.
  final Map<String, dynamic>? notificationExtra;
  final bool? forceIsEmployee;

  @override
  State<NavbarPage> createState() => _NavbarPageState();
}

class _NavbarPageState extends State<NavbarPage> {
  bool? _isEmployee;
  bool _isAdmin = false;
  final SecureStorage _secureStorage = getIt<SecureStorage>();

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await _secureStorage.getRole();
    final token = await _secureStorage.getToken(role: role);
    final isAdmin = role == 'ADMIN' || _extractAdminFromToken(token);

    if (widget.forceIsEmployee != null) {
      if (!mounted) return;
      setState(() {
        _isEmployee = widget.forceIsEmployee;
        _isAdmin = isAdmin;
      });
      return;
    }

    final isEmployee = _resolveIsEmployee(role, token);

    if (isEmployee && role != 'OPERATOR' && role != 'ADMIN') {
      await _secureStorage.setRole('OPERATOR');
    }

    if (!mounted) return;
    setState(() {
      _isEmployee = isEmployee;
      _isAdmin = isAdmin;
    });
  }

  bool _resolveIsEmployee(String? role, String? token) {
    if (role == 'OPERATOR' || role == 'ADMIN' || role == 'EMPLOYEE') {
      return true;
    }

    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      final decoded = JwtDecoder.decode(token);
      final realmAccess = decoded['realm_access'];
      if (realmAccess is Map && realmAccess['roles'] is List) {
        final roles = List<String>.from(realmAccess['roles'] as List);
        return roles.contains('OPERATOR') || roles.contains('ADMIN');
      }
    } catch (_) {}

    return false;
  }

  bool _extractAdminFromToken(String? token) {
    if (token == null || token.isEmpty) return false;
    try {
      final decoded = JwtDecoder.decode(token);
      final realmAccess = decoded['realm_access'];
      if (realmAccess is Map && realmAccess['roles'] is List) {
        final roles = List<String>.from(realmAccess['roles'] as List);
        if (roles.contains('ADMIN')) {
          // Persist the role so future loads don't need JWT decoding
          _secureStorage.setRole('ADMIN');
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isEmployee == null) {
      return const Scaffold(
        body: Center(
          child: AppLoadingWidget(size: 60),
        ),
      );
    }

    // If notification extra is provided, switch to home tab
    if (widget.notificationExtra != null && _isEmployee == false) {
      // Ensure we're on the home tab (index 0)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<NavbarBloc>().add(ChangeBottomNavTabEvent(0));
        }
      });
    }

    return BlocProvider(
      create: (context) => NavbarBloc(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          final l10n = context.l10n;
          showDialog<void>(
            context: context,
            builder: (_) => DynamicConfirmDialog(
              title: l10n.exitAppTitle,
              message: l10n.exitAppMessage,
              confirmBtnText: l10n.exitAppConfirm,
              cancelBtnText: l10n.cancel,
              onConfirm: SystemNavigator.pop,
            ),
          );
        },
        child: Scaffold(
          extendBody: true,
          body: BlocBuilder<NavbarBloc, NavbarState>(
            buildWhen: (previous, current) =>
                previous.currentTabIndex != current.currentTabIndex,
            builder: (context, state) {
              final currentIndex = state.currentTabIndex;

              return IndexedStack(
                index: currentIndex,
                children: _buildChildren(_isEmployee!),
              );
            },
          ),
          bottomNavigationBar: CustomBottomNavBarWidget(
            isEmployee: _isEmployee!,
            isAdmin: _isAdmin,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChildren(bool isEmployee) {
    if (isEmployee) {
      // Order must match CustomBottomNavBarWidget._buildEmployeeNavItems.
      final children = <Widget>[
        const DashboardPage(),
        const StatisticsPage(tabIndex: 1),
        const NotificationsPage(),
      ];
      if (_isAdmin) {
        children.add(
          const ComplaintsPage(isEmployeeView: true, isAdminView: true),
        );
      }
      children.add(const SettingsPage(isEmployee: true));
      return children;
    } else {
      return [
        HomePage(notificationExtra: widget.notificationExtra),
        const NotificationsPage(),
        const SettingsPage(),
      ];
    }
  }
}
