// Screen 04 · Counting Entry — with rack-location validation.
// Counter scans/selects a rack, counts items in it, and the system auto-flags
// any item whose expectedRack != currentRack as "Misplaced".
import 'package:flutter/material.dart';
import '../models/data.dart';
import '../theme/tokens.dart';
import '../widgets/primitives.dart';
import '../widgets/overlays.dart';
import 'barcode_scanner.dart';
import 'variance_screen.dart';
import 'add_item_sheet.dart';

const _diffUnitValue = 56; // matches the prototype's flat per-unit value on this screen

class CountingScreen extends StatefulWidget {
  final CountSummary baseCount;
  const CountingScreen({super.key, required this.baseCount});

  @override
  State<CountingScreen> createState() => _CountingScreenState();
}

class _CountingScreenState extends State<CountingScreen> {
  late final List<CountItem> _items;
  String _currentRack = 'A-Bay-12';
  int? _highlightIdx;

  @override
  void initState() {
    super.initState();
    final seeded = seedItems().take(6).toList();
    for (var i = 0; i < seeded.length; i++) {
      if (i < 4) {
        seeded[i].counted = true;
        seeded[i].foundRack ??= seeded[i].expectedRack;
      } else {
        seeded[i].counted = false;
        seeded[i].foundRack = null;
      }
    }
    _items = seeded;
  }

  // ── derived ──
  int get _totalScope => _items.length + 2;
  int get _counted => _items.where((i) => i.counted).length;
  num get _variance => _items.where((i) => i.counted).fold<num>(0, (a, it) => a + (it.physical - it.system) * _diffUnitValue);
  int get _misplaced => _items.where((i) => i.misplaced).length;

  int get _rackExpected => _items.where((i) => i.expectedRack == _currentRack).length;
  int get _rackCounted => _items.where((i) => i.counted && i.expectedRack == _currentRack).length;

  List<CountItem> get _itemsInRack => _items.where((i) => i.expectedRack == _currentRack).toList();
  List<CountItem> get _misplacedHere =>
      _items.where((i) => i.counted && i.foundRack == _currentRack && i.expectedRack != _currentRack).toList();
  List<CountItem> get _otherRackCounted => _items
      .where((i) => i.expectedRack != _currentRack && !(i.counted && i.foundRack == _currentRack) && i.counted)
      .toList();

  String get _zone => kRacks.firstWhere((r) => r.id == _currentRack, orElse: () => kRacks.first).zone;

  void _updatePhysical(CountItem it, int val) {
    setState(() {
      final wasMisplaced = it.expectedRack != _currentRack && (!it.counted || it.foundRack != _currentRack);
      it.physical = val;
      it.counted = true;
      it.foundRack = _currentRack;
      if (it.expectedRack != _currentRack && it.reason.isEmpty) it.reason = 'Misplaced';
      if (wasMisplaced) _showMisplaceToast(it, it.expectedRack, _currentRack);
    });
  }

