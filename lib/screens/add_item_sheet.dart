// Screen 08 · Add Item — Search + Entry bottom sheet.
import 'package:flutter/material.dart';
import '../models/data.dart';
import '../theme/tokens.dart';
import '../widgets/primitives.dart';

const _reasons = ['Damaged', 'Expired', 'Theft / Pilferage', 'Misplaced', 'Returns', 'Data Entry Error', 'Other'];

Future<void> showAddItemSheet({
  required BuildContext context,
  required String currentRack,
  required List<String> existingCodes,
  required VoidCallback onScanRequest,
  required ValueChanged<CountItem> onAdd,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.scrim,
    builder: (ctx) => _AddItemSheet(
      currentRack: currentRack,
      existingCodes: existingCodes,
      onScanRequest: onScanRequest,
      onAdd: onAdd,
    ),
  );
}

class _AddItemSheet extends StatefulWidget {
  final String currentRack;
  final List<String> existingCodes;
  final VoidCallback onScanRequest;
  final ValueChanged<CountItem> onAdd;
  const _AddItemSheet({required this.currentRack, required this.existingCodes, required this.onScanRequest, required this.onAdd});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _searchCtrl = TextEditingController();
  final _rackCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  String _q = '';
  CountItem? _picked;
  int _physical = 0;
  String _reason = '';
  int _photoCount = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _rackCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  bool get _misplaced => _picked != null && _picked!.expectedRack != widget.currentRack;

  List<CountItem> get _filtered {
    final candidates = seedItems().where((i) => !widget.existingCodes.contains(i.code));
    if (_q.isEmpty) return candidates.toList();
    final q = _q.toLowerCase();
    return candidates.where((i) => i.name.toLowerCase().contains(q) || i.code.toLowerCase().contains(q) || i.batch.toLowerCase().contains(q)).toList();
  }

  void _pick(CountItem it) {
    setState(() {
      _picked = it;
      _physical = it.system;
      _rackCtrl.text = widget.currentRack;
      _reason = it.expectedRack != widget.currentRack ? 'Misplaced' : '';
    });
  }

