import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';

InputDecoration fieldDecoration(String hint, {Widget? suffix, String? error}) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30),
      suffixIcon: suffix,
      errorText: error,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.trailing});
  final String text;
  final String? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 18),
        child: Row(children: [
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (trailing != null) Text(trailing!, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
      );
}

const fieldText = TextStyle(color: Colors.white);

/// A single-choice dropdown over value → label.
class ChoiceField extends StatelessWidget {
  const ChoiceField({super.key, required this.value, required this.options, required this.onChanged, this.hint = 'Choose'});
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;
  final String hint;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        initialValue: options.containsKey(value) ? value : null,
        isExpanded: true,
        dropdownColor: AppColors.darkSurface2,
        style: fieldText,
        decoration: fieldDecoration(hint),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('—', style: TextStyle(color: Colors.white38))),
          ...options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
        ],
        onChanged: onChanged,
      );
}
