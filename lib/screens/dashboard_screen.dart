// Screen 01 · Dashboard
import 'package:flutter/material.dart';
import '../api/app_config.dart';
import '../models/data.dart';
import '../api/inventory_repository.dart';
import '../theme/tokens.dart';
import '../widgets/primitives.dart';
import '../widgets/overlays.dart';
import '../widgets/chip.dart';
import 'new_count_screen.dart';
import 'counting_screen.dart';
import 'variance_screen.dart';
import 'view_log_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchCtrl = TextEditingController();
  String _q = '';
  String _status = 'all';
  String _store = 'all';
  String _type = 'all';

  List<CountSummary> _counts = kCounts;
  bool _loading = false;
  bool _usingSample = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AppConfig.useLiveApi) return; // sample data only
    setState(() => _loading = true);
    try {
      final counts = await InventoryRepository.instance.listCounts();
      if (!mounted) return;
      setState(() {
        _counts = counts;
        _usingSample = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Route not deployed / network down → keep working on sample data.
      if (AppConfig.fallbackToSampleData) {
        setState(() {
          _counts = kCounts;
          _usingSample = true;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CountSummary> get _filtered => _counts.where((c) {
        if (_q.isNotEmpty &&
            !(c.id.toLowerCase().contains(_q.toLowerCase()) ||
                c.storeName.toLowerCase().contains(_q.toLowerCase()))) {
          return false;
        }
        if (_status != 'all' && c.status != _status) return false;
        if (_store != 'all' && c.store != _store) return false;
        if (_type != 'all' && c.type != _type) return false;
        return true;
      }).toList();

  void _open(CountSummary c) {
    Widget dest;
    switch (c.status) {
      case 'progress':
      case 'draft':
        dest = CountingScreen(baseCount: c);
      case 'submitted':
        dest = VarianceScreen(baseCount: c);
      default:
        dest = ViewLogScreen(baseCount: c);
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => dest));
  }

  String _actionLabel(String status) => switch (status) {
        'progress' || 'draft' => 'Continue Count',
        'submitted' => 'Review Variance',
        'rejected' => 'View Reason',
        _ => 'View Log',
      };

  @override
  Widget build(BuildContext context) {
    final open = _counts.where((c) => c.status == 'progress' || c.status == 'draft').length;
    final review = _counts.where((c) => c.status == 'submitted').length;
    final totalVar = _counts.fold<num>(0, (a, c) => a + c.variance);
    final countedToday = _counts.fold<int>(0, (a, c) => a + c.counted);

    final activeFilters = <Widget>[
      if (_status != 'all') ChoiceChipX(label: kStatusLabel[_status]!, active: true, onTap: () => setState(() => _status = 'all'), showClose: true),
      if (_store != 'all') ChoiceChipX(label: _store, active: true, onTap: () => setState(() => _store = 'all'), showClose: true),
      if (_type != 'all') ChoiceChipX(label: _type, active: true, onTap: () => setState(() => _type = 'all'), showClose: true),
    ];

    final list = _filtered;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              title: const Text('Inventory Counts'),
              subtitle: 'Mumbai Central WH · Stock Audit',
              actions: [
                IconBtn(icon: AppIcons.notifications),
                if (AppConfig.useLiveApi) IconBtn(icon: AppIcons.refresh, onTap: _load),
                const IconBtn(icon: AppIcons.person),
              ],
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2, backgroundColor: AppColors.line, color: AppColors.primary),
            if (_usingSample)
              Container(
                width: double.infinity,
                color: AppColors.orangeBg,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    const Icon(AppIcons.offline, size: 13, color: AppColors.orangeFg),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Showing sample data — live API unreachable', style: AppText.sans(size: 10.5, color: AppColors.orangeFg))),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 96),
                  children: [
                  SearchField(
                    controller: _searchCtrl,
                    placeholder: 'Search count #, store...',
                    onChanged: (v) => setState(() => _q = v),
                    onFilter: _openFilters,
                  ),
                  const SizedBox(height: 8),
                  KpiGrid(cols: 4, [
                    KpiData('Open', '$open', tint: KpiTint.blue),
                    KpiData('Review', '$review', tint: KpiTint.orange),
                    KpiData('Variance', fmtINR(totalVar), tone: totalVar < 0 ? KpiTone.neg : KpiTone.pos),
                    KpiData('Counted', fmtNum(countedToday)),
                  ]),
                  if (activeFilters.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: activeFilters),
                  ],
                  const SizedBox(height: 8),
                  if (list.isEmpty)
                    const EmptyState(icon: AppIcons.search, message: 'No counts match your filters')
                  else
                    ...list.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _CountCard(count: c, actionLabel: _actionLabel(c.status), onAction: () => _open(c)),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _NewCountFab(onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewCountScreen()));
      }),
    );
  }

  void _openFilters() {
    showAppSheet(
      context: context,
      title: 'Filters',
      builder: (ctx, setSheet) {
        Widget group(String label, List<String> opts, String current, ValueChanged<String> onPick) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(label, style: AppText.sans(size: 11, weight: FontWeight.w600, color: AppColors.ink2, letterSpacing: 0.22)),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: opts.map((s) {
                  final lbl = s == 'all' ? 'All' : (kStatusLabel[s] ?? s);
                  return ChoiceChipX(
                    label: lbl,
                    active: current == s,
                    onTap: () => setSheet(() => onPick(s)),
                  );
                }).toList(),
              ),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              group('STATUS', const ['all', 'draft', 'progress', 'submitted', 'approved', 'posted'], _status, (v) => _status = v),
              const SizedBox(height: 14),
              group('STORE / WAREHOUSE', const ['all', 'WH-Mumbai-01', 'WH-Pune-02', 'WH-Bangalore-03', 'WH-Delhi-04'], _store, (v) => _store = v),
              const SizedBox(height: 14),
              group('COUNT TYPE', const ['all', 'Full Count', 'Category-wise', 'Item-wise', 'Rack-wise', 'Batch-wise'], _type, (v) => _type = v),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: AppButton(label: 'Reset', variant: BtnVariant.ghost, onTap: () => setSheet(() { _status = 'all'; _store = 'all'; _type = 'all'; }))),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: AppButton(label: 'Apply', onTap: () => Navigator.of(ctx).pop())),
                ],
              ),
            ],
          ),
        );
      },
    ).then((_) => setState(() {}));
  }
}

