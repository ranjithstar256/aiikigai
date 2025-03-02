import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/services/analytics_service.dart';
import '../../data/services/ai_service.dart';
import '../../models/insight.dart';
import '../../providers/auth_provider.dart';
import '../../providers/insights_provider.dart';
import '../../widgets/common/app_bar.dart';

// State class for chat messages
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

// Provider for chat state
final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier();
});

// Notifier for chat messages
class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  ChatMessagesNotifier() : super([]);

  void addUserMessage(String message) {
    state = [
      ...state,
      ChatMessage(text: message, isUser: true),
    ];
  }

  void addAiMessage(String message) {
    state = [
      ...state,
      ChatMessage(text: message, isUser: false),
    ];
  }

  void addLoadingMessage() {
    state = [
      ...state,
      ChatMessage(text: '', isUser: false, isLoading: true),
    ];
  }

  void removeLastMessage() {
    if (state.isNotEmpty) {
      state = state.sublist(0, state.length - 1);
    }
  }

  void clear() {
    state = [];
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AIService _aiService;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _aiService = AIService();

    // Log screen view
    ref.read(analyticsServiceProvider).logScreenView('chat_screen');

    // Add welcome message after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addWelcomeMessage();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    final insight = ref.read(insightsProvider).insight;
    final userName = ref.read(authProvider).user?.name ?? 'there';

    String welcomeMessage = 'Hello $userName! I\'m your Ikigai Guide. ';

    if (insight != null) {
      welcomeMessage += 'I\'ve analyzed your responses and created personalized insights for you. Feel free to ask me any questions about your Ikigai journey!';
    } else {
      welcomeMessage += 'I\'m here to help you on your journey to discover your Ikigai. You can ask me questions or discuss your insights anytime.';
    }

    chatNotifier.addAiMessage(welcomeMessage);
  }

  void _handleSubmitted(String text) async {
    _textController.clear();
    setState(() {
      _isComposing = false;
    });

    if (text.trim().isEmpty) return;

    final chatNotifier = ref.read(chatMessagesProvider.notifier);

    chatNotifier.addUserMessage(text);
    _scrollToBottom();

    chatNotifier.addLoadingMessage();

    try {
      final insight = ref.read(insightsProvider).insight;
      final userName = ref.read(authProvider).user?.name;
      final isPremium = ref.read(authProvider).user?.isPremium ?? false;

      String prompt = 'You are an AI assistant specializing in helping people discover their Ikigai (Japanese concept for purpose in life).\n\n';
      if (userName != null) {
        prompt += 'The user\'s name is $userName.\n';
      }
      if (insight != null) {
        prompt += 'Based on the user\'s responses, here are insights about their Ikigai:\n';
        prompt += 'Things they love: ${insight.topGoodAt.join(', ')}\n';
        prompt += 'Their strengths: ${insight.topStrengths.join(', ')}\n';
        prompt += 'What they can be paid for: ${insight.topPaidFor.join(', ')}\n';
        prompt += 'What the world needs from them: ${insight.topWorldNeeds.join(', ')}\n';
      }
      if (isPremium) {
        prompt += 'The user is a premium subscriber, so provide detailed, personalized responses.\n';
      } else {
        prompt += 'The user is on the free plan, so provide helpful but general responses.\n';
      }
      prompt += 'User says: $text\n\n';
      prompt += 'Please provide a thoughtful, empathetic response that helps them understand their purpose better. Keep responses concise but insightful.';

      // Updated call with isPremium parameter
      final response = await _aiService.sendMessage(prompt, isPremium: isPremium);

      chatNotifier.removeLastMessage();
      chatNotifier.addAiMessage(response);
      _scrollToBottom();

      ref.read(analyticsServiceProvider).logEvent(
        'chat_message_sent',
        parameters: {
          'is_premium': isPremium.toString(),
        },
      );
    } catch (e) {
      chatNotifier.removeLastMessage();
      chatNotifier.addAiMessage(
        'Sorry, I encountered an error. Please try again later.\nError: $e',
      );
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    // Wait a bit for the UI to update
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = ref.watch(chatMessagesProvider);
    final isPremium = ref.watch(authProvider).user?.isPremium ?? false;

    return Scaffold(
      appBar: IkigaiAppBar(
        title: 'Ikigai Guide Chat',
        actions: [
          // Clear chat button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Clear Chat',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Chat'),
                  content: const Text('Are you sure you want to clear all messages?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(chatMessagesProvider.notifier).clear();
                        _addWelcomeMessage();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Premium banner if not premium
          if (!isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upgrade to Premium for more personalized AI responses.',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/subscription');
                    },
                    child: const Text('Upgrade'),
                    style: TextButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Chat messages
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(messages[index]);
              },
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Message composer
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                // Text field
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onChanged: (text) {
                      setState(() {
                        _isComposing = text.trim().isNotEmpty;
                      });
                    },
                    onSubmitted: _isComposing ? _handleSubmitted : null,
                    decoration: InputDecoration(
                      hintText: 'Ask anything about your Ikigai...',
                      hintStyle: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: GoogleFonts.lato(
                      fontSize: 16,
                    ),
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),

                // Send button
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: _isComposing ? theme.primaryColor : Colors.grey.shade400,
                  ),
                  onPressed: _isComposing
                      ? () => _handleSubmitted(_textController.text)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Start chatting with your Ikigai Guide',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Ask questions about your insights or get guidance on your Ikigai journey.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final theme = Theme.of(context);
    final isPremium = ref.watch(authProvider).user?.isPremium ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar or indicator
          if (message.isUser)
            const SizedBox(width: 40) // Spacer for user messages
          else
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPremium
                    ? const Color(0xFFD4AF37).withOpacity(0.1)
                    : theme.primaryColor.withOpacity(0.1),
                border: Border.all(
                  color: isPremium
                      ? const Color(0xFFD4AF37)
                      : theme.primaryColor,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: message.isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPremium
                          ? const Color(0xFFD4AF37)
                          : theme.primaryColor,
                    ),
                  ),
                )
                    : Icon(
                  Icons.psychology,
                  size: 20,
                  color: isPremium
                      ? const Color(0xFFD4AF37)
                      : theme.primaryColor,
                ),
              ),
            ),

          // Message bubble
          Expanded(
            child: Container(
              margin: EdgeInsets.only(
                left: message.isUser ? 8.0 : 0.0,
                right: message.isUser ? 0.0 : 8.0,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? theme.primaryColor.withOpacity(0.1)
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(20.0),
                border: message.isUser
                    ? null
                    : Border.all(
                  color: theme.dividerColor,
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message text
                  message.isLoading
                      ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Thinking...',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  )
                      : Text(
                    message.text,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),

                  // Timestamp
                  if (!message.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        DateFormat('h:mm a').format(message.timestamp),
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // User avatar
          if (message.isUser)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(left: 8.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withOpacity(0.1),
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            )
          else
            const SizedBox(width: 40), // Spacer for AI messages
        ],
      ),
    );
  }
}