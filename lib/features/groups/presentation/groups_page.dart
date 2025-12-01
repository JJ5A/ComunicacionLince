import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/conversation.dart';
import '../../../models/user_profile.dart';
import '../../../state/app_state.dart';
import '../../../state/providers.dart';
import '../../../theme/design_tokens.dart';
import '../../chats/presentation/chat_detail_page.dart';
import '../../../widgets/loading_overlay.dart';

class GroupsPage extends ConsumerStatefulWidget {
  const GroupsPage({super.key});

  @override
  ConsumerState<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends ConsumerState<GroupsPage> {
  late final TextEditingController _nameController;
  final Set<String> _selectedParticipants = <String>{};
  bool _hidePhones = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    final groups = state.groupConversations;
    final currentUser = state.currentUser;
    final availableContacts = state.directory.where((user) => user.id != currentUser?.id).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Grupos TecNM')),
      body: Stack(
        children: <Widget>[
          DecoratedBox(
            decoration: AppDecorations.surfaceBackground,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: <Widget>[
                  if (currentUser?.isProfessor == true)
                    _CreateGroupCard(
                      nameController: _nameController,
                      hidePhones: _hidePhones,
                      selectedParticipants: _selectedParticipants,
                      contacts: availableContacts,
                      onTogglePrivacy: (value) => setState(() => _hidePhones = value),
                      onToggleParticipant: (participantId, isSelected) => setState(() {
                        if (isSelected) {
                          _selectedParticipants.add(participantId);
                        } else {
                          _selectedParticipants.remove(participantId);
                        }
                      }),
                      onCreate: () {
                        ref
                            .read(appControllerProvider.notifier)
                            .createGroup(
                              title: _nameController.text,
                              participantIds: _selectedParticipants.toList(),
                              hidePhoneNumbers: _hidePhones,
                            )
                            .then((_) {
                          if (!mounted) return;
                          setState(() {
                            _nameController.clear();
                            _selectedParticipants.clear();
                            _hidePhones = true;
                          });
                        });
                      },
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Mis grupos', style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (groups.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Aún no existen grupos', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Si eres profesor puedes crear uno para coordinar avisos, tareas y enlaces de videollamada.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  for (final group in groups)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _GroupTile(
                        group: group,
                        isProfessor: currentUser?.isProfessor == true,
                        participants: state.directory,
                        onTogglePrivacy: (value) =>
                            ref.read(appControllerProvider.notifier).toggleGroupPrivacy(group.id, value),
                        onOpenConversation: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ChatDetailPage(conversationId: group.id),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          AppLoadingOverlay(visible: state.isLoading),
        ],
      ),
    );
  }
}

class _CreateGroupCard extends StatelessWidget {
  const _CreateGroupCard({
    required this.nameController,
    required this.hidePhones,
    required this.selectedParticipants,
    required this.contacts,
    required this.onTogglePrivacy,
    required this.onToggleParticipant,
    required this.onCreate,
  });

  final TextEditingController nameController;
  final bool hidePhones;
  final Set<String> selectedParticipants;
  final List<UserProfile> contacts;
  final ValueChanged<bool> onTogglePrivacy;
  final void Function(String participantId, bool selected) onToggleParticipant;
  final VoidCallback onCreate;

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
              const Icon(Icons.auto_awesome_mosaic_outlined, color: AppColors.brandPrimary),
              const SizedBox(width: AppSpacing.sm),
              Text('Crear grupo docente', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Organiza canales privados por materia o laboratorio. Solo los integrantes verán los mensajes y archivos.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Nombre del grupo', prefixIcon: Icon(Icons.badge_outlined)),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: contacts
                .map(
                  (contact) => FilterChip(
                    label: Text(contact.displayName),
                    avatar: CircleAvatar(child: Text(contact.initials())),
                    selected: selectedParticipants.contains(contact.id),
                    onSelected: (value) => onToggleParticipant(contact.id, value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile.adaptive(
            title: const Text('Ocultar teléfonos de los integrantes'),
            subtitle: const Text('Solo tú podrás ver los números completos.'),
            value: hidePhones,
            onChanged: onTogglePrivacy,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Crear grupo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.isProfessor,
    required this.participants,
    required this.onTogglePrivacy,
    required this.onOpenConversation,
  });

  final Conversation group;
  final bool isProfessor;
  final List<UserProfile> participants;
  final ValueChanged<bool> onTogglePrivacy;
  final VoidCallback onOpenConversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        title: Text(group.title),
        subtitle: Text(group.hidePhoneNumbers ? 'Teléfonos ocultos' : 'Teléfonos visibles'),
        trailing: IconButton(
          icon: const Icon(Icons.chat_outlined),
          onPressed: onOpenConversation,
        ),
        children: <Widget>[
          if (isProfessor)
            SwitchListTile.adaptive(
              title: const Text('Ocultar teléfonos del grupo'),
              value: group.hidePhoneNumbers,
              onChanged: onTogglePrivacy,
            ),
          ...group.participantIds.map((participantId) {
            final participant = participants.firstWhere((user) => user.id == participantId);
            final shouldHidePhone = group.hidePhoneNumbers && !participant.isProfessor;
            final phone = shouldHidePhone ? 'Oculto por docente' : participant.maskedPhone(showFull: true);
            return ListTile(
              leading: CircleAvatar(child: Text(participant.initials())),
              title: Text(participant.displayName),
              subtitle: Text(phone),
            );
          }),
        ],
      ),
    );
  }
}