  void _addItem(CountItem it) {
    setState(() {
      it.counted = true;
      it.foundRack = _currentRack;
      _items.add(it);
      _highlightIdx = _items.length - 1;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _highlightIdx = null);
    });
    if (it.expectedRack != _currentRack) {
      _showMisplaceToast(it, it.expectedRack, _currentRack);
    }
  }

  void _showMisplaceToast(CountItem it, String from, String to) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      duration: const Duration(milliseconds: 4500),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 72),
      padding: EdgeInsets.zero,
      content: _MisplaceToast(item: it, from: from, to: to, onDismiss: () => messenger.hideCurrentSnackBar()),
    ));
  }

  Future<void> _scan(String mode) async {
    final result = await openScanner(context, mode: mode, currentRack: _currentRack);
    if (result == null || !mounted) return;
    if (result.type == 'rack') {
      setState(() => _currentRack = result.rackId ?? 'B-Bay-04');
      return;
    }
    // Item scan: pull a not-yet-listed catalogue item.
    final existing = _items.map((i) => i.code).toSet();
    final candidate = seedItems().skip(6).where((it) => !existing.contains(it.code)).toList();
    if (candidate.isNotEmpty) {
      _addItem(candidate.first..reason = candidate.first.expectedRack != _currentRack ? 'Misplaced' : '');
    }
  }

  void _openAddSheet() {
    showAddItemSheet(
      context: context,
      currentRack: _currentRack,
      existingCodes: _items.map((i) => i.code).toList(),
      onScanRequest: () => _scan('item'),
      onAdd: _addItem,
    );
  }

  void _openSwitchRack() {
    showAppSheet(
      context: context,
      title: 'Switch Rack Location',
      builder: (ctx, setSheet) => _RackSwitchBody(
        currentRack: _currentRack,
        items: _items,
        onScan: () {
          Navigator.pop(ctx);
          _scan('rack');
        },
        onPick: (id) {
          setState(() => _currentRack = id);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _submit() {
    final rackCount = _items.where((i) => i.counted).map((i) => i.foundRack).toSet().length;
    showAppModal(
      context: context,
      icon: AppIcons.send,
      tone: ModalTone.warn,
      title: 'Submit for variance review?',
      body: '$_counted items counted across $rackCount racks. '
          '${_misplaced > 0 ? '$_misplaced misplaced item(s) flagged. ' : ''}'
          "Counters won't be able to edit after submission.",
      actions: [
        Expanded(child: AppButton(label: 'Cancel', variant: BtnVariant.ghost, onTap: () => Navigator.pop(context))),
        const SizedBox(width: 8),
        Expanded(
          child: AppButton(
            label: 'Yes, Submit',
            icon: AppIcons.check,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => VarianceScreen(baseCount: widget.baseCount)),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final inRack = _itemsInRack;
    final misHere = _misplacedHere;
    final others = _otherRackCounted;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              onBack: () => Navigator.pop(context),
              title: Text.rich(TextSpan(children: [
                const TextSpan(text: 'Count '),
                TextSpan(text: widget.baseCount.id, style: AppText.mono(size: 14, weight: FontWeight.w600, color: AppColors.ink)),
              ])),
              subtitle: widget.baseCount.storeName,
              status: 'progress',
            ),
            _rackBar(),
            _toolbar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 96),
                children: [
                  KpiGrid(cols: 4, [
                    KpiData('Total', '$_totalScope'),
                    KpiData('Counted', '$_counted', tint: KpiTint.green, tone: KpiTone.pos),
                    KpiData('Misplaced', '$_misplaced', tint: _misplaced > 0 ? KpiTint.red : KpiTint.blue, tone: _misplaced > 0 ? KpiTone.neg : KpiTone.none),
                    KpiData('Variance', fmtINR(_variance), tone: _variance < 0 ? KpiTone.neg : KpiTone.pos),
                  ]),
                  const SizedBox(height: 8),
                  SectionHeader(
                    title: Text.rich(TextSpan(children: [
                      const TextSpan(text: 'THIS RACK · '),
                      TextSpan(text: '$_rackCounted', style: AppText.sans(size: 11, weight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.44)),
                      TextSpan(text: ' / $_rackExpected'),
                    ])),
                    trailing: const AppTag('Live save', tone: TagTone.info, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  if (inRack.isEmpty)
                    const EmptyState(icon: AppIcons.item, message: 'No items expected in this rack')
                  else
                    ...inRack.map((it) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ItemRow(
                            item: it,
                            currentRack: _currentRack,
                            highlighted: _highlightIdx == _items.indexOf(it),
                            onPhysical: (v) => _updatePhysical(it, v),
                            onScan: () => _scan('item'),
                          ),
                        )),
                  _addRowButton(),
                  if (misHere.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SectionHeader(
                      title: Row(children: [
                        const Icon(AppIcons.warning, size: 11, color: AppColors.orangeFg),
                        const SizedBox(width: 4),
                        Text('MISPLACED — FOUND HERE', style: AppText.sans(size: 11, weight: FontWeight.w700, color: AppColors.ink2, letterSpacing: 0.44)),
                      ]),
                      trailing: AppTag('${misHere.length} ${misHere.length == 1 ? 'item' : 'items'}', tone: TagTone.warn),
                    ),
                    const SizedBox(height: 8),
                    ...misHere.map((it) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ItemRow(item: it, currentRack: _currentRack, onPhysical: (v) => _updatePhysical(it, v), onScan: () => _scan('item')),
                        )),
                  ],
                  if (others.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SectionHeader(
                      title: Text('ALREADY COUNTED IN OTHER RACKS', style: AppText.sans(size: 11, weight: FontWeight.w700, color: AppColors.ink2, letterSpacing: 0.44)),
                      trailing: AppTag('${others.length}', tone: TagTone.ok),
                    ),
                    const SizedBox(height: 8),
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Column(
                        children: others.take(3).map((it) {
                          final correct = it.foundRack == it.expectedRack;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(AppIcons.checkCircle, size: 14, color: AppColors.greenFg),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(it.name, style: AppText.sans(size: 12, weight: FontWeight.w600)),
                                      Text('${it.code} · ${it.foundRack}', style: AppText.sans(size: 10.5, color: AppColors.ink3)),
                                    ],
                                  ),
                                ),
                                AppTag(correct ? 'Correct' : 'Misplaced', tone: correct ? TagTone.ok : TagTone.warn),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            StickyBar(children: [
              Expanded(flex: 10, child: AppButton(label: 'Save Draft', variant: BtnVariant.ghost, icon: AppIcons.save, onTap: () => Navigator.pop(context))),
              const SizedBox(width: 8),
              Expanded(flex: 16, child: AppButton(label: 'Submit Count', trailingIcon: AppIcons.send, onTap: _submit)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _rackBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF4F8FF), Color(0xFFFBFCFE)]),
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.rMd,
              boxShadow: const [BoxShadow(color: Color(0x4D277DFE), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: const Icon(AppIcons.grid, size: 15, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACTIVE RACK', style: AppText.sans(size: 9.5, weight: FontWeight.w700, color: AppColors.primary600, letterSpacing: 0.95)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(_currentRack, style: AppText.mono(size: 13.5, weight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(width: 6),
                    Flexible(child: Text('· $_zone', style: AppText.sans(size: 10.5, weight: FontWeight.w500, color: AppColors.ink3), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.line)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$_rackCounted', style: AppText.mono(size: 13, weight: FontWeight.w700, color: AppColors.primary)),
                Text('/', style: AppText.mono(size: 11, color: AppColors.ink4)),
                Text('$_rackExpected', style: AppText.mono(size: 12, weight: FontWeight.w600, color: AppColors.ink2)),
                const SizedBox(width: 4),
                Text('ITEMS', style: AppText.sans(size: 9.5, color: AppColors.ink3, letterSpacing: 0.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppButton(label: 'Switch', variant: BtnVariant.ghost, small: true, icon: AppIcons.refresh, onTap: _openSwitchRack),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(child: AppButton(label: 'Scan Item', small: true, icon: AppIcons.scan, onTap: () => _scan('item'))),
          const SizedBox(width: 8),
          Expanded(child: AppButton(label: 'Search', variant: BtnVariant.ghost, small: true, icon: AppIcons.search, onTap: _openAddSheet)),
          const SizedBox(width: 8),
          SizedBox(width: 38, child: AppButton(variant: BtnVariant.ghost, small: true, icon: AppIcons.mic, onTap: () {})),
        ],
      ),
    );
  }

  Widget _addRowButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: _openAddSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: ShapeDecoration(
            color: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg, side: const BorderSide(color: AppColors.line)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(AppIcons.add, size: 14, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Add Item to This Rack', style: AppText.sans(size: 12.5, weight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Item row ─────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final CountItem item;
  final String currentRack;
  final bool highlighted;
  final ValueChanged<int> onPhysical;
  final VoidCallback onScan;
  const _ItemRow({
    required this.item,
    required this.currentRack,
    this.highlighted = false,
    required this.onPhysical,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final it = item;
    final diff = it.physical - it.system;
    final value = diff * _diffUnitValue;
    final misplaced = it.misplaced;
    final (bg, border) = _tone(it, diff, misplaced);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: border),
        boxShadow: highlighted ? const [BoxShadow(color: AppColors.primary, blurRadius: 0, spreadRadius: 2), BoxShadow(color: Color(0x33277DFE), blurRadius: 20, offset: Offset(0, 6))] : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top
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
                        AppTag('Exp ${it.exp}', tone: it.expSoon ? TagTone.warn : TagTone.normal, icon: it.expSoon ? AppIcons.warning : null),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (it.counted)
                    AppTag(
                      diff == 0 ? 'Match' : '${diff < 0 ? '−' : '+'}${diff.abs()}',
                      tone: diff < 0 ? TagTone.danger : diff > 0 ? TagTone.ok : TagTone.normal,
                      icon: diff == 0 ? AppIcons.check : null,
                    )
                  else
                    const AppTag('Pending', tone: TagTone.warn),
                  const SizedBox(height: 4),
                  GestureDetector(onTap: onScan, child: const Icon(AppIcons.scan, size: 14, color: AppColors.ink3)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          _rackLine(it, misplaced),
          const SizedBox(height: 6),
          // Grid: UoM / System / Diff Value
          Row(
            children: [
              Expanded(child: _gridCell('UoM', it.uom)),
              Expanded(child: _gridCell('System', fmtNum(it.system))),
              Expanded(child: _gridCell('Diff Value', it.counted ? fmtINR(value) : '—', color: diff < 0 ? AppColors.redFg : diff > 0 ? AppColors.greenFg : AppColors.ink)),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: AppColors.line2),
          const SizedBox(height: 6),
          // Physical count + reason
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PHYSICAL COUNT', style: AppText.sans(size: 10, color: AppColors.ink3, letterSpacing: 0.6)),
                  const SizedBox(height: 4),
                  SizedBox(width: 116, child: NumStepper(value: it.physical, onChanged: onPhysical)),
                ],
              ),
              const Spacer(),
              if (it.counted)
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (it.reason.isNotEmpty) AppTag(it.reason, tone: it.reason == 'Misplaced' ? TagTone.warn : TagTone.normal),
                      if (it.remarks.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        SizedBox(width: 140, child: Text('"${it.remarks}"', textAlign: TextAlign.right, style: AppText.sans(size: 10.5, color: AppColors.ink3))),
                      ],
                      const SizedBox(height: 3),
                      AppButton(label: 'Reason', variant: BtnVariant.ghost, small: true, icon: AppIcons.edit, onTap: () {}),
                    ],
                  ),
                )
              else
                const Padding(padding: EdgeInsets.only(top: 8), child: BarcodeViz(width: 100)),
            ],
          ),
        ],
      ),
    );
  }

  (Color, Color) _tone(CountItem it, int diff, bool misplaced) {
    if (!it.counted) return (AppColors.card, AppColors.line);
    if (misplaced) return (const Color(0xFFFFFAEE), AppColors.orangeBorder);
    if (diff < 0) return (const Color(0xFFFFF6F8), AppColors.redBorder);
    if (diff > 0) return (const Color(0xFFF4FBF6), AppColors.greenBorder);
    return (AppColors.card, AppColors.line);
  }

  Widget _gridCell(String label, String value, {Color color = AppColors.ink}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.sans(size: 10.5, color: AppColors.ink3)),
        Text(value, style: AppText.sans(size: 11.5, weight: FontWeight.w600, color: color, tabular: true)),
      ],
    );
  }

  Widget _rackLine(CountItem it, bool misplaced) {
    Widget statusTag;
    if (it.counted) {
      statusTag = misplaced
          ? AppTag('Misplaced · found in ${it.foundRack}', tone: TagTone.warn, icon: AppIcons.warning)
          : const AppTag('Correct rack', tone: TagTone.ok, icon: AppIcons.check);
    } else if (currentRack == it.expectedRack) {
      statusTag = const AppTag('You are here', tone: TagTone.info);
    } else {
      statusTag = const AppTag('Not yet found');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        color: misplaced ? const Color(0xFFFFF9EE) : const Color(0xFFF8FAFD),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rSm,
          side: BorderSide(
            color: misplaced ? AppColors.orangeBorder : AppColors.line,
            style: misplaced ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.location, size: 11, color: AppColors.ink3),
          const SizedBox(width: 5),
          Text('Expected:', style: AppText.sans(size: 10.5, color: AppColors.ink3)),
          const SizedBox(width: 4),
          Text('${it.expectedRack} · ${it.bin ?? '—'}', style: AppText.mono(size: 10.5, color: AppColors.ink2)),
          const Spacer(),
          Flexible(child: Align(alignment: Alignment.centerRight, child: statusTag)),
        ],
      ),
    );
  }
}

