import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ConversationsProvider extends ChangeNotifier {
  List<dynamic> _conversations = [];
  bool _loading = false;
  String? _error;

  List<dynamic> get conversations => _conversations;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _conversations = (await ApiService.getConversations())
        .map((c) => Map<String, dynamic>.from(c as Map))
        .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getOrCreateDirect(int userId) async {
    try {
      final convo = await ApiService.getOrCreateDirect(userId);
      // Add to local list if not present
      final exists = _conversations.any((c) => c['id'].toString() == convo['id'].toString());
      if (!exists) {
        _conversations.insert(0, Map<String, dynamic>.from(convo));
        notifyListeners();
      }
      return convo;
    } on ApiException {
      return null;
    }
  }

  void updateConversationLastMessage(int convoId, Map<String, dynamic> msg) {
    final idx = _conversations.indexWhere((c) => c['id'].toString() == convoId.toString());
    if (idx != -1) {
      _conversations[idx] = {
        ..._conversations[idx],
        'last_message': msg,
        'updated_at': msg['created_at'],
      };
      // Bubble to top
      final item = _conversations.removeAt(idx);
      _conversations.insert(0, item);
      notifyListeners();
    }
  }

  void markRead(int convoId) {
    final idx = _conversations.indexWhere((c) => c['id'].toString() == convoId.toString());
    if (idx != -1) {
      // Immediately zero out badge — .then() reload will sync full state from server
      final updated = Map<String, dynamic>.from(_conversations[idx] as Map);
      updated['unread_count'] = 0;
      _conversations[idx] = updated;
      notifyListeners();
    }
  }
}
