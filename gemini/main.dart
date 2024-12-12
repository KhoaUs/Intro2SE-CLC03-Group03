// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_markdown/flutter_markdown.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:image_picker_web/image_picker_web.dart';
// import 'dart:html' as html; // for web file handling

// /// The API key to use when accessing the Gemini API.
// ///
// /// To learn how to generate and specify this key,
// /// check out the README file of this sample.
// const String _apiKey = String.fromEnvironment('API_KEY');
// // flutter run --dart-define=API_KEY=AIzaSyAqkrM-DQDwpAcKbiro-fNYLZJJ61dGWO4

// // https://github.com/google-gemini/generative-ai-dart/tree/main/samples/flutter_app

// void main() {
//   runApp(const GenerativeAISample());
// }

// class GenerativeAISample extends StatelessWidget {
//   const GenerativeAISample({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter + Generative AI',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//           brightness: Brightness.dark,
//           seedColor: const Color.fromARGB(255, 244, 171, 237),
//         ),
//         useMaterial3: true,
//       ),
//       home: const ChatScreen(title: 'Flutter + Generative AI'),
//     );
//   }
// }

// class ChatScreen extends StatefulWidget {
//   const ChatScreen({super.key, required this.title});

//   final String title;

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: const ChatWidget(apiKey: _apiKey),
//     );
//   }
// }

// class ChatWidget extends StatefulWidget {
//   const ChatWidget({
//     required this.apiKey,
//     super.key,
//   });

//   final String apiKey;

//   @override
//   State<ChatWidget> createState() => _ChatWidgetState();
// }

// class _ChatWidgetState extends State<ChatWidget> {
//   late final GenerativeModel _model;
//   late final ChatSession _chat;
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _textController = TextEditingController();
//   final FocusNode _textFieldFocus = FocusNode();
//   final List<({Image? image, String? text, bool fromUser})> _generatedContent =
//       <({Image? image, String? text, bool fromUser})>[];
//   bool _loading = false;

//   @override
//   void initState() {
//     super.initState();
//     _model = GenerativeModel(
//       model: 'gemini-1.5-flash-latest',
//       apiKey: widget.apiKey,
//     );
//     _chat = _model.startChat();
//   }

//   void _scrollDown() {
//     WidgetsBinding.instance.addPostFrameCallback(
//       (_) => _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: const Duration(
//           milliseconds: 750,
//         ),
//         curve: Curves.easeOutCirc,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final textFieldDecoration = InputDecoration(
//       contentPadding: const EdgeInsets.all(15),
//       hintText: 'Enter a prompt...',
//       border: OutlineInputBorder(
//         borderRadius: const BorderRadius.all(
//           Radius.circular(14),
//         ),
//         borderSide: BorderSide(
//           color: Theme.of(context).colorScheme.secondary,
//         ),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: const BorderRadius.all(
//           Radius.circular(14),
//         ),
//         borderSide: BorderSide(
//           color: Theme.of(context).colorScheme.secondary,
//         ),
//       ),
//     );

//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             child: _apiKey.isNotEmpty
//                 ? ListView.builder(
//                     controller: _scrollController,
//                     itemBuilder: (context, idx) {
//                       final content = _generatedContent[idx];
//                       return MessageWidget(
//                         text: content.text,
//                         image: content.image,
//                         isFromUser: content.fromUser,
//                       );
//                     },
//                     itemCount: _generatedContent.length,
//                   )
//                 : ListView(
//                     children: const [
//                       Text(
//                         'No API key found. Please provide an API Key using '
//                         "'--dart-define' to set the 'API_KEY' declaration.",
//                       ),
//                     ],
//                   ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(
//               vertical: 25,
//               horizontal: 15,
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     autofocus: true,
//                     focusNode: _textFieldFocus,
//                     decoration: textFieldDecoration,
//                     controller: _textController,
//                     onSubmitted: _sendChatMessage,
//                   ),
//                 ),
//                 const SizedBox.square(dimension: 15),
//                 IconButton(
//                   onPressed: !_loading
//                       ? () async {
//                           _sendImagePrompt(_textController.text);
//                         }
//                       : null,
//                   icon: Icon(
//                     Icons.image,
//                     color: _loading
//                         ? Theme.of(context).colorScheme.secondary
//                         : Theme.of(context).colorScheme.primary,
//                   ),
//                 ),
//                 if (!_loading)
//                   IconButton(
//                     onPressed: () async {
//                       _sendChatMessage(_textController.text);
//                     },
//                     icon: Icon(
//                       Icons.send,
//                       color: Theme.of(context).colorScheme.primary,
//                     ),
//                   )
//                 else
//                   const CircularProgressIndicator(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _sendImagePrompt(String message) async {
//   setState(() {
//     _loading = true;
//   });

