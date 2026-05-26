import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../globals.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance= DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database !=null) return _database!;
    _database = await _initDB ('edugrade.db');
    return _database!;

  }
  
  Future<Database> _initDB(String fileName) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path= join(dbPath.path, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS teacher (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        school_name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
        ) '''
    );
   await db.execute(''' 
      CREATE TABLE IF NOT EXISTS grading_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        level  TEXT NOT NULL,
        grade  TEXT NOT NULL,
        min_mark INTEGER,
        max_mark  INTEGER,
        point    INTEGER,
        color    TEXT
      )
      ''');
    


       
  

      await db.execute('''
          CREATE TABLE IF NOT EXISTS settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT UNIQUE NOT NULL,
          value TEXT NOT NULL,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )''');
      await db.insert ('settings',{
              'key': 'useAdmissionNumber',
              'value': 'false',


            }, conflictAlgorithm: ConflictAlgorithm.replace);
           


      await db.execute('''
        CREATE TABLE IF NOT EXISTS tracker (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT UNIQUE NOT NULL,
          value TEXT NOT NULL,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
          )''');
      
      await db.insert ('tracker', {
        'key': 'hasTeacher',
        'value': '$hasTeacher', 
      

      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert ('tracker', {
          'key': 'isjss',
          'value': '$isjss',
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await db.insert('tracker', {
          'key': 'continuingOnboarding',
          'value': '$continuingOnboarding',
      }, conflictAlgorithm: ConflictAlgorithm.replace );
      
    await db.execute('''
      CREATE TABLE IF NOT EXISTS classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_name TEXT NOT NULL,           -- e.g., "Form 2A", "Grade 7B"
        level TEXT NOT NULL,                -- "Primary" or "Junior Secondary"
        academic_year TEXT,
        term INTEGER DEFAULT 1,
        teacher_id INTEGER,
        student_count INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        admission_number TEXT UNIQUE,
        full_name TEXT NOT NULL,
        class_name TEXT,                    
        class_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
  CREATE TABLE IF NOT EXISTS assessments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER NOT NULL,
    class_id INTEGER NOT NULL,
    subject_code TEXT NOT NULL,
    academic_year TEXT NOT NULL,
    term INTEGER NOT NULL,
    raw_score REAL NOT NULL,           
    assessment_type TEXT,              
    recorded_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (class_id) REFERENCES classes(id),
    UNIQUE(student_id, subject_code, academic_year, term, assessment_type)
  )
''');

    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_code TEXT UNIQUE NOT NULL,
        subject_name TEXT NOT NULL,
        category TEXT,
        is_default INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

  await _insertDefaultSubjects(db);
  await _insertPrimaryGrades(db);

  }

   Future<void> _insertPrimaryGrades(Database db) async {
      final defaultPrimaryGrades= [
        {'level':'primary', 'grade': 'EE', 'min_mark':80, 'max_mark': 100, 'color': '#28A745'},
        {'level':'primary', 'grade': 'ME', 'min_mark':60, 'max_mark': 79, 'color': '#2196F3'},
        {'level':'primary', 'grade': 'AE', 'min_mark':40, 'max_mark': 59, 'color': '#FF9800'},
        {'level':'primary', 'grade': 'BE', 'min_mark':0, 'max_mark': 39 ,'color':'#F44336'},
        {'level':'jss', 'grade':'EE1', 'min_mark':85,'max_mark':100, 'point':8, 'color':'#15803D'},
        {'level':'jss', 'grade':'EE2', 'min_mark':75,'max_mark':84, 'point':7, 'color':'#16A34A'},
        {'level':'jss', 'grade':'ME1', 'min_mark':65,'max_mark':74, 'point':6, 'color':'#2563EB'},
        {'level':'jss', 'grade':'ME2', 'min_mark':55,'max_mark':64, 'point':5, 'color':'#3B82F6'},
        {'level':'jss', 'grade':'AE1', 'min_mark':45,'max_mark':54, 'point':4, 'color':'#60A5FA'},
        {'level':'jss', 'grade':'AE2', 'min_mark':35,'max_mark':44, 'point':3, 'color':'#F59E0B'},
        {'level':'jss', 'grade':'BE1', 'min_mark':25,'max_mark':34, 'point':2, 'color':'#F97316'},
        {'level':'jss', 'grade':'BE2', 'min_mark':0,'max_mark':24, 'point':1, 'color':'#DC2626'},

        //Aggregate points
        {'level':'agp', 'grade':'EE1', 'min_mark':68,'max_mark':72, 'point':8, 'color':'#15803D'},
        {'level':'agp', 'grade':'EE2', 'min_mark':63,'max_mark':67, 'point':7, 'color':'#16A34A'},
        {'level':'agp', 'grade':'ME1', 'min_mark':54,'max_mark':62, 'point':6, 'color':'#2563EB'},
        {'level':'agp', 'grade':'ME2', 'min_mark':45,'max_mark':53, 'point':5, 'color':'#3B82F6'},
        {'level':'agp', 'grade':'AE1', 'min_mark':36,'max_mark':44, 'point':4, 'color':'#60A5FA'},
        {'level':'agp', 'grade':'AE2', 'min_mark':27,'max_mark':35, 'point':3, 'color':'#F59E0B'},
        {'level':'agp', 'grade':'BE1', 'min_mark':19,'max_mark':26, 'point':2, 'color':'#F97316'},
        {'level':'agp', 'grade':'BE2', 'min_mark':0,'max_mark':24, 'point':1, 'color':'#DC2626'},

      ];
      for (var grades in defaultPrimaryGrades) {
        await db.insert('grading_config',{
          'level': grades['level'],
          'grade': grades['grade'],
          'min_mark': grades['min_mark'],
          'max_mark': grades['max_mark'],
          'point': grades['point'],
          'color': grades['color'],

        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
   }
   Future<void> _insertDefaultSubjects(Database db) async {
    final defaultSubjects = [
      {'code': 'ENG', 'name': 'English', 'category': 'Core'},
      {'code': 'KISW', 'name': 'Kiswahili', 'category': 'Core'},
      {'code': 'MAT', 'name': 'Mathematics', 'category': 'Core'},
      {'code': 'INT SCI', 'name': 'Integrated Science', 'category': 'Core'},
      {'code': 'S/ST', 'name': 'Social Studies', 'category': 'Core'},
      {'code': 'PRE-TECH', 'name': 'Pre-Technical Studies', 'category': 'Core'},
      {'code': 'AGRIC', 'name': 'Agriculture', 'category': 'Core'},
      {'code': 'CAS', 'name': 'Creative Arts & Sports', 'category': 'Core'},
      {'code': 'CRE', 'name': 'Christian Religious Education', 'category': 'Core'},
    ];

    for (var sub in defaultSubjects) {
      await db.insert('subjects', {
        'subject_code': sub['code'],
        'subject_name': sub['name'],
        'category': sub['category'],
        'is_default': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
   Future<void> close() async{
    final db = await instance.database;
    await db.close();
    
   }
}