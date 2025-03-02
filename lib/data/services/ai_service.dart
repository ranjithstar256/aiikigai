import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../models/insight.dart';

// Provider definition
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

class AIService {
  final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final String apiUrl = 'https://api.openai.com/v1/chat/completions';
  final Uuid uuid = Uuid();

  Future<Insight> generateInsights({
    required Map<String, List<String>> sectionAnswers,
    required String userId,
    bool isPremium = false,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('OpenAI API key not found. Please check your .env file.');
    }

    try {
      final prompt = _createPrompt(sectionAnswers, isPremium);
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': isPremium ? 'gpt-4-turbo' : 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': 'You are a helpful AI assistant.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': isPremium ? 2500 : 1500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'];

        final jsonMatch = RegExp(r'({[\s\S]*})').firstMatch(content);
        if (jsonMatch != null) {
          final jsonString = jsonMatch.group(1);
          final data = jsonDecode(jsonString!);

          return Insight(
            id: uuid.v4(),
            userId: userId,
            data: data,
            isPremium: isPremium,
          );
        } else {
          throw Exception('Failed to parse AI response as JSON');
        }
      } else {
        throw Exception('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // New method for chat functionality
  Future<String> sendMessage(String prompt, {bool isPremium = false}) async {
    if (apiKey.isEmpty) {
      throw Exception('OpenAI API key not found. Please check your .env file.');
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': isPremium ? 'gpt-4-turbo' : 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': 'You are a helpful AI assistant.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': isPremium ? 500 : 300, // Smaller token limit for chat
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'].trim();
        return content;
      } else {
        throw Exception('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  String _createPrompt(Map<String, List<String>> sectionAnswers, bool isPremium) {
    // Existing method unchanged
    String prompt = "I am using this app to help users find their purpose in life using the Japanese IKIGAI method.\n\n";
    sectionAnswers.forEach((section, answers) {
      prompt += "Section: $section\n";
      for (int i = 0; i < answers.length; i++) {
        prompt += "- ${answers[i]}\n";
      }
      prompt += "\n";
    });
    prompt += "Based on the following answers, please analyze the user's personality, strengths, and career fit in depth. ";
    if (isPremium) {
      prompt += "Since this is a premium analysis, please provide detailed, nuanced insights with specific examples and actionable advice tailored to their unique situation. ";
      prompt += "Include advanced psychological insights and customized career path suggestions based on market trends. ";
    } else {
      prompt += "Provide actionable insights and a realistic, specific plan for them. ";
    }
    prompt += "Please provide the analysis as a JSON object with the following format. Make sure to fill every field with a non-empty response:\n";
    prompt += '''
{
  "top_good_at": "Top 5 things the user is good at (each point separated by a newline as bullet points)",
  "top_strengths": "Top 5 strengths of the user (each point separated by a newline as bullet points)",
  "top_paid_for": "Top 5 ways the user can be paid for (be very specific, each point separated by a newline as bullet points)",
  "top_world_needs": "Top 5 things the world needs from the user (each point separated by a newline as bullet points)",
  "get_started_plan": "A simple and clear get-started plan with actionable steps (each step on a new line)",
  "what_you_are_missing": "Insights on what the user is missing based on patterns in their answers (each point separated by a newline as bullet points)",
  "future_outlook": {
      "next_5_years": "Realistic outcomes for the next 5 years (each point separated by a newline )",
      "next_30_years": "A long-term vision for the next 30 years (each point separated by a newline as bullet points)"
  }
''';
    if (isPremium) {
      prompt += ''',
  "career_recommendations": {
      "immediate_opportunities": "Specific job titles or freelance opportunities the user can pursue now (each point separated by a newline)",
      "growth_path": "A 5-year career progression plan with specific milestones (each point separated by a newline)",
      "dream_roles": "Ambitious but achievable dream positions based on the user's profile (each point separated by a newline)"
  },
  "psychological_insights": {
      "motivational_drivers": "What truly motivates this person based on their answers (each point separated by a newline)",
      "potential_blind_spots": "Potential challenges or growth areas that may hold them back (each point separated by a newline)",
      "unique_strengths": "Psychological strengths that make them unique in their field (each point separated by a newline)"
  },
  "ikigai_zone": "A paragraph describing what appears to be their Ikigai sweet spot where passion, talent, market need, and income potential all meet"
''';
    }
    prompt += "\n}\n\nEnsure that the response is only in valid JSON format with the keys as provided above.";
    return prompt;
  }
}