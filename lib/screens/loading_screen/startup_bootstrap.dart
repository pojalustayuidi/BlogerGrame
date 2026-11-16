/// Flutter-independent startup steps: every increment represents completed I/O.
class PrufaniBootstrap {
  final Future<void> Function() readLocalSession;
  final Future<void> Function() recoverSession;
  final Future<void> Function() verifyIdentity;
  final Future<void> Function() loadHomeData;

  const PrufaniBootstrap({
    required this.readLocalSession,
    required this.recoverSession,
    required this.verifyIdentity,
    required this.loadHomeData,
  });

  static const int totalStages = 4;

  Future<void> run({void Function(int completed)? onStageDone}) async {
    await readLocalSession();
    onStageDone?.call(1);
    await recoverSession();
    onStageDone?.call(2);
    await verifyIdentity();
    onStageDone?.call(3);
    await loadHomeData();
    onStageDone?.call(4);
  }
}
