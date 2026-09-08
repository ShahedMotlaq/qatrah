import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/features/home/presentation/bloc/home_bloc.dart';
import 'package:qatrah/features/home/presentation/bloc/home_event.dart';
import 'package:qatrah/features/home/presentation/widgets/dummy_area_details_page.dart';

class AreaDropdownItemWidget extends StatelessWidget {
  const AreaDropdownItemWidget({
    required this.areaId,
    required this.cityName,
    required this.subTitle,
    required this.isSelected,
    super.key,
  });

  final int areaId;
  final String cityName;
  final String subTitle;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        context.read<HomeBloc>().add(
          ToggleAreaWatchEvent(areaId: areaId, watch: !isSelected),
        );
        context.read<HomeBloc>().add(SelectDisplayAreaEvent(areaId));
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                AppIconWidget(
                  icon: isSelected
                      ? HugeIcons.strokeRoundedPlayCircle02
                      : HugeIcons.strokeRoundedCircle,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 26,
                ),
                16.horizontalSpace,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cityName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subTitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Arrow icon is now a separate button for navigation only
            IconButton(
              icon: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DummyAreaDetailsPage(areaName: cityName),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
