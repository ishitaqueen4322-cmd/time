import 'package:clock_app/common/widgets/modal.dart';
import 'package:clock_app/theme/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

Future<int?> showNumberPicker(
  BuildContext context, {
  String? title,
  int initialNumber = 0,
}) async {
  final theme = Theme.of(context);
  final textTheme = theme.textTheme;
  final colorScheme = theme.colorScheme;

  return showDialog<int>(
    context: context,
    builder: (BuildContext context) {
      int number = initialNumber;

      return StatefulBuilder(
        builder: (context, StateSetter setState) {
          return Modal(
            onSave: () => Navigator.of(context).pop(number),
            // title: "Choose Duration",
            child: Builder(
              builder: (context) {
                // Get available height and width of the build area of this widget. Make a choice depending on the size.
                Orientation orientation = MediaQuery.of(context).orientation;

                Widget label() => Text(
                      title ?? "",
                      style: textTheme.displayMedium,
                    );

                Widget numpad() => NumpadInput(
                      title: "Select Number",
                      value: number,
                      onChange: (int newNumber) {
                        setState(() {
                          number = newNumber;
                        });
                      },
                    );

                return orientation == Orientation.portrait
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 16),
                          if (title != null) label(),
                          const SizedBox(height: 16),
                          numpad(),
                        ],
                      )
                    : Row(children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            // mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              if (title != null) label(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: Column(
                            // mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 16),
                              numpad(),
                            ],
                          ),
                        ),
                      ]);
              },
            ),
          );
        },
      );
    },
  );
}

class NumpadInput extends StatefulWidget {
  NumpadInput(
      {super.key,
      required this.title,
      required this.value,
      required this.onChange});

  final String title;
  final int value;
  final void Function(int) onChange;

  @override
  State<NumpadInput> createState() => _NumpadInputState();
}

class _NumpadInputState extends State<NumpadInput> {
  bool isEmpty = false;

  @override
  void initState() {
    super.initState();
  }

  List<String> getTimeInput() {
    return widget.value.toString().split("");
  }

  void _addDigit(String digit) {
    setState(() {
      final timeInput = getTimeInput();

      //remove the final 0
      if (isEmpty) {
        timeInput.removeLast();
        isEmpty = false;
      }
      timeInput.add(digit);

      _update(timeInput);
    });
  }

  void _removeDigit() {
    setState(() {
      final timeInput = getTimeInput();
      if (timeInput.isNotEmpty) {
        timeInput.removeLast();
      }
      isEmpty = timeInput.isEmpty;
      if (isEmpty) {
        timeInput.add("0");
      }
      _update(timeInput);
    });
  }

  void _update(List<String> timeInput) {
    widget.onChange(int.parse(timeInput.join("")));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final labelStyle = textTheme.headlineLarge
        ?.copyWith(color: colorScheme.onSurface, height: 1);

    final grayedLabelStyle =
        labelStyle?.copyWith(color: colorScheme.onSurface.withOpacity(0.5));

    double originalWidth = MediaQuery.of(context).size.width;

    final value = NumberFormat.decimalPattern().format(widget.value);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: isEmpty ? grayedLabelStyle : labelStyle),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: originalWidth * 0.76,
          height: originalWidth * 1.1,
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shrinkWrap: true,
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < 9) {
                return TimerButton(
                  label: (index + 1).toString(),
                  onTap: () => _addDigit((index + 1).toString()),
                );
              } else if (index == 9) {
                return TimerButton(isSpacer: true, label: "", onTap: () {});
              } else if (index == 10) {
                return TimerButton(
                  label: "0",
                  onTap: () => _addDigit("0"),
                );
              } else {
                return TimerButton(
                  isHighlighted: true,
                  icon: Icons.backspace_outlined,
                  onTap: _removeDigit,
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class TimerButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isHighlighted;
  final bool isSpacer;

  const TimerButton(
      {super.key,
      this.label,
      required this.onTap,
      this.icon,
      this.isHighlighted = false,
      this.isSpacer = false});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    ColorScheme colorScheme = theme.colorScheme;
    TextTheme textTheme = theme.textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        decoration: BoxDecoration(
          color: isSpacer
              ? colorScheme.primary.withOpacity(0.0)
              : isHighlighted
                  ? colorScheme.primary.withOpacity(0.2)
                  : colorScheme.onBackground.withOpacity(0.1),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
            child: label != null
                ? Text(
                    label!,
                    style: textTheme.titleMedium
                        ?.copyWith(color: colorScheme.onSurface),
                  )
                : icon != null
                    ? Icon(icon, color: colorScheme.onSurface)
                    : Container()),
      ),
    );
  }
}
