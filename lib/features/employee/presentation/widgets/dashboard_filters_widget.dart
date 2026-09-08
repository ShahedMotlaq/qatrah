import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/features/employee/presentation/widgets/dashboard_location_filters_widget.dart';
import 'package:qatrah/features/employee/presentation/widgets/dashboard_status_date_filters_widget.dart';

class DashboardFiltersWidget extends StatelessWidget {
  const DashboardFiltersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DashboardLocationFiltersWidget(),
        12.verticalSpace,
        const DashboardStatusDateFiltersWidget(),
      ],
    );
  }
}
