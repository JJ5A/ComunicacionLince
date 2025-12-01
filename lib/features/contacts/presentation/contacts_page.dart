import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/user_profile.dart';
import '../../../state/app_state.dart';
import '../../../state/providers.dart';
import '../../../theme/design_tokens.dart';
import '../../chats/presentation/chat_detail_page.dart';
import '../../../widgets/loading_overlay.dart';

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
  late final TextEditingController _phoneController;
  late final TextEditingController _searchController;
  String _searchQuery = '';
  UserRole? _selectedRoleFilter;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<UserProfile> _filterContacts(List<UserProfile> contacts) {
    var filtered = contacts;

    // Filtrar por rol si hay uno seleccionado
    if (_selectedRoleFilter != null) {
      filtered = filtered.where((contact) => contact.role == _selectedRoleFilter).toList();
    }

    // Filtrar por texto de búsqueda
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((contact) {
        return contact.displayName.toLowerCase().contains(query) ||
            contact.email.toLowerCase().contains(query) ||
            contact.phoneNumber.toLowerCase().contains(query) ||
            contact.role.label.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
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
    final contacts = state.contactDirectory;
    final filteredContacts = _filterContacts(contacts);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Contactos TecNM')),
      body: Stack(
        children: <Widget>[
          DecoratedBox(
            decoration: AppDecorations.surfaceBackground,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: <Widget>[
            _AddContactCard(
              phoneController: _phoneController,
              onAddPhone: () {
                ref.read(appControllerProvider.notifier).addContactByPhone(_phoneController.text).then((_) {
                  _phoneController.clear();
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Mis contactos', style: Theme.of(context).textTheme.headlineSmall),
                Text('${filteredContacts.length} de ${contacts.length}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar contacto',
                hintText: 'Nombre, email o teléfono',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
            ),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _RoleChip(
                    icon: Icons.filter_list_off,
                    label: 'Todos',
                    isSelected: _selectedRoleFilter == null,
                    onTap: () => setState(() => _selectedRoleFilter = null),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _RoleChip(
                    icon: Icons.groups_3_outlined,
                    label: 'Profesores',
                    isSelected: _selectedRoleFilter == UserRole.professor,
                    onTap: () => setState(() => _selectedRoleFilter = UserRole.professor),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _RoleChip(
                    icon: Icons.school_outlined,
                    label: 'Estudiantes',
                    isSelected: _selectedRoleFilter == UserRole.student,
                    onTap: () => setState(() => _selectedRoleFilter = UserRole.student),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (contacts.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.soft,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.info_outline, color: AppColors.brandPrimary.withValues(alpha: 0.6)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Aún no tienes contactos. Usa los formularios para enviar invitaciones a tus compañeros y docentes.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )
            else if (filteredContacts.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.soft,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.search_off, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'No se encontraron contactos con ese criterio. Intenta con otra búsqueda.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final contact in filteredContacts)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ContactTile(
                  contact: contact,
                  onChat: () async {
                    try {
                      final conversation = await ref.read(appControllerProvider.notifier).ensureDirectConversation(contact.id);
                      if (!context.mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatDetailPage(conversationId: conversation.id),
                        ),
                      );
                    } catch (_) {
                      // Ignoramos errores para no bloquear la UI; AppController ya reporta mensajes.
                    }
                  },
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
}

class _AddContactCard extends StatelessWidget {
  const _AddContactCard({
    required this.phoneController,
    required this.onAddPhone,
  });

  final TextEditingController phoneController;
  final VoidCallback onAddPhone;

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
          Text('Agregar contacto', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Busca por número telefónico. Si el usuario está registrado en Firebase, se agregará a tus contactos.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Número de teléfono',
              hintText: '+52 461 123 4567',
              prefixIcon: Icon(Icons.phone_outlined),
              helperText: 'Formato: +52 seguido de 10 dígitos',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onAddPhone,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Buscar y agregar'),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Chip(
        avatar: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : AppColors.brandPrimary,
        ),
        label: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : null),
        ),
        backgroundColor: isSelected ? AppColors.brandPrimary : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(
            color: isSelected ? AppColors.brandPrimary : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact, required this.onChat});

  final UserProfile contact;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
            child: Text(contact.initials()),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(contact.displayName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('${contact.role.label} • ${contact.email}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: onChat,
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Abrir'),
          ),
        ],
      ),
    );
  }
}
