import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/src/app/view/widgets/dynamic_input_widget.dart';
import 'package:frontend/src/utils/extension/int_validator.dart';
import 'package:frontend/src/utils/validators/validators.dart';

class StepNumberScreen extends ConsumerStatefulWidget {
  const StepNumberScreen({super.key});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _StepNumberScreenState();
}

class _StepNumberScreenState extends ConsumerState<StepNumberScreen> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    _controller.addListener(
      () {
        final text = _controller.text;
        debugPrint(text);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: NumericalInputField(
        textInputType: TextInputType.number,
        prefIcon: Icons.vpn_key_rounded,
        controller: _controller,
        textInputAction: TextInputAction.done,
        focusNode: _focusNode,
        labelText: const Text("K-step"),
        validator: Validator.stepNumberValidator,
      ),
    );
  }
}
