import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/app_text_field_widget.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_event.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_state.dart';
import 'package:qatrah/features/employee/presentation/widgets/dashboard_location_filters_widget.dart';
import 'package:qatrah/features/employee/presentation/widgets/dashboard_status_date_filters_widget.dart';

/// Body of the filter sheet opened from the dashboard AppBar: keyword search,
/// location, status and date range, plus reset / apply.
///
/// ponytail: every control applies to the list as it changes, so "apply" only
/// closes the sheet. Buffering a draft would mean duplicating the region →
/// unit → neighborhood → zone cascade, which only the bloc can load.
class DashboardFiltersWidget extends StatefulWidget {
  const DashboardFiltersWidget({super.key});

  @override
  State<DashboardFiltersWidget> createState() => _DashboardFiltersWidgetState();
}

class _DashboardFiltersWidgetState extends State<DashboardFiltersWidget> {
  static const _debounceDelay = Duration(milliseconds: 300);

  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Reopening the sheet must show the query the list is already filtered by.
    _searchController = TextEditingController(
      text: context.read<DashboardBloc>().state.searchQuery,
    );
  }

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

  void _reset() {
    _debounce?.cancel();
    _searchController.clear();
    context.read<DashboardBloc>().add(ResetFilters());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              icon: const AppIconWidget(
                                icon: HugeIcons.strokeRoundedCancel01,
                              ),
                            ),
                    ),
                  ),
                  12.verticalSpace,
                  const DashboardLocationFiltersWidget(),
                  12.verticalSpace,
                  const DashboardStatusDateFiltersWidget(),
                ],
              ),
            ),
          ),
          16.verticalSpace,
          BlocBuilder<DashboardBloc, DashboardState>(
            buildWhen: (p, c) => p.activeFilterCount != c.activeFilterCount,
            builder: (context, state) {
              return Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: l10n.resetFilter,
                      isOutline: true,
                      onPressed: state.activeFilterCount > 0 ? _reset : null,
                    ),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: AppButton(
                      text: l10n.applyFilters,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
