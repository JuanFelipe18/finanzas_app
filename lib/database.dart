import 'package:sqflite/sqflite.dart';
import 'models/gasto_antiguo.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _db;
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
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE configuracion (
            clave TEXT PRIMARY KEY,
            valor TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE fijos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            descripcion TEXT,
            monto REAL,
            icono TEXT DEFAULT '🔒'
          )
        ''');

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

        await db.execute('''
          CREATE TABLE ahorros (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            descripcion TEXT,
            monto REAL,
            fecha TEXT
          )
        ''');

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
        if (oldVersion < 4) {
          await db.execute("ALTER TABLE fijos ADD COLUMN icono TEXT DEFAULT '🔒'");
        }
        if (oldVersion < 5) {
          await db.execute("ALTER TABLE fijos ADD COLUMN fecha_pago INTEGER");
          await db.execute("ALTER TABLE fijos ADD COLUMN recordatorio_dias INTEGER DEFAULT 0");
          await db.execute("ALTER TABLE fijos ADD COLUMN recordatorio_activo INTEGER DEFAULT 0");
        }
      },
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
    static Future<void> insertarFijo(String descripcion, double monto, {
    String icono = '🔒',
    int? fechaPago,
    int recordatorioDias = 0,
    int recordatorioActivo = 0,
  }) async {
    final database = await db;
    await database.insert('fijos', {
      'descripcion': descripcion,
      'monto': monto,
      'icono': icono,
      'fecha_pago': fechaPago,
      'recordatorio_dias': recordatorioDias,
      'recordatorio_activo': recordatorioActivo,
    });
  }

  static Future<void> actualizarFijo(int id, String descripcion, double monto, {
    String icono = '🔒',
    int? fechaPago,
    int recordatorioDias = 0,
    int recordatorioActivo = 0,
  }) async {
    final database = await db;
    await database.update('fijos', {
      'descripcion': descripcion,
      'monto': monto,
      'icono': icono,
      'fecha_pago': fechaPago,
      'recordatorio_dias': recordatorioDias,
      'recordatorio_activo': recordatorioActivo,
    }, where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> obtenerFijos() async {
    final database = await db;
    return await database.query('fijos');
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
  // --- DATOS DE PRUEBA ---
  static Future<void> cargarDatosPrueba() async {
    final database = await db;

    // 1. Configuración base
    await guardarSalario(2869895);
    await guardarConfiguracion('meta_ahorro', '1400000');
    await guardarConfiguracion('tipo_presupuesto', 'Mensual');
    await completarOnboarding();

    // 2. Fijos (los que me pasaste)
    final fijosPrueba = [
      {'desc': 'Devolver Ahorro', 'monto': 400000.0, 'icono': '💰'},
      {'desc': 'PS Plus', 'monto': 55000.0, 'icono': '🎮'},
      {'desc': 'Gatos', 'monto': 60000.0, 'icono': '🐱'},
      {'desc': 'HBO', 'monto': 18900.0, 'icono': '🎬'},
      {'desc': 'Celular', 'monto': 43900.0, 'icono': '📱'},
      {'desc': 'Ayuda aseo', 'monto': 70000.0, 'icono': '🧹'},
      {'desc': 'Transporte', 'monto': 177730.0, 'icono': '🚌'},
      {'desc': 'Almuerzo Cumpleaños', 'monto': 80000.0, 'icono': '🎂'},
    ];
    for (final f in fijosPrueba) {
      await insertarFijo(f['desc'] as String, f['monto'] as double, icono: f['icono'] as String);
    }

    // 3. Gastos de ejemplo distribuidos en el mes actual
    final ahora = DateTime.now();
    final y = ahora.year;
    final m = ahora.month;

    final gastosRaw = [
      {'dia': 2,  'desc': 'Almuerzo oficina', 'monto': 18500,  'cat': 'Alimentación',      'met': 'Débito',  'cuotas': 1},
      {'dia': 3,  'desc': 'Uber',             'monto': 12300,  'cat': 'Transporte',        'met': 'Débito',  'cuotas': 1},
      {'dia': 3,  'desc': 'Café',             'monto': 8500,   'cat': 'Alimentación',      'met': 'Débito',  'cuotas': 1},
      {'dia': 5,  'desc': 'Cine',             'monto': 35000,  'cat': 'Entretenimiento',   'met': 'Crédito', 'cuotas': 2},
      {'dia': 8,  'desc': 'Supermercado',     'monto': 145000, 'cat': 'Hogar',             'met': 'Débito',  'cuotas': 1},
      {'dia': 10, 'desc': 'Gasolina',         'monto': 78000,  'cat': 'Transporte',        'met': 'Débito',  'cuotas': 1},
      {'dia': 12, 'desc': 'Paracetamol',      'monto': 12500,  'cat': 'Salud',             'met': 'Débito',  'cuotas': 1},
      {'dia': 15, 'desc': 'Netflix',          'monto': 16900,  'cat': 'Entretenimiento',   'met': 'Crédito', 'cuotas': 1},
      {'dia': 18, 'desc': 'Pizza',            'monto': 42000,  'cat': 'Alimentación',      'met': 'Débito',  'cuotas': 1},
      {'dia': 20, 'desc': 'Libro',            'monto': 35000,  'cat': 'Educación',         'met': 'Débito',  'cuotas': 1},
      {'dia': 22, 'desc': 'Ropa',             'monto': 89000,  'cat': 'Ropa',              'met': 'Crédito', 'cuotas': 3},
      {'dia': 25, 'desc': 'Gimnasio',         'monto': 65000,  'cat': 'Salud',             'met': 'Débito',  'cuotas': 1},
    ];

    for (final g in gastosRaw) {
      final fecha = DateTime(y, m, g['dia'] as int);
      await database.insert('gastos', {
        'descripcion': g['desc'],
        'monto': g['monto'],
        'categoria': g['cat'],
        'metodo_pago': g['met'],
        'tipo': 'Gasto',
        'cuotas': g['cuotas'],
        'fecha': fecha.toIso8601String(),
      });
    }
  }
}