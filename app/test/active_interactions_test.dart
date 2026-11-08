import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/active_interactions.dart';
import 'package:kiosk_satellite/core/events.dart';

void main() {
  test('held lists the open holds as source:reason', () {
    final ledger = ActiveInteractions();
    expect(ledger.held, isEmpty);
    ledger.update(
      const VoiceInteractionChanged(
        active: true,
        reason: 'voice',
        source: InteractionSource.page,
      ),
    );
    ledger.update(
      const VoiceInteractionChanged(
        active: true,
        source: InteractionSource.page,
      ),
    );
    expect(ledger.held.toList(), ['page:voice', 'page:legacy']);
    final stillHeld = ledger.update(
      const VoiceInteractionChanged(
        active: false,
        reason: 'voice',
        source: InteractionSource.page,
      ),
    );
    expect(stillHeld, isTrue);
    expect(ledger.held.toList(), ['page:legacy']);
  });

  test('a reasonless release clears every hold of that source', () {
    final ledger = ActiveInteractions();
    ledger.update(
      const VoiceInteractionChanged(
        active: true,
        reason: 'media',
        source: InteractionSource.page,
      ),
    );
    ledger.update(
      const VoiceInteractionChanged(
        active: true,
        reason: 'media',
        source: InteractionSource.sendspin,
      ),
    );
    final stillHeld = ledger.update(
      const VoiceInteractionChanged(
        active: false,
        source: InteractionSource.page,
      ),
    );
    expect(stillHeld, isTrue);
    expect(ledger.held.toList(), ['sendspin:media']);
  });

  test('needsScreen ignores page media and reasonless pauses', () {
    final ledger = ActiveInteractions();
    ledger.update(
      const VoiceInteractionChanged(
        active: true,
        reason: 'media',
        source: InteractionSource.page,
      ),
    );
    ledger.update(const VoiceInteractionChanged(active: true));
    expect(ledger.needsScreen, isFalse);
    ledger.update(
      const VoiceInteractionChanged(
        active: true,
        reason: 'timer',
        source: InteractionSource.page,
      ),
    );
    expect(ledger.needsScreen, isTrue);
  });
}
