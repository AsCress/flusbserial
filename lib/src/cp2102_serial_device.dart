import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:flusbserial/flusbserial_platform_interface.dart';
import 'package:flusbserial/src/usb_configuration.dart';
import 'package:flusbserial/src/usb_device.dart';
import 'package:flusbserial/src/usb_endpoint.dart';
import 'package:flusbserial/src/usb_serial_device.dart';
import 'package:flusbserial/src/usb_serial_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:libusb/libusb64.dart';

class Cp2102SerialDevice extends UsbSerialDevice {
  final Libusb _libusb = FlUsbSerialPlatform.instance.libusb;
  UsbConfiguration? configuration;

  static const int purge = 0x12;
  static const int ifcEnable = 0x00;
  static const int setBaudDiv = 0x01;
  static const int setLineCtl = 0x03;
  static const int getLineCtl = 0x04;
  static const int setBr = 0x05;
  static const int setMhs = 0x07;
  static const int setBaud = 0x1E;
  static const int setFlow = 0x13;
  static const int setXon = 0x09;
  static const int setXoff = 0x0A;
  static const int setChars = 0x19;
  static const int getMdmSts = 0x08;
  static const int getCommStatus = 0x10;

  static const int reqTypeHostToDevice = 0x41;
  static const int reqTypeDeviceToHost = 0xC1;

  static const int breakOn = 0x0001;
  static const int breakOff = 0x0000;

  static const int mhsRtsOn = 0x0202;
  static const int mhsRtsOff = 0x0200;
  static const int mhsDtrOn = 0x0101;
  static const int mhsDtrOff = 0x0100;

  static const int purgeAll = 0x000F;

  /// Default Serial Configuration
  /// Baud rate: 9600
  /// Data bits: 8
  /// Stop bits: 1
  /// Parity: None
  /// Flow Control: Off
  static const int uartEnable = 0x0001;
  static const int uartDisable = 0x0000;
  static const int lineCtlDefault = 0x0800;
  static const int mhsDefault = 0x0000;
  static const int mhsDtr = 0x0001;
  static const int mhsRts = 0x0010;
  static const int mhsAll = 0x0011;
  static const int xon = 0x0000;
  static const int xoff = 0x0000;
  static const int defaultBaudRate = 9600;

  @override
  Future<void> close() {
    throw UnimplementedError();
  }

  @override
  Future<bool> open(UsbDevice usbDevice) async {
    if (_libusb.libusb_init(nullptr) != libusb_error.LIBUSB_SUCCESS) {
      return false;
    }

    assert(UsbSerialDevice.deviceHandle == null, 'Last device not closed');

    var handle = _libusb.libusb_open_device_with_vid_pid(
      nullptr,
      usbDevice.vendorId,
      usbDevice.productId,
    );
    if (handle == nullptr) {
      return false;
    }

    UsbSerialDevice.deviceHandle = handle;

    configuration = await UsbSerialDevice.getConfiguration(0);

    if (_libusb.libusb_claim_interface(
          UsbSerialDevice.deviceHandle!,
          configuration!.interfaces[0].id,
        ) !=
        libusb_error.LIBUSB_SUCCESS) {
      return false;
    }

    UsbSerialDevice.usbInterface = configuration!.interfaces[0];

    int numberOfEndpoints = UsbSerialDevice.usbInterface.endpoints.length;

    for (int i = 0; i < numberOfEndpoints - 1; i++) {
      UsbEndpoint endpoint = UsbSerialDevice.usbInterface.endpoints[i];
      if (endpoint.direction == UsbEndpoint.directionIn) {
        UsbSerialDevice.inEndpoint = endpoint;
      } else {
        UsbSerialDevice.outEndpoint = endpoint;
      }
    }

    if (await setControlCommand(ifcEnable, uartEnable, null) < 0) {
      return false;
    }
    await setBaudRate(defaultBaudRate);
    if (await setControlCommand(setLineCtl, lineCtlDefault, null) < 0) {
      return false;
    }
    await setFlowControl(UsbSerialInterface.flowControlOff);
    if (await setControlCommand(setMhs, mhsDefault, null) < 0) {
      return false;
    }
    return true;
  }

  Future<int> setControlCommand(int request, int value, Uint8List? data) async {
    assert(UsbSerialDevice.deviceHandle != null, 'Device not open');

    Pointer<Uint8> ptrData = nullptr;
    int dataLength = 0;

    if (data != null && data.isNotEmpty) {
      dataLength = data.length;
      ptrData = ffi.calloc<Uint8>(dataLength);
      for (var i = 0; i < dataLength; i++) {
        ptrData[i] = data[i];
      }
    }

    var result = _libusb.libusb_control_transfer(
      UsbSerialDevice.deviceHandle!,
      reqTypeHostToDevice,
      request,
      value,
      UsbSerialDevice.usbInterface.id,
      ptrData,
      dataLength,
      UsbSerialDevice.usbTimeout,
    );
    if (result != libusb_error.LIBUSB_SUCCESS) {
      throw 'controlTransfer error';
    }
    return result;
  }

