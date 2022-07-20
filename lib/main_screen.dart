import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

const appId = 'ffc03d4b42bf41d0ba477284b2936cc7';
const token =
    '006ffc03d4b42bf41d0ba477284b2936cc7IAC2MHHwCkMac4jE5+UeOrxd9TcVDkQsoO6N9P9je7LpgtzDPrsAAAAAEACPl0pWziPRYgEAAQDNI9Fi';
const channelId = "firstChannel";

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int? remoteId;
  RtcEngine? rtcEngine;

  Future<bool> _validateTools({required BuildContext context}) async {
    var haveRecordPermission = await microphonePermission();
    var haveCameraPermission = await cameraPermission();
    if (!haveRecordPermission) {
      showMessage("You need to give record voice permission.");
      return false;
    } else if (!haveCameraPermission) {
      showMessage("You need to give camera permission.");
      return false;
    }

    return true;
  }

  void showMessage(String title) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(title)));
  }

  Future<void> initAgora(BuildContext context) async {
    //Permission Camera and audio
    if (!await _validateTools(context: context)) {
      await Future.delayed(const Duration(microseconds: 300), () {
        Navigator.pop(context);
      });
      return;
    }

    // Initializing RTC Engine
    rtcEngine = await RtcEngine.createWithContext(RtcEngineContext(appId));

    if (rtcEngine != null) {
      // Enabling Video
      await rtcEngine!.enableVideo();
      await rtcEngine!.enableLocalVideo(true);

      // Event Handeling
      rtcEngine!.setEventHandler(
        RtcEngineEventHandler(
          joinChannelSuccess: (channel, uid, elapsed) {
            debugPrint('Current User $uid joined');
          },
          userJoined: (uid, elapsed) {
            debugPrint('Other User $uid joined');
            setState(() {
              remoteId = uid;
            });
          },
          userOffline: (uid, offlineReason) {
            debugPrint('Other User $uid left');
            setState(() {
              remoteId = null;
            });
          },
        ),
      );

      // Joining Channel
      await rtcEngine!.joinChannel(token, channelId, null, 0);
    }
  }

  @override
  void dispose() {
    // destroy sdk
    if (rtcEngine != null) {
      rtcEngine!.leaveChannel();
      rtcEngine!.destroy();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initAgora(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agora Test'),
      ),
      body: Stack(
        children: [
          Center(
            child: otherUserPreview(),
          ),
          Positioned(
            top: 20,
            right: 10,
            child: SizedBox(
              height: 180,
              width: 130,
              child: Center(
                child: currentUserPreview(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Current User View
  Widget currentUserPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.0),
      child: const SizedBox(
        width: 120,
        height: 170,
        child: rtc_local_view.SurfaceView(),
      ),
    );
  }

  // Other User View
  Widget otherUserPreview() {
    if (remoteId != null) {
      return Stack(
        children: [
          rtc_remote_view.SurfaceView(
            uid: remoteId!,
            channelId: channelId,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: buttonBar(),
          ),
        ],
      );
    } else {
      return const Text('Please Wait.. While other user joins');
    }
  }

  // Buttons
  Widget buttonBar() {
    return Container(
      padding: const EdgeInsets.only(bottom: 30),
      child: IconButton(
        onPressed: () {
          rtcEngine!.leaveChannel();
          rtcEngine!.destroy();
          Navigator.pop(context);
        },
        icon: const Icon(
          Icons.call_end,
          size: 50,
          color: Colors.red,
        ),
      ),
    );
  }
}

Future<bool> microphonePermission() async {
  try {
    var status = await Permission.microphone.request();
    if (status == PermissionStatus.granted) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}

Future<bool> cameraPermission() async {
  try {
    var status = await Permission.camera.request();
    if (status == PermissionStatus.granted) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}
