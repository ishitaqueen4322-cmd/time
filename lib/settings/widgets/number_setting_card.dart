import 'package:clock_app/common/widgets/card_container.dart';
import 'package:clock_app/common/widgets/fields/duration_picker_field.dart';
import 'package:clock_app/common/widgets/fields/number_picker_field.dart';
import 'package:clock_app/settings/types/setting.dart';
import 'package:clock_app/timer/types/time_duration.dart';
import 'package:flutter/material.dart';

class NumberSettingCard extends StatefulWidget {
  const NumberSettingCard(
      {super.key,
      required this.setting,
      this.showAsCard = false,
      this.onChanged});

  final NumberSetting setting;
  final bool showAsCard;
  final void Function(double)? onChanged;

  @override
  State<NumberSettingCard> createState() => _NumberSettingCardState();
}

class _NumberSettingCardState<T> extends State<NumberSettingCard> {
  @override
  Widget build(BuildContext context) {
    NumberPickerField toggleCard = NumberPickerField(
      title: widget.setting.displayName(context),
      value: widget.setting.value.round(),
      onChange: (value) {
        setState(() {
          widget.setting.setValue(context, value.toDouble());
        });

        widget.onChanged?.call(widget.setting.value);
      },
    );

    return widget.showAsCard ? CardContainer(child: toggleCard) : toggleCard;
  }
}
