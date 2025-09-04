import 'dart:typed_data';

/// Defines the common interface for USB serial devices.
///
/// All USB serial device implementations (e.g., CDC, CP210x) must
/// implement this contract. It provides constants for common
/// serial configurations and abstract methods for I/O and control.
interface class UsbSerialInterface {
  // ---------------------------------------------------------------------------
  // Serial configuration constants
  // ---------------------------------------------------------------------------

  /// Data Bits: 5.
  static final int dataBits5 = 5;

  /// Data Bits: 6.
  static final int dataBits6 = 6;

  /// Data Bits: 7.
  static final int dataBits7 = 7;

  /// Data Bits: 8.
  static final int dataBits8 = 8;

  /// Stop Bits: 1.
  static final int stopBits1 = 1;

  /// Stop Bits: 1.5.
  static final int stopBits1_5 = 3;

  /// Stop Bits: 2.
  static final int stopBits2 = 2;

  /// No parity.
  static final int parityNone = 0;

  /// Odd parity.
  static final int parityOdd = 1;

  /// Even parity.
  static final int parityEven = 2;

  /// Mark parity.
  static final int parityMark = 3;

  /// Space parity.
  static final int paritySpace = 4;

  /// No flow control.
  static final int flowControlOff = 0;

  /// Hardware flow control using RTS/CTS.
  static final int flowControlRtsCts = 1;

  /// Hardware flow control using DSR/DTR.
  static final int flowControlDsrDtr = 2;

  /// Software flow control using XON/XOFF.
  static final int flowControlXonXoff = 3;

  // ---------------------------------------------------------------------------
  // Device control methods
  // ---------------------------------------------------------------------------

  /// Opens the device and prepares it for communication.
  Future<bool> open() async {
    throw UnimplementedError();
  }

  /// Writes [data] to the device.
  ///
  /// [timeout] is specified in milliseconds.
  /// Returns the number of bytes successfully written.
  Future<int> write(Uint8List data, int timeout) async {
    throw UnimplementedError();
  }

  /// Reads [bytesToRead] bytes from the device.
  ///
  /// [timeout] is specified in milliseconds.
  /// Returns a [Uint8List] containing the received data.
  Future<Uint8List> read(int bytesToRead, int timeout) async {
    throw UnimplementedError();
  }

  /// Closes the device and releases resources.
  Future<void> close() async {
    throw UnimplementedError();
  }

  /// Sets the baud rate (bits per second).
  Future<void> setBaudRate(int baudRate) async {
    throw UnimplementedError();
  }

  /// Sets the number of data bits (see [dataBits5]–[dataBits8]).
  Future<void> setDataBits(int dataBits) async {
    throw UnimplementedError();
  }

  /// Sets the number of stop bits (see [stopBits1], [stopBits1_5], [stopBits2]).
  Future<void> setStopBits(int stopBits) async {
    throw UnimplementedError();
  }

  /// Sets the parity mode (see [parityNone]–[paritySpace]).
  Future<void> setParity(int parity) async {
    throw UnimplementedError();
  }

  /// Sets the flow control mode (see [flowControlOff]–[flowControlXonXoff]).
  Future<void> setFlowControl(int flowControl) async {
    throw UnimplementedError();
  }

  /// Enables or disables the break condition.
  Future<void> setBreak(bool state) async {
    throw UnimplementedError();
  }

  /// Sets the DTR (Data Terminal Ready) line.
  Future<void> setDtr(bool state) async {
    throw UnimplementedError();
  }

  /// Sets the RTS (Request To Send) line.
  Future<void> setRts(bool state) async {
    throw UnimplementedError();
  }
}
