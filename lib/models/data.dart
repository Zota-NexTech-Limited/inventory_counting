// Sample data + models — mirrors data.jsx and the RACKS list in screens-3.
import 'package:flutter/foundation.dart';

@immutable
class CountSummary {
  final String id;
  final String store;
  final String storeName;
  final String type;
  final String status;
  final num variance;
  final int varianceQty;
  final int counted;
  final int total;
  final String updated;
  final String supervisor;

  const CountSummary({
    required this.id,
    required this.store,
    required this.storeName,
    required this.type,
    required this.status,
    required this.variance,
    required this.varianceQty,
    required this.counted,
    required this.total,
    required this.updated,
    required this.supervisor,
  });
}

class CountItem {
  final String code;
  final String name;
  final String batch;
  final String exp;
  final String uom;
  final double mrp;
  final double sp; // selling price
  final int system;
  int physical;
  String reason;
  String remarks;
  final String expectedRack;
  final String? bin;
  String? foundRack;
  bool counted;
  List<String> images;

  CountItem({
    required this.code,
    required this.name,
    required this.batch,
    required this.exp,
    required this.uom,
    required this.mrp,
    required this.sp,
    required this.system,
    this.physical = 0,
    this.reason = '',
    this.remarks = '',
    required this.expectedRack,
    this.bin,
    this.foundRack,
    this.counted = false,
    List<String>? images,
  }) : images = images ?? [];

  CountItem copy() => CountItem(
        code: code,
        name: name,
        batch: batch,
        exp: exp,
        uom: uom,
        mrp: mrp,
        sp: sp,
        system: system,
        physical: physical,
        reason: reason,
        remarks: remarks,
        expectedRack: expectedRack,
        bin: bin,
        foundRack: foundRack,
        counted: counted,
        images: List.of(images),
      );

  int get diff => physical - system;
  bool get expSoon => exp.startsWith('04/2026');
  bool get misplaced =>
      counted && foundRack != null && foundRack != expectedRack;
}

@immutable
class Rack {
  final String id;
  final String zone;
  final int bins;
  const Rack({required this.id, required this.zone, required this.bins});
}

const List<Rack> kRacks = [
  Rack(id: 'A-Bay-12', zone: 'Zone A · Pharma', bins: 12),
  Rack(id: 'B-Bay-04', zone: 'Zone B · Pharma', bins: 8),
  Rack(id: 'C-Bay-09', zone: 'Zone C · Cold', bins: 6),
  Rack(id: 'D-Bay-02', zone: 'Zone D · FMCG', bins: 10),
];

const List<String> kRackOptions = [
  'A-Bay-12',
  'B-Bay-04',
  'C-Bay-09',
  'D-Bay-02',
  'E-Bay-07',
];

const List<CountSummary> kCounts = [
  CountSummary(
    id: 'IC-2026-0184',
    store: 'WH-Mumbai-01',
    storeName: 'Mumbai Central WH',
    type: 'Full Count',
    status: 'progress',
    variance: -12450,
    varianceQty: -86,
    counted: 142,
    total: 320,
    updated: '2 min ago',
    supervisor: 'A. Mehta',
  ),
  CountSummary(
    id: 'IC-2026-0183',
    store: 'WH-Pune-02',
    storeName: 'Pune Hinjewadi DC',
    type: 'Category-wise',
    status: 'submitted',
    variance: 8420,
    varianceQty: 24,
    counted: 89,
    total: 89,
    updated: '14 min ago',
    supervisor: 'R. Iyer',
  ),
  CountSummary(
    id: 'IC-2026-0182',
    store: 'WH-Mumbai-01',
    storeName: 'Mumbai Central WH',
    type: 'Rack-wise',
    status: 'approved',
    variance: -2150,
    varianceQty: -8,
    counted: 47,
    total: 47,
    updated: '1 hr ago',
    supervisor: 'A. Mehta',
  ),
  CountSummary(
    id: 'IC-2026-0181',
    store: 'WH-Bangalore-03',
    storeName: 'Bangalore Whitefield',
    type: 'Batch-wise',
    status: 'posted',
    variance: -940,
    varianceQty: -4,
    counted: 22,
    total: 22,
    updated: '3 hrs ago',
    supervisor: 'K. Rao',
  ),
  CountSummary(
    id: 'IC-2026-0180',
    store: 'WH-Mumbai-01',
    storeName: 'Mumbai Central WH',
    type: 'Item-wise',
    status: 'draft',
    variance: 0,
    varianceQty: 0,
    counted: 0,
    total: 12,
    updated: 'Yesterday',
    supervisor: 'A. Mehta',
  ),
  CountSummary(
    id: 'IC-2026-0179',
    store: 'WH-Pune-02',
    storeName: 'Pune Hinjewadi DC',
    type: 'Full Count',
    status: 'posted',
    variance: 14820,
    varianceQty: 41,
    counted: 612,
    total: 612,
    updated: '2 days ago',
    supervisor: 'R. Iyer',
  ),
  CountSummary(
    id: 'IC-2026-0178',
    store: 'WH-Delhi-04',
    storeName: 'Delhi Bawana DC',
    type: 'Category-wise',
    status: 'posted',
    variance: -3210,
    varianceQty: -19,
    counted: 156,
    total: 156,
    updated: '4 days ago',
    supervisor: 'S. Khan',
  ),
];

