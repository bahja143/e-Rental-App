import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/centered_header_bar.dart';
import '../data/models/chat_message.dart';
import '../data/repositories/messages_repository.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.threadId,
    this.agentName = 'Amanda',
  });

  final String threadId;
  final String agentName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Future<List<ChatMessage>> _conversationFuture;
  final _inputController = TextEditingController();
  final List<ChatMessage> _localMessages = <ChatMessage>[];

  @override
  void initState() {
    super.initState();
    _conversationFuture = MessagesRepository().getConversation(widget.threadId);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _handleSend(String text) {
    final msg = text.trim();
    if (msg.isEmpty) return;
    _inputController.clear();
    setState(() {
      _localMessages.add(
        ChatMessage(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          message: msg,
          time: _currentTime(),
          isMe: true,
        ),
      );
    });
  }

  String _currentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: SizedBox(
                height: 50,
                child: Row(
                  children: [
                    HeaderCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.messages);
                        }
                      },
                    ),
                    Expanded(
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: AppColors.greySoft1,
                              child: Text(
                                widget.agentName.substring(0, 1).toUpperCase(),
                                style: GoogleFonts.lato(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.agentName,
                                  style: GoogleFonts.raleway(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 0.42,
                                  ),
                                ),
                                Text(
                                  'Online',
                                  style: GoogleFonts.raleway(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.greyMedium,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    HeaderCircleButton(
                      icon: Icons.delete_outline_rounded,
                      onTap: _showDeleteSheet,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 20, 10, 14),
                decoration: BoxDecoration(
                  color: AppColors.greySoft1,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: FutureBuilder<List<ChatMessage>>(
                  future: _conversationFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    final messages = [...(snapshot.data ?? const <ChatMessage>[]), ..._localMessages];
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBackground.withValues(alpha: 0.69),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'December 12, 2022',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            itemCount: messages.length,
                            itemBuilder: (_, i) {
                              final m = messages[i];
                              return _ChatBubble(message: m.message, isMe: m.isMe, time: m.time);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ChatInput(
                          controller: _inputController,
                          onSend: _handleSend,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: 467,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 27, 24, 24),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6E6A99),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 56),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '?',
                    style: GoogleFonts.montserrat(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 74),
                Text.rich(
                  TextSpan(
                    style: GoogleFonts.lato(
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.4,
                      letterSpacing: 0.75,
                    ),
                    children: [
                      const TextSpan(text: 'Are you sure want to\n'),
                      TextSpan(
                        text: 'delete',
                        style: GoogleFonts.lato(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          height: 1.4,
                          letterSpacing: 0.75,
                        ),
                      ),
                      const TextSpan(text: ' all your chat?'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'This action can\'t be undo',
                  style: GoogleFonts.raleway(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.greyMedium,
                    letterSpacing: 0.36,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 70,
                        child: ElevatedButton(
                          onPressed: () => context.pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.48,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 70,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _localMessages.clear();
                              _conversationFuture = Future<List<ChatMessage>>.value(const <ChatMessage>[]);
                            });
                            context.pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.greySoft1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Delete',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.36,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isMe, required this.time});

  final String message;
  final bool isMe;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
              decoration: BoxDecoration(
                color: isMe ? Colors.white : AppColors.primaryBackground,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 16),
                ),
              ),
              child: Text(
                message,
                textAlign: isMe ? TextAlign.right : TextAlign.left,
                style: GoogleFonts.raleway(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isMe ? AppColors.greyMedium : Colors.white,
                  letterSpacing: 0.36,
                  height: 1.65,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              time.replaceAll(':', '.'),
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.greyBarelyMedium,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final void Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.only(left: 16, right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          const Icon(Icons.camera_alt_outlined, color: AppColors.greyMedium),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              style: GoogleFonts.raleway(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                letterSpacing: 0.36,
              ),
              decoration: InputDecoration(
                hintText: 'Say something',
                border: InputBorder.none,
                hintStyle: GoogleFonts.raleway(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.greyBarelyMedium,
                  letterSpacing: 0.36,
                ),
              ),
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFF8BC83F),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: () => onSend(controller.text),
            ),
          ),
        ],
      ),
    );
  }
}