  void _submit(bool another) {
    final p = _picked!;
    final item = p.copy()
      ..physical = _physical
      ..reason = _reason
      ..remarks = _remarksCtrl.text
      ..foundRack = _rackCtrl.text
      ..images = List.generate(_photoCount, (i) => 'photo_$i');
    widget.onAdd(item);
    if (another) {
      setState(() {
        _picked = null;
        _q = '';
        _searchCtrl.clear();
        _physical = 0;
        _reason = '';
        _remarksCtrl.clear();
        _photoCount = 0;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.86;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 38, height: 4, margin: const EdgeInsets.fromLTRB(0, 6, 0, 10), decoration: BoxDecoration(color: const Color(0xFFD7DDE6), borderRadius: BorderRadius.circular(999))),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_picked != null ? 'Add Item — Entry' : 'Add Item to Count', style: AppText.sans(size: 14, weight: FontWeight.w600)),
                SizedBox(width: 30, height: 30, child: AppButton(variant: BtnVariant.ghost, icon: AppIcons.close, small: true, onTap: () => Navigator.pop(context))),
              ],
            ),
          ),
          Flexible(child: SingleChildScrollView(child: _picked == null ? _searchState() : _entryState())),
        ],
      ),
    );
  }

  Widget _searchState() {
    final results = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFFF4F8FF), borderRadius: AppRadius.rLg, border: Border.all(color: AppColors.blueBorder)),
          child: Row(
            children: [
              const Icon(AppIcons.location, size: 13, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(TextSpan(
                  style: AppText.sans(size: 11.5, color: AppColors.ink2),
                  children: [
                    const TextSpan(text: 'Adding to rack '),
                    TextSpan(text: widget.currentRack, style: AppText.sans(size: 11.5, weight: FontWeight.w700, color: AppColors.primary)),
                  ],
                )),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: AppButton(label: 'Scan Barcode', icon: AppIcons.scan, onTap: () { Navigator.pop(context); widget.onScanRequest(); })),
            const SizedBox(width: 8),
            Expanded(child: AppButton(label: 'Voice', variant: BtnVariant.ghost, icon: AppIcons.mic, onTap: () {})),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _searchCtrl,
          autofocus: true,
          onChanged: (v) => setState(() => _q = v),
          style: AppText.sans(size: 13),
          decoration: appInputDecoration(
            hintText: 'Item name, code or barcode...',
            prefixIcon: const Padding(padding: EdgeInsets.only(left: 10, right: 6), child: Icon(AppIcons.search, size: 15, color: AppColors.ink4)),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(_q.isNotEmpty ? 'RESULTS · ${results.length}' : 'SUGGESTED FOR THIS SCOPE', style: AppText.sans(size: 10.5, weight: FontWeight.w600, color: AppColors.ink3, letterSpacing: 0.63)),
        ),
        if (results.isEmpty)
          EmptyState(icon: AppIcons.search, message: 'No items match "$_q"')
        else
          ...results.take(5).map((it) {
            final wrongRack = it.expectedRack != widget.currentRack;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                onTap: () => _pick(it),
                child: Row(
                  children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFF2F5FA), borderRadius: AppRadius.rMd), child: const Icon(AppIcons.item, size: 16, color: AppColors.ink3)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.name, style: AppText.sans(size: 12.5, weight: FontWeight.w600)),
                          const SizedBox(height: 1),
                          Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(it.code, style: AppText.mono(size: 10.5, color: AppColors.ink3)),
                              Text('· ${it.expectedRack}', style: AppText.sans(size: 10.5, color: AppColors.ink3)),
                              if (wrongRack) const AppTag('Belongs elsewhere', tone: TagTone.warn, fontSize: 9.5),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('System', style: AppText.sans(size: 10, color: AppColors.ink3)),
                        Text(fmtNum(it.system), style: AppText.sans(size: 13, weight: FontWeight.w700, tabular: true)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _entryState() {
    final p = _picked!;
    final diff = _physical - p.system;
    final diffValue = diff * p.sp;
    final diffColor = diff < 0 ? AppColors.redFg : diff > 0 ? AppColors.greenFg : AppColors.ink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Picked card with stats row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFFF4F8FF), borderRadius: AppRadius.rLg, border: Border.all(color: AppColors.blueBorder)),
          child: Column(
            children: [
              Row(
                children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.rMd), child: const Icon(AppIcons.item, size: 16, color: AppColors.primary)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: AppText.sans(size: 12.5, weight: FontWeight.w600)),
                        Text('${p.code} · Batch ${p.batch} · Exp ${p.exp}', style: AppText.sans(size: 10.5, color: AppColors.ink3)),
                      ],
                    ),
                  ),
                  AppButton(label: 'Change', variant: BtnVariant.ghost, small: true, onTap: () => setState(() => _picked = null)),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.blueBorder))),
                child: Row(
                  children: [
                    Expanded(child: _statCell('MRP', '₹${p.mrp.toStringAsFixed(2)}')),
                    Expanded(child: _statCell('Selling Price', '₹${p.sp.toStringAsFixed(2)}')),
                    Expanded(child: _statCell('System Available', fmtNum(p.system), uom: p.uom)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Rack location + Physical Qty side by side
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 3,
              child: Field(
                label: 'Rack Location',
                required: true,
                child: TextField(
                  controller: _rackCtrl,
                  style: AppText.mono(size: 13, weight: FontWeight.w600, color: AppColors.ink),
                  decoration: appInputDecoration(
                    hintText: 'e.g. A-Bay-12',
                    prefixIcon: const Padding(padding: EdgeInsets.only(left: 10, right: 6), child: Icon(AppIcons.location, size: 13, color: AppColors.ink4)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Field(
                label: 'Physical Qty',
                required: true,
                child: NumStepper(value: _physical, onChanged: (v) => setState(() => _physical = v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Info grid (read-only): Difference Qty + Difference Value
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFBFCFE), Color(0xFFF6F8FC)]),
            borderRadius: AppRadius.rMd,
            border: Border.all(color: AppColors.line2),
          ),
          child: Row(
            children: [
              Expanded(child: _infoCell('Difference Qty', '${diff > 0 ? '+' : ''}$diff', diffColor, rightBorder: true)),
              Expanded(child: _infoCell('Difference Value', fmtINR(diffValue), diffColor)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Field(
          label: 'Reason for Difference',
          required: _misplaced,
          child: _reasonSelect(),
        ),
        const SizedBox(height: 12),
        Field(
          label: 'Remarks',
          child: TextField(
            controller: _remarksCtrl,
            maxLines: 2,
            style: AppText.sans(size: 13),
            decoration: appInputDecoration(hintText: _misplaced ? 'Found in ${widget.currentRack}, belongs in ${p.expectedRack}' : 'Optional note...'),
          ),
        ),
        const SizedBox(height: 12),
        Field(
          label: 'Photos',
          hint: '$_photoCount/4 attached · proof of condition or rack location',
          child: _photoGrid(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(flex: 10, child: AppButton(label: 'Cancel', variant: BtnVariant.ghost, onTap: () => Navigator.pop(context))),
            const SizedBox(width: 8),
            Expanded(flex: 12, child: AppButton(label: 'Save & Add Another', variant: BtnVariant.ghost, onTap: () => _submit(true))),
            const SizedBox(width: 8),
            Expanded(flex: 12, child: AppButton(label: 'Add Item', icon: AppIcons.check, onTap: () => _submit(false))),
          ],
        ),
      ],
    );
  }

  Widget _statCell(String label, String value, {String? uom}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppText.sans(size: 9, weight: FontWeight.w600, color: AppColors.primary600, letterSpacing: 0.54)),
        const SizedBox(height: 1),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(child: Text(value, style: AppText.sans(size: 12.5, weight: FontWeight.w700, tabular: true), overflow: TextOverflow.ellipsis)),
            if (uom != null) ...[const SizedBox(width: 3), Text(uom, style: AppText.sans(size: 9.5, weight: FontWeight.w500, color: AppColors.ink3))],
          ],
        ),
      ],
    );
  }

  Widget _infoCell(String label, String value, Color color, {bool rightBorder = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        border: rightBorder ? const Border(right: BorderSide(color: AppColors.line2)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppText.sans(size: 9, weight: FontWeight.w600, color: AppColors.ink3, letterSpacing: 0.54)),
          const SizedBox(height: 1),
          Text(value, style: AppText.sans(size: 11.5, weight: FontWeight.w700, color: color, tabular: true)),
        ],
      ),
    );
  }

  Widget _reasonSelect() {
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
              children: _reasons
                  .map((r) => ListTile(
                        title: Text(r, style: AppText.sans(size: 13)),
                        trailing: _reason == r ? const Icon(AppIcons.check, size: 16, color: AppColors.primary) : null,
                        onTap: () => Navigator.pop(ctx, r),
                      ))
                  .toList(),
            ),
          ),
        );
        if (picked != null) setState(() => _reason = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.rMd, border: Border.all(color: AppColors.line)),
        child: Row(
          children: [
            Expanded(child: Text(_reason.isEmpty ? 'Select reason...' : _reason, style: AppText.sans(size: 13, color: _reason.isEmpty ? AppColors.ink4 : AppColors.ink))),
            const Icon(AppIcons.caretDown, size: 16, color: AppColors.ink3),
          ],
        ),
      ),
    );
  }

  Widget _photoGrid() {
    const tints = [Color(0xFFE8F1FF), Color(0xFFE4F6EA), Color(0xFFEFE7FF), Color(0xFFFFF4E0)];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      children: [
        ...List.generate(_photoCount, (i) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(color: tints[i % tints.length], borderRadius: AppRadius.rMd, border: Border.all(color: AppColors.line)),
                child: const Icon(AppIcons.image, size: 20, color: AppColors.ink3),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _photoCount--),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(color: Color(0xC70F172A), shape: BoxShape.circle),
                    child: const Icon(AppIcons.close, size: 11, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        }),
        if (_photoCount < 4)
          GestureDetector(
            onTap: () => setState(() => _photoCount++),
            child: Container(
              decoration: ShapeDecoration(
                color: const Color(0xFFF8FAFD),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd, side: const BorderSide(color: AppColors.line, width: 1.5)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8)), child: const Icon(AppIcons.add, size: 16, color: AppColors.primary)),
                  const SizedBox(height: 2),
                  Text('Add Photo', style: AppText.sans(size: 10.5, weight: FontWeight.w600, color: AppColors.ink3)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
