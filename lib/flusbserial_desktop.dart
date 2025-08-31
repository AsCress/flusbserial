import 'dart:ffi';
import 'dart:io';

import 'package:flusbserial/flusbserial_platform_interface.dart';
import 'package:flusbserial/src/utils/utils.dart';
import 'package:libusb/libusb64.dart';

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

class FlUsbSerialWindows extends FlUsbSerialPlatform {
  FlUsbSerialWindows() {
    libusb = Libusb(DynamicLibrary.open('libusb-1.0.23.dll'));
  }

  static void registerWith() {
    FlUsbSerialPlatform.instance = FlUsbSerialWindows();
  }
}

class FlUsbSerialMac extends FlUsbSerialPlatform {
  FlUsbSerialMac() {
    libusb = Libusb(DynamicLibrary.open('libusb-1.0.23.dylib'));
  }

  static void registerWith() {
    FlUsbSerialPlatform.instance = FlUsbSerialMac();
  }
}
