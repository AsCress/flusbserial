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

class Ch34xSerialDevice extends UsbSerialDevice {
  final Libusb _libusb = libusb;
  UsbConfiguration? configuration;
  static late final UsbInterface usbInterface;

  static const int defaultBaudRate = 9600;

  static const int reqTypeHostFromDevice =
      libusb_request_type.LIBUSB_REQUEST_TYPE_VENDOR |
      libusb_endpoint_direction.LIBUSB_ENDPOINT_IN;
  static const int reqTypeHostToDevice = 0x40;

  static const int reqWriteReg = 0x9A;
  static const int reqReadReg = 0x95;
  static const int regBreak1 = 0x05;
  static const int regBreak2 = 0x18;
  static const int nbreakBitsReg1 = 0x01;
  static const int nbreakBitsReg2 = 0x40;

  // Baud rate values
  static const int baud300_1312 = 0xd980;
  static const int baud300_0f2c = 0xeb;

  static const int baud600_1312 = 0x6481;
  static const int baud600_0f2c = 0x76;

  static const int baud1200_1312 = 0xb281;
  static const int baud1200_0f2c = 0x3b;

  static const int baud2400_1312 = 0xd981;
  static const int baud2400_0f2c = 0x1e;

  static const int baud4800_1312 = 0x6482;
  static const int baud4800_0f2c = 0x0f;

  static const int baud9600_1312 = 0xb282;
  static const int baud9600_0f2c = 0x08;

  static const int baud19200_1312 = 0xd982;
  static const int baud19200_0f2cRest = 0x07;

  static const int baud38400_1312 = 0x6483;

  static const int baud57600_1312 = 0x9883;

  static const int baud115200_1312 = 0xcc83;

  static const int baud230400_1312 = 0xe683;

  static const int baud460800_1312 = 0xf383;

  static const int baud921600_1312 = 0xf387;

  static const int baud1228800_1312 = 0xfb03;
  static const int baud1228800_0f2c = 0x21;

  static const int baud2000000_1312 = 0xfd03;
  static const int baud2000000_0f2c = 0x02;

  // Parity values
  static const int parityNone = 0xc3;
  static const int parityOdd = 0xcb;
  static const int parityEven = 0xdb;
  static const int parityMark = 0xeb;
  static const int paritySpace = 0xfb;

  // Flow control values
  static const int flowControlNone = 0x0000;
  static const int flowControlRtsCts = 0x0101;
  static const int flowControlDsrDtr = 0x0202;

  bool rtsCtsEnabled = false;
  bool dsrDtrEnabled = false;
  bool dtr = false;
  bool rts = false;
  bool ctsState = false;
  bool dsrState = false;

  Ch34xSerialDevice(super.device, super.interfaceId);

  @override
  Future<void> close() async {
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
    return await init() == 0;
  }

  Future<int> init() async {
    if (await setControlCommandOut(0xa1, 0xc29c, 0xb2b9, null) < 0) {
      debugPrint('Failed to init #1');
      return -1;
    }
    if (await setControlCommandOut(0xa4, 0xdf, 0, null) < 0) {
      debugPrint('Failed to init #2');
      return -1;
    }
    if (await setControlCommandOut(0xa4, 0x9f, 0, null) < 0) {
      debugPrint('Failed to init #3');
      return -1;
    }
    if (await checkState("init #4", 0x95, 0x0706, [0x9f, 0xee]) == -1) {
      return -1;
    }
    if (await setControlCommandOut(0x9a, 0x2727, 0x0000, null) < 0) {
      debugPrint('Failed to init #5');
      return -1;
    }
    if (await setControlCommandOut(0x9a, 0x1312, 0xb282, null) < 0) {
      debugPrint('Failed to init #6');
      return -1;
    }
    if (await setControlCommandOut(0x9a, 0x0f2c, 0x0008, null) < 0) {
      debugPrint('Failed to init #7');
      return -1;
    }
    if (await setControlCommandOut(0x9a, 0x2518, 0x00c3, null) < 0) {
      debugPrint('Failed to init #8');
      return -1;
    }
    if (await checkState("init #9", 0x95, 0x0706, [0x9f, 0xee]) == -1) {
      return -1;
    }
    if (await setControlCommandOut(0x9a, 0x2727, 0x0000, null) < 0) {
      debugPrint('Failed to init #10');
      return -1;
    }
    return 0;
  }