/// Master item catalogue. Returns fresh copies so screens can mutate freely.
List<CountItem> seedItems() => [
      CountItem(code: 'PHA-AMX-500', name: 'Amoxicillin 500mg Cap', batch: 'B24-0871', exp: '08/2026', uom: 'BOX', mrp: 185.00, sp: 162.50, system: 480, physical: 472, reason: 'Damaged', remarks: 'Box 4 leaking', expectedRack: 'A-Bay-12', bin: 'A12-03'),
      CountItem(code: 'PHA-PCM-650', name: 'Paracetamol 650mg Tab', batch: 'B25-1142', exp: '11/2026', uom: 'STR', mrp: 28.00, sp: 24.20, system: 1200, physical: 1240, reason: 'Misplaced', remarks: 'Found in rack B-04', expectedRack: 'A-Bay-12', bin: 'A12-04', foundRack: 'B-Bay-04'),
      CountItem(code: 'PHA-CET-10', name: 'Cetirizine 10mg Tab', batch: 'B24-0993', exp: '04/2026', uom: 'STR', mrp: 38.50, sp: 33.80, system: 860, physical: 832, reason: 'Expired', remarks: 'Near expiry, segregated', expectedRack: 'A-Bay-12', bin: 'A12-07'),
      CountItem(code: 'FMC-SHM-200', name: 'Herbal Shampoo 200ml', batch: 'B25-2003', exp: '06/2027', uom: 'PCS', mrp: 245.00, sp: 215.00, system: 240, physical: 246, reason: 'Returns', remarks: '', expectedRack: 'A-Bay-12', bin: 'A12-11'),
      CountItem(code: 'PHA-VIT-D3', name: 'Vitamin D3 60K IU', batch: 'B25-1188', exp: '09/2026', uom: 'STR', mrp: 78.00, sp: 68.50, system: 320, physical: 295, reason: 'Theft', remarks: 'CCTV pull requested', expectedRack: 'B-Bay-04', bin: 'B04-02'),
      CountItem(code: 'FMC-TPS-100', name: 'Toothpaste 100g', batch: 'B25-2114', exp: '10/2027', uom: 'PCS', mrp: 125.00, sp: 108.00, system: 540, physical: 540, reason: '', remarks: '', expectedRack: 'B-Bay-04', bin: 'B04-05'),
      CountItem(code: 'PHA-INS-30', name: 'Insulin Pen 30U', batch: 'B26-0044', exp: '02/2027', uom: 'PCS', mrp: 940.00, sp: 845.00, system: 84, physical: 80, reason: 'Damaged', remarks: 'Cold chain check', expectedRack: 'C-Bay-09', bin: 'C09-01'),
      CountItem(code: 'FMC-SOAP-75', name: 'Bath Soap 75g (3pk)', batch: 'B25-2210', exp: '12/2027', uom: 'PCS', mrp: 95.00, sp: 82.50, system: 1100, physical: 1108, reason: '', remarks: '', expectedRack: 'D-Bay-02'),
    ];
