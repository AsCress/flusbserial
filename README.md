# flusbserial
[![flusbserial](https://img.shields.io/pub/v/flusbserial?label=flusbserial)](https://pub.dev/packages/flusbserial)

A cross-platform **USB Serial plugin for Flutter desktop apps** (Windows, Linux, macOS).  
This plugin provides direct access to USB serial devices using [libusb](https://libusb.info), without relying on traditional COM ports.
It is inspired and based on code from [UsbSerial](https://github.com/felHR85/UsbSerial) and [quick_usb](https://github.com/woodemi/quick.flutter/tree/master/packages/quick_usb).

### Supported / Planned Devices
| Device Family | CP210x | CDC ACM | CH34X | FTDI | PL2303 | BLED112 |
| ------------- | --------- | --------- | --------- | --------- | --------- | --------- |
| **Status**    | ✅ | ✅ | ✅ | ⏳ | ⏳ | ⏳ |

>Note: This library is in development. [File any potential issues you see.](https://github.com/AsCress/flusbserial/issues)

## Getting Started

### 1. Install libusb driver
This plugin requires an appropriate **WinUSB (_libusb_)** driver to access your device.

- **Windows:**  
  You can use [Zadig](https://zadig.akeo.ie/) to replace the default driver with **WinUSB** for your device.  
  (Plug in your USB device → open Zadig → select your device from the list → choose *WinUSB* → click *Install Driver*).

- **Linux / macOS:**  
  Usually libusb is available by default.  
  If not, install it with your package manager:  

  ```bash
  # Ubuntu/Debian
  sudo apt-get install libusb-1.0-0-dev

  # macOS (Homebrew)
  brew install libusb
## Installing

1.  Add dependency to `pubspec.yaml`

    Get the latest version from the 'Installing' tab on [pub.dev](https://pub.dev/packages/flusbserial/install)
    
```dart
dependencies:
    flusbserial: <latest_version>
```
>Note: Based upon the other dependencies included in your project, you may have to add a _dependency override_ for the `ffi` package.

2.  Import the package
```dart
import 'package:flusbserial/flusbserial.dart';
```
## Usage
Here are some examples to show the usage:

### Initialize plugin
```dart
UsbSerialDevice.init();
```

### List available devices
```dart
List<UsbDevice> devices = await UsbSerialDevice.listDevices();
```

### Instantiate a new object of the UsbSerialDevice class
```dart
UsbDevice? device;
...
// Auto-detect interface
UsbSerialDevice? mDevice = UsbSerialDevice.createDevice(device);

// Specific interface
UsbSerialDevice? mDevice = UsbSerialDevice.createDevice(device, interfaceId: 0);

// Specific driver (eg:- CDC ACM)
UsbSerialDevice? mDevice = UsbSerialDevice.createDevice(device, type: UsbSerialDevice.cdc);
```

### Open a device and set it up
```dart
await mDevice.open();
await mDevice.setBaudRate(1000000);
await mDevice.setDataBits(UsbSerialInterface.dataBits8);
await mDevice.setStopBits(UsbSerialInterface.stopBits1);
await mDevice.setParity(UsbSerialInterface.parityNone);
```

### Set flow control if needed (only supported in CP210x devices)
```dart
await mDevice.setFlowControl(UsbSerialInterface.flowControlRtsCts);
```

### Read / Write
```dart
int bytesWritten = await mDevice.write(data, timeout);

Uint8List bytesRead = await mDevice.read(bytesToRead, timeout);
```

### Change the state of DTR/RTS lines
```dart
await mDevice.setDtr(true);
await mDevice.setDtr(false);
await mDevice.setRts(true);
await mDevice.setRts(false);
```

### Set Auto Detach Kernel Driver (only for Linux)
```dart
UsbSerialDevice.setAutoDetachKernelDriver(true);
```

### Close the device
```dart
await mDevice.close();
```

## License
```
MIT License

Copyright (c) 2025 Anashuman Singh

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```