  Future<int> checkState(
    String msg,
    int request,
    int value,
    List<int> expected,
  ) async {
    Uint8List buffer = Uint8List(expected.length);
    int ret = await setControlCommandIn(request, value, 0, buffer);

    if (ret != expected.length) {
      debugPrint(
        '$msg: Expected ${expected.length} bytes, but got $ret [$msg]',
      );
      return -1;
    }
    return 0;
  }

  Future<int> writeHandshakeByte() async {
    if (await setControlCommandOut(
          0xA4,
          ~((dtr ? 1 << 5 : 0) | (rts ? 1 << 6 : 0)),
          0,
          null,
        ) <
        0) {
      debugPrint('Failed to set handshake byte');
      return -1;
    }
    return 0;
  }

  Future<int> setControlCommandOut(
    int request,
    int value,
    int index,
    Uint8List? data,
  ) async {
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
      index,
      ptrData,
      dataLength,
      UsbSerialDevice.usbTimeout,
    );
    if (result < 0) {
      throw 'controlTransfer error: ${_libusb.describeError(result)}';
    }
    if (ptrData != nullptr) {
      ffi.calloc.free(ptrData);
    }
    debugPrint('Control transfer response: $result');
    return result;
  }

  Future<int> setControlCommandIn(
    int request,
    int value,
    int index,
    Uint8List? data,
  ) async {
    assert(deviceHandle != nullptr, 'Device not open');

    Pointer<Uint8> ptrData = nullptr;
    int dataLength = 0;

    if (data != null && data.isNotEmpty) {
      ptrData = toPtr(data);
      dataLength = data.length;
    }

    var result = _libusb.libusb_control_transfer(
      deviceHandle,
      reqTypeHostFromDevice,
      request,
      value,
      index,
      ptrData,
      dataLength,
      UsbSerialDevice.usbTimeout,
    );
    if (result < 0) {
      throw 'controlTransfer error: ${_libusb.describeError(result)}';
    }
    if (ptrData != nullptr) {
      ffi.calloc.free(ptrData);
    }
    debugPrint('Control transfer response: $result');
    return result;
  }

  @override
  Future<void> setBaudRate(int baudRate) async {
    int ret = 0;

    if (baudRate <= 300) {
      ret = await setCh34xBaudRate(baud300_1312, baud300_0f2c);
    } else if (baudRate > 300 && baudRate <= 600) {
      ret = await setCh34xBaudRate(baud600_1312, baud600_0f2c);
    } else if (baudRate > 600 && baudRate <= 1200) {
      ret = await setCh34xBaudRate(baud1200_1312, baud1200_0f2c);
    } else if (baudRate > 1200 && baudRate <= 2400) {
      ret = await setCh34xBaudRate(baud2400_1312, baud2400_0f2c);
    } else if (baudRate > 2400 && baudRate <= 4800) {
      ret = await setCh34xBaudRate(baud4800_1312, baud4800_0f2c);
    } else if (baudRate > 4800 && baudRate <= 9600) {
      ret = await setCh34xBaudRate(baud9600_1312, baud9600_0f2c);
    } else if (baudRate > 9600 && baudRate <= 19200) {
      ret = await setCh34xBaudRate(baud19200_1312, baud19200_0f2cRest);
    } else if (baudRate > 19200 && baudRate <= 38400) {
      ret = await setCh34xBaudRate(baud38400_1312, baud19200_0f2cRest);
    } else if (baudRate > 38400 && baudRate <= 57600) {
      ret = await setCh34xBaudRate(baud57600_1312, baud19200_0f2cRest);
    } else if (baudRate > 57600 && baudRate <= 115200) {
      ret = await setCh34xBaudRate(baud115200_1312, baud19200_0f2cRest);
    } else if (baudRate > 115200 && baudRate <= 230400) {
      ret = await setCh34xBaudRate(baud230400_1312, baud19200_0f2cRest);
    } else if (baudRate > 230400 && baudRate <= 460800) {
      ret = await setCh34xBaudRate(baud460800_1312, baud19200_0f2cRest);
    } else if (baudRate > 460800 && baudRate <= 921600) {
      ret = await setCh34xBaudRate(baud921600_1312, baud19200_0f2cRest);
    } else if (baudRate > 921600 && baudRate <= 1228800) {
      ret = await setCh34xBaudRate(baud1228800_1312, baud1228800_0f2c);
    } else if (baudRate > 1228800 && baudRate <= 2000000) {
      ret = await setCh34xBaudRate(baud2000000_1312, baud2000000_0f2c);
    }

    if (ret == -1) {
      debugPrint("setBaudRate failed!");
    }
  }

  Future<int> setCh34xBaudRate(int index1312, int index0f2c) async {
    if (await setControlCommandOut(reqWriteReg, 0x1312, index1312, null) < 0) {
      return -1;
    }
    if (await setControlCommandOut(reqWriteReg, 0x0f2c, index0f2c, null) < 0) {
      return -1;
    }
    if (await checkState("setBaudRate", 0x95, 0x0706, [0x9f, 0xee]) == -1) {
      return -1;
    }
    if (await setControlCommandOut(reqWriteReg, 0x2727, 0, null) < 0) {
      return -1;
    }
    return 0;
  }

  @override
  Future<void> setBreak(bool state) async {}

  @override
  Future<void> setDataBits(int dataBits) async {}

  @override
  Future<void> setDtr(bool state) async {
    dtr = state;
    await writeHandshakeByte();
  }

  @override
  Future<void> setFlowControl(int flowControl) async {
    switch (flowControl) {
      case 0:
        rtsCtsEnabled = false;
        dsrDtrEnabled = false;
        await setCh34xFlow(flowControlNone);
        break;
      case 1:
        rtsCtsEnabled = true;
        dsrDtrEnabled = false;
        await setCh34xFlow(flowControlRtsCts);
        ctsState = await checkCts();
        break;
      case 2:
        rtsCtsEnabled = false;
        dsrDtrEnabled = true;
        await setCh34xFlow(flowControlDsrDtr);
        dsrState = await checkDsr();
        break;
      default:
        break;
    }
    return Future.value();
  }

  Future<bool> checkCts() async {
    Uint8List buffer = Uint8List(2);
    int ret = await setControlCommandIn(reqReadReg, 0x0706, 0, buffer);

    if (ret != 2) {
      debugPrint('checkCts: Expected 2 bytes, but got $ret');
      return false;
    }

    if ((buffer[0] & 0x01) == 0x00) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> checkDsr() async {
    Uint8List buffer = Uint8List(2);
    int ret = await setControlCommandIn(reqReadReg, 0x0706, 0, buffer);

    if (ret != 2) {
      debugPrint('checkDsr: Expected 2 bytes, but got $ret');
      return false;
    }

    if ((buffer[0] & 0x02) == 0x00) {
      return true;
    } else {
      return false;
    }
  }

  Future<int> setCh34xFlow(int flowControl) async {
    if (await checkState("setFlowControl", 0x95, 0x0706, [0x9f, 0xee]) == -1) {
      return -1;
    }
    if (await setControlCommandOut(reqWriteReg, 0x2727, flowControl, null) <
        0) {
      return -1;
    }
    return 0;
  }

  @override
  Future<void> setParity(int parity) async {
    switch (parity) {
      case 0:
        await setCh340xParity(parityNone);
        break;
      case 1:
        await setCh340xParity(parityOdd);
        break;
      case 2:
        await setCh340xParity(parityEven);
        break;
      case 3:
        await setCh340xParity(parityMark);
        break;
      case 4:
        await setCh340xParity(paritySpace);
        break;
      default:
        break;
    }
  }

  Future<int> setCh340xParity(int indexParity) async {
    if (await setControlCommandOut(reqWriteReg, 0x2518, indexParity, null) <
        0) {
      return -1;
    }
    if (await checkState("setParity", 0x95, 0x0706, [0x9f, 0xee]) == -1) {
      return -1;
    }
    if (await setControlCommandOut(reqWriteReg, 0x2727, 0, null) < 0) {
      return -1;
    }
    return 0;
  }

  @override
  Future<void> setRts(bool state) async {
    rts = state;
    await writeHandshakeByte();
  }

  @override
  Future<void> setStopBits(int stopBits) async {}

  Pointer<Uint8> toPtr(Uint8List data) {
    final ptr = ffi.calloc<Uint8>(data.length);
    final nativeList = ptr.asTypedList(data.length);
    nativeList.setAll(0, data);
    return ptr;
  }
}
