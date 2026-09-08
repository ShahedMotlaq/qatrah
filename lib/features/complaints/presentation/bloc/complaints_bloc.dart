import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/features/complaints/domain/entities/complaints_entity.dart';
import 'package:qatrah/features/complaints/domain/usecases/complaint_usecases.dart';
import 'package:qatrah/features/complaints/presentation/bloc/complaints_event.dart';
import 'package:qatrah/features/complaints/presentation/bloc/complaints_state.dart';

class ComplaintsBloc extends Bloc<ComplaintsEvent, ComplaintsState> {
  ComplaintsBloc(
    this._getMyComplaints,
    this._getScopedComplaintsForEmployee,
    this._createComplaint,
    this._respondToComplaint,
  ) : super(ComplaintsInitial()) {
    on<FetchMyComplaintsEvent>(_onFetchMyComplaints);
    on<FetchAllComplaintsEvent>(_onFetchAllComplaints);
    on<SearchComplaintsEvent>(_onSearchComplaints);
    on<CreateComplaintSubmittedEvent>(_onCreateComplaint);
    on<RespondToComplaintEvent>(_onRespondToComplaint);
    on<FetchMoreMyComplaintsEvent>(_onFetchMoreMyComplaints);
    on<FetchMoreAllComplaintsEvent>(_onFetchMoreAllComplaints);
  }

  final GetMyComplaintsUseCase _getMyComplaints;
  final GetScopedComplaintsForEmployeeUseCase _getScopedComplaintsForEmployee;
  final CreateComplaintUseCase _createComplaint;
  final RespondToComplaintUseCase _respondToComplaint;

  static const int _pageSize = 20;

  Future<void> _onFetchMyComplaints(
    FetchMyComplaintsEvent event,
    Emitter<ComplaintsState> emit,
  ) async {
    emit(ComplaintsLoading());
    final result = await _getMyComplaints();
    result.fold(
      (failure) => emit(ComplaintsError(failure.errMessage)),
      (paginated) => emit(
        ComplaintsLoaded(
          paginated.items,
          currentPage: paginated.currentPage,
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }

  Future<void> _onFetchAllComplaints(
    FetchAllComplaintsEvent event,
    Emitter<ComplaintsState> emit,
  ) async {
    emit(ComplaintsLoading());
    final result = await _getScopedComplaintsForEmployee();
    result.fold(
      (failure) => emit(ComplaintsError(failure.errMessage)),
      (paginated) => emit(
        ComplaintsLoaded(
          paginated.items,
          currentPage: paginated.currentPage,
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }

  Future<void> _onFetchMoreMyComplaints(
    FetchMoreMyComplaintsEvent event,
    Emitter<ComplaintsState> emit,
  ) async {
    final current = state;
    if (current is! ComplaintsLoaded) return;
    if (current.fetchingNextPage || !current.hasMore) return;

    emit(current.copyWith(fetchingNextPage: true));
    final nextPage = current.currentPage + 1;
    final result = await _getMyComplaints(page: nextPage);
    result.fold(
      (failure) => emit(current.copyWith(fetchingNextPage: false)),
      (paginated) {
        final combined = [...current.complaints, ...paginated.items];
        final deduped = _dedup(combined);
        emit(
          ComplaintsLoaded(
            deduped,
            currentPage: paginated.currentPage,
            hasMore: paginated.hasMore,
          ),
        );
      },
    );
  }

  Future<void> _onFetchMoreAllComplaints(
    FetchMoreAllComplaintsEvent event,
    Emitter<ComplaintsState> emit,
  ) async {
    final current = state;
    if (current is! ComplaintsLoaded) return;
    if (current.fetchingNextPage || !current.hasMore) return;

    emit(current.copyWith(fetchingNextPage: true));
    final nextPage = current.currentPage + 1;
    final result = await _getScopedComplaintsForEmployee(
      page: nextPage,
    );
    result.fold(
      (failure) => emit(current.copyWith(fetchingNextPage: false)),
      (paginated) {
        final combined = [...current.complaints, ...paginated.items];
        final deduped = _dedup(combined);
        emit(
          ComplaintsLoaded(
            deduped,
            currentPage: paginated.currentPage,
            hasMore: paginated.hasMore,
          ),
        );
      },
    );
  }

  Future<void> _onSearchComplaints(
    SearchComplaintsEvent event,
    Emitter<ComplaintsState> emit,
  ) async {
    emit(ComplaintsLoading());
    final result = await _getMyComplaints();
    result.fold(
      (failure) => emit(ComplaintsError(failure.errMessage)),
      (paginated) {
        final filtered = paginated.items
            .where(
              (c) =>
                  c.title.toLowerCase().contains(event.query.toLowerCase()) ||
                  c.description.toLowerCase().contains(
                    event.query.toLowerCase(),
                  ),
            )
            .toList();
        emit(
          ComplaintsLoaded(
            filtered,
            currentPage: paginated.currentPage,
            hasMore: false,
          ),
        );
      },
    );
  }

  Future<void> _onCreateComplaint(
    CreateComplaintSubmittedEvent event,
    Emitter<ComplaintsState> emit,
  ) async {
    emit(ComplaintsLoading());
    final result = await _createComplaint(
      event.title,
      event.description,
      event.category,
    );
    result.fold(
      (failure) => emit(ComplaintsError(failure.errMessage)),
      (_) {
        emit(ComplaintSubmitSuccess());
        add(const FetchMyComplaintsEvent());
      },
    );
  }

  Future<void> _onRespondToComplaint(
    RespondToComplaintEvent event,
    Emitter<ComplaintsState> emit,
  ) async {
    final result = await _respondToComplaint(
      id: event.complaintId,
      response: event.response,
      status: event.status,
    );
    result.fold(
      (failure) => emit(ComplaintsError(failure.errMessage)),
      (_) {
        emit(ComplaintRespondSuccess());
        // Respond is only reachable from the admin/employee scoped list, so
        // always reload that scope (don't gate on the previous state).
        add(const FetchAllComplaintsEvent());
      },
    );
  }

  List<ComplaintEntity> _dedup(List<ComplaintEntity> items) {
    final seen = <int>{};
    return items.where((item) => seen.add(item.id)).toList();
  }
}
