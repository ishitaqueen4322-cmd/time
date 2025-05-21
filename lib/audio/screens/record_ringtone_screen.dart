import 'dart:io';
import 'dart:math';
import 'package:clock_app/audio/types/ringtone_player.dart';
import 'package:clock_app/common/types/file_item.dart';
import 'package:clock_app/common/utils/list_storage.dart';
import 'package:clock_app/common/utils/snackbar.dart';
import 'package:clock_app/common/widgets/fab.dart';
import 'package:clock_app/common/widgets/file_item_card.dart';
import 'package:clock_app/common/widgets/list/persistent_list_view.dart';
import 'package:clock_app/developer/logic/logger.dart';
import 'package:clock_app/navigation/widgets/app_top_bar.dart';
import 'package:clock_app/settings/types/setting_item.dart';
import 'package:clock_app/system/data/device_info.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:record/record.dart';

class RecordRingtoneScreen extends StatefulWidget {
  const RecordRingtoneScreen({
    super.key,
  });

  @override
  State<RecordRingtoneScreen> createState() => _RecordRingtoneScreenState();
}

class _RecordRingtoneScreenState extends State<RecordRingtoneScreen> {
  bool recording = false;
  DateTime? recordingStart;
  late Record recorder;

  @override
  void initState() {
    recorder = Record();
    super.initState();
  }

  @override
  void dispose() {
    RingtonePlayer.stop();
    recorder.dispose();
    super.dispose();
  }

  void _toggleRecord() {
    if (recording) {
      _stopRecord();
    } else {
      _beginRecord();
    }
  }

  void _stopRecord() async {
    if (!recording || recordingStart == null) return;

    try {
      final filename = (await recorder.stop())!;
      final file = File(filename);
      final bytes = await file.readAsBytes();

      final ringtoneList = await loadList<FileItem>("ringtones");
      final uri = await saveRingtone(path.basename(filename), bytes);
      ringtoneList.add(
        FileItem("Recording from ${recordingStart.toString()}", uri,
            FileItemType.audio),
      );
      await saveList("ringtones", ringtoneList);
    } catch (ex) {
      //this version of `record` is the latest that works
      //with sdk level 21, but it has an issue where spurious
      //errors can be thrown when stopping the record.
    } finally {
      setState(() {
        recording = false;
      });
    }
  }

  void _beginRecord() async {
    if (recording) return;

    if (await recorder.hasPermission()) {
      setState(() {
        recording = true;
        recordingStart = DateTime.now();
      });

      final folderPath = await getTemporaryDirectory();
      final time = recordingStart!
          .toLocal()
          .toIso8601String()
          .replaceAll(RegExp(r'[^0-9]'), "-");
      final rand = Random().nextInt(255).toRadixString(16);

      final filename = path.join(folderPath.path, "Recording-$time-$rand.m4a");

      await recorder.start(path: filename);
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    TextTheme textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppTopBar(
        title: AppLocalizations.of(context)!.melodiesSetting,
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Material(
                color: Colors.redAccent,
                shape: const CircleBorder(),
                child: InkWell(
                    customBorder: const CircleBorder(),
                    highlightColor: Colors.red,
                    splashColor: Colors.red,
                    onTap: () => _toggleRecord(),
                    child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Icon(recording ? Icons.stop : Icons.mic,
                            size: 100)))),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
