import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;
import 'package:flusbserial/src/device_ids/ch34x_ids.dart';
import 'package:flusbserial/src/flusbserial/cdc_serial_device.dart';
import 'package:flusbserial/src/flusbserial/ch34x_serial_device.dart';
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

/// Base class for USB serial devices.
///
/// This abstract class defines the common API for communicating with
/// USB serial devices via libusb. Subclasses implement device-specific
/// behaviors (e.g., [Cp210XSerialDevice] or [CdcSerialDevice]).
abstract class UsbSerialDevice implements UsbSerialInterface {
  static const String cdc = 'CDC';
  static const String cp210x = 'CP210x';
  static const String ch34x = 'CH34x';

  static bool autoDetachKernelDriverEnabled = false;

  static final int usbTimeout = 0;
  static final Libusb _libusb = libusb;

  @protected
  late Pointer<libusb_device_handle> deviceHandle;
  late final UsbDevice usbDevice;
  int usbInterfaceId = 0;
  UsbEndpoint? inEndpoint;
  UsbEndpoint? outEndpoint;

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

  /// Factory method that creates a [UsbSerialDevice] implementation.
  ///
  /// Determines the appropriate driver based on the provided [UsbDevice]'s
  /// vendor and product IDs, or by the optional [type] hint.
  ///
  /// - If [type] is specified and matches a supported driver (e.g., [UsbSerialDevice.cp210x],
  ///   [UsbSerialDevice.ch34x], [UsbSerialDevice.cdc]), that driver is used
  ///   if the device is compatible.
  /// - If [type] is not specified or does not match, the method attempts to
  ///   auto-detect support for known chipsets (currently CP210x and CH34x).
  /// - If no specific driver is found, a [CdcSerialDevice] is created as the
  ///   default fallback.
  static UsbSerialDevice? createDevice(
    UsbDevice device, {
    int interfaceId = -1,
    String type = '',
  }) {
    if (type == UsbSerialDevice.cp210x) {
      if (CP210xIds.isDeviceSupported(device.vendorId, device.productId)) {
        if (interfaceId == -1) {
          interfaceId = 0;
        }
        return Cp210XSerialDevice(device, interfaceId);
      }
    } else if (type == UsbSerialDevice.ch34x) {
      if (Ch34xIds.isDeviceSupported(device.vendorId, device.productId)) {
        if (interfaceId == -1) {
          interfaceId = 0;
        }
        return Ch34xSerialDevice(device, interfaceId);
      }
    } else if (type == UsbSerialDevice.cdc) {
      return CdcSerialDevice(device, interfaceId);
    }

    if (CP210xIds.isDeviceSupported(device.vendorId, device.productId)) {
      if (interfaceId == -1) {
        interfaceId = 0;
      }
      return Cp210XSerialDevice(device, interfaceId);
    } else if (Ch34xIds.isDeviceSupported(device.vendorId, device.productId)) {
      if (interfaceId == -1) {
        interfaceId = 0;
      }
      return Ch34xSerialDevice(device, interfaceId);
    } else {
      return CdcSerialDevice(device, interfaceId);
    }
  }

  /// Checks whether the given [UsbDevice] is supported.
  static bool isSupported(UsbDevice device) {
    return CP210xIds.isDeviceSupported(device.vendorId, device.productId);
  }

  /// Lists all USB devices currently connected to the system.
  ///
  /// Returns an empty list if no devices are found or on error.
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

  /// Retrieves the USB configuration at the given [index].
  ///
  /// Throws an exception if the configuration cannot be retrieved.
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
          interfaceClass: intfDesc.bInterfaceClass,
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

  /// Reads data from the device using bulk transfer.
  ///
  /// [bytesToRead] specifies how many bytes to read.
  /// [timeout] is in milliseconds.
  ///
  /// Throws if the transfer fails.
  @override
  Future<Uint8List> read(int bytesToRead, int timeout) async {
    assert(deviceHandle != nullptr, 'Device not open');

    var ptrActualLength = ffi.calloc<Int32>();
    var ptrData = ffi.calloc<Uint8>(bytesToRead);
    try {
      var result = _libusb.libusb_bulk_transfer(
        deviceHandle,
        inEndpoint!.endpointAddress,
        ptrData,
        bytesToRead,
        ptrActualLength,
        timeout,
      );
      if (result != libusb_error.LIBUSB_SUCCESS) {
        throw 'bulkTransferIn error: ${_libusb.describeError(result)}';
      }
      return Uint8List.fromList(ptrData.asTypedList(bytesToRead));
    } finally {
      ffi.calloc.free(ptrActualLength);
      ffi.calloc.free(ptrData);
    }
  }

  /// Writes data to the device using bulk transfer.
  ///
  /// [data] is the buffer to send.
  /// [timeout] is in milliseconds.
  ///
  /// Returns the number of bytes actually written.
  @override
  Future<int> write(Uint8List data, int timeout) async {
    assert(deviceHandle != nullptr, 'Device not open');

    var ptrData = ffi.calloc<Uint8>(data.length);
    var ptrActualLength = ffi.calloc<Int32>();
    ptrData.asTypedList(data.length).setAll(0, data);
    try {
      var result = _libusb.libusb_bulk_transfer(
        deviceHandle,
        outEndpoint!.endpointAddress,
        ptrData,
        data.length,
        ptrActualLength,
        timeout,
      );
      if (result != libusb_error.LIBUSB_SUCCESS) {
        throw 'bulkTransferOut error: ${_libusb.describeError(result)}';
      }
      return ptrActualLength.value;
    } finally {
      ffi.calloc.free(ptrData);
      ffi.calloc.free(ptrActualLength);
    }
  }

  /// Sets whether the kernel driver should be automatically detached
  /// when the device is opened, on Linux.
  static void setAutoDetachKernelDriver(bool enabled) {
    autoDetachKernelDriverEnabled = enabled;
  }

  static void exit() {
    _libusb.libusb_exit(nullptr);
  }

  /// Closes the device and releases resources.
  @override
  Future<void> close();

  /// Opens the device and claims its interface(s).
  @override
  Future<bool> open();

  /// Configures the baud rate for serial communication.
  @override
  Future<void> setBaudRate(int baudRate);

  /// Sets or clears the break condition on the line.
  @override
  Future<void> setBreak(bool state);

  /// Configures the number of data bits per character.
  @override
  Future<void> setDataBits(int dataBits);

  /// Configures hardware/software flow control.
  @override
  Future<void> setFlowControl(int flowControl);

  /// Configures the parity bit (none, even, odd, etc.).
  @override
  Future<void> setParity(int parity);

  /// Configures the number of stop bits.
  @override
  Future<void> setStopBits(int stopBits);

  /// Asserts or deasserts the DTR (Data Terminal Ready) line.
  @override
  Future<void> setDtr(bool state);

  /// Asserts or deasserts the RTS (Request To Send) line.
  @override
  Future<void> setRts(bool state);
}
