import 'dart:math';

enum MessageType { text, image, audio, file, emoji }

enum MessageStatus { sending, sent, delivered, read }

enum UserStatus { online, away, offline }

class User {
  final String id;
  final String name;
  final String avatarUrl;
  final UserStatus status;
  final String? statusMessage;
  final DateTime lastSeen;

  const User({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.status = UserStatus.offline,
    this.statusMessage,
    required this.lastSeen,
  });
}

class Message {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final MessageStatus status;
  final bool isDeleted;
  final String? replyToId;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.status = MessageStatus.read,
    this.isDeleted = false,
    this.replyToId,
  });

  String get shortId => id.substring(0, 8);
}

class Chat {
  final String id;
  final List<User> participants;
  final List<Message> messages;
  final bool isGroup;
  final String? groupName;
  final String? groupAvatarUrl;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;

  Chat({
    required this.id,
    required this.participants,
    required this.messages,
    this.isGroup = false,
    this.groupName,
    this.groupAvatarUrl,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
  });

  Message? get lastMessage => messages.isNotEmpty ? messages.last : null;

  String get displayName {
    if (isGroup) return groupName ?? 'Group Chat';
    return participants.isNotEmpty ? participants.first.name : 'Unknown';
  }

  String get displayAvatar {
    if (isGroup) return groupAvatarUrl ?? '';
    return participants.isNotEmpty ? participants.first.avatarUrl : '';
  }

  UserStatus get displayStatus {
    if (isGroup) return UserStatus.offline;
    return participants.isNotEmpty ? participants.first.status : UserStatus.offline;
  }
}

// ── Seed Data ──────────────────────────────────────────────────────────────────

final User currentUser = User(
  id: 'me',
  name: 'You',
  avatarUrl: 'https://i.pravatar.cc/150?img=12',
  status: UserStatus.online,
  lastSeen: DateTime.now(),
);

final List<User> sampleUsers = [
  User(id: 'u1', name: 'Ariana Wells', avatarUrl: 'https://i.pravatar.cc/150?img=47', status: UserStatus.online, statusMessage: '🎵 In the zone', lastSeen: DateTime.now()),
  User(id: 'u2', name: 'Marcus Chen', avatarUrl: 'https://i.pravatar.cc/150?img=33', status: UserStatus.away, statusMessage: 'At lunch', lastSeen: DateTime.now().subtract(const Duration(minutes: 23))),
  User(id: 'u3', name: 'Sofia Reyes', avatarUrl: 'https://i.pravatar.cc/150?img=56', status: UserStatus.online, lastSeen: DateTime.now()),
  User(id: 'u4', name: 'Liam Okafor', avatarUrl: 'https://i.pravatar.cc/150?img=15', status: UserStatus.offline, lastSeen: DateTime.now().subtract(const Duration(hours: 3))),
  User(id: 'u5', name: 'Priya Nair', avatarUrl: 'https://i.pravatar.cc/150?img=62', status: UserStatus.online, statusMessage: '💻 Working', lastSeen: DateTime.now()),
  User(id: 'u6', name: 'Jake Thornton', avatarUrl: 'https://i.pravatar.cc/150?img=11', status: UserStatus.away, lastSeen: DateTime.now().subtract(const Duration(minutes: 45))),
];

String _msgId() => Random().nextInt(999999).toString();

List<Message> _convo1() => [
  Message(id: _msgId(), senderId: 'u1', content: 'Hey! Are you coming tonight? 🎉', timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 12))),
  Message(id: _msgId(), senderId: 'me', content: 'Definitely! What time does it start?', timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 8))),
  Message(id: _msgId(), senderId: 'u1', content: 'Around 8pm. Bring something to drink if you can 🍹', timestamp: DateTime.now().subtract(const Duration(hours: 2))),
  Message(id: _msgId(), senderId: 'me', content: 'Sure! I\'ll bring some lemonade', timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 50))),
  Message(id: _msgId(), senderId: 'u1', content: 'Perfect 😊 See you then!', timestamp: DateTime.now().subtract(const Duration(minutes: 30))),
];

