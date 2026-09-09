import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/app_text_field_widget.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_event.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_state.dart';
import 'package:qatrah/features/employee/presentation/widgets/dashboard_location_filters_widget.dart';
import 'package:qatrah/features/employee/presentation/widgets/dashboard_status_date_filters_widget.dart';

/// Search box always visible; the heavier location / status / date filters sit
/// behind one collapsible row so the dashboard stays short on a phone.
class DashboardFiltersWidget extends StatefulWidget {
  const DashboardFiltersWidget({super.key});

  @override
  State<DashboardFiltersWidget> createState() => _DashboardFiltersWidgetState();
}

class _DashboardFiltersWidgetState extends State<DashboardFiltersWidget> {
  static const _debounceDelay = Duration(milliseconds: 300);

  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      if (!mounted) return;
      context.read<DashboardBloc>().add(FilterSearchChanged(value.trim()));
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    context.read<DashboardBloc>().add(const FilterSearchChanged(''));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocConsumer<DashboardBloc, DashboardState>(
      // Reset Filters clears the query in the bloc; mirror that into the field.
      listenWhen: (p, c) => p.searchQuery != c.searchQuery,
      listener: (context, state) {
        if (state.searchQuery.isEmpty && _searchController.text.isNotEmpty) {
          _debounce?.cancel();
          _searchController.clear();
        }
      },
      buildWhen: (p, c) => p.activeFilterCount != c.activeFilterCount,
      builder: (context, state) {
        return Column(
          children: [
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) => AppTextField(
                controller: _searchController,
                hintText: l10n.searchSchedulesHint,
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                prefixIcon: const AppIconWidget(
                  icon: HugeIcons.strokeRoundedSearch01,
                ),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _clearSearch,
                        tooltip: l10n.resetFilter,
                        icon: const AppIconWidget(
                          icon: HugeIcons.strokeRoundedCancel01,
                        ),
                      ),
              ),
            ),
            // ExpansionTile draws its own dividers; the card already has edges.
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.only(bottom: 8.h),
                expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                leading: const AppIconWidget(
                  icon: HugeIcons.strokeRoundedFilter,
                ),
                title: Row(
                  children: [
                    Text(
                      l10n.filter,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (state.activeFilterCount > 0) ...[
                      8.horizontalSpace,
                      _FilterCountBadge(count: state.activeFilterCount),
                    ],
                  ],
                ),
                children: [
                  const DashboardLocationFiltersWidget(),
                  12.verticalSpace,
                  const DashboardStatusDateFiltersWidget(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterCountBadge extends StatelessWidget {
  const _FilterCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
