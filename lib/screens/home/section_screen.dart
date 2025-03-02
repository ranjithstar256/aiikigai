import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/analytics_service.dart';
import '../../models/section.dart';
import '../../providers/answers_provider.dart';
import '../../providers/questions_provider.dart';

class SectionScreen extends ConsumerStatefulWidget {
  final String sectionId;

  const SectionScreen({
    Key? key,
    required this.sectionId,
  }) : super(key: key);

  @override
  ConsumerState<SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends ConsumerState<SectionScreen>
    with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  final TextEditingController _answerController = TextEditingController();
  late AnimationController _saveAnimationController;
  late Animation<double> _saveAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation
    _saveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _saveAnimation = Tween<double>(begin: 0, end: 1).animate(_saveAnimationController);

    // Load current answer if exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentAnswer();
    });

    // Log screen view
    final section = ref.read(sectionByIdProvider(widget.sectionId));
    if (section != null) {
      ref.read(analyticsServiceProvider).logScreenView('section_screen_${section.id}');
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    _saveAnimationController.dispose();
    super.dispose();
  }

  void _loadCurrentAnswer() {
    final section = ref.read(sectionByIdProvider(widget.sectionId));
    if (section == null) return;

    final currentQuestion = section.questions[_currentQuestionIndex];
    final key = '${section.id}_${currentQuestion.id}';

    final answers = ref.read(answersProvider).answers;
    if (answers.containsKey(key)) {
      _answerController.text = answers[key] ?? '';
    } else {
      _answerController.clear();
    }
  }

  Future<void> _saveAnswer() async {
    final section = ref.read(sectionByIdProvider(widget.sectionId));
    if (section == null) return;

    final currentQuestion = section.questions[_currentQuestionIndex];
    final answer = _answerController.text.trim();

    if (answer.isNotEmpty) {
      await ref.read(answersProvider.notifier).saveAnswer(
        section.id,
        currentQuestion.id,
        answer,
      );

      _saveAnimationController.forward().then((_) {
        _saveAnimationController.reverse();
      });
    } else {
      _showSnackBar('Please enter an answer.');
    }
  }

  void _clearTextField() {
    _answerController.clear();
  }

  void _nextQuestion() {
    final section = ref.read(sectionByIdProvider(widget.sectionId));
    if (section == null) return;

    String answer = _answerController.text.trim();
    if (answer.isNotEmpty) {
      _saveAnswer().then((_) {
        if (_currentQuestionIndex < section.questions.length - 1) {
          setState(() {
            _currentQuestionIndex++;
            _loadCurrentAnswer();
          });
        } else {
          _finishSection();
        }
      });
    } else {
      _showSnackBar('Please enter an answer before proceeding.');
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _loadCurrentAnswer();
      });
    }
  }

  void _finishSection() {
    final section = ref.read(sectionByIdProvider(widget.sectionId));
    if (section == null) return;

    // Log section completion
    ref.read(analyticsServiceProvider).logSectionCompleted(
      section.id,
      section.title,
    );

    // Show completion dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Section Completed!'),
        content: Text(
          'You\'ve completed the "${section.title}" section. '
              'Continue exploring other sections or connect the dots to get insights.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get section data
    final sectionAsync = ref.watch(sectionByIdProvider(widget.sectionId));

    if (sectionAsync == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Section')),
        body: const Center(child: Text('Section not found')),
      );
    }

    final section = sectionAsync;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          section.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontFamily: GoogleFonts.playfairDisplay().fontFamily,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor.withOpacity(
                theme.brightness == Brightness.dark ? 0.4 : 0.8,
              ),
              theme.colorScheme.secondary.withOpacity(
                theme.brightness == Brightness.dark ? 0.2 : 0.6,
              ),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                verticalDirection: VerticalDirection.down,
                children: [
                  // Progress indicator
                  LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / section.questions.length,
                    backgroundColor: theme.brightness == Brightness.dark
                        ? theme.colorScheme.surfaceVariant
                        : Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                  ),
                  const SizedBox(height: 16),

                  // Question card
                  _buildQuestionCard(section),
                  const SizedBox(height: 16),

                  // Clear button
                  _buildClearButton(),
                  const SizedBox(height: 16),

                  // Navigation buttons
                  _buildButtonSection(section),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Section section) {
    final theme = Theme.of(context);
    final currentQuestion = section.questions[_currentQuestionIndex];

    return Card(
      elevation: theme.brightness == Brightness.dark ? 4 : 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: theme.brightness == Brightness.dark
          ? theme.colorScheme.surfaceVariant
          : theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1} of ${section.questions.length}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                fontWeight: FontWeight.bold,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : theme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              currentQuestion.text,
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

            TextField(
              controller: _answerController,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: GoogleFonts.lora().fontFamily,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : theme.colorScheme.onSurface,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: currentQuestion.hint ?? "Share your thoughts here...",
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: ElevatedButton(
          onPressed: _clearTextField,
          style: ElevatedButton.styleFrom(
            foregroundColor: theme.brightness == Brightness.dark
                ? Colors.white
                : theme.colorScheme.onSurface,
            backgroundColor: theme.brightness == Brightness.dark
                ? theme.colorScheme.surfaceContainer
                : theme.colorScheme.surfaceContainerHighest,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(12),
            elevation: theme.brightness == Brightness.dark ? 3 : 6,
          ),
          child: Icon(
            Icons.clear,
            color: theme.brightness == Brightness.dark
                ? Colors.white
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildButtonSection(Section section) {
    final theme = Theme.of(context);
    final isLastQuestion = _currentQuestionIndex == section.questions.length - 1;
    final isFirstQuestion = _currentQuestionIndex == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button (hidden on first question)
          if (!isFirstQuestion)
            ElevatedButton.icon(
              onPressed: _previousQuestion,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                backgroundColor: Colors.grey.shade200,
                foregroundColor: theme.brightness == Brightness.dark
                    ? Colors.black
                    : Colors.grey.shade800,
              ),
            )
          else
            const SizedBox(width: 10),

          // Next/Finish button
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: isFirstQuestion ? 0 : 10),
              child: ElevatedButton.icon(
                onPressed: _nextQuestion,
                icon: Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
                label: Text(isLastQuestion ? 'Finish Section' : 'Next Question'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: theme.brightness == Brightness.dark ? 4 : 8,
                  shadowColor: theme.primaryColor.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}