import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/conversation.dart';
import '../../../state/app_state.dart';
import '../../../state/providers.dart';
import '../../../theme/design_tokens.dart';
import 'chat_detail_page.dart';

class ChatsPage extends ConsumerStatefulWidget {
  const ChatsPage({super.key});

  @override
  ConsumerState<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends ConsumerState<ChatsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final conversations = appState.currentConversations;
    final filtered = _applyFilter(conversations);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Conversaciones'),
            Text(
              '${filtered.length} canales activos',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: DecoratedBox(
        decoration: AppDecorations.surfaceBackground,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar conversación o grupo',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: filtered.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final conversation = filtered[index];
                        final lastMessage = conversation.lastMessage;
                        final subtitle = lastMessage?.body ?? 'Sin mensajes aún';
                        final time = lastMessage == null ? '' : DateFormat.Hm().format(lastMessage.timestamp);
                        
                                                // Calcular el título correcto para conversaciones directas
                                                String displayTitle = conversation.title;
                                                if (!conversation.isGroup && appState.currentUser != null) {
                                                  final otherUserId = conversation.participantIds.firstWhere(
                                                    (id) => id != appState.currentUser!.id,
                                                    orElse: () => conversation.participantIds.first,
                                                  );
                                                  final otherUserIndex = appState.directory.indexWhere((user) => user.id == otherUserId);
                                                  if (otherUserIndex >= 0) {
                                                    displayTitle = appState.directory[otherUserIndex].displayName;
                                                  }
                                                }
                        
                        return GestureDetector(
                          onTap: () => _openConversation(conversation),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              boxShadow: AppShadows.soft,
                            ),
                            child: Row(
                              children: <Widget>[
                                _buildConversationAvatar(conversation, appState),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Text(
                                              displayTitle,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          if (time.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.sm,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.brandSecondary.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                              ),
                                              child: Text(
                                                time,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(color: AppColors.textMuted),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                if (conversation.isMuted) ...<Widget>[
                                  const SizedBox(width: AppSpacing.sm),
                                  const Icon(Icons.volume_off, color: Colors.redAccent),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Conversation> _applyFilter(List<Conversation> conversations) {
    if (_query.isEmpty) return conversations;
    final normalized = _query.toLowerCase();
    return conversations
        .where(
          (conversation) => conversation.title.toLowerCase().contains(normalized) ||
              (conversation.lastMessage?.body.toLowerCase().contains(normalized) ?? false),
        )
        .toList(growable: false);
  }

  void _openConversation(Conversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatDetailPage(conversationId: conversation.id),
      ),
    );
  }

  Widget _buildConversationAvatar(Conversation conversation, AppState appState) {
    if (conversation.isGroup) {
      // Para grupos, mostrar ícono de grupo
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
        child: const Icon(
          Icons.groups_2,
          color: AppColors.brandPrimary,
        ),
      );
    }

    // Para conversaciones 1-a-1, obtener el otro usuario
    final currentUserId = appState.currentUser?.id;
    final otherUserId = conversation.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => conversation.participantIds.first,
    );

    final int idx = appState.directory.indexWhere((user) => user.id == otherUserId);
    final otherUser = idx >= 0 ? appState.directory[idx] : null;

    // Si tiene foto de perfil, mostrarla
    if (otherUser != null && otherUser.avatarPath != null && otherUser.avatarPath!.isNotEmpty) {
      final isNetworkImage = otherUser.avatarPath!.startsWith('http://') ||
          otherUser.avatarPath!.startsWith('https://');
      
      return CircleAvatar(
        radius: 24,
        backgroundImage: isNetworkImage 
            ? NetworkImage(otherUser.avatarPath!) 
            : null,
        backgroundColor: AppColors.brandSecondary.withValues(alpha: 0.12),
        child: !isNetworkImage 
            ? const Icon(Icons.person, color: AppColors.brandPrimary)
            : null,
      );
    }

    // Si no tiene foto, mostrar ícono
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.brandSecondary.withValues(alpha: 0.12),
      child: const Icon(
        Icons.person,
        color: AppColors.brandPrimary,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.chat_bubble_outline, size: 72, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Aún no tienes conversaciones. Agrega contactos o únete a un grupo.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: AppColors.brandPrimary),
      label: Text(label),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
    );
  }
}
