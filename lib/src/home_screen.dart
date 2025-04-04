import 'dart:convert';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'constants/app_colors.dart';
import 'widgets/message_list_builder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final FocusNode _textFieldFocusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [];

  bool _isListening = false;
  bool _isTextFieldFocused = false;
  bool _isTextNotEmpty = false;
  String _text = '';
  int _textFieldLines = 1;
  final int _lineLimit = 1;

  @override
  void initState() {
    super.initState();

    _textFieldFocusNode.addListener(() {
      setState(() {
        _isTextFieldFocused = _textFieldFocusNode.hasFocus;
      });

      if (_textFieldFocusNode.hasFocus) scrollToBottom();
    });

    _textController.addListener(() {
      setState(() {
        _isTextNotEmpty = _textController.text.trim().isNotEmpty;
      });
    });
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Future<void> _startListening() async {
    _textFieldFocusNode.unfocus();
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() => _text = result.recognizedWords);
        },
      );
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);

    if (_text.isNotEmpty) {
      final message = _text;
      _textController.text = message;
      _text = '';
      _sendMessage(message);
    }
    _textController.clear();
  }

  Future<void> _sendMessage(String userMessage) async {
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
    });

    scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer OPENAI_API_KEY', // Replace securely
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': 'You are a helpful assistant.'},
            ..._messages,
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiReply = data['choices'][0]['message']['content'];

        setState(() {
          _messages.add({'role': 'assistant', 'content': aiReply});
        });

        await _speak(aiReply);
      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content':
                'Error: ${response.statusCode} - ${json.decode(response.body)['error']['message'] ?? 'Unknown error'}',
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Sorry, something went wrong.',
        });
      });
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    _textController.dispose();
    _scrollController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ask Anything',
          style: TextStyle(
            fontFamily: 'sv-pro',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.backgroundColor,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          MessageListBuilder(
            textFieldFocusNode: _textFieldFocusNode,
            scrollController: _scrollController,
            messages: _messages,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.textfieldBackgroundColor,
                      borderRadius: BorderRadius.circular(
                        _textFieldLines > _lineLimit ? 48 : 24,
                      ),
                      border: Border.all(
                        color: AppColors.textfieldBackgroundColor,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: _isTextFieldFocused
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: 15),
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                focusNode: _textFieldFocusNode,
                                maxLines: null,
                                minLines: 1,
                                cursorColor: AppColors.primaryColor,
                                style: const TextStyle(
                                  fontFamily: 'sv-pro',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Ask a Follow-Up',
                                  hintStyle: TextStyle(
                                    fontFamily: 'sv-pro',
                                    color: AppColors.labelSecondary
                                        .withOpacity(0.6),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                ),
                                onChanged: (text) {
                                  final lines =
                                      '\n'.allMatches(text).length + 1;
                                  if (lines != _textFieldLines) {
                                    setState(() {
                                      _textFieldLines = lines;
                                    });
                                  }
                                },
                              ),
                            ),
                            _isTextFieldFocused
                                ? _buildSendButton()
                                : _buildMicButton(),
                            const SizedBox(width: 6),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(
        bottom: _textFieldLines > _lineLimit ? 0 : 8,
      ),
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
      ),
      color: _isTextNotEmpty
          ? AppColors.primaryColor
          : AppColors.disableColor.withOpacity(0.18),
      child: SizedBox(
        height: 32,
        width: 32,
        child: InkWell(
          onTap: _isTextNotEmpty
              ? () {
                  final message = _textController.text.trim();
                  if (message.isNotEmpty) {
                    _sendMessage(message);
                    _textController.clear();
                  }
                }
              : null,
          child: const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    return IconButton(
      onPressed: _isListening ? _stopListening : _startListening,
      icon: Icon(
        _isListening ? Iconsax.microphone_slash_1 : Iconsax.microphone_2,
        color: AppColors.gray2,
        size: 30,
      ),
    );
  }
}
