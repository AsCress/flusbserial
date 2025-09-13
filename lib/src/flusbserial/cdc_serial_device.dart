import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart' as ffi;
import 'package:flusbserial/flusbserial.dart';
import 'package:flusbserial/src/models/usb_configuration.dart';
import 'package:flusbserial/src/models/usb_endpoint.dart';
import 'package:flusbserial/src/models/usb_interface.dart';
import 'package:flusbserial/src/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:libusb/libusb64.dart';

class CdcSerialDevice extends UsbSerialDevice {
  final Libusb _libusb = libusb;
  UsbConfiguration? configuration;
  static late final UsbInterface usbInterface;
  int cdcControl = 0;
  int initialBaudRate = 0;
  int controlLineState = 0;

  static const int reqTypeHostToDevice = 0x21;
  static const int reqTypeDeviceToHost = 0xA1;

  static const int setLineCoding = 0x20;
  static const int getLineCoding = 0x21;
  static const int setControlLineState = 0x22;

  static const int setControlLineStateRts = 0x2;
  static const int setControlLineStateDtr = 0x1;

  /// Default Serial Configuration
  /// Baud rate: 115200
  /// Data bits: 8
  /// Stop bits: 1
  /// Parity: None
  /// Flow Control: Off
  static Uint8List lineCodingDefault = Uint8List.fromList([
    0x00, // Offset 0:4 dwDTERate
    0xC2,
    0x01,
    0x00,
    0x00, // Offset 5 bCharFormat (1 Stop bit)
    0x00, // bParityType (None)
    0x08, // bDataBits (8)
  ]);

  static const int controlLineOn = 0x0003;
  static const int controlLineOff = 0x0000;
  CdcSerialDevice(super.device, super.interfaceId);

  @override
  Future<void> close() async {
    await setControlCommand(setControlLineState, controlLineOff, null);
    _libusb.libusb_release_interface(
      deviceHandle,
      configuration!.interfaces[usbInterfaceId].id,
    );
  }

  @override
  Future<bool> open() async {
    assert(deviceHandle == nullptr, 'Last device not closed');

    var handle = _libusb.libusb_open_device_with_vid_pid(
      nullptr,
      usbDevice.vendorId,
      usbDevice.productId,
    );
    if (handle == nullptr) {
      return false;
    }

    deviceHandle = handle;

    if (UsbSerialDevice.autoDetachKernelDriverEnabled && Platform.isLinux) {
      _libusb.libusb_set_auto_detach_kernel_driver(deviceHandle, 1);
    }

    configuration = await getConfiguration(0);

    if (usbInterfaceId == -1) {
      for (var iface in configuration!.interfaces) {
        if (iface.interfaceClass == libusb_class_code.LIBUSB_CLASS_DATA) {
          usbInterfaceId = iface.id;
          break;
        }
      }
    }

    for (var iface in configuration!.interfaces) {
      if (iface.interfaceClass == libusb_class_code.LIBUSB_CLASS_COMM) {
        cdcControl = iface.id;
        break;
      }
    }

    if (_libusb.libusb_claim_interface(
          deviceHandle,
          configuration!.interfaces[usbInterfaceId].id,
        ) !=
        libusb_error.LIBUSB_SUCCESS) {
      return false;
    }

    usbInterface = configuration!.interfaces[usbInterfaceId];

    int numberOfEndpoints = usbInterface.endpoints.length;

    for (int i = 0; i < numberOfEndpoints; i++) {
      UsbEndpoint endpoint = usbInterface.endpoints[i];
      if (endpoint.transferType ==
              libusb_transfer_type.LIBUSB_TRANSFER_TYPE_BULK &&
          endpoint.direction == UsbEndpoint.directionIn) {
        inEndpoint = endpoint;
      } else if (endpoint.transferType ==
              libusb_transfer_type.LIBUSB_TRANSFER_TYPE_BULK &&
          endpoint.direction == UsbEndpoint.directionOut) {
        outEndpoint = endpoint;
      }
    }

    if (outEndpoint == null || inEndpoint == null) {
      return false;
    }

    await setControlCommand(setLineCoding, 0, getInitialLineCoding());
    await setControlCommand(setControlLineState, controlLineOn, null);

    return true;
  }

