import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/conversation.dart';
import '../../../models/message.dart';
import '../../../state/app_state.dart';
import '../../../state/providers.dart';
import '../../calls/presentation/video_call_page.dart';
import '../../../theme/design_tokens.dart';
import '../widgets/message_bubble.dart';
import '../../../widgets/loading_overlay.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  const ChatDetailPage({required this.conversationId, super.key});

  final String conversationId;

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  late final TextEditingController _messageController;
  final ScrollController _scrollController = ScrollController();
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppState>(appControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (!mounted || message == null || message == previous?.errorMessage) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
    });

    final state = ref.watch(appControllerProvider);
    final conversation = state.conversations.firstWhere((c) => c.id == widget.conversationId);
    final messages = state.messages[conversation.id] ?? const <Message>[];
    final currentUser = state.currentUser;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Row(
          children: [
            _buildAppBarAvatar(conversation, state),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(conversation.title),
                  if (conversation.isGroup)
                    Text(
                      '${conversation.participantIds.length} integrantes',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Video llamada',
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () => _openVideoCall(conversation.title),
          ),
          IconButton(
            icon: Icon(conversation.isMuted ? Icons.notifications_off : Icons.notifications_active_outlined),
            onPressed: () => ref.read(appControllerProvider.notifier).toggleMute(conversation.id),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          DecoratedBox(
            decoration: AppDecorations.surfaceBackground,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final sender = state.directory.firstWhere(
                        (user) => user.id == message.senderId,
                        orElse: () => currentUser ?? state.directory.first,
                      );
                      final isMine = currentUser?.id == message.senderId;
                      return MessageBubble(
                        message: message,
                        isMine: isMine,
                        conversation: conversation,
                        sender: sender,
                      );
                    },
                  ),
                ),
                _Composer(
                  controller: _messageController,
                  onSend: (text, type, attachmentPath) =>
                      _handleSend(text, type, attachmentPath, conversation.id),
                  onEmojiToggle: () => setState(() => _showEmoji = !_showEmoji),
                  onPickImage: () => _pickImage(conversation.id),
                  onPickVideo: () => _pickVideo(conversation.id),
                  onPickAnimation: () => _pickAnimation(conversation.id),
                ),
                if (_showEmoji)
                  SizedBox(
                    height: 260,
                    child: EmojiPicker(
                      onEmojiSelected: (_, emoji) {
                        _messageController.text += emoji.emoji;
                      },
                      config: const Config(),
                    ),
                  ),
              ],
            ),
          ),
          AppLoadingOverlay(visible: state.isLoading),
        ],
      ),
    );
  }

  void _openVideoCall(String title) {
    final agoraAppId = dotenv.env['AGORA_APP_ID'];
    
    if (agoraAppId == null || agoraAppId.isEmpty || agoraAppId == 'YOUR_AGORA_APP_ID_HERE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configura AGORA_APP_ID en el archivo .env para habilitar videollamadas'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    
    final conversation = ref.read(appControllerProvider).conversations
        .firstWhere((c) => c.title == title, orElse: () => throw StateError('Conversación no encontrada'));
    
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoCallPage(
          conversationTitle: title,
          channelName: conversation.id,
          agoraAppId: agoraAppId,
        ),
      ),
    );
  }

  void _handleSend(String text, MessageContentType type, String? attachmentPath, String conversationId) {
    ref.read(appControllerProvider.notifier).sendMessage(
          conversationId: conversationId,
          text: text,
          type: type,
          attachmentPath: attachmentPath,
        );
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildAppBarAvatar(Conversation conversation, AppState appState) {
    if (conversation.isGroup) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        child: const Icon(Icons.groups_2, size: 20),
      );
    }

    final currentUserId = appState.currentUser?.id;
    final otherUserId = conversation.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => conversation.participantIds.first,
    );

    final otherUser = appState.directory.firstWhere(
      (user) => user.id == otherUserId,
      orElse: () => appState.directory.first,
    );

    if (otherUser.avatarPath != null && otherUser.avatarPath!.isNotEmpty) {
      final isNetworkImage = otherUser.avatarPath!.startsWith('http://') || 
                              otherUser.avatarPath!.startsWith('https://');
      
      return CircleAvatar(
        radius: 20,
        backgroundImage: isNetworkImage ? NetworkImage(otherUser.avatarPath!) : null,
        child: !isNetworkImage ? const Icon(Icons.person, size: 20) : null,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      child: const Icon(Icons.person, size: 20),
    );
  }

  Future<void> _pickImage(String conversationId) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    _handleSend('Imagen adjunta', MessageContentType.image, file.path, conversationId);
  }

  Future<void> _pickVideo(String conversationId) async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    _handleSend('Video adjunto', MessageContentType.video, file.path, conversationId);
  }

  Future<void> _pickAnimation(String conversationId) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: <String>['gif']);
    final path = result?.files.single.path;
    if (path == null) return;
    _handleSend('Animación compartida', MessageContentType.animation, path, conversationId);
  }
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onEmojiToggle,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onPickAnimation,
  });

  final TextEditingController controller;
  final void Function(String text, MessageContentType type, String? attachmentPath) onSend;
  final VoidCallback onEmojiToggle;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onPickAnimation;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(covariant _Composer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_handleTextChange);
    widget.controller.addListener(_handleTextChange);
    _handleTextChange();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleTextChange() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText == _hasText) return;
    setState(() => _hasText = hasText);
  }

  void _handleSendPressed() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text, MessageContentType.text, null);
    widget.controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.soft,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: <Widget>[
                      _ComposerIconButton(
                        icon: Icons.photo_outlined,
                        tooltip: 'Foto',
                        onPressed: widget.onPickImage,
                      ),
                      _ComposerIconButton(
                        icon: Icons.videocam_outlined,
                        tooltip: 'Video',
                        onPressed: widget.onPickVideo,
                      ),
                      _ComposerIconButton(
                        icon: Icons.gif_box_outlined,
                        tooltip: 'GIF',
                        onPressed: widget.onPickAnimation,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        AppColors.card,
                        AppColors.card.withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56, maxHeight: 150),
                          child: Scrollbar(
                            child: TextField(
                              controller: widget.controller,
                              minLines: 2,
                              maxLines: 6,
                              decoration: const InputDecoration(
                                hintText: 'Mensaje…',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Tooltip(
                          message: _hasText ? 'Enviar mensaje' : 'Escribe para habilitar',
                          child: AnimatedScale(
                            scale: _hasText ? 1 : 0.9,
                            duration: const Duration(milliseconds: 150),
                            child: FilledButton(
                              onPressed: _hasText ? _handleSendPressed : null,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                shape: const CircleBorder(),
                              ),
                              child: const Icon(Icons.send),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.brandPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Icon(icon, color: AppColors.brandPrimary),
          ),
        ),
      ),
    );
  }
}
