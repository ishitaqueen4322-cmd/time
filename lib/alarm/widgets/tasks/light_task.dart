import 'dart:async';

import 'package:clock_app/common/widgets/linear_progress_bar.dart';
import 'package:light_sensor/light_sensor.dart';
import 'package:clock_app/settings/types/setting_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LightTask extends StatefulWidget {
  const LightTask({
    super.key,
    required this.onSolve,
    required this.settings,
  });

  final VoidCallback onSolve;
  final SettingGroup settings;

  @override
  State<LightTask> createState() => _LightTaskState();
}

class LightSample {
  const LightSample({required this.timestamp, required this.value});

  final DateTime timestamp;
  final int value;
}

class _LightTaskState extends State<LightTask> with TickerProviderStateMixin {
  late final double targetLux = widget.settings.getSetting("targetLux").value;
  late final StreamSubscription<int> _luxStream;
  final List<LightSample> lightSensorSamples = [];

  double lightValue = 0.0;

  @override
  void initState() {
    super.initState();

    //Start a check for whether the sensor exists;
    // if it doesn't, then immediately pass.
    LightSensor.hasSensor().then((hasSensor) {
      if(!hasSensor) {
        widget.onSolve();
      }
    });

    _luxStream = LightSensor.luxStream().listen((int lux) {
      lightSensorSamples
          .add(LightSample(timestamp: DateTime.now(), value: lux));
      _dropOldSensorEvents();
      _updateLightSensorData();
    });
  }

  void _updateLightSensorData() {
    double lightSecond = _lowPassLight();

    if (lightSecond > targetLux) {
      widget.onSolve();
    } else {
      setState(() {
        lightValue = lightSecond;
      });
    }
  }

  double _lowPassLight() {
    //use an average to put a low pass filter on the last second's worth of data
    double avg = 0.0;
    double count = 0.0;

    DateTime oldest =
        DateTime.now().subtract(const Duration(milliseconds: 500));

    for (LightSample samp in lightSensorSamples.reversed) {
      count++;
      avg += (samp.value.toDouble() - avg) / count;

      if (samp.timestamp.isBefore(oldest)) break;
    }

    return avg;
  }

  void _dropOldSensorEvents() {
    DateTime oldestNonDropped =
        DateTime.now().subtract(const Duration(milliseconds: 4000));

    int accelerometerFirstValidIndex = lightSensorSamples
        .indexWhere((samp) => samp.timestamp.isAfter(oldestNonDropped));
    if (accelerometerFirstValidIndex == -1) {
      accelerometerFirstValidIndex = lightSensorSamples.length;
    }
    lightSensorSamples.removeRange(0, accelerometerFirstValidIndex);
  }

  @override
  void dispose() {
    super.dispose();
    _luxStream.cancel();
  }

  static String _roundLux(double lux) {
    final rounded = (lux * 100).roundToDouble() / 100;

    if(rounded.truncateToDouble() == rounded) {
      return rounded.toInt().toString();
    } else {
      return rounded.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    ColorScheme colorScheme = theme.colorScheme;
    TextTheme textTheme = theme.textTheme;

    double percentageThere = lightValue / targetLux;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textBaseline: TextBaseline.alphabetic,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Text(
                  _roundLux(lightValue),
                  style: textTheme.displayLarge,
                ),
                Text(
                  AppLocalizations.of(context)!.luxUnitSuffix,
                  style: textTheme.displaySmall,
                ),
              ]),
          LinearProgressBar(
            backgroundColor: colorScheme.onSurface.withOpacity(0.25),
            value: percentageThere,
            color: colorScheme.secondary,
            minHeight: 18,
            semanticsLabel: AppLocalizations.of(context)!.lightProgressSemanticsLabel,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            Text(
              _roundLux(0.0) + AppLocalizations.of(context)!.luxUnitSuffix,
              style: textTheme.displaySmall,
            ),
            Text(
              _roundLux(targetLux) + AppLocalizations.of(context)!.luxUnitSuffix,
              style: textTheme.displaySmall,
            ),
          ]),
          const SizedBox(height: 16.0),
          Text(
            textAlign: TextAlign.center,
            lightValue < 10
                ? AppLocalizations.of(context)!.lightNoticeTurnOnLights
                : lightValue < 50
                    ? AppLocalizations.of(context)!.lightNoticeFaceScreen
                    : AppLocalizations.of(context)!.lightNoticeMoveCloser,
            style: textTheme.headlineLarge,
          ),
        ],
      ),
    );
  }
}
