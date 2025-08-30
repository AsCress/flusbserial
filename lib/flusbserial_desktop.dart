import 'dart:ffi';
import 'dart:io';

import 'package:flusbserial/flusbserial_platform_interface.dart';
import 'package:libusb/libusb64.dart';

class FlUsbSerialLinux extends FlUsbSerialPlatform {
  late final Libusb _libusb;

  FlUsbSerialLinux() {
    _libusb = Libusb(
      DynamicLibrary.open(
        '${File(Platform.resolvedExecutable).parent.path}/lib/libusb-1.0.23.so',
      ),
    );
  }

  @override
  Libusb get libusb => _libusb;

  static void registerWith() {
    FlUsbSerialPlatform.instance = FlUsbSerialLinux();
  }
}

class FlUsbSerialWindows extends FlUsbSerialPlatform {
  late final Libusb _libusb;

  FlUsbSerialWindows() {
    _libusb = Libusb(DynamicLibrary.open('libusb-1.0.23.dll'));
  }

  @override
  Libusb get libusb => _libusb;

  static void registerWith() {
    FlUsbSerialPlatform.instance = FlUsbSerialWindows();
  }
}

class FlUsbSerialMac extends FlUsbSerialPlatform {
  late final Libusb _libusb;

  FlUsbSerialMac() {
    _libusb = Libusb(DynamicLibrary.open('libusb-1.0.23.dylib'));
  }

  @override
  Libusb get libusb => _libusb;

  static void registerWith() {
    FlUsbSerialPlatform.instance = FlUsbSerialMac();
  }
}
