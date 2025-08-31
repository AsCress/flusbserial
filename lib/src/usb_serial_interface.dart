import 'dart:typed_data';

interface class UsbSerialInterface {
  static final int dataBits5 = 5;
  static final int dataBits6 = 6;
  static final int dataBits7 = 7;
  static final int dataBits8 = 8;

  static final int stopBits1 = 1;
  static final int stopBits1_5 = 3;
  static final int stopBits2 = 2;

  static final int parityNone = 0;
  static final int parityOdd = 1;
  static final int parityEven = 2;
  static final int parityMark = 3;
  static final int paritySpace = 4;

  static final int flowControlOff = 0;
  static final int flowControlRtsCts = 1;
  static final int flowControlDsrDtr = 2;
  static final int flowControlXonXoff = 3;

  Future<bool> open() async {
    throw UnimplementedError();
  }

  Future<int> write(Uint8List data, int timeout) async {
    throw UnimplementedError();
  }

  Future<Uint8List> read(int bytesToRead, int timeout) async {
    throw UnimplementedError();
  }

  Future<void> close() async {
    throw UnimplementedError();
  }

  Future<void> setBaudRate(int baudRate) async {
    throw UnimplementedError();
  }

  Future<void> setDataBits(int dataBits) async {
    throw UnimplementedError();
  }

  Future<void> setStopBits(int stopBits) async {
    throw UnimplementedError();
  }

  Future<void> setParity(int parity) async {
    throw UnimplementedError();
  }

  Future<void> setFlowControl(int flowControl) async {
    throw UnimplementedError();
  }

  Future<void> setBreak(bool state) async {
    throw UnimplementedError();
  }
}
