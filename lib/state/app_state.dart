import 'package:collection/collection.dart';

import '../models/announcement.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user_profile.dart';

enum AuthStep { phoneEntry, otp, profile, home }

class AppState {
  const AppState({
    required this.step,
    required this.directory,
    required this.conversations,
    required this.messages,
    required this.announcements,
    this.isLoading = false,
    this.pendingPhone,
    this.verificationId,
    this.resendToken,
    this.currentUser,
    this.errorMessage,
  });

  final AuthStep step;
  final bool isLoading;
  final String? pendingPhone;
  final String? verificationId;
  final int? resendToken;
  final UserProfile? currentUser;
  final String? errorMessage;

  final List<UserProfile> directory;
  final List<Conversation> conversations;
  final Map<String, List<Message>> messages;
  final List<Announcement> announcements;

  static const Object _sentinel = Object();

  List<UserProfile> get contactDirectory {
    if (currentUser == null) return const <UserProfile>[];
    return directory
        .where((user) => currentUser!.contactIds.contains(user.id))
        .toList(growable: false);
  }

  List<Conversation> get currentConversations {
    if (currentUser == null) return const <Conversation>[];
    return conversations
        .where((conversation) => conversation.participantIds.contains(currentUser!.id))
        .sortedBy((c) => c.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0))
        .reversed
        .toList(growable: false);
  }

  List<Conversation> get groupConversations => conversations.where((c) => c.isGroup).toList(growable: false);

  AppState copyWith({
    AuthStep? step,
    bool? isLoading,
    Object? pendingPhone = _sentinel,
    Object? verificationId = _sentinel,
    Object? resendToken = _sentinel,
    Object? currentUser = _sentinel,
    List<UserProfile>? directory,
    List<Conversation>? conversations,
    Map<String, List<Message>>? messages,
    List<Announcement>? announcements,
    Object? errorMessage = _sentinel,
  }) {
    return AppState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      pendingPhone: pendingPhone == _sentinel ? this.pendingPhone : pendingPhone as String?,
      verificationId: verificationId == _sentinel ? this.verificationId : verificationId as String?,
      resendToken: resendToken == _sentinel ? this.resendToken : resendToken as int?,
      currentUser: currentUser == _sentinel ? this.currentUser : currentUser as UserProfile?,
      directory: directory ?? this.directory,
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      announcements: announcements ?? this.announcements,
      errorMessage: errorMessage == _sentinel ? this.errorMessage : errorMessage as String?,
    );
  }

  factory AppState.initial() {
    return const AppState(
      step: AuthStep.phoneEntry,
      directory: <UserProfile>[],
      conversations: <Conversation>[],
      messages: <String, List<Message>>{},
      announcements: <Announcement>[],
    );
  }
}
