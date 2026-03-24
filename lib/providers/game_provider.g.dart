// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$gameHash() => r'de3a92c122213301da2905794a952da8c646b10a';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$Game extends BuildlessAutoDisposeNotifier<GameState> {
  late final Level level;

  GameState build(
    Level level,
  );
}

/// See also [Game].
@ProviderFor(Game)
const gameProvider = GameFamily();

/// See also [Game].
class GameFamily extends Family<GameState> {
  /// See also [Game].
  const GameFamily();

  /// See also [Game].
  GameProvider call(
    Level level,
  ) {
    return GameProvider(
      level,
    );
  }

  @override
  GameProvider getProviderOverride(
    covariant GameProvider provider,
  ) {
    return call(
      provider.level,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'gameProvider';
}

/// See also [Game].
class GameProvider extends AutoDisposeNotifierProviderImpl<Game, GameState> {
  /// See also [Game].
  GameProvider(
    Level level,
  ) : this._internal(
          () => Game()..level = level,
          from: gameProvider,
          name: r'gameProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product') ? null : _$gameHash,
          dependencies: GameFamily._dependencies,
          allTransitiveDependencies: GameFamily._allTransitiveDependencies,
          level: level,
        );

  GameProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.level,
  }) : super.internal();

  final Level level;

  @override
  GameState runNotifierBuild(
    covariant Game notifier,
  ) {
    return notifier.build(
      level,
    );
  }

  @override
  Override overrideWith(Game Function() create) {
    return ProviderOverride(
      origin: this,
      override: GameProvider._internal(
        () => create()..level = level,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        level: level,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<Game, GameState> createElement() {
    return _GameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GameProvider && other.level == level;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, level.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GameRef on AutoDisposeNotifierProviderRef<GameState> {
  /// The parameter `level` of this provider.
  Level get level;
}

class _GameProviderElement
    extends AutoDisposeNotifierProviderElement<Game, GameState> with GameRef {
  _GameProviderElement(super.provider);

  @override
  Level get level => (origin as GameProvider).level;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
