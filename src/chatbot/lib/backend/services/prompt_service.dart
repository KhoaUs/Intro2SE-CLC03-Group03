import 'dart:html' as html;
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:image_picker_web/image_picker_web.dart';
// import '../UI/ui.dart'

class ChatService {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  ChatService(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
    );
    _chat = _model.startChat();
  }

  Future<String?> sendMessage(String message) async {
    final response = await _chat.sendMessage(Content.text(message));
    return response.text;
  }
}