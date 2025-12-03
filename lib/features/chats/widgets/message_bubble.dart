import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/conversation.dart';
import '../../../models/message.dart';
import '../../../models/user_profile.dart';
import '../../../theme/design_tokens.dart';
import 'image_viewer_page.dart';
import 'video_player_page.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.conversation,
    required this.sender,
  });

  final Message message;
  final bool isMine;
  final Conversation conversation;
  final UserProfile? sender;

  @override
  Widget build(BuildContext context) {
    final bgColor = isMine ? null : Theme.of(context).colorScheme.surface;
    final alignment = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textColor = isMine ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: bgColor,
          gradient: isMine ? AppColors.messageGradient : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(isMine ? AppRadius.lg : AppRadius.xs),
            bottomRight: Radius.circular(isMine ? AppRadius.xs : AppRadius.lg),
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: alignment,
          children: <Widget>[
            if (conversation.isGroup && !isMine && sender != null)
              Text(
                sender!.displayName,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
              ),
            if (conversation.isGroup && !isMine && sender != null)
              const SizedBox(height: AppSpacing.xs),
            _buildMessageBody(context, textColor),
            const SizedBox(height: AppSpacing.xs),
            Text(
              TimeOfDay.fromDateTime(message.timestamp).format(context),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isMine ? Colors.white70 : AppColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBody(BuildContext context, Color textColor) {
    switch (message.type) {
      case MessageContentType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (message.attachmentPath != null) _buildImagePreview(context),
            if (message.body.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(message.body, style: TextStyle(color: textColor)),
              ),
          ],
        );
      case MessageContentType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (message.attachmentPath != null) _buildVideoPreview(context),
            if (message.body.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(message.body, style: TextStyle(color: textColor)),
              ),
          ],
        );
      case MessageContentType.animation:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (message.attachmentPath != null) _buildAnimationPreview(context),
            if (message.body.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(message.body, style: TextStyle(color: textColor)),
              ),
          ],
        );
      case MessageContentType.emoji:
        return Text(
          message.body,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 44),
        );
      case MessageContentType.text:
        return Text(message.body, style: TextStyle(color: textColor));
    }
  }

  Widget _buildImagePreview(BuildContext context) {
    final path = message.attachmentPath;
    if (path == null) return const SizedBox.shrink();
    
    // Determinar si es URL de red o archivo local
    final isNetworkImage = path.startsWith('http://') || path.startsWith('https://');
    
    return GestureDetector(
      onTap: () {
        // Abrir visor de imagen en pantalla completa
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ImageViewerPage(
              imagePath: path,
              isNetworkImage: isNetworkImage,
            ),
          ),
        );
      },
      child: Hero(
        tag: 'image_${message.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: isNetworkImage
              ? Image.network(
                  path,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        color: Colors.grey.shade200,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        color: Colors.grey.shade200,
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.broken_image, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Error al cargar imagen'),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : File(path).existsSync()
                  ? Image.file(
                      File(path),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        color: Colors.grey.shade200,
                      ),
                      child: const Center(child: Text('Imagen adjunta')),
                    ),
        ),
      ),
    );
  }

  Widget _buildAnimationPreview(BuildContext context) {
    final path = message.attachmentPath;
    if (path == null) return const SizedBox.shrink();
    
    // Determinar si es URL de red o archivo local
    final isNetworkImage = path.startsWith('http://') || path.startsWith('https://');
    
    return GestureDetector(
      onTap: () {
        // Abrir visor de GIF en pantalla completa
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ImageViewerPage(
              imagePath: path,
              isNetworkImage: isNetworkImage,
            ),
          ),
        );
      },
      child: Hero(
        tag: 'gif_${message.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: isNetworkImage
              ? Image.network(
                  path,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        color: Colors.grey.shade200,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        color: Colors.grey.shade200,
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.broken_image, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Error al cargar GIF'),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : File(path).existsSync()
                  ? Image.file(
                      File(path),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        color: Colors.grey.shade200,
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.gif_box, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('GIF adjunto'),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview(BuildContext context) {
    final path = message.attachmentPath!;
    final isNetworkVideo = path.startsWith('http://') || path.startsWith('https://');

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => VideoPlayerPage(videoUrl: path),
          ),
        );
      },
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isNetworkVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 64,
                ),
              )
            else
              const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            const Positioned(
              bottom: 8,
              right: 8,
              child: Icon(
                Icons.videocam,
                color: Colors.white70,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

