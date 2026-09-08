import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/widgets/app_failure_view.dart';
import 'package:qatrah/core/widgets/app_loading_widget.dart';
import 'package:qatrah/features/home/domain/entities/pumping_status_entity.dart';
import 'package:qatrah/features/home/domain/repositories/i_home_repository.dart';
import 'package:qatrah/features/home/presentation/bloc/home_state.dart';
import 'package:qatrah/features/home/presentation/widgets/current_pumping_status_widget.dart';

/// Read-only viewer for the pumping status of a *specific* saved address,
/// shown from the "My Addresses" page. It never changes the default location —
/// it just fetches that address's zone/neighbourhood status and renders the
/// same cards used on the home screen.
class AddressPumpingStatusSheet extends StatefulWidget {
  const AddressPumpingStatusSheet({
    required this.zoneId,
    required this.neighborhoodId,
    super.key,
  });

  final int? zoneId;
  final int? neighborhoodId;

  @override
  State<AddressPumpingStatusSheet> createState() =>
      _AddressPumpingStatusSheetState();
}

class _AddressPumpingStatusSheetState extends State<AddressPumpingStatusSheet> {
  bool _loading = true;
  String? _error;
  List<PumpingStatusEntity> _status = const [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await getIt<IHomeRepository>().getPumpingStatus(
      neighborhoodId: widget.neighborhoodId,
      zoneId: widget.zoneId,
      isDefault: false,
    );

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.errMessage;
      }),
      (list) => setState(() {
        _loading = false;
        _status = list;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 8.h,
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: const Center(child: AppLoadingWidget(size: 48)),
      );
    }

    if (_error != null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: AppFailureView(message: _error!, onRetry: _fetch),
      );
    }

    // Reuse the home's display-mode selection + card widgets by feeding the
    // fetched list into a throwaway HomeState (its selectors derive purely
    // from pumpingStatus).
    return PumpingModeCard(
      state: HomeState(pumpingStatus: _status, isLoading: false),
    );
  }
}
