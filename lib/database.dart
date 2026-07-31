// lib/database.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/gasto.dart';

class DatabaseHelper {
  static Database? _db;
  // FIX: Evita que _initDB se ejecute 2 veces si hay llamadas simultáneas
  static Future<Database>? _dbFuture;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _dbFuture ??= _initDB().then((database) {
      _db = database;
      return database;
    });
    return _dbFuture!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'monai_local.db');

    return openDatabase(
      path,
      version: 3, // VERSIÓN 3 (Soporta Tipo y Cuotas)
      onCreate: (db, version) async {
        // 1. Tabla Configuracion
        await db.execute('''
          CREATE TABLE configuracion (
            clave TEXT PRIMARY KEY,
            valor TEXT
          )
        ''');

        // 2. Tabla Fijos
        await db.execute('''
          CREATE TABLE fijos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            descripcion TEXT,
            monto REAL
          )
        ''');

        // 3. Tabla Gastos (Actualizada con tipo y cuotas)
        await db.execute('''
          CREATE TABLE gastos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            descripcion TEXT,
            monto REAL,
            categoria TEXT,
            metodo_pago TEXT,
            fecha TEXT,
            tipo TEXT DEFAULT 'Gasto',
            cuotas INTEGER DEFAULT 1
          )
        ''');
        
        await db.execute('CREATE INDEX IF NOT EXISTS idx_gastos_fecha ON gastos(fecha)');

        // 4. Tabla Ahorros
        await db.execute('''
          CREATE TABLE ahorros (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            descripcion TEXT,
            monto REAL,
            fecha TEXT
          )
        ''');

        // Valores por defecto
        await db.insert('configuracion', {'clave': 'onboarding_completo', 'valor': 'false'});
        await db.insert('configuracion', {'clave': 'salario', 'valor': '0.0'});
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE gastos ADD COLUMN tipo TEXT DEFAULT 'Gasto'");
        }
        if (oldVersion < 3) {
          await db.execute("ALTER TABLE gastos ADD COLUMN cuotas INTEGER DEFAULT 1");
        }
      }
    );
  }

  // --- MÉTODOS DE CONFIGURACIÓN ---
  static Future<void> guardarSalario(double monto) async {
    final database = await db;
    final res = await database.query('configuracion', where: 'clave = ?', whereArgs: ['salario']);
    if (res.isEmpty) {
      await database.insert('configuracion', {'clave': 'salario', 'valor': monto.toString()});
    } else {
      await database.update('configuracion', {'valor': monto.toString()}, where: 'clave = ?', whereArgs: ['salario']);
    }
  }

  static Future<double> obtenerSalario() async {
    final database = await db;
    final res = await database.query('configuracion', where: 'clave = ?', whereArgs: ['salario']);
    if (res.isNotEmpty) return double.tryParse(res.first['valor'] as String) ?? 0.0;
    return 0.0;
  }

  static Future<void> completarOnboarding() async {
    final database = await db;
    await database.insert('configuracion', {'clave': 'onboarding_completo', 'valor': 'true'}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<bool> esOnboardingCompleto() async {
    final database = await db;
    final res = await database.query('configuracion', where: 'clave = ?', whereArgs: ['onboarding_completo']);
    if (res.isNotEmpty) return res.first['valor'] == 'true';
    return false;
  }

  // --- MÉTODOS PARA FIJOS ---
  static Future<void> insertarFijo(String descripcion, double monto) async {
    final database = await db;
    await database.insert('fijos', {'descripcion': descripcion, 'monto': monto});
  }

  static Future<List<Map<String, dynamic>>> obtenerFijos() async {
    final database = await db;
    return await database.query('fijos');
  }

  static Future<void> actualizarFijo(int id, String descripcion, double monto) async {
    final database = await db;
    await database.update('fijos', {'descripcion': descripcion, 'monto': monto}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> eliminarFijo(int id) async {
    final database = await db;
    await database.delete('fijos', where: 'id = ?', whereArgs: [id]);
  }

  // --- MÉTODOS PARA VARIABLES (Diarios) ---
  static Future<void> insertarGasto(Gasto gasto) async {
    final database = await db;
    await database.insert('gastos', {
      'descripcion': gasto.descripcion,
      'monto': gasto.monto,
      'categoria': gasto.categoria,
      'metodo_pago': gasto.metodoPago,
      'tipo': gasto.tipoMovimiento, 
      'cuotas': gasto.cuotas, 
      'fecha': DateTime.now().toIso8601String(),
    });
  }
  
  static Future<List<Map<String, dynamic>>> obtenerGastos() async {
    final database = await db;
    return database.query('gastos', orderBy: 'fecha DESC');
  }
  
  static Future<void> actualizarGasto(int id, String descripcion, double monto, String categoria, String metodoPago, String fecha, String tipo, int cuotas) async {
    final database = await db;
    await database.update(
      'gastos',
      {'descripcion': descripcion, 'monto': monto, 'categoria': categoria, 'metodo_pago': metodoPago, 'fecha': fecha, 'tipo': tipo, 'cuotas': cuotas},
      where: 'id = ?', whereArgs: [id],
    );
  }

  static Future<void> eliminarGasto(int id) async {
    final database = await db;
    await database.delete('gastos', where: 'id = ?', whereArgs: [id]);
  }
  
  static Future<List<Map<String, dynamic>>> obtenerGastosPorMes(DateTime mes) async {
    final database = await db;
    String mesStr = mes.month.toString().padLeft(2, '0');
    String prefijoFecha = '${mes.year}-$mesStr-';
    return await database.query('gastos', where: 'fecha LIKE ?', whereArgs: ['$prefijoFecha%'], orderBy: 'fecha DESC, id DESC');
  }

  // --- MÉTODOS DE CONFIGURACIÓN UNIFICADOS ---
  static Future<String> obtenerConfiguracion(String clave, String valorPorDefecto) async {
    final database = await db;
    final res = await database.query('configuracion', where: 'clave = ?', whereArgs: [clave]);
    if (res.isNotEmpty) return res.first['valor'].toString();
    return valorPorDefecto;
  }

  static Future<void> guardarConfiguracion(String clave, String valor) async {
    final database = await db;
    final res = await database.query('configuracion', where: 'clave = ?', whereArgs: [clave]);
    if (res.isEmpty) {
      await database.insert('configuracion', {'clave': clave, 'valor': valor});
    } else {
      await database.update('configuracion', {'valor': valor}, where: 'clave = ?', whereArgs: [clave]);
    }
  }

  static Future<String> obtenerTipoPresupuesto() async => await obtenerConfiguracion('tipo_presupuesto', 'Mensual');
  
  static Future<void> guardarTipoPresupuesto(String tipo) async => await guardarConfiguracion('tipo_presupuesto', tipo);
  
  // --- MÉTODOS PARA CATEGORÍAS ---
  static Future<void> inicializarCategorias() async {
    final database = await db;

    await database.execute('''
      CREATE TABLE IF NOT EXISTS categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        icono TEXT NOT NULL,
        presupuesto REAL DEFAULT 0.0
      )
    ''');

    // 1. POBLACIÓN BASE SEGURA (Con flag para no revivir categorías que borres intencionalmente después)
    final checkBase = await database.query('configuracion', where: 'clave = ?', whereArgs: ['base_v3']);
    if (checkBase.isEmpty) {
      final existeAlimentacion = await database.query('categorias', where: 'nombre = ?', whereArgs: ['Alimentación']);
      if (existeAlimentacion.isEmpty) {
        final categoriasBase = [
          {'nombre': 'Alimentación', 'icono': '🍔'},
          {'nombre': 'Transporte', 'icono': '🚌'},
          {'nombre': 'Salud', 'icono': '🏥'},
          {'nombre': 'Entretenimiento', 'icono': '🎬'},
          {'nombre': 'Hogar', 'icono': '🏠'},
          {'nombre': 'Ropa', 'icono': '👕'},
          {'nombre': 'Educación', 'icono': '📚'},
          {'nombre': 'Otros', 'icono': '📁'}
        ];
        for (var c in categoriasBase) {
          await database.insert('categorias', c);
        }
      }
      await database.insert('configuracion', {'clave': 'base_v3', 'valor': 'true'});
    }

    // 2. Migración 1: Emojis antiguos
    final migracionCheck = await database.query('configuracion', where: 'clave = ?', whereArgs: ['categorias_migradas']);
    if (migracionCheck.isEmpty || migracionCheck.first['valor'] != 'true') {
      await database.rawUpdate("UPDATE categorias SET icono = '🍔' WHERE icono = 'restaurant'");
      await database.rawUpdate("UPDATE categorias SET icono = '🚌' WHERE icono = 'directions_bus'");
      await database.rawUpdate("UPDATE categorias SET icono = '🏥' WHERE icono = 'local_hospital'");
      await database.rawUpdate("UPDATE categorias SET icono = '🎬' WHERE icono = 'movie'");
      await database.rawUpdate("UPDATE categorias SET icono = '🏠' WHERE icono = 'home'");
      await database.rawUpdate("UPDATE categorias SET icono = '👕' WHERE icono = 'checkroom'");
      await database.rawUpdate("UPDATE categorias SET icono = '📚' WHERE icono = 'school'");
      await database.rawUpdate("UPDATE categorias SET icono = '📁' WHERE icono = 'category'");
      await database.insert('configuracion', {'clave': 'categorias_migradas', 'valor': 'true'}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    // 3. Migración 2: Inyectar categorías para Ingresos
    final migracionIngresos = await database.query('configuracion', where: 'clave = ?', whereArgs: ['cat_ingresos_v2']);
    if (migracionIngresos.isEmpty || migracionIngresos.first['valor'] != 'true') {
      await database.insert('categorias', {'nombre': 'Salario', 'icono': '💵', 'presupuesto': 0.0});
      await database.insert('categorias', {'nombre': 'Reembolso', 'icono': '🔄', 'presupuesto': 0.0});
      await database.insert('categorias', {'nombre': 'Ventas', 'icono': '🏷️', 'presupuesto': 0.0});
      await database.insert('configuracion', {'clave': 'cat_ingresos_v2', 'valor': 'true'}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerCategorias() async {
    final database = await db;
    return await database.query('categorias');
  }

  static Future<void> actualizarCategoria(int id, String nombre, String icono, double presupuesto) async {
    final database = await db;
    await database.update('categorias', {'nombre': nombre, 'icono': icono, 'presupuesto': presupuesto}, where: 'id = ?', whereArgs: [id]);
  }
  
  static Future<void> insertarCategoria(String nombre, String icono, double presupuesto) async {
    final database = await db;
    await database.insert('categorias', {'nombre': nombre, 'icono': icono, 'presupuesto': presupuesto});
  }

  static Future<void> eliminarCategoria(int id) async {
    final database = await db;
    await database.delete('categorias', where: 'id = ?', whereArgs: [id]);
  }
}