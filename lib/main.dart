import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:weylusmousereplacement/dimens.dart';
import 'package:weylusmousereplacement/global.dart';
import 'package:weylusmousereplacement/settings.dart' as SettingsDialog;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weylus Mouse Replacement',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Weylus Mouse Replacement'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum Mode { LEFT_CLICK, RIGHT_CLICK, SCROLL, MIDDLE_MOUSE }

class _MyHomePageState extends State<MyHomePage> {
  late WebSocketChannel channel;
  bool ready = false;

  Mode mode = Mode.LEFT_CLICK;
  bool? down;
  (double, double)? downStart;
  int prevButtons = 0;
  int prevPrevButtons = 0;

  int clickCount = 0;
  Timer? clickTimer;

  bool socketClosed = true;
  bool socketLoading = true;
  int connectTimestamp = 0;

  (int, (double, double)) previousClickDetails = (0, (0, 0));

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    WakelockPlus.enable();

    connect();
    super.initState();
  }

  Future<void> connect() async {
    final ipAddress = await storage.read(key: 'server_ip') ?? "";
    final accessCode = await storage.read(key: 'access_code') ?? "";
    try {
      channel = IOWebSocketChannel.connect(
        Uri.parse('ws://$ipAddress:9001/'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Android 14; Mobile; rv:145.0) Gecko/145.0 Firefox/145.0',
          'Accept': '*/*',
          'Accept-Language': 'en-US',
          'Accept-Encoding': 'gzip, deflate',
          'Sec-WebSocket-Version': '13',
          'Origin': 'http://192.168.1.180:1701',
          'Sec-WebSocket-Extensions': 'permessage-deflate',
          'Sec-WebSocket-Key': '0wR7NAmEb889xUSZDonXxQ==',
          'Connection': 'keep-alive, Upgrade',
          'Pragma': 'no-cache',
          'Cache-Control': 'no-cache',
          'Upgrade': 'websocket',
        },
      );
      connectTimestamp = DateTime.now().millisecondsSinceEpoch;

      channel.stream.listen(
        (message) {
          socketClosed = false;
          print('Received: $message');
          switch (message) {
            case '"ConfigOk"':
              ready = true;
          }
          setState(() {});
        },
        onError: (error) {
          print('Error: $error');
          connectTimestamp = 0;
          socketClosed = true;
          socketLoading = false;
          setState(() {});
        },
        onDone: () {
          print('WebSocket closed');
          connectTimestamp = 0;
          socketClosed = true;
          socketLoading = false;
          setState(() {});
        },
      );

      channel.sink.add(accessCode);
      channel.sink.add('"GetCapturableList"');
      channel.sink.add('"RequestVirtualKeysProfiles"');
      channel.sink.add(
        jsonEncode({
          "Config": {"capturable_id": 0, "uinput_support": true, "capture_cursor": false, "max_width": 200, "max_height": 105},
        }),
      );
    } catch (e) {
      print(e);
      socketLoading = false;
      socketClosed = true;
      setState(() {});
    }
  }

  Future<void> vibrateOnce() async {
    HapticFeedback.vibrate();
    if (await Vibration.hasVibrator() == true) {
      await Vibration.vibrate();
    }
  }

  void addToSink(String json) {
    channel.sink.add(json);
  }

  void sendMessage(double x, double y, {buttons = 0, button = 0, eventType = "pointermove"}) async {
    if (socketClosed) return;
    if (prevButtons != buttons && eventType != "pointerdown") {
      addToSink(
        jsonEncode({
          "PointerEvent": {
            "event_type": "pointerup",
            "pointer_id": 0,
            "timestamp": DateTime.now().millisecondsSinceEpoch - connectTimestamp,
            "is_primary": true,
            "pointer_type": "mouse",
            "button": prevButtons,
            "buttons": 0,
            "x": x,
            "y": y,
            "movement_x": 0,
            "movement_y": 0,
            "pressure": 0,
            "tilt_x": 0,
            "tilt_y": 0,
            "width": 0.0006644581511011717,
            "height": 0.0006644581511011717,
            "twist": 0,
          },
        }),
      );
    }
    prevPrevButtons = prevButtons;
    prevButtons = buttons;

    if (down != null) {
      if (eventType == "pointerdown" && buttons == 2 && mode != Mode.LEFT_CLICK) {
        down = true;
        downStart = (x * 100, y * 100);
      } else {
        if (buttons != 2 && button != 2 && prevPrevButtons != 2) {
          if (down != null) {
            mode = Mode.LEFT_CLICK;
            down = null;
            downStart = null;
            return;
          }
        }
      }

      if (down == true) {
        int buttonsVal = 0;
        switch (mode) {
          case Mode.LEFT_CLICK:
            buttonsVal = 1;
            break;
          case Mode.SCROLL:
            {
              final dx = (x * 100 - (downStart?.$1 ?? 0)) * -1;
              final dy = (y * 100 - (downStart?.$2 ?? 0));
              if (eventType == "pointerup") {
                down = false;
                downStart = null;
                return;
              }
              channel.sink.add(
                jsonEncode({
                  "WheelEvent": {
                    "dx": (dx * 100).round(),
                    "dy": (dy * 100).round(),
                    "timestamp": DateTime.now().millisecondsSinceEpoch - connectTimestamp,
                  },
                }),
              );
              downStart = (x * 100, y * 100);
              return;
            }
          case Mode.RIGHT_CLICK:
            buttonsVal = 2;
            break;
          case Mode.MIDDLE_MOUSE:
            buttonsVal = 4;
            break;
        }
        addToSink(
          jsonEncode({
            "PointerEvent": {
              "event_type": eventType,
              "pointer_id": 0,
              "timestamp": DateTime.now().millisecondsSinceEpoch - connectTimestamp,
              "is_primary": true,
              "pointer_type": "mouse",
              "button": eventType == "pointerdown" ? buttonsVal : (eventType == "pointerup" ? buttonsVal : 0),
              "buttons": eventType == "pointerdown" ? buttonsVal : (eventType == "pointerup" ? 0 : buttonsVal),
              "x": x,
              "y": y,
              "movement_x": 0,
              "movement_y": 0,
              "pressure": eventType != "pointerup" ? 0.5 : 0,
              "tilt_x": 0,
              "tilt_y": 0,
              "width": 0.0006644581511011717,
              "height": 0.0006644581511011717,
              "twist": 0,
            },
          }),
        );
      } else {
        addToSink(
          jsonEncode({
            "PointerEvent": {
              "event_type": "pointermove",
              "pointer_id": 0,
              "timestamp": DateTime.now().millisecondsSinceEpoch - connectTimestamp,
              "is_primary": true,
              "pointer_type": "mouse",
              "button": 0,
              "buttons": 0,
              "x": x,
              "y": y,
              "movement_x": 0,
              "movement_y": 0,
              "pressure": 0,
              "tilt_x": 0,
              "tilt_y": 0,
              "width": 0.0006644581511011717,
              "height": 0.0006644581511011717,
              "twist": 0,
            },
          }),
        );
      }

      return;
    }

    final overrideXY =
        eventType == "pointerdown" &&
            DateTime.now().millisecondsSinceEpoch - previousClickDetails.$1 < 1000 &&
            sqrt(pow(x - previousClickDetails.$2.$1, 2) + pow(y - previousClickDetails.$2.$2, 2)) <= 0.02
        ? previousClickDetails.$2
        : null;

    addToSink(
      jsonEncode({
        "PointerEvent": {
          "event_type": eventType,
          "pointer_id": 0,
          "timestamp": DateTime.now().millisecondsSinceEpoch - connectTimestamp,
          "is_primary": true,
          "pointer_type": "mouse",
          "button": eventType == "pointerdown" ? buttons : button,
          "buttons": buttons,
          "x": overrideXY?.$1 ?? x,
          "y": overrideXY?.$2 ?? y,
          "movement_x": 0,
          "movement_y": 0,
          "pressure": buttons != 0 ? 0.5 : 0,
          "tilt_x": 0,
          "tilt_y": 0,
          "width": 0.0006644581511011717,
          "height": 0.0006644581511011717,
          "twist": 0,
        },
      }),
    );

    if (eventType == "pointerdown") {
      previousClickDetails = (DateTime.now().millisecondsSinceEpoch, (x, y));
    }
  }

  Future<void> detectButtonClicks(int buttons) async {
    if (socketClosed) return;
    if (buttons == 2 && prevButtons == 0 && prevPrevButtons == 0 && down != true) {
      clickCount++;
      Future.delayed(Duration.zero, () async {
        final player = AudioPlayer();
        await player.setVolume(0.2);
        await player.setAsset("assets/audio/single_ratchet.wav");
        await player.play();
        await player.stop();
      });
      clickTimer?.cancel();
      print('Detected $clickCount clicks');
      down = false;
      switch (clickCount) {
        case 1:
          mode = Mode.RIGHT_CLICK;
        case 2:
          {
            mode = Mode.SCROLL;
            await vibrateOnce();
            break;
          }
        case 3:
        case 4:
        case 5:
        case 6:
          {
            mode = Mode.MIDDLE_MOUSE;
            await vibrateOnce();
            break;
          }
      }

      clickTimer = Timer(Duration(milliseconds: 500), () async {
        clickCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
        onPointerDown: (e) {
          if (e.kind != PointerDeviceKind.stylus) return;
          sendMessage(
            e.position.dx / MediaQuery.of(context).size.width,
            e.position.dy / MediaQuery.of(context).size.height,
            eventType: "pointerdown",
            button: e.buttons,
            buttons: e.buttons,
          );
        },
        onPointerMove: (e) {
          if (e.kind != PointerDeviceKind.stylus) return;
          sendMessage(
            e.position.dx / MediaQuery.of(context).size.width,
            e.position.dy / MediaQuery.of(context).size.height,
            eventType: "pointermove",
            button: 0,
            buttons: e.buttons,
          );
        },
        onPointerHover: (e) {
          if (e.kind != PointerDeviceKind.stylus) return;
          detectButtonClicks(e.buttons);
          sendMessage(
            e.position.dx / MediaQuery.of(context).size.width,
            e.position.dy / MediaQuery.of(context).size.height,
            eventType: "pointermove",
            button: 0,
            buttons: e.buttons,
          );
        },
        onPointerUp: (e) {
          if (e.kind != PointerDeviceKind.stylus) return;
          sendMessage(
            e.position.dx / MediaQuery.of(context).size.width,
            e.position.dy / MediaQuery.of(context).size.height,
            eventType: "pointerup",
            button: e.buttons,
            buttons: 0,
          );
        },
        child: Stack(
          children: [
            Container(color: Colors.black, width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.height),
            if (!socketClosed)
              Positioned.fill(
                right: null,
                child: SizedBox(
                  width: spaceXL * 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Expanded(
                      //   child: Listener(
                      //     onPointerDown: (e) async {
                      //       if (e.kind == PointerDeviceKind.touch) {
                      //         print("////1");
                      //       }
                      //     },
                      //     child: Container(
                      //       decoration: BoxDecoration(color: Colors.pinkAccent),
                      //       child: Center(
                      //         child: Text(
                      //           "1".toUpperCase(),
                      //           style: TextStyle(fontWeight: FontWeight.bold, fontSize: textXL, color: Colors.black),
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      Listener(
                        onPointerDown: (e) async {
                          if (e.kind == PointerDeviceKind.touch) {
                            print("////disconnect");
                            await channel.sink.close();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: spaceXL),
                          decoration: BoxDecoration(color: Colors.pinkAccent),
                          child: Icon(Icons.close, size: textXL, color: Colors.black),
                        ),
                      ),
                      Listener(
                        onPointerDown: (e) async {
                          if (e.kind == PointerDeviceKind.touch) {
                            print("////settings");
                            await SettingsDialog.showDialog(context);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: spaceXL),
                          decoration: BoxDecoration(color: Colors.pinkAccent),
                          child: Icon(Icons.settings, size: textXL, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (socketClosed)
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          socketLoading = true;
                          setState(() {});
                          connect();
                        },
                        style: ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM)),
                          backgroundColor: WidgetStatePropertyAll(Colors.pinkAccent),
                        ),
                        icon: socketLoading
                            ? SizedBox.square(
                                dimension: spaceLG,
                                child: CircularProgressIndicator(color: Colors.black),
                              )
                            : Icon(Icons.cloud, size: textXL, color: Colors.black),
                        label: Text(
                          "Reconnect".toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: textXL, color: Colors.black),
                        ),
                      ),
                      SizedBox(height: spaceMD),
                      TextButton.icon(
                        onPressed: () async {
                          await SettingsDialog.showDialog(context);
                        },
                        style: ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceXS)),
                          backgroundColor: WidgetStatePropertyAll(Colors.pinkAccent),
                        ),
                        icon: Icon(Icons.settings, size: textLG, color: Colors.black),
                        label: Text(
                          "Settings".toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: textLG, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
