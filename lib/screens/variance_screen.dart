// Screen 10–13 · Variance Review (+ filter sheet, reject sheet).
import 'package:flutter/material.dart';
import '../models/data.dart';
import '../theme/tokens.dart';
import '../widgets/primitives.dart';
import '../widgets/overlays.dart';
import '../widgets/chip.dart';
import 'adjustment_screen.dart';
import 'recount_screen.dart';

class _VItem {
  final CountItem item;
  final int diff;
  final num diffValue;
  final String counter;
  _VItem(this.item, this.diff, this.diffValue, this.counter);
}

class VarianceScreen extends StatefulWidget {
  final CountSummary baseCount;
  const VarianceScreen({super.key, required this.baseCount});

  @override
  State<VarianceScreen> createState() => _VarianceScreenState();
}

class _VarianceScreenState extends State<VarianceScreen> {
  String _tab = 'all';
  late final List<_VItem> _all;

  @override
  void initState() {
    super.initState();
    const counters = ['A. Mehta', 'R. Kaur', 'S. Verma', 'K. Rao'];
    final items = seedItems();
    _all = items.asMap().entries.map((e) {
      final it = e.value;
      final diff = it.physical - it.system;
      final diffValue = diff * (60 + (e.key * 7) % 25);
      return _VItem(it, diff, diffValue, counters[e.key % 4]);
    }).toList();
  }

  List<_VItem> get _filtered => _all.where((v) {
        switch (_tab) {
          case 'excess':
            return v.diff > 0;
          case 'shortage':
            return v.diff < 0;
          case 'expired':
            return v.item.expSoon;
          default:
            return true;
        }
      }).toList();

