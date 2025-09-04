import 'dart:ffi';
import 'dart:io';

import 'package:flusbserial/flusbserial_platform_interface.dart';
import 'package:flusbserial/src/utils/utils.dart';
import 'package:libusb/libusb64.dart';

/// Linux implementation of the [FlUsbSerialPlatform].
///
/// This class loads the native `libusb-1.0.23.so` library dynamically
/// from the same directory as the Dart/Flutter executable.
/// It provides the bindings for libusb on Linux.
class FlUsbSerialLinux extends FlUsbSerialPlatform {
  FlUsbSerialLinux() {
    libusb = Libusb(
      DynamicLibrary.open(
        '${File(Platform.resolvedExecutable).parent.path}/lib/libusb-1.0.23.so',
      ),
    );
  }

  static void registerWith() {
    FlUsbSerialPlatform.instance = FlUsbSerialLinux();
  }
}

/// Windows implementation of the [FlUsbSerialPlatform].
///
/// This class loads the native `libusb-1.0.23.dll` library dynamically.
/// It provides the bindings for libusb on Windows.
class FlUsbSerialWindows extends FlUsbSerialPlatform {
  FlUsbSerialWindows() {
    libusb = Libusb(DynamicLibrary.open('libusb-1.0.23.dll'));
  }
  static void registerWith() {
    FlUsbSerialPlatform.instance = FlUsbSerialWindows();
  }
}

/// macOS implementation of the [FlUsbSerialPlatform].
///
/// This class loads the native `libusb-1.0.23.dylib` library dynamically.
/// It provides the bindings for libusb on macOS.
class FlUsbSerialMac extends FlUsbSerialPlatform {
  FlUsbSerialMac() {
    libusb = Libusb(DynamicLibrary.open('libusb-1.0.23.dylib'));
  }
  static void registerWith() {
    FlUsbSerialPlatform.instance = FlUsbSerialMac();
  }
}
