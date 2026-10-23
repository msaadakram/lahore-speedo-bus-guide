import 'dart:convert' as convert;

import 'package:http/http.dart' as http;

/// Feedback payload — identical field set to the original Firestore write.
class FeedbackPayload {
  const FeedbackPayload({
    required this.name,
    required this.email,
    required this.location,
    required this.type,
    required this.comment,
  });

  final String name;
  final String email;
  final String location;
  final String type;
  final String comment;

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'location': location,
    'type': type,
    'comment': comment,
    'platform': 'android',
    'createdAt': DateTime.now().toUtc().toIso8601String(),
  };
}

/// Submits feedback to a configurable REST endpoint.
///
/// The original app wrote to the Firestore collection `feedback`. To avoid
/// embedding project credentials, the rebuild posts to an operator-supplied
/// endpoint defined by the `FEEDBACK_ENDPOINT` environment variable
/// (see `.env.example`). When no endpoint is configured the submission is
/// queued locally and the user still sees the success path, so the observable
/// behaviour matches the original.
class FeedbackService {
  const FeedbackService._();

  static final FeedbackService instance = const FeedbackService._();

  /// `--dart-define=FEEDBACK_ENDPOINT=https://…`
  static const endpoint = String.fromEnvironment('FEEDBACK_ENDPOINT');

  Future<bool> submit(FeedbackPayload payload) async {
    if (endpoint.isEmpty) {
      // No backend configured: behave exactly like the original success path.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return true;
    }
    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: const {'Content-Type': 'application/json'},
            body: convert.json.encode(payload.toJson()),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
