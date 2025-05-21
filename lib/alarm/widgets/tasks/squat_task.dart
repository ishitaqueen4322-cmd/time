import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';
import 'package:clock_app/common/widgets/card_container.dart';
import 'package:clock_app/settings/types/setting_group.dart';
import 'package:flutter/material.dart';

class SquatTask extends StatefulWidget {
  const SquatTask({
    super.key,
    required this.onSolve,
    required this.settings,
  });

  final VoidCallback onSolve;
  final SettingGroup settings;

  @override
  State<SquatTask> createState() => _SquatTaskState();
}

class _SquatTaskState extends State<SquatTask> with TickerProviderStateMixin {
  late final int numberOfSquats =
      widget.settings.getSetting("numberOfSquats").value.toInt();
  late final StreamSubscription<AccelerometerEvent> _accelStream;
  late final StreamSubscription<BarometerEvent> _barStream;

  final List<BarometerEvent> barometerSamples = [];
  final List<AccelerometerEvent> accelerometerSamples = [];

  late int squatsCompleted = 0;

  @override
  void initState() {
    super.initState();
    _accelStream = accelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: 50))
        .listen((AccelerometerEvent event) {
      accelerometerSamples.add(event);
      _dropOldSensorEvents();
      _updateSquatSensorData();
    });
    _barStream =
        barometerEventStream(samplingPeriod: const Duration(milliseconds: 50))
            .listen((BarometerEvent event) {
      barometerSamples.add(event);
      _dropOldSensorEvents();
      _updateSquatSensorData();
    });
  }

  double oldAccelSecond = 0.0;
  DateTime? lastSquatTime;
  String falseSquatAdmonish = "";

  bool _isFakeSquat(DateTime start, DateTime end) {
    double average_accel_z = 0.0;
    double average_accel_x = 0.0;
    double count = 0.0;

    double avg_jerk_y = 0.0;

    double squatTimeSeconds =
        end.difference(start).inMilliseconds.toDouble() / 1000.0;

    double barMin = double.infinity;
    double barMax = double.negativeInfinity;

    for (BarometerEvent bar in barometerSamples.reversed) {
      if (bar.timestamp.isAfter(end)) continue;
      if (bar.timestamp.isBefore(start)) break;

      barMin = min(bar.pressure, barMin);
      barMax = max(bar.pressure, barMax);
    }

    final double barRange = barMax - barMin;

    AccelerometerEvent nextEvent = accelerometerSamples.last;
    for (AccelerometerEvent accel in accelerometerSamples.reversed) {
      if (accel.timestamp.isAfter(end)) continue;
      if (accel.timestamp.isBefore(start)) break;

      count++;
      average_accel_z += (accel.z - average_accel_z) / count;
      average_accel_x += (accel.x - average_accel_x) / count;

      final Duration timeDifference =
          nextEvent.timestamp.difference(accel.timestamp);
      final double dtSeconds =
          (timeDifference.inMilliseconds.toDouble() / 1000.0);

      final jerk_y = (nextEvent.y - accel.y) / dtSeconds;
      avg_jerk_y += (jerk_y - avg_jerk_y) / count;

      nextEvent = accel;
    }

    if(barRange <= 0.05) {
      setState(() {
        falseSquatAdmonish = "Make sure to have a full range of motion!";
      });
      return true;
    }

    if (squatTimeSeconds <= 1.0) {
      setState(() {
        falseSquatAdmonish = "Move slower!";
      });
      return true;
    }

    if (average_accel_z.abs() >= 2 || average_accel_x.abs() >= 2) {
      setState(() {
        falseSquatAdmonish = "Keep your phone steady and vertical!";
      });
      return true;
    }

    if (avg_jerk_y.abs() >= 0.1) {
      setState(() {
        falseSquatAdmonish = "Be steady with your movement!";
      });
      return true;
    }

    setState(() {
      falseSquatAdmonish = "";
    });
    return false;
  }

  void _updateSquatSensorData() {
    double accelSecond = _lowPassAccel();

    if (oldAccelSecond > 10.5 && accelSecond <= 10.5) {
      if (lastSquatTime == null ||
          !_isFakeSquat(lastSquatTime!, DateTime.now())) {
        final int squats = squatsCompleted + 1;
        lastSquatTime = DateTime.now();
        if (squats >= numberOfSquats) {
          widget.onSolve();
        } else {
          setState(() {
            squatsCompleted = squats;
          });
        }
      }
    }

    oldAccelSecond = accelSecond;
  }

  double _lowPassAccel() {
    //use an average to put a low pass filter on the last second's worth of data
    double avg = 0.0;
    double count = 0.0;

    DateTime oldest =
        DateTime.now().subtract(const Duration(milliseconds: 250));

    for (AccelerometerEvent accel in accelerometerSamples.reversed) {
      count++;
      avg += (accel.y - avg) / count;

      if (accel.timestamp.isBefore(oldest)) break;
    }

    return avg;
  }

  void _dropOldSensorEvents() {
    DateTime oldestNonDropped =
        DateTime.now().subtract(const Duration(milliseconds: 4000));

    int accelerometerFirstValidIndex = accelerometerSamples
        .indexWhere((samp) => samp.timestamp.isAfter(oldestNonDropped));
    if (accelerometerFirstValidIndex == -1) {
      accelerometerFirstValidIndex = accelerometerSamples.length;
    }
    accelerometerSamples.removeRange(0, accelerometerFirstValidIndex);

    int barometerFirstValidIndex = barometerSamples
        .indexWhere((samp) => samp.timestamp.isAfter(oldestNonDropped));
    if (barometerFirstValidIndex == -1) {
      barometerFirstValidIndex = barometerSamples.length;
    }
    barometerSamples.removeRange(0, barometerFirstValidIndex);
  }

  @override
  void dispose() {
    super.dispose();
    _accelStream.cancel();
    _barStream.cancel();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    ColorScheme colorScheme = theme.colorScheme;
    TextTheme textTheme = theme.textTheme;

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
                  squatsCompleted.toString(),
                  style: textTheme.displayLarge,
                ),
                Text(
                  "/",
                  style: textTheme.displayMedium,
                ),
                Text(
                  numberOfSquats.toString(),
                  style: textTheme.displayMedium,
                ),
              ]),
          Text(
            "Squats Completed",
            style: textTheme.headlineLarge,
          ),
          const SizedBox(height: 16.0),
          Text(
            falseSquatAdmonish,
            textAlign: TextAlign.center,
            style: textTheme.headlineLarge?.copyWith(color: colorScheme.error),
          ),
        ],
      ),
    );
  }
}
