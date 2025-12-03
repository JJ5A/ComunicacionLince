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

    // Obtener el título correcto basado en el otro participante para chats directos
    String displayTitle = conversation.title;
    if (!conversation.isGroup && currentUser != null) {
      final otherUserId = conversation.participantIds.firstWhere(
        (id) => id != currentUser.id,
        orElse: () => conversation.participantIds.first,
      );
      final otherUserIndex = state.directory.indexWhere((user) => user.id == otherUserId);
      if (otherUserIndex >= 0) {
        displayTitle = state.directory[otherUserIndex].displayName;
      }
    }

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
                  Text(displayTitle),
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
            onPressed: () => _openVideoCall(displayTitle),
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
                      final senderIndex = state.directory.indexWhere((user) => user.id == message.senderId);
                      final sender = senderIndex >= 0 ? state.directory[senderIndex] : null;
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
    final token = dotenv.env['AGORA_TOKEN'] ?? dotenv.env['AGORA_TEMP_TOKEN'];
    
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
          token: token,
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

    final int idx = appState.directory.indexWhere((user) => user.id == otherUserId);
    final otherUser = idx >= 0 ? appState.directory[idx] : null;

    if (otherUser != null && otherUser.avatarPath != null && otherUser.avatarPath!.isNotEmpty) {
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
    // Mostrar selector de GIFs predefinidos
    final selectedGif = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => const _GifPickerBottomSheet(),
    );
    
    if (selectedGif != null) {
      _handleSend('GIF', MessageContentType.animation, selectedGif, conversationId);
      return;
    }
    
    // Si no seleccionó ninguno, ofrecer subir desde galería
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
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Icon(icon, size: 20, color: AppColors.brandPrimary),
          ),
        ),
      ),
    );
  }
}

class _GifPickerBottomSheet extends StatelessWidget {
  const _GifPickerBottomSheet();

  // GIFs populares de Tenor/Giphy (URLs públicas)
  static const List<Map<String, String>> _popularGifs = [
    {
      'url': 'https://media.giphy.com/media/3o7qDSOvfaCO9b3MlO/giphy.gif',
      'label': '👍 Pulgar arriba',
    },
    {
      'url': 'https://media.giphy.com/media/l0MYGb1LuZ3n7dRnO/giphy.gif',
      'label': '😂 Risa',
    },
    {
      'url': 'https://media.giphy.com/media/111ebonMs90YLu/giphy.gif',
      'label': '👏 Aplauso',
    },
    {
      'url': 'https://media.giphy.com/media/g9582DNuQppxC/giphy.gif',
      'label': '🎉 Celebración',
    },
    {
      'url': 'https://media.giphy.com/media/l0HlBO7eyXzSZkJri/giphy.gif',
      'label': '❤️ Corazón',
    },
    {
      'url': 'https://media.giphy.com/media/KEYEpIngcmXlHetDqz/giphy.gif',
      'label': '👋 Hola',
    },
    {
      'url': 'https://media.giphy.com/media/3oEjI6SIIHBdRxXI40/giphy.gif',
      'label': '😮 Sorpresa',
    },
    {
      'url': 'https://media.giphy.com/media/l3q2K5jinAlChoCLS/giphy.gif',
      'label': '😴 Aburrido',
    },
    {
      'url': 'https://media.giphy.com/media/26uf4r3EldfX5Ykqk/giphy.gif',
      'label': '💪 Fuerza',
    },
    {
      'url': 'https://media.giphy.com/media/XreQmk7ETCak0/giphy.gif',
      'label': '👀 Mirando',
    },
    {
      'url': 'https://media.giphy.com/media/3o7bu3XilJ5BOiSGic/giphy.gif',
      'label': '🤔 Pensando',
    },
    {
      'url': 'https://media.giphy.com/media/26u4cqiYI30juCOGY/giphy.gif',
      'label': '🔥 Fuego',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.gif_box, color: AppColors.brandPrimary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Selecciona un GIF',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1,
              ),
              itemCount: _popularGifs.length,
              itemBuilder: (context, index) {
                final gif = _popularGifs[index];
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(gif['url']),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Image.network(
                      gif['url']!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
