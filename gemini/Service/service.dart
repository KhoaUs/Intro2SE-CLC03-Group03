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

  Future<String?> sendImagePrompt(String message, html.File file) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);

    // Wait for the file to be read
    await reader.onLoadEnd.first;
    final Uint8List imageData = reader.result as Uint8List;

    // Combine the text and image into a single content request
    final content = [
      Content.multi([
        TextPart(message),
        DataPart('image/jpeg', imageData),
      ]),
    ];

    // Generate content using the API
    final response = await _model.generateContent(content);
    return response.text;
  }
}