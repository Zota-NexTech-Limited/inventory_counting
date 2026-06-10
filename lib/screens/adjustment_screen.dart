// Screen 15–17 · Stock Adjustment Posting (+ confirm modal) and Posted Success.
import 'package:flutter/material.dart';
import '../models/data.dart';
import '../theme/tokens.dart';
import '../widgets/primitives.dart';
import '../widgets/overlays.dart';
import 'view_log_screen.dart';

class AdjustmentScreen extends StatelessWidget {
  final CountSummary baseCount;
  const AdjustmentScreen({super.key, required this.baseCount});

  @override
  Widget build(BuildContext context) {
    final items = seedItems().asMap().entries.map((e) {
      final it = e.value;
      final diff = it.physical - it.system;
      final diffValue = diff * (60 + (e.key * 7) % 25);
      return (it, diff, diffValue);
    }).toList();

    final pos = items.where((e) => e.$2 > 0).length;
    final neg = items.where((e) => e.$2 < 0).length;
    final value = items.fold<num>(0, (a, e) => a + e.$3);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(onBack: () => Navigator.pop(context), title: const Text('Stock Adjustment Posting'), subtitle: baseCount.id, status: 'approved'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                children: [
                  KpiGrid(cols: 4, [
                    KpiData('Total Items', '${items.length}'),
                    KpiData('Positive Δ', '$pos', tint: KpiTint.green, tone: KpiTone.pos),
                    KpiData('Negative Δ', '$neg', tint: KpiTint.red, tone: KpiTone.neg),
                    KpiData('Net Value', fmtINR(value), tone: value < 0 ? KpiTone.neg : KpiTone.pos),
                  ]),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CardLabel('Adjustment Entries', trailing: AppTag('${items.length} items', tone: TagTone.info)),
                        ...items.asMap().entries.map((e) {
                          final (it, diff, diffValue) = e.value;
                          final last = e.key == items.length - 1;
                          final iconBg = diff < 0 ? const Color(0xFFFEF4F6) : diff > 0 ? const Color(0xFFF2FBF5) : const Color(0xFFF2F5FA);
                          final iconColor = diff < 0 ? AppColors.redFg : diff > 0 ? AppColors.greenFg : AppColors.ink3;
                          final iconData = diff < 0 ? AppIcons.caretDown : diff > 0 ? AppIcons.caretUp : AppIcons.check;
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.line2))),
                            child: Row(
                              children: [
                                Container(width: 30, height: 30, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)), child: Icon(iconData, size: 16, color: iconColor)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(it.name, style: AppText.sans(size: 12.5, weight: FontWeight.w600, height: 1.2)),
                                      Row(children: [
                                        Text(it.code, style: AppText.mono(size: 10.5, color: AppColors.ink3)),
                                        Text(' · ${it.batch}', style: AppText.sans(size: 10.5, color: AppColors.ink3)),
                                      ]),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    AppTag('${diff < 0 ? 'Reduce' : diff > 0 ? 'Increase' : 'No change'} ${diff.abs()}', tone: diff < 0 ? TagTone.danger : diff > 0 ? TagTone.ok : TagTone.normal),
                                    const SizedBox(height: 2),
                                    Text(fmtINR(diffValue), style: AppText.sans(size: 11, weight: FontWeight.w600, color: diff < 0 ? AppColors.redFg : AppColors.greenFg, tabular: true)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        CardLabel('Audit & References'),
                        KvRow('Adjustment Ref #', 'ADJ-2026-04812', mono: true),
                        KvRow('Approved By', 'A. Mehta · Supervisor'),
                        KvRow('Posted By', 'P. Shah · Inventory Lead'),
                        KvRow('Posting Date', 'May 8, 2026 · 14:32'),
                        KvRow('GL Account', '5240 · Inv. Adj.', last: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.orangeBg, borderRadius: AppRadius.rLg, border: Border.all(color: AppColors.orangeBorder)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(AppIcons.warning, size: 15, color: AppColors.orangeFg),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Posting creates permanent ledger entries. Reversal requires a counter-adjustment with manager approval.', style: AppText.sans(size: 11, color: const Color(0xFF7A4A09), height: 1.45))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            StickyBar(children: [
              Expanded(child: AppButton(label: 'Cancel', variant: BtnVariant.ghost, onTap: () => Navigator.pop(context))),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: AppButton(label: 'Post Adjustment', icon: AppIcons.send, onTap: () => _confirm(context))),
            ]),
          ],
        ),
      ),
    );
  }

  void _confirm(BuildContext context) {
    showAppModal(
      context: context,
      icon: AppIcons.warning,
      tone: ModalTone.warn,
      title: 'Post stock adjustment?',
      body: 'This action will update inventory stock quantities and create permanent stock adjustment entries. This cannot be undone.',
      actions: [
        Expanded(child: AppButton(label: 'Cancel', variant: BtnVariant.ghost, onTap: () => Navigator.pop(context))),
        const SizedBox(width: 8),
        Expanded(
          child: AppButton(
            label: 'Confirm Post',
            icon: AppIcons.check,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => PostedScreen(baseCount: baseCount)));
            },
          ),
        ),
      ],
    );
  }
}

