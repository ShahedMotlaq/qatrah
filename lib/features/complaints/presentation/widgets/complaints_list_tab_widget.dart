import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_empty_state_widget.dart';
import 'package:qatrah/core/widgets/app_failure_view.dart';
import 'package:qatrah/core/widgets/app_loading_widget.dart';
import 'package:qatrah/core/widgets/app_refresh_indicator.dart';
import 'package:qatrah/features/complaints/presentation/bloc/complaints_bloc.dart';
import 'package:qatrah/features/complaints/presentation/bloc/complaints_event.dart';
import 'package:qatrah/features/complaints/presentation/bloc/complaints_state.dart';
import 'package:qatrah/features/complaints/presentation/widgets/complaint_card_widget.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/toast_service.dart';

class ComplaintsListTabWidget extends StatefulWidget {
  const ComplaintsListTabWidget({
    required this.statusFilter,
    super.key,
    this.isAdminView = false,
  });

  final String statusFilter;
  final bool isAdminView;

  @override
  State<ComplaintsListTabWidget> createState() =>
      _ComplaintsListTabWidgetState();
}

class _ComplaintsListTabWidgetState extends State<ComplaintsListTabWidget> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.7;

    if (currentScroll >= threshold) {
      final state = context.read<ComplaintsBloc>().state;
      if (state is ComplaintsLoaded &&
          state.hasMore &&
          !state.fetchingNextPage) {
        if (widget.isAdminView) {
          context.read<ComplaintsBloc>().add(FetchMoreAllComplaintsEvent());
        } else {
          context.read<ComplaintsBloc>().add(FetchMoreMyComplaintsEvent());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppRefreshIndicator(
      onRefresh: () async {
        final completer = Completer<void>();
        final bloc = context.read<ComplaintsBloc>();

        if (widget.isAdminView) {
          bloc.add(const FetchAllComplaintsEvent());
        } else {
          bloc.add(const FetchMyComplaintsEvent());
        }

        late StreamSubscription sub;
        sub = bloc.stream.listen((state) {
          if (state is ComplaintsLoaded || state is ComplaintsError) {
            if (!completer.isCompleted) completer.complete();
            sub.cancel();
          }
        });

        return completer.future;
      },
      child: BlocListener<ComplaintsBloc, ComplaintsState>(
        listenWhen: (_, current) => current is ComplaintRespondSuccess,
        listener: (context, state) {
          if (state is ComplaintRespondSuccess) {
            getIt<ToastService>().showSuccess(
              context.l10n.complaintRespondSuccess,
            );
          }
        },
        child: BlocBuilder<ComplaintsBloc, ComplaintsState>(
          builder: (context, state) {
            if (state is ComplaintsLoading) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: const Center(child: AppLoadingWidget(size: 60)),
                  ),
                ],
              );
            } else if (state is ComplaintsError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: AppFailureView(
                      message: _mapComplaintError(context, state.message),
                      onRetry: () {
                        final bloc = context.read<ComplaintsBloc>();
                        if (widget.isAdminView) {
                          bloc.add(const FetchAllComplaintsEvent());
                        } else {
                          bloc.add(const FetchMyComplaintsEvent());
                        }
                      },
                    ),
                  ),
                ],
              );
            } else if (state is ComplaintsLoaded) {
              final filtered = state.complaints
                  .where((c) => c.status == widget.statusFilter)
                  .toList();

              if (filtered.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: AppEmptyState(
                        message: l10n.noComplaintsInThisSection,
                        icon: HugeIcons.strokeRoundedFileSearch,
                      ),
                    ),
                  ],
                );
              }

              return ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => 10.verticalSpace,
                itemBuilder: (context, index) {
                  final complaint = filtered[index];
                  return ComplaintCardWidget(
                    complaintId: complaint.id,
                    title: complaint.title,
                    description: complaint.description,
                    status: complaint.status,
                    date: DateFormat('yyyy-MM-dd').format(complaint.createdAt),
                    adminResponse: complaint.adminResponse,
                    userName: complaint.userName,
                    userPhone: complaint.userPhone,
                    isAdminView: widget.isAdminView,
                  );
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  String _mapComplaintError(BuildContext context, String message) {
    final l10n = context.l10n;
    switch (message.trim()) {
      case 'errorFetchingData':
        return l10n.errorFetchingData;
      case 'errorUpdatingData':
        return l10n.errorUpdatingData;
      case 'forbidden':
        return l10n.forbidden;
      default:
        return l10n.errorOccurred;
    }
  }
}
