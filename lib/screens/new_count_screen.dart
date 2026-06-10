// Screen 02 · Create Inventory Count (+ 03 Start confirmation modal)
import 'package:flutter/material.dart';
import '../models/data.dart';
import '../theme/tokens.dart';
import '../widgets/primitives.dart';
import '../widgets/overlays.dart';
import '../widgets/chip.dart';
import 'counting_screen.dart';

class _CountType {
  final String id;
  final IconData icon;
  final String hint;
  const _CountType(this.id, this.icon, this.hint);
}

const _types = [
  _CountType('Full Count', AppIcons.item, 'All items in store'),
  _CountType('Category-wise', AppIcons.layers, 'By category'),
  _CountType('Item-wise', AppIcons.sku, 'Specific items'),
  _CountType('Rack-wise', AppIcons.grid, 'By rack/zone'),
  _CountType('Batch-wise', AppIcons.pin, 'By batch number'),
];

const _stores = [
  ['WH-Mumbai-01', 'Mumbai Central WH', '8 zones · 142 racks'],
  ['WH-Pune-02', 'Pune Hinjewadi DC', '12 zones · 218 racks'],
  ['WH-Bangalore-03', 'Bangalore Whitefield', '6 zones · 96 racks'],
  ['WH-Delhi-04', 'Delhi Bawana DC', '10 zones · 188 racks'],
];

const _scopeRows = [
  ['category', 'Category', 'Pharma,FMCG,Cosmetics,Generics,OTC'],
  ['brand', 'Brand', 'Cipla,Sun Pharma,Dabur,Himalaya,HUL,Nestle,P&G'],
  ['item', 'Item', 'Amoxicillin 500,Paracetamol 650,Cetirizine 10,Vitamin D3,Insulin Pen'],
  ['rack', 'Rack', 'A-Bay-12,B-Bay-04,C-Bay-09,D-Bay-02,E-Bay-07'],
  ['bin', 'Bin', 'BIN-A12-03,BIN-A12-04,BIN-B04-01,BIN-C09-12'],
];

const _scopeIcons = {
  'category': AppIcons.layers,
  'brand': AppIcons.sku,
  'item': AppIcons.item,
  'rack': AppIcons.grid,
  'bin': AppIcons.pin,
};

class NewCountScreen extends StatefulWidget {
  const NewCountScreen({super.key});

  @override
  State<NewCountScreen> createState() => _NewCountScreenState();
}

class _NewCountScreenState extends State<NewCountScreen> {
  String _store = 'WH-Mumbai-01';
  String _countType = 'Full Count';
  final Map<String, List<String>> _scope = {
    'category': ['Pharma'],
    'brand': [],
    'item': [],
    'rack': ['A-Bay-12', 'B-Bay-04'],
    'bin': [],
  };
  bool _freeze = true;
  bool _blind = true;
  bool _autoRecount = false;
  final List<String> _team = ['A. Mehta', 'R. Kaur', 'S. Verma'];

