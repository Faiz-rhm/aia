import 'package:flutter/material.dart';
import 'package:chat_bubbles/chat_bubbles.dart';

import '../constants/app_colors.dart';

class MessageListBuilder extends StatelessWidget {
  const MessageListBuilder({
    super.key,
    required FocusNode textFieldFocusNode,
    required ScrollController scrollController,
    required List<Map<String, String>> messages,
  }) : _textFieldFocusNode = textFieldFocusNode, _scrollController = scrollController, _messages = messages;

  final FocusNode _textFieldFocusNode;
  final ScrollController _scrollController;
  final List<Map<String, String>> _messages;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _textFieldFocusNode.unfocus(),
        child: ListView.builder(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(8.0),
          itemCount: _messages.length + 1,
          itemBuilder: (context, index) {
            if (index == _messages.length) {
              return const SizedBox(height: 30);
            }

            final msg = _messages[index];
            final bool isUser = msg['role'] == 'user';

            return Padding(
              padding: EdgeInsets.only(
                top: isUser ? 8.0 : 12.0,
                bottom: isUser ? 12.0 : 8.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        color: AppColors.senderBubbleColor,
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/icon.png', height: 16, width: 16,),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, right: 16),
                        child: Text(
                          msg['content'] ?? '',
                          style: TextStyle(
                            fontFamily: 'sv-pro',
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (isUser) ...[
                    // Sender: Bubble tail (a triangle)
                    BubbleSpecialThree(
                      text: msg['content'] ?? '',
                      color: AppColors.senderBubbleColor,
                      tail: true,
                      textStyle: TextStyle(
                        fontFamily: 'sv-pro',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
        ),
      ),
    );
  }
}
