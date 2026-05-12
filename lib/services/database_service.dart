import 'package:mysql_client/mysql_client.dart';



// Servicio de conexion MySQL con migraciones automaticas y sistema de parametros nombrados
class DatabaseService {
  MySQLConnection? _connection;
  static const String _host     = 'sql8.freesqldatabase.com';
  static const int    _port     = 3306;
  static const String _user     = 'sql8825716';
  static const String _password = 'mTKy8mbhj5';
  static const String _database = 'sql8825716';
  static const bool   _secure   = false;

  
// Conecta a MySQL remoto y ejecuta migraciones para mantener esquema actualizado
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
    await _ejecutarMigraciones();
  }

  
// Migraciones automaticas: agrega columnas faltantes sin intervencion manual
  Future<void> _ejecutarMigraciones() async {
    try {
      final check = await _connection!.execute(
        "SHOW COLUMNS FROM sesion_ejercicio LIKE 'duracion_minutos'",
      );
      if (check.rows.isEmpty) {
        await _connection!.execute(
          'ALTER TABLE sesion_ejercicio ADD COLUMN duracion_minutos INT NULL',
        );
      }
    } catch (_) {}
  }

  
  Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<Object?> params = const [],
  ]) async {
    _checkConnection();
    final prepared = _prepararParams(sql, params);
// Convierte ? posicionales a :p0, :p1... para el driver MySQL que usa parametros nombrados
    final result = await _connection!.execute(prepared.sql, prepared.params);
    return result.rows.map((row) => row.typedAssoc()).toList();
  }

  
  Future<int> insert(String sql, [List<Object?> params = const []]) async {
    _checkConnection();
    final prepared = _prepararParams(sql, params);
// Convierte ? posicionales a :p0, :p1... para el driver MySQL que usa parametros nombrados
    final result = await _connection!.execute(prepared.sql, prepared.params);
    return result.lastInsertID.toInt();
  }

  
  
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


class _PreparedQuery {
  final String sql;
  final Map<String, dynamic>? params;
  const _PreparedQuery({required this.sql, required this.params});
}