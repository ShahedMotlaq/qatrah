// lib/features/complaints/presentation/pages/complaints_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/utils/app_logger.dart';
import 'package:qatrah/core/widgets/app_background_widget.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/appbar/qatrah_appbar_widget.dart';
import 'package:qatrah/features/complaints/presentation/bloc/complaints_bloc.dart';
import 'package:qatrah/features/complaints/presentation/bloc/complaints_event.dart';
import 'package:qatrah/features/complaints/presentation/widgets/complaint_tab_widget.dart';
import 'package:qatrah/features/complaints/presentation/widgets/complaints_list_tab_widget.dart';
import 'package:qatrah/features/complaints/presentation/widgets/create_complaint_form.dart';

class ComplaintsPage extends StatelessWidget {
  const ComplaintsPage({
    this.isEmployeeView = false,
    this.isAdminView = false,
    super.key,
  });

  final bool isEmployeeView;
  final bool isAdminView;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 4,
      child: BlocProvider(
        create: (context) {
          final bloc = getIt<ComplaintsBloc>();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkTokenAndFetch(bloc, isEmployeeView: isEmployeeView);
          });
          return bloc;
        },
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: QatrahAppBarWidget(
            title: Text(isEmployeeView ? l10n.complaints : l10n.myComplaints),
            actions: isEmployeeView
                ? null
                : [
                    Builder(
                      builder: (context) => IconButton(
                        onPressed: () => showCreateComplaintDialog(context),
                        icon: AppIconWidget(
                          icon: HugeIcons.strokeRoundedAdd01,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
          ),
          floatingActionButton: isEmployeeView
              ? null
              : Builder(
                  builder: (context) => FloatingActionButton(
                    onPressed: () => showCreateComplaintDialog(context),
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
                  ),
                ),
          body: AppBackground(
            child: Column(
              children: [
                24.verticalSpace,
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorWeight: 0,
                    dividerHeight: 0,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    labelColor: theme.colorScheme.onPrimary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.5),
                    labelPadding: const EdgeInsets.symmetric(vertical: 7),
                    tabs: const [
                      ComplaintTabWidget(status: 'PENDING'),
                      ComplaintTabWidget(status: 'IN_PROGRESS'),
                      ComplaintTabWidget(status: 'RESOLVED'),
                      ComplaintTabWidget(status: 'REJECTED'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ComplaintsListTabWidget(
                        statusFilter: 'PENDING',
                        isAdminView: isAdminView,
                      ),
                      ComplaintsListTabWidget(
                        statusFilter: 'IN_PROGRESS',
                        isAdminView: isAdminView,
                      ),
                      ComplaintsListTabWidget(
                        statusFilter: 'RESOLVED',
                        isAdminView: isAdminView,
                      ),
                      ComplaintsListTabWidget(
                        statusFilter: 'REJECTED',
                        isAdminView: isAdminView,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkTokenAndFetch(
    ComplaintsBloc bloc, {
    required bool isEmployeeView,
  }) async {
    final secureStorage = getIt<SecureStorage>();
    final token = await secureStorage.getToken();

    if (token != null && token.isNotEmpty) {
      if (isEmployeeView) {
        bloc.add(const FetchAllComplaintsEvent());
      } else {
        bloc.add(const FetchMyComplaintsEvent());
      }
    } else {
      AppLogger.debug('No token found - user not logged in');
    }
  }
}
