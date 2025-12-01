import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({
    required this.videoUrl,
    super.key,
  });

  final String videoUrl;

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Determinar si es URL de red o archivo local
      if (widget.videoUrl.startsWith('http://') || widget.videoUrl.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      } else {
        // Si no es URL, intentar como asset (aunque probablemente no se use)
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      }

      await _controller.initialize();
      _controller.setLooping(true);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
      }
    } catch (e) {
      debugPrint('Error al inicializar video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Implementar descarga
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Descarga en desarrollo')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _hasError
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Error al cargar el video',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              )
            : !_isInitialized
                ? const CircularProgressIndicator(color: Colors.white)
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_controller.value.isPlaying) {
                              _controller.pause();
                            } else {
                              _controller.play();
                            }
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: AnimatedOpacity(
                              opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                Icons.play_circle_outline,
                                color: Colors.white,
                                size: 80,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.green,
                            bufferedColor: Colors.grey,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
