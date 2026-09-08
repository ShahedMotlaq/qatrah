import 'package:equatable/equatable.dart';

abstract class ComplaintsEvent extends Equatable {
  const ComplaintsEvent();
  @override
  List<Object?> get props => [];
}

class FetchMyComplaintsEvent extends ComplaintsEvent {
  const FetchMyComplaintsEvent({this.page = 0});
  final int page;
  @override
  List<Object?> get props => [page];
}

class FetchAllComplaintsEvent extends ComplaintsEvent {
  const FetchAllComplaintsEvent({this.page = 0});
  final int page;
  @override
  List<Object?> get props => [page];
}

class FetchMoreMyComplaintsEvent extends ComplaintsEvent {}

class FetchMoreAllComplaintsEvent extends ComplaintsEvent {}

class SearchComplaintsEvent extends ComplaintsEvent {
  const SearchComplaintsEvent({required this.query, this.page = 0});
  final String query;
  final int page;
  @override
  List<Object?> get props => [query, page];
}

class CreateComplaintSubmittedEvent extends ComplaintsEvent {
  const CreateComplaintSubmittedEvent({
    required this.title,
    required this.description,
    required this.category,
  });
  final String title;
  final String description;
  final String category;

  @override
  List<Object?> get props => [title, description, category];
}

class RespondToComplaintEvent extends ComplaintsEvent {
  const RespondToComplaintEvent({
    required this.complaintId,
    required this.response,
    this.status = 'RESOLVED',
  });
  final int complaintId;
  final String response;
  final String status;

  @override
  List<Object?> get props => [complaintId, response, status];
}
