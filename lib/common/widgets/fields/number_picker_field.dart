import 'package:clock_app/common/widgets/fields/numpad_input.dart';
import 'package:flutter/material.dart';

class NumberPickerField<T> extends StatefulWidget {
  const NumberPickerField({
    Key? key,
    required this.title,
    this.description,
    required this.onChange,
    required this.value,
  }) : super(key: key);

  final int value;
  final String title;
  final String? description;
  final void Function(int) onChange;

  @override
  State<NumberPickerField<T>> createState() => _NumberPickerFieldState<T>();
}

enum SelectType { color, text }

class _NumberPickerFieldState<T> extends State<NumberPickerField<T>> {
  @override
  void initState() {
    super.initState();
    // _currentSelectedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    void showPicker() async {
      int? newValue = (await showNumberPicker(
        context,
        initialNumber: widget.value
      ));
      if (newValue == null) return;
      setState(() {
        widget.onChange(newValue);
      });
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: showPicker,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    widget.value.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const Spacer(),
              Icon(
                Icons.numbers_outlined,
                color:
                    Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              )
            ],
          ),
        ),
      ),
    );
  }
}
