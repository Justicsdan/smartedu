import 'dart:convert';
import 'package:http/http.dart' as http;

class DbProxy {
  static final DbProxy instance = DbProxy._();
  DbProxy._();

  static const String _proxyUrl = 'https://tcjsmkhmfjigutfhjtem.supabase.co/functions/v1/db-proxy';
  static const String _authUrl = 'https://tcjsmkhmfjigutfhjtem.supabase.co/functions/v1/auth';
  static const String _anonKey = 'sb_publishable_zWDvjhEldcV8eutnlRypGA_LGpOUhkg';

  String? _token;
  String? get token => _token;
  bool get hasToken => _token != null;

  void setToken(String t) { _token = t; }
  void clearToken() { _token = null; }

  DbTableQuery from(String table) => DbTableQuery._(this, table);

  Future<dynamic> rpc(String name, {Map<String, dynamic>? params}) async {
    final body = await _post({'action': 'rpc', 'rpcName': name, 'rpcParams': params});
    return body['data'];
  }

  Future<Map<String, dynamic>> login(String role, String username, String password) async {
    final response = await http.post(
      Uri.parse(_authUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_anonKey'},
      body: jsonEncode({'role': role, 'username': username, 'password': password}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw DbProxyException(data['error'] ?? 'Login failed');
    }
    _token = data['token'] as String;
    return Map<String, dynamic>.from(data['user'] as Map);
  }

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    if (_token == null) throw DbProxyException('No authentication token. Please log in again.');
    final response = await http.post(
      Uri.parse(_proxyUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_anonKey', 'X-Auth-Token': _token!},
      body: jsonEncode(body),
    );
    if (response.body.isEmpty) throw DbProxyException('Empty response from server');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 401) { _token = null; throw DbProxyException('Session expired. Please log in again.'); }
    if (response.statusCode == 403) throw DbProxyException(data['error'] ?? 'Access denied');
    if (response.statusCode >= 400) throw DbProxyException(data['error'] ?? 'Request failed: ${response.statusCode}');
    return data;
  }
}

class DbTableQuery {
  final DbProxy _proxy;
  final String _table;
  String _select = '*';
  final List<Map<String, dynamic>> _filters = [];
  String? _orderCol;
  bool _orderAsc = true;
  int? _limit;
  int? _rangeFrom;
  int? _rangeTo;

  DbTableQuery._(this._proxy, this._table);

  DbTableQuery select([String? cols]) { _select = cols ?? '*'; return this; }

  DbTableQuery eq(String col, dynamic val) { _filters.add({'column': col, 'op': 'eq', 'value': val}); return this; }
  DbTableQuery neq(String col, dynamic val) { _filters.add({'column': col, 'op': 'neq', 'value': val}); return this; }
  DbTableQuery gt(String col, dynamic val) { _filters.add({'column': col, 'op': 'gt', 'value': val}); return this; }
  DbTableQuery gte(String col, dynamic val) { _filters.add({'column': col, 'op': 'gte', 'value': val}); return this; }
  DbTableQuery lt(String col, dynamic val) { _filters.add({'column': col, 'op': 'lt', 'value': val}); return this; }
  DbTableQuery lte(String col, dynamic val) { _filters.add({'column': col, 'op': 'lte', 'value': val}); return this; }
  DbTableQuery in_(String col, List val) { _filters.add({'column': col, 'op': 'in', 'value': val}); return this; }
  DbTableQuery isNull(String col) { _filters.add({'column': col, 'op': 'is', 'value': null}); return this; }
  DbTableQuery isNotNull(String col) { _filters.add({'column': col, 'op': 'is_not', 'value': null}); return this; }
  DbTableQuery like(String col, String val) { _filters.add({'column': col, 'op': 'like', 'value': val}); return this; }
  DbTableQuery ilike(String col, String val) { _filters.add({'column': col, 'op': 'ilike', 'value': val}); return this; }
  DbTableQuery not(String col, String operator, dynamic value) {
    final opMap = {'in': 'not_in', 'is': 'is_not', 'like': 'not_like', 'ilike': 'not_ilike'};
    _filters.add({'column': col, 'op': opMap[operator] ?? 'neq', 'value': value});
    return this;
  }

  DbTableQuery order(String col, {bool ascending = true}) { _orderCol = col; _orderAsc = ascending; return this; }
  DbTableQuery limit(int n) { _limit = n; return this; }
  DbTableQuery range(int from, int to) { _rangeFrom = from; _rangeTo = to; return this; }

  Future<List<Map<String, dynamic>>> get() async {
    final result = await _proxy._post(_buildBody('select'));
    return _parseList(result['data']);
  }

  Future<Map<String, dynamic>> single() async {
    final result = await _proxy._post(_buildBody('select', singleMode: true));
    final data = result['data'];
    if (data == null) throw DbProxyException('No row found (single)');
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>?> maybeSingle() async {
    final result = await _proxy._post(_buildBody('select', singleMode: 'maybe'));
    final data = result['data'];
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<Map<String, dynamic>>> insert(dynamic data) async {
    final result = await _proxy._post(_buildBody('insert', data: data));
    return _parseList(result['data']);
  }

  Future<List<Map<String, dynamic>>> update(dynamic data) async {
    final result = await _proxy._post(_buildBody('update', data: data));
    return _parseList(result['data']);
  }

  Future<List<Map<String, dynamic>>> upsert(dynamic data, {String? onConflict}) async {
    final result = await _proxy._post(_buildBody('upsert', data: data, onConflict: onConflict));
    return _parseList(result['data']);
  }

  Future<List<Map<String, dynamic>>> delete() async {
    final result = await _proxy._post(_buildBody('delete'));
    return _parseList(result['data']);
  }

  Map<String, dynamic> _buildBody(String action, {dynamic data, String? onConflict, dynamic singleMode = false}) {
    final body = <String, dynamic>{'action': action, 'table': _table};
    if (_select != '*') body['select'] = _select;
    if (_filters.isNotEmpty) body['filters'] = _filters;
    if (_orderCol != null) body['order'] = {'column': _orderCol, 'ascending': _orderAsc};
    if (_limit != null) body['limit'] = _limit;
    if (_rangeFrom != null && _rangeTo != null) body['range'] = [_rangeFrom, _rangeTo];
    if (data != null) body['data'] = data;
    if (onConflict != null) body['onConflict'] = onConflict;
    if (singleMode == true) body['single'] = true;
    else if (singleMode == 'maybe') body['single'] = 'maybe';
    return body;
  }

  List<Map<String, dynamic>> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is List) return List<Map<String, dynamic>>.from(data);
    return [Map<String, dynamic>.from(data as Map)];
  }
}

class DbProxyException implements Exception {
  final String message;
  DbProxyException(this.message);
  @override
  String toString() => 'DbProxyException: $message';
}
