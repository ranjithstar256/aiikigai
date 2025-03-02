import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/analytics_service.dart';
import '../../models/insight.dart';
import '../../providers/answers_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/insights_provider.dart';
import '../../providers/questions_provider.dart';
import '../../widgets/ikigai/insight_card.dart';

class ConnectingDotsScreen extends ConsumerStatefulWidget {
  const ConnectingDotsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConnectingDotsScreen> createState() => _ConnectingDotsScreenState();
}

class _ConnectingDotsScreenState extends ConsumerState<ConnectingDotsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Map<String, bool> _expandedCards = {};
  bool _isGenerating = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();

    // Animation controller for card animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Log screen view
    ref.read(analyticsServiceProvider).logScreenView('connecting_dots_screen');

    // Load or generate insights
    _loadInsights();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    final insightsState = ref.read(insightsProvider);

    // If we already have insights, animate them in
    if (insightsState.insight != null) {
      _animationController.forward();
      return;
    }

    // Otherwise, generate new insights
    _generateInsights();
  }

  Future<void> _generateInsights() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Generate insights
      await ref.read(insightsProvider.notifier).generateInsight();

      // Log event
      ref.read(analyticsServiceProvider).logInsightGenerated(
        ref.read(authProvider).user?.isPremium ?? false,
      );

      // Animate cards
      _animationController.forward();
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate insights: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _toggleCardExpanded(String cardId) {
    setState(() {
      _expandedCards[cardId] = !(_expandedCards[cardId] ?? false);
    });
  }

  Future<void> _downloadPdf() async {
    final insight = ref.read(insightsProvider).insight;
    if (insight == null) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      // Request storage permission on Android
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            throw Exception('Storage permission required');
          }
        }
      }

      // Create PDF document
      final pdf = pw.Document();

      // Add content to PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Center(
                    child: pw.Text(
                      'Your Ikigai Journey',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Center(
                    child: pw.Text(
                      'Personalized Insights Report',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 40),

                  // Insight sections
                  _buildPdfSection(
                    'Things You Love',
                    insight.topGoodAt,
                  ),
                  _buildPdfSection(
                    'Your Strengths',
                    insight.topStrengths,
                  ),
                  _buildPdfSection(
                    'Ways You Can Be Paid',
                    insight.topPaidFor,
                  ),
                  _buildPdfSection(
                    'What the World Needs From You',
                    insight.topWorldNeeds,
                  ),
                  _buildPdfSection(
                    'Get Started Plan',
                    insight.getStartedPlan,
                    useNumbering: true,
                  ),
                  _buildPdfSection(
                    'What You Are Missing',
                    insight.whatYouAreMissing,
                  ),
                  _buildPdfSection(
                    '5-Year Outlook',
                    insight.futureOutlook['next_5_years'] ?? [],
                    useNumbering: true,
                  ),
                  _buildPdfSection(
                    '30-Year Vision',
                    insight.futureOutlook['next_30_years'] ?? [],
                  ),

                  // Footer
                  pw.SizedBox(height: 20),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Generated by Ikigai Journey App on ${DateTime.now().toString().split(' ')[0]}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Save PDF to file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/ikigai_insights.pdf');
      await file.writeAsBytes(await pdf.save());

      // Log event
      ref.read(analyticsServiceProvider).logPdfDownloaded();

      // Share the PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Ikigai Journey Insights',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download PDF: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  pw.Widget _buildPdfSection(
      String title,
      List<String> items,
      {bool useNumbering = false}
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        ...List.generate(
          items.length,
              (index) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 20,
                  child: pw.Text(
                    useNumbering ? '${index + 1}.' : '•',
                    style: const pw.TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    items[index],
                    style: const pw.TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insight = ref.watch(insightsProvider).insight;
    final isGenerating = ref.watch(insightsProvider).isGenerating || _isGenerating;
    final isPremium = ref.watch(authProvider).user?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Ikigai Insights',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (insight != null)
            IconButton(
              icon: Icon(
                _isDownloading ? Icons.hourglass_empty : Icons.download,
                color: Colors.white,
              ),
              onPressed: _isDownloading ? null : _downloadPdf,
              tooltip: 'Download PDF',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor.withOpacity(0.1),
              theme.colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: isGenerating
              ? _buildLoadingState()
              : insight == null
              ? _buildEmptyState()
              : _buildInsightsContent(insight, isPremium),
        ),
      ),
      floatingActionButton: insight != null
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/chat');
        },
        icon: const Icon(Icons.chat),
        label: const Text('Continue in Chat'),
        backgroundColor: theme.primaryColor,
      )
          : null,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Connecting the dots...',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'We are analyzing your answers to generate personalized insights.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'No insights available',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please complete all four sections before generating insights.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back to Sections'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsContent(Insight insight, bool isPremium) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // Introduction
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                'Based on your answers, here\'s what we\'ve discovered about your Ikigai:',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Love section
            _buildAnimatedCard(
              title: 'Things You Love',
              icon: Icons.favorite,
              items: insight.topGoodAt,
              cardId: 'love',
              index: 0,
            ),

            // Strengths section
            _buildAnimatedCard(
              title: 'Your Strengths',
              icon: Icons.star,
              items: insight.topStrengths,
              cardId: 'strengths',
              index: 1,
            ),

            // Paid for section
            _buildAnimatedCard(
              title: 'Ways You Can Be Paid',
              icon: Icons.attach_money,
              items: insight.topPaidFor,
              cardId: 'paid',
              index: 2,
            ),

            // World needs section
            _buildAnimatedCard(
              title: 'What the World Needs From You',
              icon: Icons.public,
              items: insight.topWorldNeeds,
              cardId: 'world',
              index: 3,
            ),

            // Get started plan
            _buildAnimatedCard(
              title: 'Get Started Plan',
              icon: Icons.play_arrow,
              items: insight.getStartedPlan,
              cardId: 'plan',
              index: 4,
              useNumbering: true,
            ),

            // What you are missing
            _buildAnimatedCard(
              title: 'What You Are Missing',
              icon: Icons.lightbulb,
              items: insight.whatYouAreMissing,
              cardId: 'missing',
              index: 5,
            ),

            // Future outlook
            _buildAnimatedCard(
              title: '5-Year Outlook',
              icon: Icons.timeline,
              items: insight.futureOutlook['next_5_years'] ?? [],
              cardId: 'outlook5',
              index: 6,
              useNumbering: true,
            ),

            _buildAnimatedCard(
              title: '30-Year Vision',
              icon: Icons.visibility,
              items: insight.futureOutlook['next_30_years'] ?? [],
              cardId: 'outlook30',
              index: 7,
            ),

            // Premium insights
            if (isPremium && insight.isPremium &&
                insight.data.containsKey('career_recommendations'))
              ..._buildPremiumInsights(insight),

            // Download button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : _downloadPdf,
                icon: Icon(_isDownloading ? Icons.hourglass_empty : Icons.download),
                label: Text(_isDownloading ? 'Preparing PDF...' : 'Download as PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildPremiumInsights(Insight insight) {
    final careerRecs = insight.data['career_recommendations'];
    final psychInsights = insight.data['psychological_insights'];
    final ikigaiZone = insight.data['ikigai_zone'];

    return [
      // Career recommendations
      if (careerRecs != null) ...[
        _buildAnimatedCard(
          title: 'Immediate Opportunities',
          icon: FontAwesomeIcons.briefcase,
          items: _parseStringToList(careerRecs['immediate_opportunities']),
          cardId: 'career_imm',
          index: 8,
          isPremium: true,
        ),

        _buildAnimatedCard(
          title: 'Career Growth Path',
          icon: FontAwesomeIcons.chartLine,
          items: _parseStringToList(careerRecs['growth_path']),
          cardId: 'career_growth',
          index: 9,
          isPremium: true,
          useNumbering: true,
        ),

        _buildAnimatedCard(
          title: 'Dream Roles',
          icon: FontAwesomeIcons.crown,
          items: _parseStringToList(careerRecs['dream_roles']),
          cardId: 'career_dream',
          index: 10,
          isPremium: true,
        ),
      ],

      // Psychological insights
      if (psychInsights != null) ...[
        _buildAnimatedCard(
          title: 'Your Motivational Drivers',
          icon: FontAwesomeIcons.bolt,
          items: _parseStringToList(psychInsights['motivational_drivers']),
          cardId: 'psych_motiv',
          index: 11,
          isPremium: true,
        ),

        _buildAnimatedCard(
          title: 'Potential Blind Spots',
          icon: FontAwesomeIcons.eyeSlash,
          items: _parseStringToList(psychInsights['potential_blind_spots']),
          cardId: 'psych_blind',
          index: 12,
          isPremium: true,
        ),

        _buildAnimatedCard(
          title: 'Your Unique Strengths',
          icon: FontAwesomeIcons.gem,
          items: _parseStringToList(psychInsights['unique_strengths']),
          cardId: 'psych_unique',
          index: 13,
          isPremium: true,
        ),
      ],

      // Ikigai zone
      if (ikigaiZone != null && ikigaiZone.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  0.7 + (14 * 0.02),
                  1.0,
                  curve: Curves.easeOut,
                ),
              ),
            ),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: const Color(0xFFD4AF37).withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFD4AF37).withOpacity(0.2),
                      const Color(0xFFD4AF37).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.bullseye,
                          color: const Color(0xFFD4AF37),
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Your Ikigai Sweet Spot',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.workspace_premium,
                          color: const Color(0xFFD4AF37),
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ikigaiZone,
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildAnimatedCard({
    required String title,
    required IconData icon,
    required List<String> items,
    required String cardId,
    required int index,
    bool isPremium = false,
    bool useNumbering = false,
  }) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            0.1 + (index * 0.05),
            0.6 + (index * 0.05),
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              0.1 + (index * 0.05),
              0.6 + (index * 0.05),
              curve: Curves.easeOut,
            ),
          ),
        ),
        child: InsightCard(
          title: title,
          icon: icon,
          items: items,
          isPremium: isPremium,
          useNumbering: useNumbering,
          expanded: _expandedCards[cardId] ?? false,
          onTap: () => _toggleCardExpanded(cardId),
        ),
      ),
    );
  }

  List<String> _parseStringToList(String text) {
    if (text.isEmpty) return [];

    // Split by bullet points or newlines
    final items = text
        .split(RegExp(r'[\n•]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return items;
  }
}