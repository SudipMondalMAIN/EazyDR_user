import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Six separate boxes for OTP entry, matching the reference design.
class OtpBoxes extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final int length;
  const OtpBoxes({super.key, required this.onChanged, this.length = 6});

  @override
  State<OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<OtpBoxes> {
  late final List<TextEditingController> _ctrls =
      List.generate(widget.length, (_) => TextEditingController());
  late final List<FocusNode> _nodes =
      List.generate(widget.length, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(_ctrls.map((c) => c.text).join());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) {
        return SizedBox(
          width: 46,
          height: 52,
          child: TextField(
            controller: _ctrls[i],
            focusNode: _nodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: theme.textTheme.titleLarge,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(counterText: ''),
            onChanged: (v) {
              if (v.isNotEmpty && i < widget.length - 1) {
                _nodes[i + 1].requestFocus();
              } else if (v.isEmpty && i > 0) {
                _nodes[i - 1].requestFocus();
              }
              _emit();
            },
          ),
        );
      }),
    );
  }
}
