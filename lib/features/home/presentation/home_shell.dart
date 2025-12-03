import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/providers.dart';
import '../../../theme/design_tokens.dart';
import '../../chats/presentation/chats_page.dart';
import '../../contacts/presentation/contacts_page.dart';
import '../../groups/presentation/groups_page.dart';
import '../../profile/presentation/profile_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen(appControllerProvider.select((state) => state.errorMessage), (previous, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      });
    });

    const pages = <Widget>[
      ChatsPage(),
      ContactsPage(),
      GroupsPage(),
      ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.soft,
          ),
          child: NavigationBar(
            height: 70,
            backgroundColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            indicatorColor: AppColors.brandSecondary.withValues(alpha: 0.2),
            selectedIndex: _currentIndex,
            onDestinationSelected: (value) => setState(() => _currentIndex = value),
            destinations: const <NavigationDestination>[
              NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
              NavigationDestination(icon: Icon(Icons.people_alt_outlined), label: 'Contactos'),
              NavigationDestination(icon: Icon(Icons.groups), label: 'Grupos'),
              NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }
}
