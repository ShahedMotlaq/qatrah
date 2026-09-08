import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Small cubit to control the otp field input using a single controller
class OtpInputCubit extends Cubit<void> {
  OtpInputCubit() : super(null);

  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  String get otpCode => controller.text;

  void clearAndFocus() {
    controller.clear();
    focusNode.requestFocus();
    emit(null);
  }

  @override
  Future<void> close() {
    controller.dispose();
    focusNode.dispose();
    return super.close();
  }
}
