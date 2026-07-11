import 'dart:io' show Platform;

String getDeviceName() {
  try {
    return Platform.localHostname;
  } catch (_) {
    return 'Unknown Device';
  }
}

String getOperatingSystem() {
  try {
    return Platform.operatingSystem;
  } catch (_) {
    return 'Unknown';
  }
}

String getDeviceIdentifier() {
  try {
    return Platform.localHostname;
  } catch (_) {
    return 'unknown';
  }
}
