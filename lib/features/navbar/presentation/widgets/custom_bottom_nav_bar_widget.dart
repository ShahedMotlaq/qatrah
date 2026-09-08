// lib/features/navbar/presentation/widgets/custom_bottom_nav_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/features/navbar/presentation/bloc/navbar_bloc.dart';
import 'package:qatrah/features/navbar/presentation/bloc/navbar_state.dart';
import 'package:qatrah/features/navbar/presentation/widgets/custom_navItem_widget.dart';
import 'package:qatrah/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:qatrah/features/notifications/presentation/bloc/notifications_state.dart'
    as notif_state;

class CustomBottomNavBarWidget extends StatelessWidget {
  const CustomBottomNavBarWidget({
    required this.isEmployee,
    this.isAdmin = false,
    super.key,
  });

  final bool isEmployee;
  final bool isAdmin;

  static int _unreadCount(notif_state.NotificationsState s) =>
      s is notif_state.NotificationsLoaded ? s.unreadCount : 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4D3E),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: BlocBuilder<NavbarBloc, NavbarState>(
        buildWhen: (prev, curr) => prev.currentTabIndex != curr.currentTabIndex,
        builder: (context, state) {
          return Row(
            children: isEmployee
                ? _buildEmployeeNavItems(context, state, isAdmin: isAdmin)
                : _buildCitizenNavItems(context, state),
          );
        },
      ),
    );
  }

  List<Widget> _buildCitizenNavItems(BuildContext context, NavbarState state) {
    final l10n = context.l10n;

    return [
      CustomNavItemWidget(
        icon: HugeIcons.strokeRoundedHome02,
        label: l10n.home,
        index: 0,
        currentIndex: state.currentTabIndex,
      ),
      // Notification tab with badge
      BlocBuilder<NotificationsCubit, notif_state.NotificationsState>(
        buildWhen: (prev, curr) => _unreadCount(prev) != _unreadCount(curr),
        builder: (context, notifState) {
          final unreadCount = _unreadCount(notifState);

          return CustomNavItemWidget(
            icon: HugeIcons.strokeRoundedNotification02,
            label: l10n.notificationsTab,
            index: 1,
            currentIndex: state.currentTabIndex,
            badgeCount: unreadCount > 0 ? unreadCount : null,
          );
        },
      ),
      CustomNavItemWidget(
        icon: HugeIcons.strokeRoundedSettings01,
        label: l10n.settings,
        index: 2,
        currentIndex: state.currentTabIndex,
      ),
    ];
  }

  List<Widget> _buildEmployeeNavItems(
    BuildContext context,
    NavbarState state, {
    required bool isAdmin,
  }) {
    final l10n = context.l10n;

    final items = <Widget>[
      CustomNavItemWidget(
        icon: HugeIcons.strokeRoundedDashboardSquare03,
        label: l10n.dashboard,
        index: 0,
        currentIndex: state.currentTabIndex,
      ),
      // Notification tab with badge
      BlocBuilder<NotificationsCubit, notif_state.NotificationsState>(
        buildWhen: (prev, curr) => _unreadCount(prev) != _unreadCount(curr),
        builder: (context, notifState) {
          final unreadCount = _unreadCount(notifState);

          return CustomNavItemWidget(
            icon: HugeIcons.strokeRoundedNotification02,
            label: l10n.notificationsTab,
            index: 1,
            currentIndex: state.currentTabIndex,
            badgeCount: unreadCount > 0 ? unreadCount : null,
          );
        },
      ),
    ];

    if (isAdmin) {
      items.add(
        CustomNavItemWidget(
          icon: HugeIcons.strokeRoundedMailSend02,
          label: l10n.complaints,
          index: 2,
          currentIndex: state.currentTabIndex,
        ),
      );
    }

    items.add(
      CustomNavItemWidget(
        icon: HugeIcons.strokeRoundedSettings01,
        label: l10n.settings,
        index: isAdmin ? 3 : 2,
        currentIndex: state.currentTabIndex,
      ),
    );

    return items;
  }
}
