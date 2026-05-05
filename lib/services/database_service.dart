import 'package:flutter/foundation.dart';
import 'package:mysql_client/mysql_client.dart';

// Gestiona la conexión con MySQL y expone los métodos
// query() e insert() que usan todos los repositorios.
class DatabaseService {
  MySQLConnection? _connection;

  //  NUBE 
  // static const String _host     = 'autorack.proxy.rlwy.net';
  // static const int    _port     = 44534;
  // static const String _password = 'ptXcSGxBuJkZKNgKwBKVgMtkSJJyLYTK';
  // static const bool   _secure   = true;

  //LOCAL 
  // En Android el emulador usa 10.0.2.2 para referirse al PC host
  static String get _host =>
      defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';
  static const int    _port     = 3306;
  static const bool   _secure   = true;

  static const String _user     = 'root';
  static const String _password = '1234';
  static const String _database = 'mssve';

  // Abre la conexión — se llama una sola vez al arrancar la app
  Future<void> connect() async {
    _connection = await MySQLConnection.createConnection(
      host: _host,
      port: _port,
      userName: _user,
      password: _password,
      databaseName: _database,
      secure: _secure,
    );
    await _connection!.connect();
  }

  // Ejecuta SELECT y devuelve los resultados como lista de Maps
  Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<Object?> params = const [],
  ]) async {
    _checkConnection();
    final prepared = _prepararParams(sql, params);
    final result = await _connection!.execute(prepared.sql, prepared.params);
    return result.rows.map((row) => row.typedAssoc()).toList();
  }

  // Ejecuta INSERT y devuelve el id generado por AUTO_INCREMENT
  Future<int> insert(String sql, [List<Object?> params = const []]) async {
    _checkConnection();
    final prepared = _prepararParams(sql, params);
    final result = await _connection!.execute(prepared.sql, prepared.params);
    return result.lastInsertID.toInt();
  }

  // mysql_client necesita parámetros nombrados (:p0, :p1...)
  // en lugar de los ? posicionales del SQL estándar
  _PreparedQuery _prepararParams(String sql, List<Object?> params) {
    if (params.isEmpty) return _PreparedQuery(sql: sql, params: null);
    final Map<String, dynamic> namedParams = {};
    int index = 0;
    final sqlConNombres = sql.replaceAllMapped(RegExp(r'\?'), (match) {
      final key = 'p$index';
      namedParams[key] = params[index]?.toString();
      index++;
      return ':$key';
    });
    return _PreparedQuery(sql: sqlConNombres, params: namedParams);
  }

  void _checkConnection() {
    if (_connection == null) throw Exception('DatabaseService: llama a connect() primero.');
  }

  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
}

// Agrupa el SQL procesado con sus parámetros nombrados
class _PreparedQuery {
  final String sql;
  final Map<String, dynamic>? params;
  const _PreparedQuery({required this.sql, required this.params});
}