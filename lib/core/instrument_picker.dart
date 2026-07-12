import 'package:flutter/material.dart';
import '../screens/instrument_picker_page.dart';

/// Opens the instrument picker page. Returns the selected instrument [id] or null.
Future<String?> showInstrumentPicker(BuildContext context, {String? current}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => InstrumentPickerPage(currentId: current),
    ),
  );
}
