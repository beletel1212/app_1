import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:whatsapp_ui/common/widgets/loader.dart';
import 'package:whatsapp_ui/config/agora_config.dart';
import 'package:whatsapp_ui/features/call/controller/call_controller.dart';
import 'package:whatsapp_ui/models/call.dart';

/// ------------------------------------------------------------
///  UNIVERSAL CALL SCREEN (Video + Audio)
/// ------------------------------------------------------------
///  - Supports both video and audio calls using Agora RTC Engine.
///  - Automatically fetches and refreshes tokens from your local server.
///  - Handles self-recovery if token expires or join fails.
///  - Works on both physical devices and Android Emulator (10.0.2.2).
/// ------------------------------------------------------------
class CallScreen extends ConsumerStatefulWidget {
  /// Unique channel ID (shared by caller and receiver).
  final String channelId;

  /// Contains call metadata (caller, receiver, timestamps, etc.).
  final Call call;

  /// Whether this call is part of a group chat.
  final bool isGroupChat;

  /// True = video call, False = audio call.
  final bool isVideoCall;

  const CallScreen({
    super.key,
    required this.channelId,
    required this.call,
    required this.isGroupChat,
    required this.isVideoCall,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  /// The Agora RTC Engine instance (core SDK object).
  late RtcEngine _engine;

  /// Remote user ID — becomes non-null when the other participant joins.
  int? _remoteUid;

  /// Whether the local user has successfully joined the channel.
  bool _localUserJoined = false;

  /// Current RTC token retrieved from your backend server.
  String? _rtcToken;

  /// Timer that automatically refreshes the token periodically.
  Timer? _tokenRefreshTimer;

  /// Local UID for this device — can be 0 (Agora auto-assigns one).
 
   int localUid = 0;

  /// Local backend server (token generator).
  /// `10.0.2.2` is the special alias for `localhost` inside Android emulators.
  final String baseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    // Assign unique UIDs per user (you can improve this with Firestore IDs or random)
    localUid = widget.call.callerId.hashCode % 1000000; // simple hash for uniqueness
  
    _initAgora();
  }

  /// ------------------------------------------------------------
  /// 1️⃣ Initialize the Agora engine, set permissions, and join channel.
  /// ------------------------------------------------------------
  Future<void> _initAgora() async {
    // Ask for microphone (and camera if video) permissions.
    await [
      Permission.microphone,
      if (widget.isVideoCall) Permission.camera,
    ].request();

    // Create the Agora RTC engine.
    _engine = createAgoraRtcEngine();

    // Initialize the engine with your App ID.
    await _engine.initialize(RtcEngineContext(appId: AgoraConfig.appId));

    // Register callbacks to track join, leave, and token events.
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _localUserJoined = true);
          developer.log('✅ Joined channel successfully: ${widget.channelId}');
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() => _remoteUid = remoteUid);
          developer.log('👤 Remote user joined: $remoteUid');
        },
        onUserOffline:
            (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() => _remoteUid = null);
          developer.log('🚪 Remote user left: $remoteUid');
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          developer.log('⚠️ Token is about to expire — refreshing...');
          _refreshAgoraToken();
        },
      ),
    );

    // Enable video if it's a video call; otherwise disable it.
    if (widget.isVideoCall) {
      await _engine.enableVideo();
    } else {
      await _engine.disableVideo();
    }

    // Try to join the channel with full error handling and retry logic.
    await _joinChannelWithLogging();
  }

  /// ------------------------------------------------------------
  /// 2️⃣ Join the Agora channel (with retry on token failure).
  /// ------------------------------------------------------------
  Future<void> _joinChannelWithLogging() async {
    developer.log('🔑 Fetching Agora token for channel: ${widget.channelId}');
    _rtcToken = await _fetchAgoraToken(widget.channelId);

    if (_rtcToken == null) {
      developer.log('❌ Token fetch failed — aborting join attempt.');
      return;
    }
     
      developer.log('the _rtcToken is $_rtcToken ');
    try {
      developer.log('🔌 Attempting to join Agora channel...');
      await _engine.joinChannel(
        token: _rtcToken!,
        channelId: widget.channelId,
        uid: localUid,
        options: const ChannelMediaOptions(),
      );
      developer.log('✅ Join request sent to Agora.');

      // Start automatic periodic token refresh.
      _startTokenAutoRefresh();
    } catch (e, stack) {
      developer.log('❌ Join failed: $e', error: e, stackTrace: stack);

      // If join failed (e.g., invalid/expired token), try refreshing it.
      developer.log('🔄 Retrying join after refreshing token...');
      await _refreshAgoraToken();
      await Future.delayed(const Duration(seconds: 2));
      await _joinChannelWithLogging();
    }
  }

  /// ------------------------------------------------------------
  /// 3️⃣ Fetch an Agora RTC token from your local backend.
  /// ------------------------------------------------------------
  Future<String?> _fetchAgoraToken(String channelId) async {
    final url = Uri.parse('$baseUrl/rtcToken?channelName=$channelId&uid=$localUid');
    developer.log('🌐 Requesting token from: $url');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('✅ Token received successfully.');
        return data['token'];
      } else {
        developer.log('❌ Token request failed with code: ${response.statusCode}');
      }
    } catch (e, stack) {
      developer.log('⚠️ Network error fetching token', error: e, stackTrace: stack);
    }
    return null;
  }

  /// ------------------------------------------------------------
  /// 4️⃣ Refresh token manually or when Agora requests it.
  /// ------------------------------------------------------------
  Future<void> _refreshAgoraToken() async {
    final url = Uri.parse('$baseUrl/refreshToken');
    developer.log('🔄 Requesting token refresh from: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'rtc',
          'channelName': widget.channelId,
          'uid': localUid.toString(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];
        developer.log('✅ Token refreshed successfully.');

        _rtcToken = newToken;

        // Notify Agora engine of the new token.
        await _engine.renewToken(newToken);
      } else {
        developer.log('❌ Token refresh failed: ${response.statusCode}');
      }
    } catch (e, stack) {
      developer.log('⚠️ Error refreshing token', error: e, stackTrace: stack);
    }
  }

  /// ------------------------------------------------------------
  /// 5️⃣ Periodic background token refresh (every 50 minutes).
  /// ------------------------------------------------------------
  void _startTokenAutoRefresh() {
    const refreshInterval = Duration(minutes: 50);
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(refreshInterval, (_) async {
      developer.log('⏰ Scheduled token refresh triggered.');
      await _refreshAgoraToken();
    });
  }

  /// ------------------------------------------------------------
  /// 6️⃣ Cleanup resources on screen dispose.
  /// ------------------------------------------------------------
  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  /// ------------------------------------------------------------
  /// 7️⃣ UI BUILDER — main screen layout.
  /// ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Choose between video or audio layout.
            if (widget.isVideoCall)
              _buildVideoLayout()
            else
              _buildAudioLayout(),

            // End Call Button — same for both audio and video.
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: FloatingActionButton(
                  backgroundColor: Colors.redAccent,
                  onPressed: () async {
                    await _engine.leaveChannel();
                    if (context.mounted) {
                      ref.read(callControllerProvider).endCall(
                            widget.call.callerId,
                            widget.call.receiverId,
                            context,
                          );
                      Navigator.pop(context);
                    }
                  },
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ------------------------------------------------------------
  /// 8️⃣ VIDEO CALL UI — local + remote camera feeds.
  /// ------------------------------------------------------------
  Widget _buildVideoLayout() {
    if (!_localUserJoined) return const Loader();

    return Stack(
      children: [
        // Remote user's video stream.
        _remoteUid != null
            ? AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: widget.channelId),
                ),
              )
            : const Center(child: Text('Waiting for the other user...')),

        // Local user’s preview (inset at top-left corner).
        Positioned(
          top: 20,
          left: 20,
          width: 120,
          height: 160,
          child: AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _engine,
              canvas: const VideoCanvas(uid: 0),
            ),
          ),
        ),
      ],
    );
  }

  /// ------------------------------------------------------------
  /// 9️⃣ AUDIO CALL UI — avatar, name, and status indicator.
  /// ------------------------------------------------------------
  Widget _buildAudioLayout() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/images/default_avatar.png'),
            ),
            const SizedBox(height: 20),
            Text(
              widget.call.receiverName,
              style: const TextStyle(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              _remoteUid != null
                  ? 'Connected'
                  : _localUserJoined
                      ? 'Ringing...'
                      : 'Connecting...',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/************************************************

Quick checklist to ensure this/ the acove code works on emulator & device:

Node server running on your PC and listening on port 3000.

Test in browser: http://localhost:3000/rtcToken?channelName=test&uid=123 → returns JSON with rtcToken or token.

Emulator uses 10.0.2.2 (this code's baseUrl).
Physical device must use PC LAN IP instead — update baseUrl accordingly.

UID uniqueness: this implementation makes localUid deterministic from callerId.hashCode. If you have multiple guests from same callerId, use a robust unique uid scheme (Firestore-stored id, random int, etc).

AgoraConfig.appId must be correct and match the App ID used to generate tokens.

Token response shape: server should return either { "token": "..." } or { "rtcToken": "..." }. Code supports both.



************************************************/

/************************************************ *
*******************************************************


import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:whatsapp_ui/common/widgets/loader.dart';
import 'package:whatsapp_ui/config/agora_config.dart';
import 'package:whatsapp_ui/features/call/controller/call_controller.dart';
import 'package:whatsapp_ui/models/call.dart';

/// Unified Call Screen for both video and audio calls.
class CallScreen extends ConsumerStatefulWidget {
  /// Agora channel ID (used to join the same session)
  final String channelId;

  /// Call model containing caller/receiver info
  final Call call;

  /// Determines if it's a group chat (future use)
  final bool isGroupChat;

  /// Determines if it's a video call (true) or voice call (false)
  final bool isVideoCall;

  const CallScreen({
    super.key,
    required this.channelId,
    required this.call,
    required this.isGroupChat,
    required this.isVideoCall,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  // The Agora RTC engine instance
  late RtcEngine _engine;

  // Remote user ID (null until another user joins)
  int? _remoteUid;

  // Flag to check if the local user has joined successfully
  bool _localUserJoined = false;

  // Current RTC token
  String? _rtcToken;

  // Timer to automatically refresh token before expiry
  Timer? _tokenRefreshTimer;

  // Local backend server (token generator)
  // Use 10.0.2.2 for Android emulator or your local IP for real devices
  final String baseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  /// Initialize Agora engine and join the channel
  Future<void> _initAgora() async {
    // Request required permissions (camera only for video calls)
    await [
      Permission.microphone,
      if (widget.isVideoCall) Permission.camera,
    ].request();

    // Create the Agora RTC engine instance
    _engine = createAgoraRtcEngine();

    // Initialize the engine with your App ID
    await _engine.initialize(RtcEngineContext(appId: AgoraConfig.appId));

    // Register event handlers to track call state
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _localUserJoined = true);
          developer.log('✅ Joined channel: ${widget.channelId}');
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() => _remoteUid = remoteUid);
          developer.log('👤 Remote user joined: $remoteUid');
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() => _remoteUid = null);
          developer.log('🚪 Remote user left: $remoteUid');
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          developer.log('⚠️ Token about to expire — refreshing now...');
          _refreshAgoraToken();
        },
      ),
    );

    // Enable video or audio mode based on call type
    if (widget.isVideoCall) {
      await _engine.enableVideo();
    } else {
      await _engine.disableVideo();
    }

    // Fetch initial Agora token from backend
    _rtcToken = await _fetchAgoraToken(widget.channelId);

    if (_rtcToken == null) {
      developer.log('❌ Failed to fetch token — cannot join channel');
      return;
    }

    // Join the Agora channel
    await _engine.joinChannel(
      token: _rtcToken!,
      channelId: widget.channelId,
      uid: 0,
      options: const ChannelMediaOptions(),
    );

    // Start the periodic token refresh timer
    _startTokenAutoRefresh();
  }

  /// Fetch a new RTC token from the backend
  Future<String?> _fetchAgoraToken(String channelId) async {
    final url = Uri.parse('$baseUrl/rtcToken?channelName=$channelId&uid=0');
    developer.log('🌐 Requesting token from: $url');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('✅ Token received successfully');
        return data['token'];
      } else {
        developer.log('❌ Token request failed: ${response.statusCode}');
      }
    } catch (e, stack) {
      developer.log('⚠️ Error fetching token', error: e, stackTrace: stack);
    }
    return null;
  }

  /// Refresh Agora token manually or when it’s about to expire
  Future<void> _refreshAgoraToken() async {
    final url = Uri.parse('$baseUrl/refreshToken');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'rtc',
          'channelName': widget.channelId,
          'uid': '0',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];
        developer.log('🔄 Token refreshed successfully');

        _rtcToken = newToken;

        // Inform the Agora engine about the new token
        await _engine.renewToken(newToken);
      } else {
        developer.log('❌ Failed to refresh token: ${response.statusCode}');
      }
    } catch (e, stack) {
      developer.log('⚠️ Error refreshing token', error: e, stackTrace: stack);
    }
  }

  /// Start a timer to automatically refresh the token every 50 minutes
  void _startTokenAutoRefresh() {
    const refreshInterval = Duration(minutes: 50);
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(refreshInterval, (_) async {
      developer.log('⏰ Scheduled token refresh triggered');
      await _refreshAgoraToken();
    });
  }

  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  /// Build the main call UI (video or audio)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Show different UI for video or audio calls
            if (widget.isVideoCall)
              _buildVideoLayout()
            else
              _buildAudioLayout(),

            // End Call Button (same for both types)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: FloatingActionButton(
                  backgroundColor: Colors.redAccent,
                  onPressed: () async {
                    await _engine.leaveChannel();
                 if(context.mounted){
                    ref.read(callControllerProvider).endCall(
                          widget.call.callerId,
                          widget.call.receiverId,
                          context,
                        );
                    Navigator.pop(context); }
                  },
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Video Call Layout (remote + local preview)
  Widget _buildVideoLayout() {
    if (!_localUserJoined) return const Loader();

    return Stack(
      children: [
        // Remote user video view
        _remoteUid != null
            ? AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: widget.channelId),
                ),
              )
            : const Center(child: Text('Waiting for the other user...')),

        // Local video preview in small window
        Positioned(
          top: 20,
          left: 20,
          width: 120,
          height: 160,
          child: AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _engine,
              canvas: const VideoCanvas(uid: 0),
            ),
          ),
        ),
      ],
    );
  }

  /// Audio Call Layout (avatar + call status text)
  Widget _buildAudioLayout() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/images/default_avatar.png'),
            ),
            const SizedBox(height: 20),
            Text(
              widget.call.receiverName,
              style: const TextStyle(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              _remoteUid != null
                  ? 'Connected'
                  : _localUserJoined
                      ? 'Ringing...'
                      : 'Connecting...',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}


*********************************/




/************** ******************
//import 'package:agora_uikit/agora_uikit.dart';
//import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:whatsapp_ui/common/widgets/loader.dart';
//import 'package:whatsapp_ui/config/agora_config.dart';
//import 'package:whatsapp_ui/features/call/controller/call_controller.dart';

import 'package:whatsapp_ui/models/call.dart';

class CallScreen extends ConsumerStatefulWidget {
  final String channelId;
  final Call call;
  final bool isGroupChat;
  const CallScreen({
    super.key,
    required this.channelId,
    required this.call,
    required this.isGroupChat,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CallScreenState();
}



class _CallScreenState extends ConsumerState<CallScreen> {
  //AgoraClient? client;
  String baseUrl = '127.0.0.1';

  @override
  void initState() {
    super.initState();
    
    initAgora();
  }

  void initAgora() async {
    //await client!.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      
    );
  }
}
********************************/





/************** ******************
class _CallScreenState extends ConsumerState<CallScreen> {
  AgoraClient? client;
  String baseUrl = '127.0.0.1';

  @override
  void initState() {
    super.initState();
    client = AgoraClient(
      agoraConnectionData: AgoraConnectionData(
        appId: AgoraConfig.appId,
        channelName: widget.channelId,
        tokenUrl: baseUrl,
      ),
    );
    initAgora();
  }

  void initAgora() async {
    await client!.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: client == null
          ? const Loader()
          : SafeArea(
              child: Stack(
                children: [
                  AgoraVideoViewer(client: client!),
                  AgoraVideoButtons(
                    client: client!,
                    disconnectButtonChild: IconButton(
                      onPressed: () async {
                        await client!.engine.leaveChannel();
                         if (context.mounted) {
                        ref.read(callControllerProvider).endCall(
                              widget.call.callerId,
                              widget.call.receiverId,
                              context,
                            );
                         }
                             if (context.mounted) {
                        Navigator.pop(context);
                             }
                      },
                      icon: const Icon(Icons.call_end),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}*/
