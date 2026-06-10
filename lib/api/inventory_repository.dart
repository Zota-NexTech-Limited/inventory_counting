// Inventory Counts + Count Items + master data, mapped onto the app's UI models.
//
// Endpoint coverage (from the API sheet):
//   /inventory-counts (+ /start /submit /approve /reject /recount)
//   /inventory-count-items (+ /scan, by-count)
//   /warehouses /zones /racks /categories /products /batches
//   /inventory-locations /approvals /audit
//
// Field names are not specified in the sheet, so mappers use tolerant readers.
// When you share one sample JSON per endpoint, only this file needs edits.
import 'api_client.dart';
import 'json_utils.dart';
import '../models/data.dart';
import '../theme/tokens.dart';

class InventoryRepository {
  InventoryRepository._();
  static final InventoryRepository instance = InventoryRepository._();
  final _api = ApiClient.instance;

  // ── Inventory Counts ────────────────────────────────────────
  Future<List<CountSummary>> listCounts({String? status, String? countType}) async {
    final data = await _api.get('/inventory-counts', query: {
      'status': ?status,
      'countType': ?countType,
    });
    return asList(data).map(_count).toList();
  }

  Future<CountSummary> getCount(String id) async {
    final data = await _api.get('/inventory-counts/$id');
    return _count(asMap(data) ?? {});
  }

  Future<CountSummary> createCount(Map<String, dynamic> body) async {
    final data = await _api.post('/inventory-counts', body: body);
    return _count(asMap(data) ?? {});
  }

  Future<void> startCount(String id) => _api.post('/inventory-counts/$id/start');
  Future<void> submitCount(String id) => _api.post('/inventory-counts/$id/submit');
  Future<void> approveCount(String id) => _api.post('/inventory-counts/$id/approve');
  Future<void> rejectCount(String id, {required String reason, String? remarks}) =>
      _api.post('/inventory-counts/$id/reject', body: {'reason': reason, 'remarks': ?remarks});
  Future<void> recount(String id, Map<String, dynamic> body) =>
      _api.post('/inventory-counts/$id/recount', body: body);

  // ── Count Items ─────────────────────────────────────────────
  Future<List<CountItem>> itemsByCount(String countId) async {
    final data = await _api.get('/inventory-count-items/by-count/$countId');
    return asList(data).map(_item).toList();
  }

  Future<CountItem> scanItem(String countId, String barcode) async {
    final data = await _api.post('/inventory-count-items/scan', body: {'countId': countId, 'barcode': barcode});
    return _item(asMap(data) ?? {});
  }

  Future<CountItem> addItem(Map<String, dynamic> body) async {
    final data = await _api.post('/inventory-count-items', body: body);
    return _item(asMap(data) ?? {});
  }

  Future<void> updateItemQty(String itemId, Map<String, dynamic> body) =>
      _api.patch('/inventory-count-items/$itemId', body: body);

  // ── Master data ─────────────────────────────────────────────
  Future<List<NamedRef>> warehouses() async => asList(await _api.get('/warehouses')).map(_named).toList();
  Future<List<NamedRef>> categories() async => asList(await _api.get('/categories')).map(_named).toList();
  Future<List<NamedRef>> products({String? categoryId}) async =>
      asList(await _api.get('/products', query: {'categoryId': ?categoryId})).map(_named).toList();
  Future<List<NamedRef>> batches({String? productId}) async =>
      asList(await _api.get('/batches', query: {'productId': ?productId})).map(_named).toList();
  Future<List<Rack>> racks({String? warehouseId, String? zoneId}) async => asList(await _api.get('/racks', query: {
        'warehouseId': ?warehouseId,
        'zoneId': ?zoneId,
      })).map(_rack).toList();

  // ── Audit / Approvals ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> auditFor(String countId) async =>
      asList(await _api.get('/audit/InventoryCount/$countId'));
  Future<List<Map<String, dynamic>>> approvalHistory(String countId) async =>
      asList(await _api.get('/approvals/by-count/$countId'));

  // ── Mappers ─────────────────────────────────────────────────
  static String _normStatus(String raw) {
    switch (raw.toUpperCase().replaceAll(' ', '_')) {
      case 'DRAFT':
        return kStatusDraft;
      case 'IN_PROGRESS':
      case 'INPROGRESS':
      case 'STARTED':
      case 'COUNTING':
        return kStatusProgress;
      case 'SUBMITTED':
      case 'PENDING':
      case 'IN_REVIEW':
        return kStatusSubmitted;
      case 'APPROVED':
        return kStatusApproved;
      case 'POSTED':
      case 'COMPLETED':
        return kStatusPosted;
      case 'REJECTED':
        return kStatusRejected;
      default:
        return raw.toLowerCase();
    }
  }

