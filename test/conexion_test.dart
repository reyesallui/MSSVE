import 'package:flutter_test/flutter_test.dart';
import 'package:mysql_client/mysql_client.dart';

// Prueba de conexión real a la base de datos MySQL.
// Requiere que MySQL esté arrancado antes de ejecutar este test.
// Ejecutar solo este test: flutter test test/conexion_test.dart
void main() {
  const host     = '127.0.0.1';
  const port     = 3306;
  const user     = 'root';
  const password = '1234';
  const db       = 'mssve';

  test('Conexión a MySQL: se conecta y ejecuta una consulta simple', () async {
    MySQLConnection? conn;

    try {
      conn = await MySQLConnection.createConnection(
        host:     host,
        port:     port,
        userName: user,
        password: password,
        databaseName: db,
        secure: true,
      );

      await conn.connect();
      expect(conn.connected, isTrue,
          reason: 'La conexión a MySQL debería estar activa');

      // SELECT 1 es la forma estándar de verificar que la BD responde
      final result = await conn.execute('SELECT 1 AS test');
      expect(result.rows.isNotEmpty, isTrue,
          reason: 'SELECT 1 debe devolver al menos una fila');

      final valor = result.rows.first.colByName('test');
      expect(valor, equals('1'),
          reason: 'SELECT 1 debe devolver el valor 1');

    } catch (e) {
      fail('No se pudo conectar a MySQL: $e\n'
          'Comprueba que MySQL está arrancado y que los datos de conexión son correctos.');
    } finally {
      await conn?.close();
    }
  });

  test('Conexión a MySQL: las tablas principales existen', () async {
    MySQLConnection? conn;

    try {
      conn = await MySQLConnection.createConnection(
        host:     host,
        port:     port,
        userName: user,
        password: password,
        databaseName: db,
        secure: true,
      );

      await conn.connect();

      // Comprobamos que las tablas principales existen
      final tablas = [
        'usuarios',
        'ejercicios',
        'rutinas',
        'rutina_ejercicio',
        'sesiones_entrenamiento',
        'sesion_ejercicio',
        'registros_diarios',
        'comidas',
        'comida_alimento',
        'alimentos',
      ];

      for (final tabla in tablas) {
        final result = await conn.execute(
          'SELECT COUNT(*) AS n FROM information_schema.tables '
          "WHERE table_schema = '$db' AND table_name = '$tabla'",
        );
        final existe =
            result.rows.first.colByName('n') != '0';
        expect(existe, isTrue,
            reason: 'La tabla "$tabla" debe existir en la BD');
      }

    } catch (e) {
      fail('Error al comprobar tablas: $e');
    } finally {
      await conn?.close();
    }
  });
}