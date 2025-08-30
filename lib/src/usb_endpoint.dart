class UsbEndpoint {
  static final int maskNumber = 0x07;
  static final int maskDirection = 0x80;
  static final int directionIn = 0x80;
  static final int directionOut = 0x00;

  final int endpointNumber;
  final int direction;

  UsbEndpoint({required this.endpointNumber, required this.direction});

  factory UsbEndpoint.fromMap(Map<dynamic, dynamic> map) {
    return UsbEndpoint(
      endpointNumber: map['endpointNumber'],
      direction: map['direction'],
    );
  }

  int get endpointAddress => endpointNumber | direction;

  Map<String, dynamic> toMap() {
    return {'endpointNumber': endpointNumber, 'direction': direction};
  }

  @override
  String toString() => toMap().toString();
}
