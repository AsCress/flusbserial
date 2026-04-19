## 0.4.0

* Switch to [`dart_libusb`](https://pub.dev/packages/dart_libusb) for ffi bindings.

## 0.3.3

* Migrates to spm for macOS.

## 0.3.2

* Implements missing functions in the CH34x driver.

## 0.3.1

* Fixes USB read operation to return only the actual number of bytes transferred, preventing garbage data on partial reads.

## 0.3.0

* Switch to system libusb on Linux and macOS.

## 0.2.2

* Adds `setAutoDetachKernelDriver` for Linux.
* Fixes libusb bundling with macOS Pod.

## 0.2.1

* Fixes libusb bundling on Linux

## 0.2.0

* Adds support for CH34x-based devices.
* Adds support for manual driver selection.
* Fixes interface selection for CDC devices.

## 0.1.1

* Fixes dependency resolution.

## 0.1.0

* Initial development release.
