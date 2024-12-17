import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:image_picker_web/image_picker_web.dart';
// import '../UI/ui.dart'

class ChatService {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  ChatService(String apiKey, String model) {
    _model = GenerativeModel(
      model: model, // Model AI
      apiKey: apiKey, // API Key
    );
    _chat = _model.startChat(); // Khởi tạo phiên chat
  }

  /// Gửi tin nhắn và nhận phản hồi từ AI
  Future<String> sendMessage(String message) async {
    try {
      // Gửi tin nhắn
      final response = await _chat.sendMessage(Content.text(message));

      // Kiểm tra xem phản hồi có tồn tại không
      if (response.text != null) {
        return response.text!;
      } else {
        return 'No response from AI.';
      }
    } catch (error) {
      // Xử lý lỗi
      return 'Error: ${error.toString()}';
    }
  }
}