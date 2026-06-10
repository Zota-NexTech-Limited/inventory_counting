// Screens 18–21 · Audit Log (Activity / Variance / Approval / Adjustment tabs).
import 'package:flutter/material.dart';
import '../models/data.dart';
import '../theme/tokens.dart';
import '../widgets/primitives.dart';

class _Event {
  final String title;
  final String meta;
  final bool warn;
  final String? remark;
  const _Event(this.title, this.meta, {this.warn = false, this.remark});
}

class ViewLogScreen extends StatefulWidget {
  final CountSummary baseCount;
  const ViewLogScreen({super.key, required this.baseCount});

  @override
  State<ViewLogScreen> createState() => _ViewLogScreenState();
}

class _ViewLogScreenState extends State<ViewLogScreen> {
  String _tab = 'activity';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              onBack: () => Navigator.pop(context),
              title: Text.rich(TextSpan(children: [
                const TextSpan(text: 'Audit Log '),
                TextSpan(text: widget.baseCount.id, style: AppText.mono(size: 11, weight: FontWeight.w600, color: AppColors.ink3)),
              ])),
              subtitle: 'Mumbai Central WH',
              status: 'posted',
            ),
            AppTabs(
              value: _tab,
              onChanged: (v) => setState(() => _tab = v),
              tabs: const [
                TabItem('activity', 'Activity'),
                TabItem('variance', 'Variance'),
                TabItem('approval', 'Approval'),
                TabItem('adjustment', 'Adjustment'),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 96),
                children: [
                  KpiGrid(cols: 2, [
                    KpiData('Total Variance', fmtINR(-12450), tone: KpiTone.neg, tint: KpiTint.red),
                    KpiData('Items Adjusted', '8', tint: KpiTint.blue),
                    KpiData('Positive Δ', '+74', tone: KpiTone.pos, tint: KpiTint.green),
                    KpiData('Negative Δ', '−112', tone: KpiTone.neg, tint: KpiTint.red),
                  ]),
                  const SizedBox(height: 8),
                  ..._tabBody(),
                ],
              ),
            ),
            StickyBar(children: [
              Expanded(child: AppButton(label: 'Excel', variant: BtnVariant.ghost, icon: AppIcons.download, onTap: () {})),
              const SizedBox(width: 8),
              Expanded(child: AppButton(label: 'PDF', variant: BtnVariant.ghost, icon: AppIcons.download, onTap: () {})),
              const SizedBox(width: 8),
              Expanded(child: AppButton(label: 'Print', icon: AppIcons.print, onTap: () {})),
            ]),
          ],
        ),
      ),
    );
  }

  List<Widget> _tabBody() {
    switch (_tab) {
      case 'variance':
        return _variance();
      case 'approval':
        return _approval();
      case 'adjustment':
        return _adjustment();
      default:
        return _activity();
    }
  }

  List<Widget> _activity() {
    const events = [
      _Event('Posted stock adjustment ADJ-2026-04812', 'P. Shah · May 8 · 14:32', remark: '8 items adjusted, ₹12,450 variance written off'),
      _Event('Approved variance review', 'A. Mehta · May 8 · 14:18', remark: 'All shortages have valid reasons attached'),
      _Event('Reviewed 12 variance items', 'A. Mehta · May 8 · 13:55'),
      _Event('Submitted count for review', 'R. Kaur · May 8 · 13:40'),
      _Event('Counted Vitamin D3 60K IU (B25-1188)', 'R. Kaur · May 8 · 13:12', warn: true, remark: 'Shortage of 25 units — flagged as theft'),
      _Event('Counted 24 items in A-Bay-12', 'S. Verma · May 8 · 12:48'),
      _Event('Started inventory count', 'A. Mehta · May 8 · 12:30', remark: 'Stock movements frozen across scope'),
    ];
    return [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardLabel('User Activity'),
            _Timeline(events),
          ],
        ),
      ),
    ];
  }

  List<Widget> _variance() {
    final items = seedItems().take(5).toList();
    return items.map((it) {
      final diff = it.physical - it.system;
      final (bg, border) = diff < 0 ? (const Color(0xFFFFF6F8), AppColors.redBorder) : diff > 0 ? (const Color(0xFFF4FBF6), AppColors.greenBorder) : (AppColors.card, AppColors.line);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: bg, borderRadius: AppRadius.rLg, border: Border.all(color: border)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.name, style: AppText.sans(size: 13, weight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Row(children: [Text(it.code, style: AppText.mono(size: 11, color: AppColors.ink3)), const SizedBox(width: 6), AppTag(it.batch)]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${diff > 0 ? '+' : ''}$diff', style: AppText.sans(size: 14, weight: FontWeight.w700, color: diff < 0 ? AppColors.redFg : AppColors.greenFg, tabular: true)),
                  const SizedBox(height: 2),
                  AppTag(it.reason.isEmpty ? 'Adjusted' : it.reason, tone: diff < 0 ? TagTone.danger : TagTone.ok),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _approval() {
    const events = [
      _Event('Submitted by R. Kaur', 'May 8 · 13:40'),
      _Event('Reviewed by A. Mehta', 'May 8 · 13:55', remark: 'All variance reasons validated'),
      _Event('Approved by A. Mehta · Supervisor', 'May 8 · 14:18'),
      _Event('Posted by P. Shah · Inventory Lead', 'May 8 · 14:32'),
    ];
    return [
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const CardLabel('Approval Chain'), _Timeline(events)])),
      const SizedBox(height: 8),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            CardLabel('Recount History'),
            KvRow('Recounts triggered', '1'),
            KvRow('Original count', 'IC-2026-0181', mono: true),
            KvRow('Recount reason', 'Suspected counting errors', last: true),
          ],
        ),
      ),
    ];
  }

  List<Widget> _adjustment() {
    final items = seedItems().take(4).toList();
    return [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardLabel('Adjustment Entry', trailing: AppTag('ADJ-2026-04812', tone: TagTone.info)),
            const KvRow('Posted By', 'P. Shah'),
            const KvRow('Posting Date', 'May 8, 2026 · 14:32'),
            const KvRow('Increased Qty', '+74 units', valueColor: AppColors.greenFg),
            const KvRow('Reduced Qty', '−112 units', valueColor: AppColors.redFg),
            KvRow('Net Value', fmtINR(-12450), valueColor: AppColors.redFg),
            const KvRow('GL Account', '5240 · Inv. Adj.', last: true),
          ],
        ),
      ),
      const SizedBox(height: 8),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardLabel('Line Items'),
            ...items.asMap().entries.map((e) {
              final it = e.value;
              final diff = it.physical - it.system;
              final last = e.key == items.length - 1;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.line2))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.name, style: AppText.sans(size: 12, weight: FontWeight.w600)),
                          Text(it.code, style: AppText.mono(size: 10.5, color: AppColors.ink3)),
                        ],
                      ),
                    ),
                    AppTag('${diff > 0 ? '+' : ''}$diff', tone: diff < 0 ? TagTone.danger : TagTone.ok),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ];
  }
}

class _Timeline extends StatelessWidget {
  final List<_Event> events;
  const _Timeline(this.events);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: events.asMap().entries.map((e) {
        final ev = e.value;
        final last = e.key == events.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: ev.warn ? AppColors.orangeAccent : AppColors.primary, width: 2),
                      ),
                    ),
                    if (!last) Expanded(child: Container(width: 2, margin: const EdgeInsets.only(top: 2), color: AppColors.line)),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ev.title, style: AppText.sans(size: 12, weight: FontWeight.w600)),
                      const SizedBox(height: 1),
                      Text(ev.meta, style: AppText.sans(size: 10.5, color: AppColors.ink3)),
                      if (ev.remark != null) ...[
                        const SizedBox(height: 3),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(6)),
                          child: Text(ev.remark!, style: AppText.sans(size: 11, color: AppColors.ink2)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