  @override
  Widget build(BuildContext context) {
    final excess = _all.where((v) => v.diff > 0).length;
    final shortage = _all.where((v) => v.diff < 0).length;
    final expired = _all.where((v) => v.item.expSoon).length;
    final pos = _all.where((v) => v.diff > 0).fold<num>(0, (a, v) => a + v.diffValue);
    final neg = _all.where((v) => v.diff < 0).fold<num>(0, (a, v) => a + v.diffValue);
    final total = pos + neg;
    final mismatch = _all.where((v) => v.diff != 0).length;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              onBack: () => Navigator.pop(context),
              title: Text.rich(TextSpan(children: [
                const TextSpan(text: 'Variance Review '),
                TextSpan(text: widget.baseCount.id, style: AppText.mono(size: 11, weight: FontWeight.w600, color: AppColors.ink3)),
              ])),
              subtitle: widget.baseCount.storeName,
              status: 'submitted',
            ),
            AppTabs(
              value: _tab,
              onChanged: (v) => setState(() => _tab = v),
              tabs: [
                TabItem('all', 'All', count: _all.length),
                TabItem('excess', 'Excess', count: excess),
                TabItem('shortage', 'Shortage', count: shortage),
                TabItem('expired', 'Expired', count: expired),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 96),
                children: [
                  KpiGrid(cols: 2, [
                    KpiData('Total Variance', fmtINR(total), tone: total < 0 ? KpiTone.neg : KpiTone.pos, tint: total < 0 ? KpiTint.red : KpiTint.green),
                    KpiData('Mismatch Items', '$mismatch', tint: KpiTint.orange),
                    KpiData('Positive', fmtINR(pos), tone: KpiTone.pos, tint: KpiTint.green),
                    KpiData('Negative', fmtINR(neg), tone: KpiTone.neg, tint: KpiTint.red),
                  ]),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('VARIANCE ITEMS · ${filtered.length}', style: AppText.sans(size: 11.5, weight: FontWeight.w600, color: AppColors.ink2, letterSpacing: 0.22)),
                        AppButton(label: 'Filter', variant: BtnVariant.ghost, small: true, icon: AppIcons.tune, onTap: _openFilter),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...filtered.map((v) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _VarianceCard(v))),
                ],
              ),
            ),
            StickyBar(children: [
              Expanded(flex: 10, child: AppButton(label: 'Reject', variant: BtnVariant.danger, icon: AppIcons.close, onTap: _openReject)),
              const SizedBox(width: 8),
              Expanded(flex: 12, child: AppButton(label: 'Recount', variant: BtnVariant.warn, icon: AppIcons.refresh, onTap: _recount)),
              const SizedBox(width: 8),
              Expanded(flex: 14, child: AppButton(label: 'Approve', variant: BtnVariant.success, icon: AppIcons.check, onTap: _approve)),
            ]),
          ],
        ),
      ),
    );
  }

  void _approve() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AdjustmentScreen(baseCount: widget.baseCount)));
  }

  void _recount() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecountScreen(baseCount: widget.baseCount)));
  }

  void _openReject() {
    showAppSheet(
      context: context,
      title: 'Reject Inventory Count',
      builder: (ctx, setSheet) => _RejectBody(onConfirm: () {
        Navigator.pop(ctx);
        Navigator.of(context).popUntil((r) => r.isFirst);
      }),
    );
  }

  void _openFilter() {
    showAppSheet(
      context: context,
      title: 'Filter Variance',
      builder: (ctx, setSheet) {
        Widget group(String label, List<String> opts) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(label, style: AppText.sans(size: 11, weight: FontWeight.w600, color: AppColors.ink2, letterSpacing: 0.22))),
                Wrap(spacing: 6, runSpacing: 6, children: opts.map((o) => ChoiceChipX(label: o)).toList()),
              ],
            );
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              group('CATEGORY', const ['Pharma', 'FMCG', 'Cosmetics', 'OTC']),
              const SizedBox(height: 14),
              group('RACK', const ['A-Bay-12', 'B-Bay-04', 'C-Bay-09']),
              const SizedBox(height: 14),
              group('COUNTER / USER', const ['A. Mehta', 'R. Kaur', 'S. Verma', 'K. Rao']),
              const SizedBox(height: 14),
              group('BATCH', const ['B24-0871', 'B25-1142', 'B24-0993']),
              const SizedBox(height: 14),
              group('EXPIRY', const ['Expired', '< 30 days', '< 90 days', 'All']),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: AppButton(label: 'Reset', variant: BtnVariant.ghost, onTap: () {})),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: AppButton(label: 'Apply Filters', onTap: () => Navigator.pop(ctx))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VarianceCard extends StatelessWidget {
  final _VItem v;
  const _VarianceCard(this.v);

  @override
  Widget build(BuildContext context) {
    final it = v.item;
    final diff = v.diff;
    final highValue = v.diffValue.abs() > 1500;
    final (bg, border) = highValue
        ? (const Color(0xFFFFFAEE), AppColors.orangeBorder)
        : diff < 0
            ? (const Color(0xFFFFF6F8), AppColors.redBorder)
            : diff > 0
                ? (const Color(0xFFF4FBF6), AppColors.greenBorder)
                : (AppColors.card, AppColors.line);
    final diffColor = diff < 0 ? AppColors.redFg : AppColors.greenFg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.rLg, border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.name, style: AppText.sans(size: 13, weight: FontWeight.w600, height: 1.25)),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(it.code, style: AppText.mono(size: 11, color: AppColors.ink3)),
                        AppTag('Batch ${it.batch}'),
                        AppTag(it.exp, tone: it.expSoon ? TagTone.warn : TagTone.normal, icon: it.expSoon ? AppIcons.warning : null),
                        if (it.expSoon) const AppTag('Expired', tone: TagTone.danger, icon: AppIcons.warning),
                        if (highValue) const AppTag('High value', tone: TagTone.warn, icon: AppIcons.flag),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${diff > 0 ? '+' : ''}$diff', style: AppText.sans(size: 15, weight: FontWeight.w700, color: diffColor, tabular: true)),
                  Text(fmtINR(v.diffValue), style: AppText.sans(size: 11, weight: FontWeight.w600, color: diffColor, tabular: true)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _cell('System', fmtNum(it.system))),
              Expanded(child: _cell('Physical', fmtNum(it.physical))),
              Expanded(child: _cell('UoM', it.uom)),
              Expanded(child: _cell('Counter', v.counter, small: true)),
            ],
          ),
          if (it.reason.isNotEmpty || it.remarks.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Divider(height: 1, color: AppColors.line2),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (it.reason.isNotEmpty) AppTag(it.reason),
                if (it.remarks.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Expanded(child: Text('"${it.remarks}"', style: AppText.sans(size: 11, color: AppColors.ink3))),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cell(String label, String value, {bool small = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.sans(size: 10.5, color: AppColors.ink3)),
        Text(value, style: AppText.sans(size: small ? 10.5 : 11.5, weight: FontWeight.w600, tabular: true)),
      ],
    );
  }
}

