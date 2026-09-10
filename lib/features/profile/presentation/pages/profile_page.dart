import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/network/network_status_cubit.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/widgets/app_background_widget.dart';
import 'package:qatrah/core/widgets/app_failure_view.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/appbar/qatrah_appbar_widget.dart';
import 'package:qatrah/core/widgets/appdialog/showApp_bottom_sheet_widget.dart';
import 'package:qatrah/core/widgets/no_internet_widget.dart';
import 'package:qatrah/features/auth/domain/entities/assigned_region_entity.dart';
import 'package:qatrah/features/auth/domain/entities/user_entity.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_event.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_state.dart';
import 'package:qatrah/features/profile/presentation/widgets/edit_location_bottom_sheet.dart';
import 'package:qatrah/features/profile/presentation/widgets/edit_name_bottom_sheet.dart';
import 'package:qatrah/features/profile/presentation/widgets/location_card_widget.dart';
import 'package:qatrah/features/profile/presentation/widgets/profile_error_message.dart';
import 'package:qatrah/features/profile/presentation/widgets/profile_info_card_widget.dart';
import 'package:qatrah/features/profile/presentation/widgets/user_card_widget.dart';
import 'package:qatrah/l10n/gen/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MultiBlocProvider(
      providers: [
        BlocProvider<NetworkStatusCubit>.value(
          value: getIt<NetworkStatusCubit>(),
        ),
        BlocProvider(
          create: (context) => getIt<EditProfileBloc>()
            ..add(LoadInitialProfileData())
            ..add(LoadUserLocationsEvent()),
        ),
      ],
      child: Scaffold(
        appBar: QatrahAppBarWidget(
          title: Text(l10n.profile),
        ),
        body: AppBackground(
          child: BlocBuilder<NetworkStatusCubit, NetworkStatusState>(
            builder: (context, networkState) {
              if (networkState.isOffline) {
                return NoInternetWidget(
                  isRetrying: networkState.isRechecking,
                  onRetry: () =>
                      context.read<NetworkStatusCubit>().recheckConnection(),
                );
              }

              return BlocBuilder<EditProfileBloc, EditProfileState>(
                builder: (context, state) {
                  if (state.user == null) {
                    if (state.errorMessage != null) {
                      return AppFailureView(
                        message: profileErrorMessage(l10n, state.errorMessage!),
                        onRetry: () => context.read<EditProfileBloc>().add(
                          LoadInitialProfileData(),
                        ),
                      );
                    }
                    return Skeletonizer(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 40.h),
                        child: _buildProfileContent(context, state, l10n),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<EditProfileBloc>().add(
                        LoadInitialProfileData(),
                      );
                      context.read<EditProfileBloc>().add(
                        LoadUserLocationsEvent(),
                      );
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 40.h),
                      child: _buildProfileContent(context, state, l10n),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    EditProfileState state,
    AppLocalizations l10n,
  ) {
    final user = state.user;
    final isLoading = user == null;
    final assignedGroups = user != null && user.isEmployee
        ? _assignedGroups(user)
        : const <AssignedRegionEntity>[];
    // Operators without a watched location are fully described by their
    // assigned units card, so the location section would only say "none".
    final showRoleSection =
        !state.isEmployee ||
        (user?.isAdmin ?? false) ||
        state.hasWatchedLocation ||
        assignedGroups.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        10.verticalSpace,
        UserCardWidget(
          isLoading: isLoading,
          fullName: isLoading
              ? 'أحمد شحادة الحريري'
              : _valueOrFallback(user.fullName, l10n.fullName),
          roleLabel: _roleLabel(user?.role, l10n),
          username: user?.username ?? '',
          isActive: user?.active,
          onEditTap: isLoading
              ? () {}
              : user.isCitizen
              ? () async {
                  context.read<EditProfileBloc>().add(ResetFormEvent());
                  await showAppBottomSheet(
                    context: context,
                    title: l10n.editData,
                    titleIcon: const AppIconWidget(
                      icon: HugeIcons.strokeRoundedEdit02,
                    ),
                    content: BlocProvider.value(
                      value: context.read<EditProfileBloc>(),
                      child: EditNameBottomSheet(
                        initialName: user.fullName,
                      ),
                    ),
                  );
                }
              : null,
        ),
        28.verticalSpace,
        _SectionHeader(title: l10n.accountGroup),
        10.verticalSpace,
        _buildAccountCard(user, l10n),

        // Role-specific card: citizen default location / operator watched
        // location / admin full-access statement.
        if (showRoleSection) ...[
          24.verticalSpace,
          _SectionHeader(title: _sectionTitle(user, l10n)),
          10.verticalSpace,
          _buildRoleSection(context, state, l10n),
        ],

        if (assignedGroups.isNotEmpty) ...[
          24.verticalSpace,
          _SectionHeader(title: l10n.professionalScope),
          10.verticalSpace,
          ProfileInfoCard(
            title: l10n.assignedUnits,
            icon: HugeIcons.strokeRoundedBuilding03,
            child: _AssignedUnitsList(groups: assignedGroups),
          ),
        ],

        32.verticalSpace,
      ],
    );
  }

  /// Identity + account state straight from `/users/me`. While loading, the
  /// placeholder values give the skeleton realistic row widths.
  Widget _buildAccountCard(UserEntity? user, AppLocalizations l10n) {
    final isActive = user?.active ?? true;
    return ProfileInfoCard(
      title: l10n.personalInformation,
      icon: HugeIcons.strokeRoundedUserAccount,
      rows: [
        if (user == null || user.username.trim().isNotEmpty)
          (
            icon: HugeIcons.strokeRoundedUser,
            label: l10n.username,
            value: user?.username.trim() ?? 'username',
          ),
        if (user == null || user.phoneNumber.trim().isNotEmpty)
          (
            icon: HugeIcons.strokeRoundedSmartPhone01,
            label: l10n.phoneNumber,
            value: user?.phoneNumber.trim() ?? '0954872922',
          ),
        (
          icon: HugeIcons.strokeRoundedUserShield01,
          label: l10n.role,
          value: _roleLabel(user?.role, l10n),
        ),
        (
          icon: isActive
              ? HugeIcons.strokeRoundedUserCheck01
              : HugeIcons.strokeRoundedUserBlock01,
          label: l10n.status,
          value: isActive ? l10n.active : l10n.inactive,
        ),
      ],
    );
  }

  String _roleLabel(String? role, AppLocalizations l10n) {
    return switch (role?.toUpperCase()) {
      'ADMIN' => l10n.admin,
      'OPERATOR' => l10n.operator,
      _ => l10n.citizen,
    };
  }

  /// Title shown above the single white card, per role.
  String _sectionTitle(UserEntity? user, AppLocalizations l10n) {
    if (user != null && user.role == 'ADMIN') return l10n.professionalScope;
    if (user?.isEmployee ?? false) return l10n.watchedLocation;
    return l10n.personalAddress;
  }

  /// The single white card under the section header.
  ///  • Admin    → a full-access statement (no region/hierarchy).
  ///  • Operator → the watched location only.
  ///  • Citizen  → the default location, or an add-location prompt.
  Widget _buildRoleSection(
    BuildContext context,
    EditProfileState state,
    AppLocalizations l10n,
  ) {
    final user = state.user;

    if (user != null && user.role == 'ADMIN') {
      return _buildAdminAccessCard(context, l10n);
    }

    if (state.isEmployee) {
      if (state.hasWatchedLocation) {
        return LocationCardWidget(
          title: l10n.watchedLocation,
          region: state.watchedRegion?.name ?? l10n.notSpecified,
          unit: state.watchedUnit?.name ?? l10n.notSpecified,
          neighborhood: state.watchedNeighborhood?.name ?? l10n.notSpecified,
          zone: state.watchedZone?.name ?? l10n.notSpecified,
          onTap: () => _openLocationEditor(context),
        );
      }
      return _CardEmptyState(
        message: l10n.noWatchedAreaAssigned,
        icon: HugeIcons.strokeRoundedNavigation01,
      );
    }

    // Citizen
    if (state.hasDefaultLocation) {
      return LocationCardWidget(
        title: l10n.myDefaultLocation,
        region: state.defaultRegion?.name ?? l10n.notSpecified,
        unit: state.defaultUnit?.name ?? l10n.notSpecified,
        neighborhood: state.defaultNeighborhood?.name ?? l10n.notSpecified,
        zone: state.defaultZone?.name ?? l10n.notSpecified,
        onTap: () => _openLocationEditor(context),
      );
    }

    return _buildAddLocationButton(context, l10n);
  }

  Future<void> _openLocationEditor(BuildContext context) async {
    await showAppBottomSheet(
      context: context,
      title: context.l10n.edit,
      titleIcon: AppIconWidget(
        icon: HugeIcons.strokeRoundedLocation04,
        color: Theme.of(context).colorScheme.primary,
      ),
      content: BlocProvider.value(
        value: context.read<EditProfileBloc>(),
        child: const EditLocationBottomSheet(),
      ),
    );
  }

  /// Admin white card: states the user is an admin with full (global) access.
  Widget _buildAdminAccessCard(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: AppIconWidget(
              icon: HugeIcons.strokeRoundedGlobal,
              size: 22.sp,
              color: theme.colorScheme.primary,
            ),
          ),
          14.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.globalAccess,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                4.verticalSpace,
                Text(
                  l10n.adminGlobalAccessDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddLocationButton(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        await showAppBottomSheet(
          context: context,
          title: l10n.selectLocation,
          titleIcon: AppIconWidget(
            icon: HugeIcons.strokeRoundedLocation04,
            color: theme.colorScheme.primary,
          ),
          content: BlocProvider.value(
            value: context.read<EditProfileBloc>(),
            child: const EditLocationBottomSheet(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 30.h),
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_location_alt_outlined,
              size: 32.sp,
              color: theme.colorScheme.primary,
            ),
            12.verticalSpace,
            Text(
              l10n.selectLocation,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Assigned units grouped by region. Falls back to one untitled group when
  /// the backend sent units without region info (or only bare unit IDs, as
  /// restored from storage by the profile repository).
  List<AssignedRegionEntity> _assignedGroups(UserEntity user) {
    if (user.assignedRegions.isNotEmpty) return user.assignedRegions;
    if (user.assignedUnits.isEmpty && user.assignedUnitNames.isEmpty) {
      return const [];
    }
    return [
      AssignedRegionEntity(
        regionId: 0,
        regionName: '',
        unitIds: user.assignedUnits,
        unitNames: user.assignedUnitNames,
      ),
    ];
  }

  String _valueOrFallback(String? value, String fallback) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallback;
    return trimmed;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _AssignedUnitsList extends StatelessWidget {
  const _AssignedUnitsList({required this.groups});

  final List<AssignedRegionEntity> groups;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, group) in groups.indexed) ...[
            if (i > 0) 14.verticalSpace,
            if (group.regionName.isNotEmpty) ...[
              Row(
                children: [
                  AppIconWidget(
                    icon: HugeIcons.strokeRoundedMaps,
                    size: 16.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  8.horizontalSpace,
                  Expanded(
                    child: Text(
                      group.regionName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              8.verticalSpace,
            ],
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final unit
                    in group.unitNames.isNotEmpty
                        ? group.unitNames
                        : group.unitIds.map((id) => '#$id'))
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                    child: Text(
                      unit,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CardEmptyState extends StatelessWidget {
  const _CardEmptyState({required this.message, required this.icon});

  final String message;
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 28.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: AppIconWidget(
              icon: icon,
              size: 28.sp,
              color: theme.colorScheme.primary,
            ),
          ),
          12.verticalSpace,
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