  @override
  Future<void> setBaudRate(int baudRate) async {
    Uint8List data = Uint8List.fromList([
      baudRate & 0xFF,
      (baudRate >> 8) & 0xFF,
      (baudRate >> 16) & 0xFF,
      (baudRate >> 24) & 0xFF,
    ]);
    await setControlCommand(setBaud, 0, data);
  }

  @override
  Future<void> setBreak(bool state) async {
    if (state) {
      await setControlCommand(setBr, breakOn, null);
    } else {
      await setControlCommand(setBr, breakOff, null);
    }
  }

  @override
  Future<void> setDataBits(int dataBits) async {
    int wValue = await getCTL();
    wValue &= ~0x0F00;
    switch (dataBits) {
      case 5:
        wValue |= 0x0500;
        break;
      case 6:
        wValue |= 0x0600;
        break;
      case 7:
        wValue |= 0x0700;
        break;
      case 8:
        wValue |= 0x0800;
        break;
      default:
        return;
    }
    await setControlCommand(setLineCtl, wValue, null);
  }

  @override
  Future<void> setFlowControl(int flowControl) async {
    switch (flowControl) {
      case 0:
        final dataOff = Uint8List.fromList([
          0x01,
          0x00,
          0x00,
          0x00,
          0x40,
          0x00,
          0x00,
          0x00,
          0x00,
          0x80,
          0x00,
          0x00,
          0x00,
          0x20,
          0x00,
          0x00,
        ]);
        await setControlCommand(setFlow, 0, dataOff);
        break;

      case 1:
        final dataRtsCts = Uint8List.fromList([
          0x09,
          0x00,
          0x00,
          0x00,
          0x40,
          0x00,
          0x00,
          0x00,
          0x00,
          0x80,
          0x00,
          0x00,
          0x00,
          0x20,
          0x00,
          0x00,
        ]);
        await setControlCommand(setFlow, 0, dataRtsCts);
        await setControlCommand(setMhs, mhsRtsOn, null);
        break;

      case 2:
        final dataDsrDtr = Uint8List.fromList([
          0x11,
          0x00,
          0x00,
          0x00,
          0x40,
          0x00,
          0x00,
          0x00,
          0x00,
          0x80,
          0x00,
          0x00,
          0x00,
          0x20,
          0x00,
          0x00,
        ]);
        await setControlCommand(setFlow, 0, dataDsrDtr);
        await setControlCommand(setMhs, mhsDtrOn, null);
        break;

      case 3:
        final dataXonXoff = Uint8List.fromList([
          0x01,
          0x00,
          0x00,
          0x00,
          0x43,
          0x00,
          0x00,
          0x00,
          0x00,
          0x80,
          0x00,
          0x00,
          0x00,
          0x20,
          0x00,
          0x00,
        ]);

        final dataChars = Uint8List.fromList([
          0x00,
          0x00,
          0x00,
          0x00,
          0x11,
          0x13,
        ]);

        await setControlCommand(setChars, 0, dataChars);
        await setControlCommand(setFlow, 0, dataXonXoff);
        break;

      default:
        return;
    }
  }

  @override
  Future<void> setParity(int parity) async {
    int wValue = await getCTL();
    wValue &= ~0x00F0;
    switch (parity) {
      case 0:
        wValue |= 0x0000;
        break;
      case 1:
        wValue |= 0x0010;
        break;
      case 2:
        wValue |= 0x0020;
        break;
      case 3:
        wValue |= 0x0030;
        break;
      case 4:
        wValue |= 0x0040;
        break;
      default:
        return;
    }
    await setControlCommand(setLineCtl, wValue, null);
  }

  @override
  Future<void> setStopBits(int stopBits) async {
    int wValue = await getCTL();
    wValue &= ~0x0003;
    switch (stopBits) {
      case 1:
        wValue |= 0;
        break;
      case 3:
        wValue |= 1;
        break;
      case 2:
        wValue |= 2;
        break;
      default:
        return;
    }
    await setControlCommand(setLineCtl, wValue, null);
  }

  Future<int> getCTL() async {
    final Pointer<Uint8> ptrData = ffi.calloc<Uint8>(2);
    int result = _libusb.libusb_control_transfer(
      UsbSerialDevice.deviceHandle!,
      reqTypeDeviceToHost,
      getLineCtl,
      0,
      UsbSerialDevice.usbInterface.id,
      ptrData,
      2,
      UsbSerialDevice.usbTimeout,
    );
    debugPrint("Control Transfer Response: $result");
    Uint8List data = ptrData.asTypedList(2);
    return (data[1] << 8) | (data[0] & 0xFF);
  }
}
