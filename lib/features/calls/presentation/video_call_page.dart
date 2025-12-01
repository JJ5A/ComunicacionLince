import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallPage extends StatefulWidget {
  const VideoCallPage({
    super.key,
    required this.conversationTitle,
    required this.channelName,
    required this.agoraAppId,
    this.token,
  });

  final String conversationTitle;
  final String channelName;
  final String agoraAppId;
  final String? token;

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  RtcEngine? _engine;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _isJoined = false;
  int? _remoteUid;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAgora();
  }

  Future<void> _initializeAgora() async {
    try {
      // Solicitar permisos
      await [Permission.microphone, Permission.camera].request();

      // Crear motor de Agora
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: widget.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Configurar eventos
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (kDebugMode) {
              debugPrint('📞 Unido al canal: ${connection.channelId}');
            }
            setState(() {
              _isJoined = true;
              _isLoading = false;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (kDebugMode) {
              debugPrint('👤 Usuario remoto conectado: $remoteUid');
            }
            setState(() {
              _remoteUid = remoteUid;
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            if (kDebugMode) {
              debugPrint('👤 Usuario remoto desconectado: $remoteUid');
            }
            setState(() {
              _remoteUid = null;
            });
          },
          onError: (ErrorCodeType err, String msg) {
            if (kDebugMode) {
              debugPrint('❌ Error de Agora: $err - $msg');
            }
            setState(() {
              _errorMessage = 'Error: $msg';
            });
          },
        ),
      );

      // Habilitar video
      await _engine!.enableVideo();
      await _engine!.startPreview();

      // Unirse al canal
      await _engine!.joinChannel(
        token: widget.token ?? '',
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inicializando Agora: $e');
      }
      setState(() {
        _errorMessage = 'Error al inicializar videollamada: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _engine?.muteLocalAudioStream(_isMuted);
  }

  Future<void> _toggleCamera() async {
    setState(() => _isCameraOff = !_isCameraOff);
    await _engine?.muteLocalVideoStream(_isCameraOff);
  }

  Future<void> _switchCamera() async {
    await _engine?.switchCamera();
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    await _engine?.setEnableSpeakerphone(_isSpeakerOn);
  }

  Future<void> _leaveChannel() async {
    await _engine?.leaveChannel();
    await _engine?.release();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _leaveChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Conectando...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.error_outline, color: Colors.red, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Volver'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: <Widget>[
                      // Video remoto (pantalla completa)
                      if (_remoteUid != null)
                        AgoraVideoView(
                          controller: VideoViewController.remote(
                            rtcEngine: _engine!,
                            canvas: VideoCanvas(uid: _remoteUid),
                            connection: RtcConnection(channelId: widget.channelName),
                          ),
                        )
                      else
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.person_outline, color: Colors.white54, size: 80),
                              SizedBox(height: 16),
                              Text(
                                'Esperando a que se una otro participante...',
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                      // Información del canal
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.conversationTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _remoteUid != null ? 'En llamada' : 'Esperando...',
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Video local (pequeño en la esquina)
                      if (!_isCameraOff)
                        Positioned(
                          top: 100,
                          right: 16,
                          width: 120,
                          height: 160,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: AgoraVideoView(
                                controller: VideoViewController(
                                  rtcEngine: _engine!,
                                  canvas: const VideoCanvas(uid: 0),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Controles
                      Positioned(
                        bottom: 40,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            _CallButton(
                              icon: _isMuted ? Icons.mic_off : Icons.mic,
                              color: _isMuted ? Colors.red : Colors.white,
                              backgroundColor: _isMuted ? Colors.white : Colors.black54,
                              onPressed: _toggleMute,
                            ),
                            _CallButton(
                              icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                              color: _isCameraOff ? Colors.red : Colors.white,
                              backgroundColor: _isCameraOff ? Colors.white : Colors.black54,
                              onPressed: _toggleCamera,
                            ),
                            _CallButton(
                              icon: Icons.call_end,
                              backgroundColor: Colors.red,
                              color: Colors.white,
                              size: 64,
                              onPressed: _leaveChannel,
                            ),
                            _CallButton(
                              icon: Icons.cameraswitch,
                              color: Colors.white,
                              backgroundColor: Colors.black54,
                              onPressed: _switchCamera,
                            ),
                            _CallButton(
                              icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                              color: Colors.white,
                              backgroundColor: Colors.black54,
                              onPressed: _toggleSpeaker,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.color,
    this.size = 56,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FloatingActionButton(
        heroTag: icon.toString(),
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        child: Icon(icon, color: color, size: size * 0.4),
      ),
    );
  }
}