List<Message> _convo2() => [
  Message(id: _msgId(), senderId: 'u2', content: 'Did you review the design files?', timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3))),
  Message(id: _msgId(), senderId: 'me', content: 'Yes, looks great. Just a few comments on the spacing.', timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2, minutes: 45))),
  Message(id: _msgId(), senderId: 'u2', content: 'Cool, I\'ll fix those and send a new version.', timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2, minutes: 30))),
  Message(id: _msgId(), senderId: 'u2', content: 'Can we hop on a call later today?', timestamp: DateTime.now().subtract(const Duration(hours: 1))),
];

List<Message> _convo3() => [
  Message(id: _msgId(), senderId: 'u3', content: 'Good morning! ☀️', timestamp: DateTime.now().subtract(const Duration(hours: 5))),
  Message(id: _msgId(), senderId: 'me', content: 'Morning Sofia! How\'s your day going?', timestamp: DateTime.now().subtract(const Duration(hours: 4, minutes: 55))),
  Message(id: _msgId(), senderId: 'u3', content: 'Pretty busy but good! Just finished my workout 💪', timestamp: DateTime.now().subtract(const Duration(hours: 4, minutes: 40))),
  Message(id: _msgId(), senderId: 'u3', content: 'What are you up to today?', timestamp: DateTime.now().subtract(const Duration(hours: 4, minutes: 38))),
];

List<Message> _convoGroup() => [
  Message(id: _msgId(), senderId: 'u1', content: 'Meeting pushed to 3pm everyone!', timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 20))),
  Message(id: _msgId(), senderId: 'u5', content: 'Got it, thanks for the heads up 👍', timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 15))),
  Message(id: _msgId(), senderId: 'me', content: 'Works for me!', timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 10))),
  Message(id: _msgId(), senderId: 'u2', content: 'I might be 5min late, please start without me', timestamp: DateTime.now().subtract(const Duration(minutes: 45))),
  Message(id: _msgId(), senderId: 'u1', content: 'No worries, we\'ll record it 🎥', timestamp: DateTime.now().subtract(const Duration(minutes: 40))),
];

final List<Chat> sampleChats = [
  Chat(id: 'c1', participants: [sampleUsers[0]], messages: _convo1(), unreadCount: 1, isPinned: true),
  Chat(id: 'c_group', participants: [sampleUsers[0], sampleUsers[1], sampleUsers[4]], messages: _convoGroup(), isGroup: true, groupName: 'Work Team 🚀', unreadCount: 2, isPinned: true),
  Chat(id: 'c2', participants: [sampleUsers[1]], messages: _convo2(), unreadCount: 1),
  Chat(id: 'c3', participants: [sampleUsers[2]], messages: _convo3()),
  Chat(id: 'c4', participants: [sampleUsers[3]], messages: [
    Message(id: _msgId(), senderId: 'u4', content: 'Let\'s catch up soon!', timestamp: DateTime.now().subtract(const Duration(days: 2))),
  ]),
  Chat(id: 'c5', participants: [sampleUsers[4]], messages: [
    Message(id: _msgId(), senderId: 'u5', content: 'The report is ready 📄', timestamp: DateTime.now().subtract(const Duration(days: 1))),
    Message(id: _msgId(), senderId: 'me', content: 'Awesome, I\'ll take a look!', timestamp: DateTime.now().subtract(const Duration(days: 1))),
  ]),
  Chat(id: 'c6', participants: [sampleUsers[5]], messages: [
    Message(id: _msgId(), senderId: 'u6', content: 'Hey, are you free for coffee? ☕', timestamp: DateTime.now().subtract(const Duration(hours: 6))),
  ], unreadCount: 1),
];
