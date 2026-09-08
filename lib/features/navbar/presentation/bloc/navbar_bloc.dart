import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/features/navbar/presentation/bloc/navbar_event.dart';
import 'package:qatrah/features/navbar/presentation/bloc/navbar_state.dart';

class NavbarBloc extends Bloc<NavbarEvent, NavbarState> {
  NavbarBloc() : super(const NavbarState()) {
    on<ChangeBottomNavTabEvent>((event, emit) {
      emit(state.copyWith(currentTabIndex: event.index));
    });
  }
}
