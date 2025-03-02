import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/question.dart';
import '../../providers/answers_provider.dart';

class QuestionCard extends ConsumerStatefulWidget {
  final Question question;
  final String sectionId;
  final int questionIndex;
  final int totalQuestions;
  final VoidCallback? onAnswerSaved;
  final bool readOnly;

  const QuestionCard({
    Key? key,
    required this.question,
    required this.sectionId,
    required this.questionIndex,
    required this.totalQuestions,
    this.onAnswerSaved,
    this.readOnly = false,
  }) : super(key: key);

  @override
  ConsumerState<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends ConsumerState<QuestionCard> with AutomaticKeepAliveClientMixin {
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  bool _isSaving = false;
  bool _isEditing = false;
  String _previousAnswer = '';
  Timer? _debounceTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCurrentAnswer();

    _answerController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id ||
        oldWidget.sectionId != widget.sectionId) {
      _loadCurrentAnswer();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _answerController.removeListener(_onTextChanged);
    _answerController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _loadCurrentAnswer() {
    final answers = ref.read(answersProvider).answers;
    final key = '${widget.sectionId}_${widget.question.id}';

    if (answers.containsKey(key)) {
      _previousAnswer = answers[key] ?? '';
      _answerController.text = _previousAnswer;
    } else {
      _previousAnswer = '';
      _answerController.clear();
    }
  }

  void _onTextChanged() {
    setState(() {
      _isTyping = _answerController.text.isNotEmpty;
    });

    // Only save if not read-only and not already saving
    if (!widget.readOnly && !_isSaving) {
      // Debounce save operation
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _autoSaveAnswer();
      });
    }
  }

  void _onFocusChanged() {
    setState(() {
      _isEditing = _focusNode.hasFocus;
    });

    // Save when focus is lost
    if (!_focusNode.hasFocus && _answerController.text != _previousAnswer) {
      _saveAnswer();
    }
  }

  Future<void> _autoSaveAnswer() async {
    if (_answerController.text.isNotEmpty && _answerController.text != _previousAnswer) {
      await _saveAnswer();
    }
  }

  Future<void> _saveAnswer() async {
    if (widget.readOnly) return;

    final text = _answerController.text.trim();

    // No need to save if text is the same as before
    if (text == _previousAnswer) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(answersProvider.notifier).saveAnswer(
        widget.sectionId,
        widget.question.id,
        text,
      );

      _previousAnswer = text;

      // Notify parent
      widget.onAnswerSaved?.call();
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save answer: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _clearTextField() {
    if (widget.readOnly) return;

    _answerController.clear();
    _saveAnswer();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);

    return Card(
      elevation: theme.brightness == Brightness.dark ? 4 : 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: theme.brightness == Brightness.dark
          ? theme.colorScheme.surfaceVariant
          : theme.colorScheme.surface,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header with number and progress
            Row(
              children: [
                Text(
                  'Question ${widget.questionIndex + 1} of ${widget.totalQuestions}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                    fontWeight: FontWeight.bold,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : theme.primaryColor,
                  ),
                ),
                const Spacer(),
                if (_isSaving)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Question text
            Text(
              widget.question.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFamily: GoogleFonts.lora().fontFamily,
                fontWeight: FontWeight.bold,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : theme.colorScheme.onSurface,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),

            // Answer field
            TextField(
              controller: _answerController,
              focusNode: _focusNode,
              maxLines: 5,
              readOnly: widget.readOnly,
              keyboardType: TextInputType.multiline,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: GoogleFonts.lora().fontFamily,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : theme.colorScheme.onSurface,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: widget.question.hint ?? "Share your thoughts here...",
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: GoogleFonts.lora().fontFamily,
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? theme.colorScheme.surfaceContainer
                    : theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.outline, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.outline, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.primaryColor, width: 2),
                ),
                suffixIcon: _isTyping && !widget.readOnly
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearTextField,
                )
                    : null,
              ),
            ),

            // Character count & validation hint
            if (!widget.readOnly)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Text(
                      '${_answerController.text.length} characters',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _answerController.text.length < 10
                            ? theme.colorScheme.error
                            : theme.brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    if (_answerController.text.length < 10)
                      Text(
                        'Please provide a more detailed answer',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}