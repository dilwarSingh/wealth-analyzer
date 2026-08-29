import 'package:ai/ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StreamingThinkingParser Tests', () {
    test('Correctly extracts streaming think tags without tag leakage in content', () {
      final textChunks = <String>[];
      final thinkingChunks = <String>[];
      var isThinkingState = false;

      final parser = StreamingThinkingParser(
        onChunk: ({required textDelta, required thinkingDelta, required isThinking, duration}) {
          if (textDelta.isNotEmpty) textChunks.add(textDelta);
          if (thinkingDelta.isNotEmpty) thinkingChunks.add(thinkingDelta);
          isThinkingState = isThinking;
        },
      );

      // Feed chunks simulating streaming token output
      parser.feedContent('<think>Analyzing');
      parser.feedContent(' asset allocation drift...');
      parser.feedContent('</think>Based on your current portfolio,');
      parser.feedContent(' you have 70% in equities.');
      parser.finalize();

      expect(parser.accumulatedThinking, 'Analyzing asset allocation drift...');
      expect(parser.accumulatedText, 'Based on your current portfolio, you have 70% in equities.');
      expect(textChunks.join(''), 'Based on your current portfolio, you have 70% in equities.');
      expect(thinkingChunks.join(''), 'Analyzing asset allocation drift...');
      expect(parser.thinkingDuration != null, true);
      expect(isThinkingState, false);
    });

    test('Correctly handles native reasoning content deltas with manual completion', () {
      final thinkingChunks = <String>[];

      final parser = StreamingThinkingParser(
        onChunk: ({required textDelta, required thinkingDelta, required isThinking, duration}) {
          if (thinkingDelta.isNotEmpty) thinkingChunks.add(thinkingDelta);
        },
      );

      parser.feedNativeReasoning('First step: ');
      parser.feedNativeReasoning('check liquid runway. ');
      parser.markNativeThinkingComplete();

      parser.feedContent('Your liquid runway is 8 months.');
      parser.finalize();

      expect(parser.accumulatedThinking, 'First step: check liquid runway. ');
      expect(parser.accumulatedText, 'Your liquid runway is 8 months.');
      expect(parser.isThinking, false);
    });

    test('Automatically transitions from native reasoning to text content without manual completion call', () {
      final textChunks = <String>[];
      final thinkingChunks = <String>[];

      final parser = StreamingThinkingParser(
        onChunk: ({required textDelta, required thinkingDelta, required isThinking, duration}) {
          if (textDelta.isNotEmpty) textChunks.add(textDelta);
          if (thinkingDelta.isNotEmpty) thinkingChunks.add(thinkingDelta);
        },
      );

      // Provider sends reasoning_content chunks
      parser.feedNativeReasoning('The user has sent two consecutive "hi" messages. ');
      parser.feedNativeReasoning('No tools are needed for this initial response.');

      // Provider transitions directly to content chunks without explicit finish call
      parser.feedContent("Hello! I'm your fiduciary Wealth Advisor and Portfolio Architect.");
      parser.feedContent(" I've reviewed your current financial snapshot.");
      parser.finalize();

      expect(parser.accumulatedThinking, 'The user has sent two consecutive "hi" messages. No tools are needed for this initial response.');
      expect(parser.accumulatedText, "Hello! I'm your fiduciary Wealth Advisor and Portfolio Architect. I've reviewed your current financial snapshot.");
      expect(textChunks.join(''), "Hello! I'm your fiduciary Wealth Advisor and Portfolio Architect. I've reviewed your current financial snapshot.");
      expect(thinkingChunks.join(''), 'The user has sent two consecutive "hi" messages. No tools are needed for this initial response.');
      expect(parser.isThinking, false);
    });
  });
}
