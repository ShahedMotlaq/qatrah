import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/features/home/presentation/bloc/home_bloc.dart';
import 'package:qatrah/features/home/presentation/bloc/home_state.dart';
import 'package:qatrah/features/home/presentation/widgets/current_pumping_status_widget.dart';
import 'package:qatrah/features/home/presentation/widgets/expanded_area_selection_widget.dart';

class MainContentSwitcherWidget extends StatelessWidget {
  const MainContentSwitcherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (previous, current) =>
          previous.isAreaSelectionExpanded != current.isAreaSelectionExpanded,
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: state.isAreaSelectionExpanded
              ? const ExpandedAreaSelectionWidget()
              : const CurrentPumpingStatusWidget(),
        );
      },
    );
  }
}
