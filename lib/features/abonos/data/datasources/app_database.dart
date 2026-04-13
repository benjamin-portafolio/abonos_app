import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'abonos.db';
  static const _dbVersion = 6;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, _dbName);

    _database = await openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return _database!;
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createComunidadTable(db);
    await _createClientesTable(db);
    await _createPrestamosTable(db);
    await _createCategoriaTable(db);
    await _createProductoTable(db);
    await _createPrestamoProductoTable(db);
    await _createAbonoTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS abono');
      await db.execute('DROP TABLE IF EXISTS prestamo_producto');
      await db.execute('DROP TABLE IF EXISTS producto');
      await db.execute('DROP TABLE IF EXISTS categoria');
      await db.execute('DROP TABLE IF EXISTS prestamos');
      await db.execute('DROP TABLE IF EXISTS clientes');
      await db.execute('DROP TABLE IF EXISTS clients');
      await db.execute('DROP TABLE IF EXISTS comunidad');

      await _onCreate(db, newVersion);
      return;
    }

    if (oldVersion < 5) {
      await db.execute('''
        ALTER TABLE producto
        ADD COLUMN precio_original REAL CHECK (precio_original >= 0)
      ''');
    }

    if (oldVersion < 6) {
      await _createCategoriaTable(db);

      await db.execute('''
        ALTER TABLE producto
        ADD COLUMN id_categoria TEXT REFERENCES categoria (id) ON UPDATE CASCADE
      ''');

      await db.execute('''
        ALTER TABLE producto
        ADD COLUMN existencia INTEGER NOT NULL DEFAULT 0 CHECK (existencia >= 0)
      ''');

      await db.execute('''
        CREATE INDEX idx_producto_id_categoria ON producto (id_categoria)
      ''');

      await db.execute('''
        ALTER TABLE prestamos
        ADD COLUMN porcentaje_extra REAL NOT NULL DEFAULT 0
        CHECK (porcentaje_extra >= 0)
      ''');

      await db.execute('''
        ALTER TABLE prestamos
        ADD COLUMN activo INTEGER NOT NULL DEFAULT 0 CHECK (activo IN (0, 1))
      ''');

      await db.execute('''
        UPDATE prestamos
        SET activo = CASE WHEN pagado = 1 THEN 0 ELSE 1 END
      ''');

      await db.execute('''
        UPDATE clientes
        SET prestamo_activo = CASE
          WHEN EXISTS (
            SELECT 1
            FROM prestamos
            WHERE prestamos.id_cliente = clientes.id
              AND prestamos.deleted_at IS NULL
              AND prestamos.activo = 1
          ) THEN 1
          ELSE 0
        END
      ''');

      await db.execute('''
        ALTER TABLE prestamo_producto
        ADD COLUMN cantidad INTEGER NOT NULL DEFAULT 1 CHECK (cantidad > 0)
      ''');

      await db.execute('''
        ALTER TABLE prestamo_producto
        ADD COLUMN importe REAL NOT NULL DEFAULT 0 CHECK (importe >= 0)
      ''');

      await db.execute('''
        UPDATE prestamo_producto
        SET importe = COALESCE(
          (
            SELECT producto.precio
            FROM producto
            WHERE producto.id = prestamo_producto.id_producto
          ),
          0
        )
      ''');

      await _createAbonoTable(db);
    }
  }

  Future<void> _createComunidadTable(Database db) async {
    await db.execute('''
      CREATE TABLE comunidad (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        dia_pago TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
  }

  Future<void> _createClientesTable(Database db) async {
    await db.execute('''
      CREATE TABLE clientes (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        prestamo_activo INTEGER NOT NULL DEFAULT 0 CHECK (prestamo_activo IN (0, 1)),
        id_comunidad TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (id_comunidad) REFERENCES comunidad (id) ON UPDATE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_clientes_id_comunidad ON clientes (id_comunidad)
    ''');
  }

  Future<void> _createPrestamosTable(Database db) async {
    await db.execute('''
      CREATE TABLE prestamos (
        id TEXT PRIMARY KEY,
        id_cliente TEXT NOT NULL,
        fecha TEXT NOT NULL,
        porcentaje_extra REAL NOT NULL DEFAULT 0 CHECK (porcentaje_extra >= 0),
        cantidad_prestada REAL NOT NULL,
        cantidad_pagada REAL NOT NULL DEFAULT 0,
        pagado INTEGER NOT NULL DEFAULT 0 CHECK (pagado IN (0, 1)),
        activo INTEGER NOT NULL DEFAULT 0 CHECK (activo IN (0, 1)),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (id_cliente) REFERENCES clientes (id) ON UPDATE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_prestamos_id_cliente ON prestamos (id_cliente)
    ''');
  }

  Future<void> _createCategoriaTable(Database db) async {
    await db.execute('''
      CREATE TABLE categoria (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
  }

  Future<void> _createProductoTable(Database db) async {
    await db.execute('''
      CREATE TABLE producto (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        precio REAL NOT NULL CHECK (precio >= 0),
        precio_original REAL CHECK (precio_original >= 0),
        existencia INTEGER NOT NULL DEFAULT 0 CHECK (existencia >= 0),
        id_categoria TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (id_categoria) REFERENCES categoria (id) ON UPDATE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_producto_id_categoria ON producto (id_categoria)
    ''');
  }

  Future<void> _createPrestamoProductoTable(Database db) async {
    await db.execute('''
      CREATE TABLE prestamo_producto (
        id TEXT PRIMARY KEY,
        id_producto TEXT NOT NULL,
        id_prestamo TEXT NOT NULL,
        cantidad INTEGER NOT NULL CHECK (cantidad > 0),
        importe REAL NOT NULL CHECK (importe >= 0),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (id_producto) REFERENCES producto (id) ON UPDATE CASCADE,
        FOREIGN KEY (id_prestamo) REFERENCES prestamos (id) ON UPDATE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_prestamo_producto_id_producto
      ON prestamo_producto (id_producto)
    ''');

    await db.execute('''
      CREATE INDEX idx_prestamo_producto_id_prestamo
      ON prestamo_producto (id_prestamo)
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_prestamo_producto_unique_pair
      ON prestamo_producto (id_prestamo, id_producto)
    ''');
  }

  Future<void> _createAbonoTable(Database db) async {
    await db.execute('''
      CREATE TABLE abono (
        id TEXT PRIMARY KEY,
        fecha TEXT NOT NULL,
        id_prestamo TEXT NOT NULL,
        cantidad REAL NOT NULL CHECK (cantidad > 0),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (id_prestamo) REFERENCES prestamos (id) ON UPDATE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_abono_id_prestamo ON abono (id_prestamo)
    ''');
  }
}
