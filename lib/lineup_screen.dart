// lib/lineup_screen.dart
//
// تشكيلة المباراة: المدرب/الأدمن يحدد عدد اللاعبين الأساسيين (الافتراضي 11)،
// يختار الأساسيين والبدلاء، ويبدّل أي لاعب بلاعب تاني. اللاعب العادي بيشوفها بس.
// السيرفر: database/08_lineups.sql  |  الخدمة: services/lineup_service.dart

import 'package:flutter/material.dart' hide Text;

import 'academy_dashboard_screen.dart' show AppColors;
import 'l10n/app_text.dart';
import 'models/match.dart';
import 'models/player.dart';
import 'services/lineup_service.dart';
import 'services/player_service.dart';

class LineupScreen extends StatefulWidget {
  final Match match;

  /// true = أدمن/مدرب (يقدر يعدّل)، false = عرض فقط
  final bool canEdit;

  const LineupScreen({super.key, required this.match, required this.canEdit});

  @override
  State<LineupScreen> createState() => _LineupScreenState();
}

class _LineupScreenState extends State<LineupScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  bool _showAll = false; // عرض كل لاعبي الأكاديمية (مش فريق المباراة بس)

  List<Player> _players = [];
  final List<String> _starters = [];
  final List<String> _subs = [];
  int _size = Lineup.defaultSize;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      PlayerService.getAllPlayers(),
      LineupService.get(widget.match.id),
    ]);
    final players = results[0] as List<Player>;
    final lineup = results[1] as Lineup;
    if (!mounted) return;
    setState(() {
      _players = players;
      _size = lineup.squadSize;
      _starters
        ..clear()
        ..addAll(lineup.starters);
      _subs
        ..clear()
        ..addAll(lineup.subs);
      _loading = false;
    });
  }

  // ------------------------------------------------------------------
  // helpers
  // ------------------------------------------------------------------
  Player? _p(String id) {
    for (final p in _players) {
      if (p.id == id) return p;
    }
    return null;
  }

  int get _teamCount =>
      _players.where((p) => p.teamId == widget.match.teamId).length;

  /// اللاعبين اللي لسه مش في التشكيلة
  List<Player> get _pool {
    final inSquad = {..._starters, ..._subs};
    final list = _players.where((p) {
      if (inSquad.contains(p.id)) return false;
      return _showAll || p.teamId == widget.match.teamId;
    }).toList();
    list.sort((a, b) => (double.tryParse(b.rating) ?? 0)
        .compareTo(double.tryParse(a.rating) ?? 0));
    return list;
  }

  void _snack(String msg, {Color color = AppColors.orange}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _touch(VoidCallback fn) => setState(() {
        fn();
        _dirty = true;
      });

  // ------------------------------------------------------------------
  // actions
  // ------------------------------------------------------------------
  void _addStarter(String id) {
    if (_starters.contains(id)) return;
    if (_starters.length >= _size) {
      _snack('الأساسيين اكتملوا ($_size). بدّل لاعب أو زوّد العدد من فوق');
      return;
    }
    _touch(() {
      _subs.remove(id);
      _starters.add(id);
    });
  }

  void _addSub(String id) {
    if (_subs.contains(id)) return;
    _touch(() {
      _starters.remove(id);
      _subs.add(id);
    });
  }

  void _remove(String id) => _touch(() {
        _starters.remove(id);
        _subs.remove(id);
      });

  void _changeSize(int delta) {
    final next = (_size + delta).clamp(1, 30);
    if (next < _starters.length) {
      _snack('عندك ${_starters.length} أساسي. انقل لاعب للبدلاء الأول');
      return;
    }
    if (next == _size) return;
    _touch(() => _size = next);
  }

  /// ترشيح تلقائي: يكمل الأساسيين من أعلى لاعبين تقييماً في الفريق
  void _autoFill() {
    final candidates = _players
        .where((p) =>
            p.teamId == widget.match.teamId &&
            !_starters.contains(p.id) &&
            !_subs.contains(p.id))
        .toList()
      ..sort((a, b) => (double.tryParse(b.rating) ?? 0)
          .compareTo(double.tryParse(a.rating) ?? 0));
    if (candidates.isEmpty || _starters.length >= _size) {
      _snack('مفيش لاعبين متاحين للترشيح أو الأساسيين مكتملين');
      return;
    }
    _touch(() {
      for (final p in candidates) {
        if (_starters.length >= _size) break;
        _starters.add(p.id);
      }
    });
  }

  /// تبديل لاعب [a] (أساسي أو بديل) بلاعب [b] (من القائمة التانية أو من خارج التشكيلة)
  void _swap(String a, String b) {
    final ai = _starters.indexOf(a);
    final as_ = _subs.indexOf(a);
    final bi = _starters.indexOf(b);
    final bs = _subs.indexOf(b);
    _touch(() {
      if (ai >= 0 && bs >= 0) {
        _starters[ai] = b;
        _subs[bs] = a;
      } else if (as_ >= 0 && bi >= 0) {
        _subs[as_] = b;
        _starters[bi] = a;
      } else if (ai >= 0) {
        _starters[ai] = b; // b جاي من خارج التشكيلة، وa بيخرج
      } else if (as_ >= 0) {
        _subs[as_] = b;
      }
    });
  }

  Future<void> _pickReplacement(String id) async {
    final isStarter = _starters.contains(id);
    final other = isStarter ? _subs : _starters;
    final candidates = <Player>[
      for (final oid in other)
        if (_p(oid) != null) _p(oid)!,
      ..._pool,
    ];
    if (candidates.isEmpty) {
      _snack('مفيش لاعب متاح للتبديل');
      return;
    }
    final me = _p(id);
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1B2D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          builder: (_, scroll) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  'بدّل ${me?.name ?? ''} بـ...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: candidates.length,
                  itemBuilder: (_, i) {
                    final c = candidates[i];
                    final inSquad = other.contains(c.id);
                    return ListTile(
                      onTap: () => Navigator.pop(ctx, c.id),
                      title: Text(c.name,
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        '${c.position} • ${c.teamName}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                      trailing: Text(
                        inSquad
                            ? (isStarter ? 'بديل' : 'أساسي')
                            : 'برّه التشكيلة',
                        style: TextStyle(
                          color: inSquad ? AppColors.blue : AppColors.green,
                          fontSize: 11,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) _swap(id, chosen);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await LineupService.save(
        widget.match.id,
        squadSize: _size,
        starters: List<String>.from(_starters),
        subs: List<String>.from(_subs),
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _dirty = false;
      });
      _snack('تم حفظ التشكيلة ✅', color: AppColors.green);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('تعذّر حفظ التشكيلة: $e', color: AppColors.red);
    }
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final canEdit = widget.canEdit;

    return AppDirectionality(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'تشكيلة ${m.teamName} × ${m.opponentName}',
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            if (canEdit)
              TextButton.icon(
                onPressed: (_saving || _loading) ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.green),
                      )
                    : Icon(
                        Icons.save_rounded,
                        color: _dirty ? AppColors.green : Colors.white38,
                        size: 20,
                      ),
                label: Text(
                  _dirty ? 'حفظ *' : 'حفظ',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: _dirty ? AppColors.green : Colors.white38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.green),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                children: [
                  if (canEdit) _controls(),
                  if (!canEdit && _starters.isEmpty && _subs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(
                          'المدرب لسه ما حدّدش التشكيلة',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
                    ),
                  if (_starters.isNotEmpty || canEdit)
                    _sectionHeader(
                      'الأساسيون',
                      '${_starters.length} / $_size',
                      AppColors.green,
                    ),
                  for (final id in _starters) _squadTile(id, starter: true),
                  if (canEdit && _starters.isEmpty)
                    _hint('لسه مفيش أساسيين. اختار من القائمة اللي تحت'),
                  if (_subs.isNotEmpty || canEdit)
                    _sectionHeader(
                      'البدلاء',
                      '${_subs.length}',
                      AppColors.blue,
                    ),
                  for (final id in _subs) _squadTile(id, starter: false),
                  if (canEdit && _subs.isEmpty)
                    _hint('مفيش بدلاء لسه (اختياري)'),
                  if (canEdit) ...[
                    _sectionHeader(
                      _showAll ? 'باقي لاعبي الأكاديمية' : 'باقي لاعبي الفريق',
                      '${_pool.length}',
                      AppColors.gray,
                    ),
                    for (final p in _pool) _poolTile(p),
                    if (_pool.isEmpty) _hint('كل اللاعبين المتاحين في التشكيلة'),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _controls() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'عدد اللاعبين الأساسيين',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _changeSize(-1),
                icon: const Icon(Icons.remove_circle_outline_rounded),
                color: Colors.white70,
              ),
              Text(
                '$_size',
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                onPressed: () => _changeSize(1),
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: Colors.white70,
              ),
            ],
          ),
          if (_teamCount < _size)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 6),
              child: Text(
                'الفريق فيه $_teamCount لاعب بس. تقدر تضيف لاعبين من فرق تانية (فعّل «لاعبي الأكاديمية») أو تقلّل العدد',
                style: const TextStyle(
                    color: AppColors.orange, fontSize: 11, height: 1.6),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _autoFill,
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                  label: const Text('ترشيح تلقائي'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  icon: Icon(
                    _showAll
                        ? Icons.groups_rounded
                        : Icons.groups_2_outlined,
                    size: 18,
                  ),
                  label: const Text('لاعبي الأكاديمية'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        _showAll ? AppColors.green : Colors.white,
                    side: BorderSide(
                      color: _showAll ? AppColors.green : Colors.white24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );

  Widget _shell({required Widget child, Color? border}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: border ?? Colors.white.withOpacity(0.08),
        ),
      ),
      child: child,
    );
  }

  Widget _info(Player? p, String fallbackId, {Color? badge, int? number}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: (badge ?? AppColors.gray).withOpacity(0.25),
          child: Text(
            number == null ? '•' : '$number',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p?.name ?? fallbackId,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (p != null)
                Text(
                  '${p.position} • ${p.teamName} • ★ ${p.rating}',
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 11),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _squadTile(String id, {required bool starter}) {
    final p = _p(id);
    final list = starter ? _starters : _subs;
    final color = starter ? AppColors.green : AppColors.blue;
    return _shell(
      border: color.withOpacity(0.35),
      child: Row(
        children: [
          Expanded(
            child: _info(p, id, badge: color, number: list.indexOf(id) + 1),
          ),
          if (widget.canEdit)
            PopupMenuButton<String>(
              color: const Color(0xFF1B2540),
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
              onSelected: (v) {
                switch (v) {
                  case 'swap':
                    _pickReplacement(id);
                    break;
                  case 'sub':
                    _addSub(id);
                    break;
                  case 'start':
                    _addStarter(id);
                    break;
                  case 'out':
                    _remove(id);
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'swap',
                  child: Text('تبديل بلاعب آخر',
                      style: TextStyle(color: Colors.white)),
                ),
                PopupMenuItem(
                  value: starter ? 'sub' : 'start',
                  child: Text(
                    starter ? 'نقل للبدلاء' : 'نقل للأساسيين',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const PopupMenuItem(
                  value: 'out',
                  child: Text('إخراج من التشكيلة',
                      style: TextStyle(color: AppColors.red)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _poolTile(Player p) {
    return _shell(
      child: Row(
        children: [
          Expanded(child: _info(p, p.id)),
          TextButton(
            onPressed: () => _addStarter(p.id),
            child: const Text('أساسي',
                style: TextStyle(color: AppColors.green, fontSize: 12)),
          ),
          TextButton(
            onPressed: () => _addSub(p.id),
            child: const Text('بديل',
                style: TextStyle(color: AppColors.blue, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
