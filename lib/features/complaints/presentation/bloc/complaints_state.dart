import 'package:equatable/equatable.dart';
import 'package:qatrah/features/complaints/domain/entities/complaints_entity.dart';

abstract class ComplaintsState extends Equatable {
  const ComplaintsState();
  @override
  List<Object?> get props => [];
}

class ComplaintsInitial extends ComplaintsState {}

class ComplaintsLoading extends ComplaintsState {}

class ComplaintsLoaded extends ComplaintsState {
  const ComplaintsLoaded(
    this.complaints, {
    this.currentPage = 0,
    this.hasMore = true,
    this.fetchingNextPage = false,
  });
  final List<ComplaintEntity> complaints;
  final int currentPage;
  final bool hasMore;
  final bool fetchingNextPage;

  @override
  List<Object?> get props => [
    complaints,
    currentPage,
    hasMore,
    fetchingNextPage,
  ];

  ComplaintsLoaded copyWith({
    List<ComplaintEntity>? complaints,
    int? currentPage,
    bool? hasMore,
    bool? fetchingNextPage,
  }) {
    return ComplaintsLoaded(
      complaints ?? this.complaints,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      fetchingNextPage: fetchingNextPage ?? this.fetchingNextPage,
    );
  }
}

class ComplaintSubmitSuccess extends ComplaintsState {}

class ComplaintRespondSuccess extends ComplaintsState {}

class ComplaintsError extends ComplaintsState {
  const ComplaintsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