class _CountCard extends StatelessWidget {
  final CountSummary count;
  final String actionLabel;
  final VoidCallback onAction;
  const _CountCard({required this.count, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final c = count;
    final inProgress = c.status == 'progress' || c.status == 'draft';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.id, style: AppText.mono(size: 11, color: AppColors.ink2)),
              const SizedBox(width: 6),
              StatusBadge(status: c.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(c.storeName, style: AppText.sans(size: 13, weight: FontWeight.w600)),
          const SizedBox(height: 1),
          Row(
            children: [
              const Icon(AppIcons.sku, size: 11, color: AppColors.ink3),
              const SizedBox(width: 4),
              Text(c.type, style: AppText.sans(size: 11, color: AppColors.ink3)),
              const SizedBox(width: 6),
              Text('·', style: AppText.sans(size: 11, color: AppColors.ink4)),
              const SizedBox(width: 6),
              const Icon(AppIcons.schedule, size: 11, color: AppColors.ink3),
              const SizedBox(width: 4),
              Text(c.updated, style: AppText.sans(size: 11, color: AppColors.ink3)),
            ],
          ),
          if (inProgress)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progress', style: AppText.sans(size: 10.5, color: AppColors.ink3)),
                      Text('${c.counted} / ${c.total} items', style: AppText.sans(size: 10.5, weight: FontWeight.w600, color: AppColors.ink2, tabular: true)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: c.total == 0 ? 0 : c.counted / c.total,
                      minHeight: 5,
                      backgroundColor: AppColors.line2,
                      valueColor: AlwaysStoppedAnimation(c.status == 'draft' ? AppColors.ink4 : AppColors.primary),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFD), borderRadius: AppRadius.rMd),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _varCell('Variance', fmtINR(c.variance), c.variance < 0 ? AppColors.redFg : c.variance > 0 ? AppColors.greenFg : AppColors.ink),
                    _varCell('Items Δ', '${c.varianceQty > 0 ? '+' : ''}${c.varianceQty}', c.varianceQty < 0 ? AppColors.redFg : c.varianceQty > 0 ? AppColors.greenFg : AppColors.ink, end: true),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(AppIcons.person, size: 11, color: AppColors.ink3),
              const SizedBox(width: 5),
              Expanded(child: Text(c.supervisor, style: AppText.sans(size: 10.5, color: AppColors.ink3))),
              AppButton(label: actionLabel, small: true, trailingIcon: AppIcons.chevronRight, onTap: onAction),
            ],
          ),
        ],
      ),
    );
  }

  Widget _varCell(String label, String value, Color color, {bool end = false}) {
    return Column(
      crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppText.sans(size: 10, color: AppColors.ink3, letterSpacing: 0.6)),
        Text(value, style: AppText.sans(size: 14, weight: FontWeight.w700, color: color, tabular: true)),
      ],
    );
  }
}

class _NewCountFab extends StatelessWidget {
  final VoidCallback onTap;
  const _NewCountFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [BoxShadow(color: Color(0x73277DFE), blurRadius: 18, offset: Offset(0, 6))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.add, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text('New Count', style: AppText.sans(size: 13, weight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