  static const Map<String, String> _typeLabel = {
    'FULL': 'Full Count',
    'CATEGORY': 'Category-wise',
    'ITEM': 'Item-wise',
    'RACK': 'Rack-wise',
    'BATCH': 'Batch-wise',
    'CYCLE': 'Cycle Count',
  };

  CountSummary _count(Map<String, dynamic> j) {
    final type = pickString(j, ['countType', 'type'], fallback: 'FULL');
    final wh = asMap(j['warehouse']);
    return CountSummary(
      id: pickString(j, ['countNumber', 'code', 'reference', 'id', '_id'], fallback: '—'),
      store: pickString(j, ['warehouseId', 'warehouseCode'], fallback: pickId(wh) ?? ''),
      storeName: pickString(wh, ['name'], fallback: pickString(j, ['warehouseName', 'storeName'], fallback: 'Warehouse')),
      type: _typeLabel[type.toUpperCase()] ?? type,
      status: _normStatus(pickString(j, ['status'], fallback: 'draft')),
      variance: pickNum(j, ['varianceValue', 'totalVariance', 'variance']),
      varianceQty: pickInt(j, ['varianceQty', 'itemsDelta', 'varianceQuantity']),
      counted: pickInt(j, ['countedItems', 'counted', 'itemsCounted']),
      total: pickInt(j, ['totalItems', 'total', 'itemCount'], fallback: 1),
      updated: pickString(j, ['updatedAtLabel', 'updatedAt', 'modifiedAt'], fallback: ''),
      supervisor: pickString(asMap(j['supervisor']), ['name'], fallback: pickString(j, ['supervisorName'], fallback: '—')),
    );
  }

  CountItem _item(Map<String, dynamic> j) {
    final product = asMap(j['product']) ?? j;
    final batch = asMap(j['batch']);
    final rack = asMap(j['rack']) ?? asMap(j['expectedRack']);
    final found = asMap(j['foundRack']);
    final system = pickInt(j, ['systemQty', 'systemQuantity', 'expectedQty', 'availableQty']);
    final physical = pickInt(j, ['physicalQty', 'countedQty', 'physicalQuantity', 'countedQuantity']);
    return CountItem(
      code: pickString(product, ['barcode', 'sku', 'code'], fallback: pickString(j, ['productCode'], fallback: '')),
      name: pickString(product, ['name', 'productName'], fallback: 'Item'),
      batch: pickString(batch, ['batchNumber', 'code', 'name'], fallback: pickString(j, ['batchNumber'], fallback: '—')),
      exp: pickString(batch, ['expiry', 'expiryDate', 'expDate'], fallback: pickString(j, ['expiry'], fallback: '—')),
      uom: pickString(product, ['uom', 'unit'], fallback: pickString(j, ['uom'], fallback: 'PCS')),
      mrp: pickDouble(product, ['mrp']),
      sp: pickDouble(product, ['sellingPrice', 'sp', 'price']),
      system: system,
      physical: physical,
      reason: pickString(j, ['reason', 'varianceReason']),
      remarks: pickString(j, ['remarks', 'note', 'comment']),
      expectedRack: pickString(rack, ['code', 'name', 'rackCode'], fallback: pickString(j, ['expectedRack', 'rackCode'], fallback: '')),
      bin: pickString(j, ['bin', 'binCode'], fallback: pickString(rack, ['bin'], fallback: '')),
      foundRack: found == null ? null : pickString(found, ['code', 'name'], fallback: ''),
      counted: pickBool(j, ['counted', 'isCounted']) || physical > 0,
    );
  }

  NamedRef _named(Map<String, dynamic> j) => NamedRef(
        id: pickId(j) ?? '',
        name: pickString(j, ['name', 'title', 'label', 'code'], fallback: '—'),
        meta: pickString(j, ['description', 'code', 'address']),
      );

  Rack _rack(Map<String, dynamic> j) => Rack(
        id: pickString(j, ['code', 'rackCode', 'name'], fallback: pickId(j) ?? '—'),
        zone: pickString(asMap(j['zone']), ['name'], fallback: pickString(j, ['zoneName'], fallback: 'Zone')),
        bins: pickInt(j, ['binCount', 'bins', 'totalBins'], fallback: 0),
      );
}

/// Lightweight id/name pair for master-data pickers (warehouses, categories…).
class NamedRef {
  final String id;
  final String name;
  final String meta;
  const NamedRef({required this.id, required this.name, this.meta = ''});
}