//   try {
//     // Pick an image using image_picker_for_web (for web).
//     final html.File? pickedFile = await ImagePickerWeb.getImageAsFile();

//     if (pickedFile == null) {
//       // User canceled image selection
//       setState(() {
//         _loading = false;
//       });
//       return;
//     }

//     // Read the file as bytes (web only).
//     final reader = html.FileReader();
//     reader.readAsArrayBuffer(pickedFile);

//     reader.onLoadEnd.listen((_) async {
//       final Uint8List imageData = reader.result as Uint8List;

//       // Display the selected image in the chat widget.
//       setState(() {
//         _generatedContent.add((
//           image: Image.memory(imageData),
//           text: message,
//           fromUser: true,
//         ));
//       });

//       // Send the image data to the API.
//       final content = [
//         Content.multi([
//           TextPart(message),
//           DataPart('image/jpeg', imageData),
//         ]),
//       ];

//       // Call the generative API with the image.
//       var response = await _model.generateContent(content);
//       var text = response.text;

//       // Add the API's response to the chat widget.
//       _generatedContent.add((image: null, text: text, fromUser: false));

//       if (text == null) {
//         _showError('No response from API.');
//         return;
//       }

//       setState(() {
//         _loading = false;
//         _scrollDown();
//       });
//     });
//   } catch (e) {
//     _showError(e.toString());
//     setState(() {
//       _loading = false;
//     });
//   } finally {
//     _textController.clear();
//     setState(() {
//       _loading = false;
//     });
//     _textFieldFocus.requestFocus();
//   }
// }

//   Future<void> _sendChatMessage(String message) async {
//     setState(() {
//       _loading = true;
//     });

//     try {
//       _generatedContent.add((image: null, text: message, fromUser: true));
//       final response = await _chat.sendMessage(
//         Content.text(message),
//       );
//       final text = response.text;
//       _generatedContent.add((image: null, text: text, fromUser: false));

//       if (text == null) {
//         _showError('No response from API.');
//         return;
//       } else {
//         setState(() {
//           _loading = false;
//           _scrollDown();
//         });
//       }
//     } catch (e) {
//       _showError(e.toString());
//       setState(() {
//         _loading = false;
//       });
//     } finally {
//       _textController.clear();
//       setState(() {
//         _loading = false;
//       });
//       _textFieldFocus.requestFocus();
//     }
//   }

//   void _showError(String message) {
//     showDialog<void>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Something went wrong'),
//           content: SingleChildScrollView(
//             child: SelectableText(message),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text('OK'),
//             )
//           ],
//         );
//       },
//     );
//   }
// }

// class MessageWidget extends StatelessWidget {
//   const MessageWidget({
//     super.key,
//     this.image,
//     this.text,
//     required this.isFromUser,
//   });

//   final Image? image;
//   final String? text;
//   final bool isFromUser;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment:
//           isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
//       children: [
//         Flexible(
//             child: Container(
//                 constraints: const BoxConstraints(maxWidth: 520),
//                 decoration: BoxDecoration(
//                   color: isFromUser
//                       ? Theme.of(context).colorScheme.primaryContainer
//                       : Theme.of(context).colorScheme.surfaceContainerHighest,
//                   borderRadius: BorderRadius.circular(18),
//                 ),
//                 padding: const EdgeInsets.symmetric(
//                   vertical: 15,
//                   horizontal: 20,
//                 ),
//                 margin: const EdgeInsets.only(bottom: 8),
//                 child: Column(children: [
//                   if (text case final text?) MarkdownBody(data: text),
//                   if (image case final image?) image,
//                 ]))),
//       ],
//     );
//   }
// }

// // uid -> log -> thread -> chat
import 'package:flutter/material.dart';
import 'UI/ui.dart';

void main() {
  runApp(const GenerativeAISample());
}

class GenerativeAISample extends StatelessWidget {
  const GenerativeAISample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter + Generative AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color.fromARGB(255, 244, 171, 237),
        ),
        useMaterial3: true,
      ),
      home: const ChatScreen(title: 'Flutter + Generative AI'),
    );
  }
}
// flutter run --dart-define=API_KEY=AIzaSyAqkrM-DQDwpAcKbiro-fNYLZJJ61dGWO4