// ─── Misplace toast ───────────────────────────────────────────
class _MisplaceToast extends StatelessWidget {
  final CountItem item;
  final String from;
  final String to;
  final VoidCallback onDismiss;
  const _MisplaceToast({required this.item, required this.from, required this.to, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        border: Border(
          top: BorderSide(color: AppColors.orangeBorder),
          right: BorderSide(color: AppColors.orangeBorder),
          bottom: BorderSide(color: AppColors.orangeBorder),
          left: BorderSide(color: AppColors.orangeFg, width: 4),
        ),
        boxShadow: [BoxShadow(color: Color(0x1F0F172A), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: AppColors.orangeBg, borderRadius: BorderRadius.circular(8)),
            child: const Icon(AppIcons.warning, size: 16, color: AppColors.orangeFg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Item misplaced', style: AppText.sans(size: 12.5, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text.rich(TextSpan(
                  style: AppText.sans(size: 11, color: AppColors.ink3, height: 1.45),
                  children: [
                    TextSpan(text: item.name, style: AppText.sans(size: 11, weight: FontWeight.w700, color: AppColors.ink2)),
                    const TextSpan(text: ' belongs in '),
                    TextSpan(text: from, style: AppText.sans(size: 11, weight: FontWeight.w700, color: AppColors.ink2)),
                    const TextSpan(text: ', found in '),
                    TextSpan(text: to, style: AppText.sans(size: 11, weight: FontWeight.w700, color: AppColors.ink2)),
                    const TextSpan(text: '. Reason auto-set to "Misplaced".'),
                  ],
                )),
              ],
            ),
          ),
          GestureDetector(onTap: onDismiss, child: const Padding(padding: EdgeInsets.all(2), child: Icon(AppIcons.close, size: 13, color: AppColors.ink3))),
        ],
      ),
    );
  }
}

