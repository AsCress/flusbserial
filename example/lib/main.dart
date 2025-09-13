import 'dart:convert';
import 'dart:typed_data';

import 'package:flusbserial/flusbserial.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String versionString = '';
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('FlUsbSerial example')),
        body: Center(
          child: Column(
            children: [
              TextButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.blueAccent),
                ),
                onPressed: () async {
                  UsbSerialDevice.init();
                  late UsbSerialDevice mDevice;
                  List<UsbDevice> devices = await UsbSerialDevice.listDevices();
                  for (var device in devices) {
                    if (device.vendorId == 0x10C4 &&
                        device.productId == 0xEA60) {
                      mDevice = UsbSerialDevice.createDevice(
                        device,
                        interfaceId: 0,
                      )!;
                      break;
                    }
                  }
                  UsbSerialDevice.setAutoDetachKernelDriver(true);
                  await mDevice.open();
                  await mDevice.setBaudRate(1000000);
                  await mDevice.setDataBits(UsbSerialInterface.dataBits8);
                  await mDevice.setStopBits(UsbSerialInterface.stopBits1);
                  await mDevice.setParity(UsbSerialInterface.parityNone);

                  await mDevice.write(Uint8List.fromList([11 & 0xFF]), 500);
                  await mDevice.write(Uint8List.fromList([5 & 0xFF]), 500);

                  Uint8List buffer = await mDevice.read(9, 500);
                  debugPrint('Read: $buffer');
                  String version = utf8.decode(buffer).split('\n').first;
                  debugPrint('Version String: $version');
                  setState(() {
                    versionString = version;
                  });

                  await mDevice.close();
                  UsbSerialDevice.exit();
                },
                child: Text(
                  'Get Version String',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Text(
                'Version: $versionString',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