class _RejectBody extends StatefulWidget {
  final VoidCallback onConfirm;
  const _RejectBody({required this.onConfirm});

  @override
  State<_RejectBody> createState() => _RejectBodyState();
}

class _RejectBodyState extends State<_RejectBody> {
  String _reason = '';
  final _remarksCtrl = TextEditingController();

  static const _reasons = [
    'Insufficient remarks on variance',
    'Suspected counting errors',
    'Missing physical counts',
    'Variance exceeds tolerance',
    'Process / SOP not followed',
    'Other',
  ];

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _reason.isNotEmpty && _remarksCtrl.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.redBg, borderRadius: AppRadius.rLg, border: Border.all(color: AppColors.redBorder)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(AppIcons.warning, size: 16, color: AppColors.redFg),
                const SizedBox(width: 10),
                Expanded(child: Text('Rejecting will return the count to the counter team. They will need to recount or fix variances before resubmitting.', style: AppText.sans(size: 11.5, color: const Color(0xFF7A1023), height: 1.4))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Field(
            label: 'Rejection Reason',
            required: true,
            child: _select(_reason, _reasons, (v) => setState(() => _reason = v)),
          ),
          const SizedBox(height: 12),
          Field(
            label: 'Remarks',
            required: true,
            child: TextField(
              controller: _remarksCtrl,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              style: AppText.sans(size: 13),
              decoration: appInputDecoration(hintText: 'Detail what needs to be corrected...'),
            ),
          ),
          const SizedBox(height: 12),
          Field(
            label: 'Attachment (optional)',
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: ShapeDecoration(color: AppColors.card, shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd, side: const BorderSide(color: AppColors.line))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(AppIcons.attach, size: 14, color: AppColors.ink),
                    const SizedBox(width: 6),
                    Text('Upload photo / file', style: AppText.sans(size: 13, weight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: AppButton(label: 'Cancel', variant: BtnVariant.ghost, onTap: () => Navigator.pop(context))),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: 'Confirm Reject',
                  icon: AppIcons.close,
                  enabled: canConfirm,
                  variant: BtnVariant.primary,
                  customChild: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(AppIcons.close, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text('Confirm Reject', style: AppText.sans(size: 13, weight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                  onTap: canConfirm ? widget.onConfirm : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _select(String value, List<String> options, ValueChanged<String> onChanged) {
    return InkWell(
      borderRadius: AppRadius.rMd,
      onTap: () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => Container(
            decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((o) => ListTile(title: Text(o, style: AppText.sans(size: 13)), onTap: () => Navigator.pop(ctx, o))).toList(),
            ),
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.rMd, border: Border.all(color: AppColors.line)),
        child: Row(
          children: [
            Expanded(child: Text(value.isEmpty ? 'Select reason...' : value, style: AppText.sans(size: 13, color: value.isEmpty ? AppColors.ink4 : AppColors.ink))),
            const Icon(AppIcons.caretDown, size: 16, color: AppColors.ink3),
          ],
        ),
      ),
    );
  }
}