  String get _storeName => _stores.firstWhere((s) => s[0] == _store, orElse: () => _stores.first)[1];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(onBack: () => Navigator.pop(context), title: const Text('Create Inventory Count'), subtitle: 'New count session'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                children: [
                  _basics(),
                  const SizedBox(height: 8),
                  _countTypeCard(),
                  const SizedBox(height: 8),
                  _scopeCard(),
                  const SizedBox(height: 8),
                  _controlsCard(),
                  const SizedBox(height: 8),
                  _teamCard(),
                ],
              ),
            ),
            StickyBar(children: [
              Expanded(flex: 10, child: AppButton(label: 'Save Draft', variant: BtnVariant.ghost, icon: AppIcons.save, onTap: () => Navigator.pop(context))),
              const SizedBox(width: 8),
              Expanded(flex: 16, child: AppButton(label: 'Start Count', trailingIcon: AppIcons.chevronRight, onTap: _confirmStart)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _basics() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardLabel('Basics'),
          Field(
            label: 'Store / Warehouse',
            required: true,
            child: _selectButton(
              onTap: _pickStore,
              child: Row(
                children: [
                  const Icon(AppIcons.warehouse, size: 15, color: AppColors.ink2),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_storeName, style: AppText.sans(size: 13, weight: FontWeight.w600)),
                        Text('$_store · 8 zones · 142 racks', style: AppText.sans(size: 10.5, color: AppColors.ink3)),
                      ],
                    ),
                  ),
                  const Icon(AppIcons.caretDown, size: 14, color: AppColors.ink2),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Field(label: 'Count Date', required: true, child: _readonlyInput('May 8, 2026', AppIcons.calendar))),
              const SizedBox(width: 8),
              Expanded(child: Field(label: 'Due By', required: true, child: _readonlyInput('May 8 · 18:00', AppIcons.schedule))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countTypeCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardLabel('Count Type'),
          ..._typeRows(),
        ],
      ),
    );
  }

  List<Widget> _typeRows() {
    final cards = <Widget>[
      ..._types.map((t) => _typeCard(t.id, t.icon, t.hint, false)),
      _typeCard('Cycle', AppIcons.refresh, 'Recurring sample', true),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      rows.add(Padding(
        padding: EdgeInsets.only(bottom: i + 2 < cards.length ? 8 : 0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[i]),
              const SizedBox(width: 8),
              Expanded(child: i + 1 < cards.length ? cards[i + 1] : const SizedBox.shrink()),
            ],
          ),
        ),
      ));
    }
    return rows;
  }

  Widget _typeCard(String id, IconData icon, String hint, bool dashed) {
    final active = _countType == id;
    return GestureDetector(
      onTap: () => setState(() => _countType = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: ShapeDecoration(
          color: active ? AppColors.primary50 : AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.rMd,
            side: BorderSide(
              color: active ? AppColors.primary : AppColors.line,
              width: active ? 1.5 : 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: active ? AppColors.primary : AppColors.ink3),
            const SizedBox(height: 4),
            Text(id == 'Cycle' ? 'Cycle Count' : id, style: AppText.sans(size: 12, weight: FontWeight.w600, color: active ? AppColors.primary600 : AppColors.ink)),
            const SizedBox(height: 2),
            Text(hint, style: AppText.sans(size: 10, color: AppColors.ink3)),
          ],
        ),
      ),
    );
  }

  Widget _scopeCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardLabel('Count Scope', trailing: Text('Filters apply during count', style: AppText.sans(size: 10, color: AppColors.ink3))),
          ..._scopeRows.map((row) {
            final key = row[0];
            final selected = _scope[key]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _selectButton(
                onTap: () => _pickScope(key, row[1], row[2].split(',')),
                child: Row(
                  children: [
                    Icon(_scopeIcons[key], size: 14, color: AppColors.ink3),
                    const SizedBox(width: 8),
                    SizedBox(width: 60, child: Text(row[1], style: AppText.sans(size: 12, weight: FontWeight.w500, color: AppColors.ink2))),
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: selected.isEmpty
                            ? [Text('All', style: AppText.sans(size: 11.5, color: AppColors.ink4))]
                            : [
                                ...selected.take(2).map((v) => AppTag(v, tone: TagTone.info)),
                                if (selected.length > 2) AppTag('+${selected.length - 2}', tone: TagTone.info),
                              ],
                      ),
                    ),
                    const Icon(AppIcons.chevronRight, size: 12, color: AppColors.ink3),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _controlsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardLabel('Inventory Controls'),
          AppSwitchRow(
            value: _freeze,
            onChanged: (v) => setState(() => _freeze = v),
            label: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(AppIcons.freeze, size: 12, color: AppColors.ink),
              const SizedBox(width: 4),
              Flexible(child: Text('Freeze stock movements during count', style: AppText.sans(size: 12, weight: FontWeight.w500))),
            ]),
            hint: 'Blocks GRN, transfers and sales for this scope',
          ),
          const SizedBox(height: 12),
          AppSwitchRow(value: _blind, onChanged: (v) => setState(() => _blind = v), label: const Text('Allow blind count (hide system stock)'), hint: "Counters won't see expected qty"),
          const SizedBox(height: 12),
          AppSwitchRow(value: _autoRecount, onChanged: (v) => setState(() => _autoRecount = v), label: const Text('Auto-trigger 2nd count on variance'), hint: '>5% deviation triggers recount'),
        ],
      ),
    );
  }

  Widget _teamCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardLabel('Team Assignment'),
          Field(
            label: 'Supervisor',
            required: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.rMd, border: Border.all(color: AppColors.line)),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.redBg, shape: BoxShape.circle),
                    child: Text('AM', style: AppText.sans(size: 10.5, weight: FontWeight.w600, color: AppColors.redFg)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('A. Mehta', style: AppText.sans(size: 12, weight: FontWeight.w600))),
                  const AppTag('Approver', tone: TagTone.warn),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Field(
            label: 'Counters / Team',
            hint: 'Tap to add or remove counters',
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ..._team.asMap().entries.map((e) {
                  const palette = [
                    [AppColors.blueBg, AppColors.blueFg],
                    [AppColors.greenBg, AppColors.greenFg],
                    [AppColors.purpleBg, AppColors.purpleFg],
                    [AppColors.orangeBg, AppColors.orangeFg],
                  ];
                  final c = palette[e.key % palette.length];
                  return AvatarChip(name: e.value, avatarBg: c[0], avatarFg: c[1], onRemove: () => setState(() => _team.remove(e.value)));
                }),
                AddChip(onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── helpers ──
  Widget _selectButton({required Widget child, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: AppRadius.rMd,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.rMd, border: Border.all(color: AppColors.line)),
        child: child,
      ),
    );
  }

  Widget _readonlyInput(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.rMd, border: Border.all(color: AppColors.line)),
      child: Row(
        children: [
          Expanded(child: Text(text, style: AppText.sans(size: 13))),
          Icon(icon, size: 14, color: AppColors.ink4),
        ],
      ),
    );
  }

  void _pickStore() {
    showAppSheet(
      context: context,
      title: 'Select Store / Warehouse',
      builder: (ctx, setSheet) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: _stores.map((s) {
            final active = _store == s[0];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                borderColor: active ? AppColors.primary : AppColors.line,
                onTap: () {
                  setState(() => _store = s[0]);
                  Navigator.pop(ctx);
                },
                child: Row(
                  children: [
                    Icon(AppIcons.warehouse, size: 18, color: active ? AppColors.primary : AppColors.ink3),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s[1], style: AppText.sans(size: 13, weight: FontWeight.w600)),
                          Text('${s[0]} · ${s[2]}', style: AppText.sans(size: 11, color: AppColors.ink3)),
                        ],
                      ),
                    ),
                    if (active) const Icon(AppIcons.check, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _pickScope(String key, String label, List<String> opts) {
    showAppSheet(
      context: context,
      title: 'Select $label',
      builder: (ctx, setSheet) {
        final selected = _scope[key]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: opts.map((o) {
                  final on = selected.contains(o);
                  return ChoiceChipX(
                    label: o,
                    active: on,
                    showCheck: true,
                    onTap: () => setSheet(() {
                      if (on) {
                        selected.remove(o);
                      } else {
                        selected.add(o);
                      }
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: AppButton(label: 'Clear', variant: BtnVariant.ghost, onTap: () => setSheet(() => selected.clear()))),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: AppButton(label: 'Done', onTap: () => Navigator.pop(ctx))),
                ],
              ),
            ],
          ),
        );
      },
    ).then((_) => setState(() {}));
  }

  void _confirmStart() {
    showAppModal(
      context: context,
      icon: AppIcons.play,
      tone: ModalTone.primary,
      title: 'Start Inventory Count?',
      body: 'This will lock stock movements for ${_countType.toLowerCase()} scope and notify ${_team.length} counters. Status will change to In Progress.',
      actions: [
        Expanded(child: AppButton(label: 'Cancel', variant: BtnVariant.ghost, onTap: () => Navigator.pop(context))),
        const SizedBox(width: 8),
        Expanded(
          child: AppButton(
            label: 'Yes, Start',
            icon: AppIcons.check,
            onTap: () {
              Navigator.pop(context); // close modal
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => const CountingScreen(
                  baseCount: CountSummary(
                    id: 'IC-2026-0185',
                    store: 'WH-Mumbai-01',
                    storeName: 'Mumbai Central WH',
                    type: 'Full Count',
                    status: 'progress',
                    variance: 0,
                    varianceQty: 0,
                    counted: 0,
                    total: 8,
                    updated: 'now',
                    supervisor: 'A. Mehta',
                  ),
                ),
              ));
            },
          ),
        ),
      ],
    );
  }
}
