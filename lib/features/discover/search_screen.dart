import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
import '../../core/api/api_client.dart';
import '../../core/ui/api_errors.dart';
import '../../core/util/json.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/common.dart';
import '../../models/member.dart';
import 'filters.dart';
import 'member_tile.dart';

/// Search (`POST /search`, full filters + saved searches) and the A–Z
/// directory (`GET /directory`). Same results grid for both.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.directory = false});
  final bool directory;
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late bool _directory = widget.directory;
  final _q = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  SearchFilters _filters = const SearchFilters();
  String? _letter;
  final List<MemberCard> _items = [];
  int? _next = 0;
  bool _loading = false;
  Object? _error;
  List<Json> _saved = [];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 500) _load();
    });
    _loadSaved();
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    _scroll.dispose();
    super.dispose();
  }

  ApiClient get _api => ref.read(apiClientProvider);

  Future<void> _loadSaved() async {
    try {
      final j = await _api.getJson('/searches');
      if (mounted) setState(() => _saved = asMapList(j['items']));
    } catch (_) {}
  }

  Future<void> _reload() async {
    setState(() {
      _items.clear();
      _next = 0;
      _error = null;
    });
    await _load();
  }

  Future<void> _load() async {
    if (_loading || _next == null) return;
    final q = _q.text.trim();
    if (_directory && q.length < 2 && _letter == null) {
      setState(() => _next = null);
      return;
    }
    setState(() => _loading = true);
    try {
      final Json j;
      if (_directory) {
        j = await _api.getJson('/directory', query: {
          if (q.length >= 2) 'q': q,
          'letter': q.length >= 2 ? null : _letter,
          'limit': 30,
          'offset': _next,
        });
      } else {
        j = await _api.postJson('/search', data: {
          'filters': {..._filters.toSearchFilters(), if (q.length >= 2) 'q': q},
          'limit': 24,
          'offset': _next,
        });
      }
      setState(() {
        _items.addAll(asMapList(j['items']).map(MemberCard.new));
        _next = asInt(j['next_offset']);
      });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onQuery(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _reload);
  }

  Future<void> _openFilters() async {
    final f = await showFiltersSheet(context, _filters, advanced: true);
    if (f != null) {
      setState(() => _filters = f);
      _reload();
    }
  }

  Future<void> _save() async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface2,
        title: const Text('Save this search', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: name,
          autofocus: true,
          maxLength: 60,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Name it'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      await _api.post('/searches', data: {'name': name.text.trim(), 'filters': _filters.toSearchFilters()});
      if (mounted) showToast(context, 'Search saved');
      _loadSaved();
    } catch (e) {
      if (mounted) handleApiError(context, e);
    }
  }

  Future<void> _deleteSaved(Json s) async {
    try {
      await _api.delete('/searches/${s['id']}');
      _loadSaved();
    } catch (e) {
      if (mounted) handleApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        title: Text(_directory ? 'Member directory' : 'Search'),
        actions: [
          if (!_directory) ...[
            IconButton(tooltip: 'Save search', onPressed: _save, icon: const Icon(Icons.bookmark_add_outlined)),
            IconButton(
              tooltip: 'Filters',
              onPressed: _openFilters,
              icon: Badge(isLabelVisible: _filters.activeCount > 0, label: Text('${_filters.activeCount}'), child: const Icon(Icons.tune_rounded)),
            ),
          ],
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SegmentedButton<bool>(
            style: SegmentedButton.styleFrom(
              foregroundColor: Colors.white70,
              selectedForegroundColor: Colors.black,
              selectedBackgroundColor: AppColors.gold,
            ),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('Search')),
              ButtonSegment(value: true, label: Text('A–Z directory')),
            ],
            selected: {_directory},
            onSelectionChanged: (s) {
              setState(() => _directory = s.first);
              _reload();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _q,
            onChanged: _onQuery,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded, color: Colors.white38),
              hintText: 'Name or username',
              hintStyle: TextStyle(color: Colors.white30),
            ),
          ),
        ),
        if (_directory)
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final l in 'abcdefghijklmnopqrstuvwxyz'.split(''))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Pill(l.toUpperCase(), selected: _letter == l, onTap: () {
                      setState(() => _letter = l);
                      _q.clear();
                      _reload();
                    }),
                  ),
              ],
            ),
          )
        else if (_saved.isNotEmpty)
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final s in _saved)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InputChip(
                      label: Text(asString(s['name']) ?? 'Saved'),
                      avatar: const Icon(Icons.bookmark_rounded, size: 16, color: AppColors.gold),
                      backgroundColor: AppColors.darkSurface2,
                      labelStyle: const TextStyle(color: Colors.white),
                      onPressed: () {
                        setState(() => _filters = SearchFilters.fromJson(asMap(s['filters'])));
                        _reload();
                      },
                      onDeleted: () => _deleteSaved(s),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Expanded(child: _results()),
      ]),
    );
  }

  Widget _results() {
    if (_error != null && _items.isEmpty) {
      final upgrade = _error is ApiException && (_error as ApiException).code == 'upgrade_required';
      return upgrade
          ? EmptyState(
              icon: Icons.workspace_premium_rounded,
              title: 'Advanced filters need Platinum',
              body: 'Remove them, or upgrade to search by religion, languages, height and more.',
              action: 'Remove advanced filters',
              onAction: () {
                setState(() => _filters = SearchFilters(
                    minAge: _filters.minAge, maxAge: _filters.maxAge, radiusKm: _filters.radiusKm, online: _filters.online,
                    verified: _filters.verified, gender: _filters.gender, country: _filters.country, city: _filters.city,
                    tribe: _filters.tribe, interests: _filters.interests));
                _reload();
              },
            )
          : ErrorView(error: _error!, onRetry: _reload);
    }
    if (_items.isEmpty) {
      if (_loading) return const LoadingView();
      return EmptyState(
        icon: _directory ? Icons.sort_by_alpha_rounded : Icons.search_off_rounded,
        title: _directory && _letter == null && _q.text.trim().length < 2 ? 'Pick a letter or type a name' : 'No members found',
      );
    }
    return GridView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .7),
      itemCount: _items.length + (_next != null ? 1 : 0),
      itemBuilder: (_, i) => i >= _items.length ? const LoadingView() : MemberGridTile(member: _items[i]),
    );
  }
}