// ─── Switch Rack sheet body ───────────────────────────────────
class _RackSwitchBody extends StatelessWidget {
  final String currentRack;
  final List<CountItem> items;
  final VoidCallback onScan;
  final ValueChanged<String> onPick;
  const _RackSwitchBody({required this.currentRack, required this.items, required this.onScan, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: AppButton(label: 'Scan Rack Barcode', icon: AppIcons.scan, onTap: onScan)),
              const SizedBox(width: 8),
              SizedBox(width: 42, child: AppButton(variant: BtnVariant.ghost, icon: AppIcons.edit, onTap: () {})),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Text('RACKS IN SCOPE', style: AppText.sans(size: 10.5, weight: FontWeight.w600, color: AppColors.ink3, letterSpacing: 0.63)),
          ),
          const SizedBox(height: 8),
          ...kRacks.map((r) {
            final expected = items.where((i) => i.expectedRack == r.id).length;
            final counted = items.where((i) => i.expectedRack == r.id && i.counted).length;
            final isCurrent = r.id == currentRack;
            final pct = expected > 0 ? counted / expected : 0.0;
            final done = pct == 1 && expected > 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                background: isCurrent ? AppColors.primary50 : AppColors.card,
                borderColor: isCurrent ? AppColors.primary : AppColors.line,
                onTap: () => onPick(r.id),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: isCurrent ? AppColors.card : const Color(0xFFF2F5FA), borderRadius: AppRadius.rMd),
                      child: Icon(AppIcons.grid, size: 16, color: isCurrent ? AppColors.primary : AppColors.ink3),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(r.id, style: AppText.sans(size: 13, weight: FontWeight.w600)),
                            const SizedBox(width: 6),
                            if (isCurrent) const AppTag('Active', tone: TagTone.info),
                            if (done) ...[const SizedBox(width: 4), const AppTag('Done', tone: TagTone.ok, icon: AppIcons.check)],
                          ]),
                          Text('${r.zone} · ${r.bins} bins', style: AppText.sans(size: 10.5, color: AppColors.ink3)),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 3,
                              backgroundColor: AppColors.line2,
                              valueColor: AlwaysStoppedAnimation(done ? AppColors.success : AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Counted', style: AppText.sans(size: 10, color: AppColors.ink3)),
                        Text('$counted/$expected', style: AppText.sans(size: 13, weight: FontWeight.w700, tabular: true)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
