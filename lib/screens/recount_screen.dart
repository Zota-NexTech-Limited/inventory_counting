// Screen 14 · Request Recount.
import 'package:flutter/material.dart';
import '../models/data.dart';
import '../theme/tokens.dart';
import '../widgets/primitives.dart';
import '../widgets/chip.dart';

class RecountScreen extends StatefulWidget {
  final CountSummary baseCount;
  const RecountScreen({super.key, required this.baseCount});

  @override
  State<RecountScreen> createState() => _RecountScreenState();
}

class _RecountScreenState extends State<RecountScreen> {
  String _reason = 'Variance exceeds tolerance';
  String _priority = 'high';
  final List<String> _team = ['R. Kaur', 'S. Verma'];
  final _remarksCtrl = TextEditingController(text: 'Recount items in A-Bay-12 with shortage > 2%');

  static const _reasons = ['Variance exceeds tolerance', 'Suspected counting errors', 'Missing physical counts', 'Audit discrepancy', 'Other'];

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  Color? _priorityColor(String p) => p == 'urgent' ? AppColors.redFg : p == 'high' ? AppColors.orangeFg : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(onBack: () => Navigator.pop(context), title: const Text('Request Recount'), subtitle: 'Re-assignment workflow'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.orangeBg, borderRadius: AppRadius.rLg, border: Border.all(color: AppColors.orangeBorder)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(AppIcons.refresh, size: 15, color: AppColors.orangeFg),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(TextSpan(
                            style: AppText.sans(size: 11, color: const Color(0xFF7A4A09), height: 1.4),
                            children: [
                              const TextSpan(text: 'A recount creates a child count linked to '),
                              TextSpan(text: widget.baseCount.id, style: AppText.mono(size: 11, weight: FontWeight.w700, color: const Color(0xFF7A4A09))),
                              const TextSpan(text: ' and freezes its variance review until completion.'),
                            ],
                          )),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Field(label: 'Recount Reason', required: true, child: _select(_reason, _reasons, (v) => setState(() => _reason = v))),
                        const SizedBox(height: 12),
                        Field(
                          label: 'Priority',
                          required: true,
                          child: _segmented(),
                        ),
                        const SizedBox(height: 12),
                        Field(label: 'Due Date / Time', required: true, child: _readonly('May 9, 2026 · 12:00')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CardLabel('Assign Counters'),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ..._team.map((m) => AvatarChip(name: m, avatarBg: AppColors.blueBg, avatarFg: AppColors.blueFg, onRemove: () => setState(() => _team.remove(m)))),
                            AddChip(label: 'Add Counter', onTap: () {}),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Field(
                      label: 'Remarks',
                      hint: 'Visible to assigned counters',
                      child: TextField(
                        controller: _remarksCtrl,
                        maxLines: 3,
                        style: AppText.sans(size: 13),
                        decoration: appInputDecoration(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            StickyBar(children: [
              Expanded(flex: 10, child: AppButton(label: 'Cancel', variant: BtnVariant.ghost, onTap: () => Navigator.pop(context))),
              const SizedBox(width: 8),
              Expanded(flex: 10, child: AppButton(label: 'Save Draft', variant: BtnVariant.ghost, icon: AppIcons.save, onTap: () => Navigator.pop(context))),
              const SizedBox(width: 8),
              Expanded(flex: 14, child: AppButton(label: 'Start Recount', icon: AppIcons.play, onTap: () => Navigator.of(context).popUntil((r) => r.isFirst))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _segmented() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.line2, borderRadius: AppRadius.rMd),
      child: Row(
        children: ['low', 'medium', 'high', 'urgent'].map((p) {
          final active = _priority == p;
          final color = active ? (_priorityColor(p) ?? AppColors.ink) : AppColors.ink3;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _priority = p),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md - 3),
                  boxShadow: active ? const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 2, offset: Offset(0, 1))] : null,
                ),
                child: Text(p[0].toUpperCase() + p.substring(1), style: AppText.sans(size: 11.5, weight: FontWeight.w600, color: color)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _readonly(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.rMd, border: Border.all(color: AppColors.line)),
      child: Row(
        children: [
          Expanded(child: Text(text, style: AppText.sans(size: 13))),
          const Icon(AppIcons.schedule, size: 14, color: AppColors.ink4),
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
              children: options.map((o) => ListTile(title: Text(o, style: AppText.sans(size: 13)), trailing: value == o ? const Icon(AppIcons.check, size: 16, color: AppColors.primary) : null, onTap: () => Navigator.pop(ctx, o))).toList(),
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
            Expanded(child: Text(value, style: AppText.sans(size: 13))),
            const Icon(AppIcons.caretDown, size: 16, color: AppColors.ink3),
          ],
        ),
      ),
    );
  }
}
