import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/announcement.dart';
import '../../../state/app_state.dart';
import '../../../state/providers.dart';
import '../../../theme/design_tokens.dart';
import '../../../widgets/loading_overlay.dart';

class AnnouncementsPage extends ConsumerStatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  ConsumerState<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends ConsumerState<AnnouncementsPage> {
  @override
  void initState() {
    super.initState();
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
    final announcements = state.announcements;
    final currentUser = state.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Boletín académico')),
      floatingActionButton: currentUser?.isProfessor == true
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add_comment),
              label: const Text('Nuevo aviso'),
            )
          : null,
      body: Stack(
        children: <Widget>[
          DecoratedBox(
            decoration: AppDecorations.surfaceBackground,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: announcements.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _HeadlineBanner(count: announcements.length),
                  );
                }
                final announcement = announcements[index - 1];
                final author = state.directory.firstWhere((user) => user.id == announcement.authorId);
                final acknowledged = announcement.isAcknowledged(currentUser?.id ?? '');
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _AnnouncementCard(
                    announcement: announcement,
                    authorName: author.displayName,
                    acknowledged: acknowledged,
                    onAcknowledge: null,
                  ),
                );
              },
            ),
          ),
          AppLoadingOverlay(visible: state.isLoading),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final categoryController = TextEditingController(text: 'Aviso');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nuevo aviso'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: bodyController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Mensaje'),
                    validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Publicar'),
            ),
          ],
        );
      },
    );
  }
}

class _HeadlineBanner extends StatelessWidget {
  const _HeadlineBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.campaign_outlined, color: Colors.white, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Avisos institucionales', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                Text('$count publicaciones recientes', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white70),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.authorName,
    required this.acknowledged,
    required this.onAcknowledge,
  });

  final Announcement announcement;
  final String authorName;
  final bool acknowledged;
  final VoidCallback? onAcknowledge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(announcement.title, style: Theme.of(context).textTheme.titleLarge),
              ),
              Chip(label: Text(announcement.category)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(announcement.body, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.md),
          Text('Autor: $authorName', style: Theme.of(context).textTheme.labelMedium),
          Text(DateFormat('dd MMM, HH:mm').format(announcement.createdAt), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: acknowledged ? null : onAcknowledge,
              icon: Icon(acknowledged ? Icons.check_circle : Icons.mark_chat_read_outlined),
              label: Text(acknowledged ? 'Recibido' : 'Marcar recibido'),
            ),
          ),
        ],
      ),
    );
  }
}
