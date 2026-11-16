import 'package:flutter/material.dart';
import '../core/backend/backend_api.dart';
import '../core/backend/backend_config.dart';
import '../core/backend/backend_models.dart';

/// Development-only integration screen, launched using main_api_smoke.dart.
/// Existing gameplay and UI remain intact until their staged migration.
class BackendCheckScreen extends StatefulWidget {
  const BackendCheckScreen({super.key});

  @override
  State<BackendCheckScreen> createState() => _BackendCheckScreenState();
}

class _BackendCheckScreenState extends State<BackendCheckScreen> {
  final BackendApi _api = BackendApi();
  bool _loading = true;
  bool _loadingLevels = false;
  String? _error;
  String? _playerId;
  GameWallet? _wallet;
  List<GameCategory> _categories = const [];
  List<LevelSummary> _levels = const [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final player = await _api.getPlayerId();
      final wallet = await _api.wallet();
      final categories = await _api.categories();
      final slug = _selectedCategory ??
          (categories.isNotEmpty ? categories.first.slug : null);
      final levels = slug == null
          ? <LevelSummary>[]
          : await _api.levels(category: slug);
      if (!mounted) return;
      setState(() {
        _playerId = player;
        _wallet = wallet;
        _categories = categories;
        _selectedCategory = slug;
        _levels = levels;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _chooseCategory(String slug) async {
    if (_loadingLevels || _selectedCategory == slug) return;
    setState(() {
      _loadingLevels = true;
      _error = null;
    });
    try {
      final levels = await _api.levels(category: slug);
      if (!mounted) return;
      setState(() {
        _selectedCategory = slug;
        _levels = levels;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingLevels = false);
    }
  }

  Future<void> _showAttempt(LevelSummary level) async {
    try {
      final attempt = await _api.startOrResumeLevel(level.id);
      // Check the persisted state through a separate backend GET.
      final restored = await _api.attempt(attempt.id);
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.75,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Уровень ${level.number} · ${restored.status}',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('Реальная попытка из PostgreSQL. '
                    'Здесь показано только поле; игровой ввод подключим в следующем патче.'),
                const SizedBox(height: 12),
                Text('Попыток до потери жизни: ${restored.triesRemaining}/${restored.triesPerLife}'),
                Text('Клеток: ${restored.layout.length}'),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 5,
                  runSpacing: 6,
                  children: restored.layout.map((cell) {
                    if (!cell.isLetter) {
                      return SizedBox(
                        width: 24,
                        height: 54,
                        child: Center(child: Text(cell.separator ?? '')),
                      );
                    }
                    return Container(
                      width: 36,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFB9CCE9)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cell.given ?? cell.letter ?? '',
                              style: const TextStyle(
                                  fontSize: 19, fontWeight: FontWeight.w700,
                                  color: Color(0xFF1C3763))),
                          Text('${cell.number}',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF66768D))),
                        ],
                      ),
                    );
                  }).toList(growable: false),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('BlogerGrame · API-тест'),
        backgroundColor: const Color(0xFF5B8DEF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded), tooltip: 'Повторить'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section(
                  title: _error == null ? 'Локальное подключение' : 'Ошибка',
                  child: Text(_error ?? BackendConfig.baseUrl,
                      style: TextStyle(color: _error == null
                          ? const Color(0xFF1D3557) : Colors.red.shade800)),
                ),
                if (_error == null) ...[
                  _section(
                    title: 'Гость и кошелёк из PostgreSQL',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Игрок: ${_playerId ?? '-'}',
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Text('🪙 ${_wallet?.coins ?? 0}    '
                            '❤️ ${_wallet?.lives ?? 0}/${_wallet?.maxLives ?? 5}    '
                            '💡 ${_wallet?.hints ?? 0}'),
                        Text('Восстановление: ${_wallet?.lifeRegenMinutes ?? 0} мин.'),
                      ],
                    ),
                  ),
                  _section(
                    title: 'Категории',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) => ChoiceChip(
                        selected: category.slug == _selectedCategory,
                        onSelected: (_) => _chooseCategory(category.slug),
                        label: Text('${category.title} (${category.levels})'),
                      )).toList(growable: false),
                    ),
                  ),
                  _section(
                    title: 'Уровни · ${_levels.length}',
                    child: _loadingLevels
                        ? const Center(child: CircularProgressIndicator())
                        : _levels.isEmpty
                            ? const Text('Уровней нет. Проверьте импорт 42 цитат '
                                'и LOCAL_DRAFT_PREVIEW=1 в .env backend.')
                            : Column(
                                children: _levels.map((level) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(child: Text('${level.number}')),
                                  title: Text('Уровень ${level.number} · ${level.difficulty}'),
                                  subtitle: Text('${level.letters} букв${level.preview ? ' · черновик' : ''}'),
                                  trailing: Icon(level.completed
                                      ? Icons.check_circle : Icons.chevron_right),
                                  onTap: level.completed ? null : () => _showAttempt(level),
                                )).toList(growable: false),
                              ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(
          color: Color(0x0D101F40), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1D3557))),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}
