import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:blogergrame/screens/loading_screen/startup_bootstrap.dart';

void main() {
  test('startup stages advance only after real operations finish', () async {
    final next = Completer<void>();
    final steps = <int>[];
    final calls = <String>[];
    final bootstrap = PrufaniBootstrap(
      readLocalSession: () async { calls.add('storage'); },
      recoverSession: () async {
        calls.add('session');
        await next.future;
      },
      verifyIdentity: () async { calls.add('identity'); },
      loadHomeData: () async { calls.add('home'); },
    );
    final running = bootstrap.run(onStageDone: steps.add);
    // Permit the first asynchronous stage to finish.
    await Future<void>.delayed(Duration.zero);
    expect(steps, [1]);
    expect(calls, ['storage', 'session']);
    next.complete();
    await running;
    expect(calls, ['storage', 'session', 'identity', 'home']);
    expect(steps, [1, 2, 3, 4]);
  });

  test('error stops startup without claiming success', () async {
    final steps = <int>[];
    final bootstrap = PrufaniBootstrap(
      readLocalSession: () async {},
      recoverSession: () async { throw StateError('Offline'); },
      verifyIdentity: () async { fail('must not request identity'); },
      loadHomeData: () async { fail('must not load wallet'); },
    );
    await expectLater(
      bootstrap.run(onStageDone: steps.add), throwsStateError);
    expect(steps, [1]);
  });

  test('retry can re-run the same bootstrap after a transient failure', () async {
    var attempts = 0;
    final bootstrap = PrufaniBootstrap(
      readLocalSession: () async {},
      recoverSession: () async {
        attempts++;
        if (attempts == 1) throw StateError('Network');
      },
      verifyIdentity: () async {},
      loadHomeData: () async {},
    );
    await expectLater(bootstrap.run(), throwsStateError);
    await bootstrap.run();
    expect(attempts, 2);
  });
}