  Uint8List getInitialLineCoding() {
    Uint8List lineCoding;

    int initialBaudRate = getInitialBaudRate();

    if (initialBaudRate > 0) {
      lineCoding = lineCodingDefault;
      for (int i = 0; i < 4; i++) {
        lineCoding[i] = (initialBaudRate >> (i * 8)) & 0xFF;
      }
    } else {
      lineCoding = lineCodingDefault;
    }
    return lineCoding;
  }

  int getInitialBaudRate() {
    return initialBaudRate;
  }

  Future<int> setControlCommand(int request, int value, Uint8List? data) async {
    assert(deviceHandle != nullptr, 'Device not open');

    Pointer<Uint8> ptrData = nullptr;
    int dataLength = 0;

    if (data != null && data.isNotEmpty) {
      ptrData = toPtr(data);
      dataLength = data.length;
    }

    var result = _libusb.libusb_control_transfer(
      deviceHandle,
      reqTypeHostToDevice,
      request,
      value,
      cdcControl,
      ptrData,
      dataLength,
      UsbSerialDevice.usbTimeout,
    );
    debugPrint("Control Transfer Response: $result");
    if (result < 0) {
      throw 'controlTransfer error: ${_libusb.describeError(result)}';
    }
    if (ptrData != nullptr) {
      ffi.calloc.free(ptrData);
    }
    return result;
  }

  @override
  Future<void> setBaudRate(int baudRate) async {
    Uint8List data = await getCdcLineCoding();

    data[0] = (baudRate & 0xFF);
    data[1] = ((baudRate >> 8) & 0xFF);
    data[2] = ((baudRate >> 16) & 0xFF);
    data[3] = ((baudRate >> 24) & 0xFF);

    await setControlCommand(setLineCoding, 0, data);
  }

  @override
  Future<void> setBreak(bool state) async {
    return;
  }

  @override
  Future<void> setDataBits(int dataBits) async {
    Uint8List data = await getCdcLineCoding();
    switch (dataBits) {
      case 5:
        data[6] = 0x05;
        break;
      case 6:
        data[6] = 0x06;
        break;
      case 7:
        data[6] = 0x07;
        break;
      case 8:
        data[6] = 0x08;
        break;
      default:
        return;
    }
    await setControlCommand(setLineCoding, 0, data);
  }

  @override
  Future<void> setFlowControl(int flowControl) async {
    return;
  }

  @override
  Future<void> setParity(int parity) async {
    Uint8List data = await getCdcLineCoding();
    switch (parity) {
      case 0:
        data[5] = 0x00;
        break;
      case 1:
        data[5] = 0x01;
        break;
      case 2:
        data[5] = 0x02;
        break;
      case 3:
        data[5] = 0x03;
        break;
      case 4:
        data[5] = 0x04;
        break;
      default:
        return;
    }
    await setControlCommand(setLineCoding, 0, data);
  }

  @override
  Future<void> setStopBits(int stopBits) async {
    Uint8List data = await getCdcLineCoding();
    switch (stopBits) {
      case 1:
        data[4] = 0x00;
        break;
      case 3:
        data[4] = 0x01;
        break;
      case 2:
        data[4] = 0x02;
        break;
      default:
        return;
    }
    await setControlCommand(setLineCoding, 0, data);
  }

  Future<Uint8List> getCdcLineCoding() async {
    final Pointer<Uint8> ptrData = ffi.calloc<Uint8>(7);
    int result = _libusb.libusb_control_transfer(
      deviceHandle,
      reqTypeDeviceToHost,
      getLineCoding,
      0,
      cdcControl,
      ptrData,
      7,
      UsbSerialDevice.usbTimeout,
    );
    debugPrint("Control Transfer Response: $result");
    Uint8List data = ptrData.asTypedList(7);
    return data;
  }

  Pointer<Uint8> toPtr(Uint8List data) {
    final ptr = ffi.calloc<Uint8>(data.length);
    final nativeList = ptr.asTypedList(data.length);
    nativeList.setAll(0, data);
    return ptr;
  }

  @override
  Future<void> setDtr(bool state) async {
    if (state) {
      controlLineState |= setControlLineStateDtr;
    } else {
      controlLineState &= ~setControlLineStateDtr;
    }
    await setControlCommand(setControlLineState, controlLineState, null);
  }

  @override
  Future<void> setRts(bool state) async {
    if (state) {
      controlLineState |= setControlLineStateRts;
    } else {
      controlLineState &= ~setControlLineStateRts;
    }
    await setControlCommand(setControlLineState, controlLineState, null);
  }
}
