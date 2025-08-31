import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;
import 'package:flusbserial/src/flusbserial/cp210x_serial_device.dart';
import 'package:flusbserial/src/device_ids/cp210x_ids.dart';
import 'package:flusbserial/src/models/usb_configuration.dart';
import 'package:flusbserial/src/models/usb_device.dart';
import 'package:flusbserial/src/models/usb_endpoint.dart';
import 'package:flusbserial/src/models/usb_interface.dart';
import 'package:flusbserial/src/flusbserial/usb_serial_interface.dart';
import 'package:flusbserial/src/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:libusb/libusb64.dart';

abstract class UsbSerialDevice implements UsbSerialInterface {
  static final int usbTimeout = 0;
  static final Libusb _libusb = libusb;

  @protected
  late Pointer<libusb_device_handle> deviceHandle;
  late final UsbDevice usbDevice;
  late final int usbInterfaceId;
  late UsbEndpoint inEndpoint;
  late UsbEndpoint outEndpoint;

  UsbSerialDevice(UsbDevice device, int interfaceId) {
    usbDevice = device;
    usbInterfaceId = interfaceId;
    deviceHandle = nullptr;
  }

  static void init() {
    if (_libusb.libusb_init(nullptr) != libusb_error.LIBUSB_SUCCESS) {
      throw 'Libusb initialization error';
    }
  }

  static UsbSerialDevice? createDevice(
    UsbDevice device, {
    int interfaceId = 0,
  }) {
    if (CP210xIds.isDeviceSupported(device.vendorId, device.productId)) {
      return Cp210XSerialDevice(device, interfaceId);
    }
    return null;
  }

  static bool isSupported(UsbDevice device) {
    return CP210xIds.isDeviceSupported(device.vendorId, device.productId);
  }

  static Future<List<UsbDevice>> listDevices() async {
    var ptrDeviceList = ffi.calloc<Pointer<Pointer<libusb_device>>>();
    try {
      var deviceCount = _libusb.libusb_get_device_list(nullptr, ptrDeviceList);
      if (deviceCount < 0) {
        return Future.value([]);
      }
      try {
        return Future.value(_iterateDevice(ptrDeviceList.value).toList());
      } finally {
        _libusb.libusb_free_device_list(ptrDeviceList.value, 1);
      }
    } finally {
      ffi.calloc.free(ptrDeviceList);
    }
  }

  static Iterable<UsbDevice> _iterateDevice(
    Pointer<Pointer<libusb_device>> deviceList,
  ) sync* {
    var ptrDescriptor = ffi.calloc<libusb_device_descriptor>();

    for (var i = 0; deviceList[i] != nullptr; i++) {
      var device = deviceList[i];
      var address = _libusb.libusb_get_device_address(device);
      var getDescriptor =
          _libusb.libusb_get_device_descriptor(device, ptrDescriptor) ==
          libusb_error.LIBUSB_SUCCESS;

      yield UsbDevice(
        identifier: address.toString(),
        vendorId: getDescriptor ? ptrDescriptor.ref.idVendor : 0,
        productId: getDescriptor ? ptrDescriptor.ref.idProduct : 0,
        configurationCount: getDescriptor
            ? ptrDescriptor.ref.bNumConfigurations
            : 0,
      );
    }
    ffi.calloc.free(ptrDescriptor);
  }

  Future<UsbConfiguration> getConfiguration(int index) async {
    assert(deviceHandle != nullptr, 'Device not open');

    var ptrConfigDescription = ffi.calloc<Pointer<libusb_config_descriptor>>();
    try {
      var device = _libusb.libusb_get_device(deviceHandle);
      var getConfigDescriptor = _libusb.libusb_get_config_descriptor(
        device,
        index,
        ptrConfigDescription,
      );
      if (getConfigDescriptor != libusb_error.LIBUSB_SUCCESS) {
        throw 'getConfigDescriptor error';
      }

      var ptrConfigDescriptor = ptrConfigDescription.value;
      var usbConfiguration = UsbConfiguration(
        id: ptrConfigDescriptor.ref.bConfigurationValue,
        index: ptrConfigDescriptor.ref.iConfiguration,
        interfaces: _iterateInterface(
          ptrConfigDescriptor.ref.interface_1,
          ptrConfigDescriptor.ref.bNumInterfaces,
        ).toList(),
      );
      _libusb.libusb_free_config_descriptor(ptrConfigDescriptor);

      return usbConfiguration;
    } finally {
      ffi.calloc.free(ptrConfigDescription);
    }
  }

  static Iterable<UsbInterface> _iterateInterface(
    Pointer<libusb_interface> ptrInterface,
    int interfaceCount,
  ) sync* {
    for (var i = 0; i < interfaceCount; i++) {
      var interface = ptrInterface[i];
      for (var j = 0; j < interface.num_altsetting; j++) {
        var intfDesc = interface.altsetting[j];
        yield UsbInterface(
          id: intfDesc.bInterfaceNumber,
          alternateSetting: intfDesc.bAlternateSetting,
          endpoints: _iterateEndpoint(
            intfDesc.endpoint,
            intfDesc.bNumEndpoints,
          ).toList(),
        );
      }
    }
  }

  static Iterable<UsbEndpoint> _iterateEndpoint(
    Pointer<libusb_endpoint_descriptor> ptrEndpointDescriptor,
    int endpointCount,
  ) sync* {
    for (var i = 0; i < endpointCount; i++) {
      var endpointDesc = ptrEndpointDescriptor[i];
      yield UsbEndpoint.fromDescriptor(endpointDesc);
    }
  }

  @override
  Future<Uint8List> read(int bytesToRead, int timeout) async {
    assert(deviceHandle != nullptr, 'Device not open');

    var ptrActualLength = ffi.calloc<Int32>();
    var ptrData = ffi.calloc<Uint8>(bytesToRead);
    try {
      var result = _libusb.libusb_bulk_transfer(
        deviceHandle,
        inEndpoint.endpointAddress,
        ptrData,
        bytesToRead,
        ptrActualLength,
        timeout,
      );
      if (result != libusb_error.LIBUSB_SUCCESS) {
        throw 'bulkTransferIn error';
      }
      return Uint8List.fromList(ptrData.asTypedList(bytesToRead));
    } finally {
      ffi.calloc.free(ptrActualLength);
      ffi.calloc.free(ptrData);
    }
  }

  @override
  Future<int> write(Uint8List data, int timeout) async {
    assert(deviceHandle != nullptr, 'Device not open');

    var ptrData = ffi.calloc<Uint8>(data.length);
    var ptrActualLength = ffi.calloc<Int32>();
    ptrData.asTypedList(data.length).setAll(0, data);
    try {
      var result = _libusb.libusb_bulk_transfer(
        deviceHandle,
        outEndpoint.endpointAddress,
        ptrData,
        data.length,
        ptrActualLength,
        timeout,
      );
      if (result != libusb_error.LIBUSB_SUCCESS) {
        throw 'bulkTransferOut error';
      }
      return ptrActualLength.value;
    } finally {
      ffi.calloc.free(ptrData);
      ffi.calloc.free(ptrActualLength);
    }
  }

  static void exit() {
    _libusb.libusb_exit(nullptr);
  }

  @override
  Future<void> close();

  @override
  Future<bool> open();

  @override
  Future<void> setBaudRate(int baudRate);

  @override
  Future<void> setBreak(bool state);

  @override
  Future<void> setDataBits(int dataBits);

  @override
  Future<void> setFlowControl(int flowControl);

  @override
  Future<void> setParity(int parity);

  @override
  Future<void> setStopBits(int stopBits);
}