class PostedScreen extends StatelessWidget {
  final CountSummary baseCount;
  const PostedScreen({super.key, required this.baseCount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(title: const Text('Adjustment Posted'), status: 'posted'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                children: [
                  // Hero
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2FBF5), Colors.white]),
                      borderRadius: AppRadius.rLg,
                      border: Border.all(color: AppColors.tintGreenBorder),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x4D16A34A), blurRadius: 24, offset: Offset(0, 8))]),
                          child: const Icon(AppIcons.check, size: 30, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text('Stock Adjustment Posted', style: AppText.sans(size: 17, weight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Inventory levels updated · Ledger entries created', style: AppText.sans(size: 12, color: AppColors.ink3)),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.rMd, border: Border.all(color: AppColors.line)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(AppIcons.document, size: 14, color: AppColors.ink3),
                              const SizedBox(width: 6),
                              Text('Reference', style: AppText.sans(size: 11, color: AppColors.ink3)),
                              const SizedBox(width: 6),
                              Text('ADJ-2026-04812', style: AppText.mono(size: 12, weight: FontWeight.w700, color: AppColors.ink)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  KpiGrid(cols: 2, [
                    KpiData('Items Updated', '8'),
                    KpiData('Variance Posted', fmtINR(-12450), tone: KpiTone.neg, tint: KpiTint.red),
                    KpiData('Stock Increased', '+74 units', tone: KpiTone.pos, tint: KpiTint.green),
                    KpiData('Stock Reduced', '−112 units', tone: KpiTone.neg, tint: KpiTint.red),
                  ]),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CardLabel("What's Next"),
                        ...[
                          (AppIcons.article, 'Audit log generated', 'View full activity trail'),
                          (AppIcons.notifications, 'Stakeholders notified', 'Supervisor & Inventory head'),
                          (AppIcons.refresh, 'Stock balances refreshed', 'Across 8 racks · 142 bins'),
                        ].map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(color: const Color(0xFFF8FAFD), borderRadius: AppRadius.rMd),
                                child: Row(
                                  children: [
                                    Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8)), child: Icon(s.$1, size: 14, color: AppColors.primary)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s.$2, style: AppText.sans(size: 12, weight: FontWeight.w600)),
                                          Text(s.$3, style: AppText.sans(size: 10.5, color: AppColors.ink3)),
                                        ],
                                      ),
                                    ),
                                    const Icon(AppIcons.check, size: 14, color: AppColors.greenFg),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CardLabel('Summary'),
                        KvRow('Count Number', baseCount.id, mono: true),
                        const KvRow('Adjustment Ref', 'ADJ-2026-04812', mono: true),
                        const KvRow('Posted By', 'P. Shah'),
                        const KvRow('Posted At', 'May 8, 2026 · 14:32', last: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: AppButton(label: 'View Log', variant: BtnVariant.ghost, icon: AppIcons.visibility, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ViewLogScreen(baseCount: baseCount))))),
                      const SizedBox(width: 8),
                      Expanded(child: AppButton(label: 'Export PDF', variant: BtnVariant.ghost, icon: AppIcons.download, onTap: () {})),
                    ],
                  ),
                ],
              ),
            ),
            StickyBar(children: [
              Expanded(
                child: AppButton(
                  label: 'Back to Dashboard',
                  icon: AppIcons.chevronLeft,
                  block: true,
                  onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
