import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/features/profile/presentation/widgets/profile_info_card_widget.dart';

class LocationCardWidget extends StatelessWidget {
  const LocationCardWidget({
    required this.title,
    required this.region,
    required this.zone,
    required this.unit,
    required this.neighborhood,
    super.key,
    this.onTap,
  });

  final String title;
  final String region;
  final String zone;
  final String unit;
  final String neighborhood;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ProfileInfoCard(
      title: title,
      icon: HugeIcons.strokeRoundedLocation04,
      onTap: onTap,
      rows: [
        (
          icon: HugeIcons.strokeRoundedMaps,
          label: l10n.regionLabelWithColon,
          value: region,
        ),
        (
          icon: HugeIcons.strokeRoundedBuilding03,
          label: l10n.unitLabelWithColon,
          value: unit,
        ),
        (
          icon: HugeIcons.strokeRoundedHome01,
          label: l10n.neighborhoodLabelWithColon,
          value: neighborhood,
        ),
        (
          icon: HugeIcons.strokeRoundedLocation04,
          label: l10n.zoneLabelWithColon,
          value: zone,
        ),
      ],
    );
  }
}
