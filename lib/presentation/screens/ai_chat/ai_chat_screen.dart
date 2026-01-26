import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/task.dart';

import '../../providers/providers.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final aiService = ref.read(aiServiceProvider);
      // For now, we reuse the existing parsing logic but wrap it to look like chat
      // Ideally, we'd have a conversational endpoint.
      // Let's assume the user wants to perform actions.

      String responseText;

      // Heuristic: Check if it looks like a task creation or planning request
      final lowerText = text.toLowerCase();
      final isTaskRelated = lowerText.startsWith('add') ||
          lowerText.startsWith('create') ||
          lowerText.contains('remind me') ||
          lowerText.contains('plan') ||
          lowerText.contains('want to') ||
          lowerText.contains('going to') ||
          lowerText.contains('need to');

      if (isTaskRelated) {
        final parsedTask = await aiService.parseNaturalLanguage(text);

        // Create Task from ParsedTask
        final newTask = Task(
          id: const Uuid().v4(),
          title: parsedTask.title,
          description: parsedTask.description,
          dueDate: parsedTask.dueDate,
          priority: parsedTask.priority ?? Priority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          checklist: parsedTask.suggestedSubtasks.asMap().entries.map((e) {
            return SubTask(
              id: const Uuid().v4(),
              title: e.value,
              order: e.key,
            );
          }).toList(),
        );

        // Add to provider
        await ref.read(tasksProvider.notifier).addTask(newTask);

        // Get a conversational response too
        responseText =
            await aiService.chat(text, context: "Added ${newTask.title}");

        // Append task confirmation if response is too short
        if (responseText.length < 50) {
          responseText += "\n\nI've added **${newTask.title}** to your list.";
        }
      } else {
        // Fallback to generic AI chat
        final tasks = ref.read(tasksProvider);
        final pendingCount =
            tasks.where((t) => t.status == TaskStatus.pending).length;
        final overdueCount = tasks.where((t) => t.isOverdue).length;
        final todaysCount =
            ref.read(taskRepositoryProvider).getTodaysTasks().length;

        final contextStr =
            "Pending: $pendingCount, Overdue: $overdueCount, Due Today: $todaysCount.";

        responseText = await aiService.chat(text, context: contextStr);
      }

      setState(() {
        _messages.add(ChatMessage(text: responseText, isUser: false));
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
            text: "Sorry, I encountered an error: ${e.toString()}",
            isUser: false,
            isError: true));
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI Assistant',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _messages.clear();
              });
            },
            icon: const Icon(Iconsax.trash),
            tooltip: 'Clear Chat',
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTypingIndicator(theme);
                      }
                      return _buildMessageBubble(theme, _messages[index]);
                    },
                  ),
          ),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final suggestions = [
      'Add a task: "Buy milk tomorrow at 5pm"',
      'Analyze my productivity',
      'What should I distinguish today?',
      'High priority tasks',
    ];

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.message_question,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              'How can I help you today?',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: suggestions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final text = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        _controller.text = text;
                        _sendMessage();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(12),
                          color: theme.cardColor,
                        ),
                        child: Row(
                          children: [
                            Icon(Iconsax.message_text,
                                size: 16,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.7)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                text,
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                            ),
                            Icon(Iconsax.arrow_right_3,
                                size: 16, color: theme.disabledColor),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: (300 + (index * 100)).ms)
                      .slideX(begin: 0.1, duration: 300.ms);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ThemeData theme, ChatMessage message) {
    final isUser = message.isUser;
    final isError = message.isError;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : isError
                  ? theme.colorScheme.error.withValues(alpha: 0.1)
                  : theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: isUser
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ],
          border: isUser || !isError
              ? null
              : Border.all(color: theme.colorScheme.error),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.inter(
            color: isUser
                ? Colors.white
                : isError
                    ? theme.colorScheme.error
                    : theme.textTheme.bodyLarge?.color,
            height: 1.4,
          ),
        ),
      ).animate().fadeIn().slideY(begin: 0.1, duration: 200.ms),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(theme, 0),
            const SizedBox(width: 4),
            _dot(theme, 150),
            const SizedBox(width: 4),
            _dot(theme, 300),
          ],
        ),
      ),
    );
  }

  Widget _dot(ThemeData theme, int delay) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
        delay: Duration(milliseconds: delay),
        duration: 600.ms,
        begin: const Offset(0.8, 0.8),
        end: const Offset(1.2, 1.2));
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            FloatingActionButton(
              heroTag: 'ai_chat_fab',
              onPressed: _sendMessage,
              mini: true,
              elevation: 0,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Iconsax.send_1, color: Colors.white, size: 20),
            )
                .animate(
                  target: 1, // Always active
                )
                .scale(duration: 200.ms),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  ChatMessage({required this.text, required this.isUser, this.isError = false});
}
