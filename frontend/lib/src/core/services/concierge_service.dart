import 'concierge_manager.dart';

/// Thin wrapper used by course/product pages to pass context to an
/// ALREADY-OPEN concierge. Never creates the iframe on its own.
class ConciergeService {
  ConciergeService._();

  static void setPrompt(String prompt) => ConciergeManager.sendPrompt(prompt);
}
