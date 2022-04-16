import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const FibonacciApplication());
}

class FibonacciApplication extends StatelessWidget {
  const FibonacciApplication({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _fibonacciLengthController;

  DateTime now = DateTime.now();

  String? formattedDate;

  @override
  void initState() {
    _fibonacciLengthController = TextEditingController();
    formattedDate = DateFormat("d MMM yyyy").format(now);
    super.initState();
  }

  @override
  void dispose() {
    _fibonacciLengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Form(
            key: _formKey,
            child: TextFormField(
              controller: _fibonacciLengthController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter a number";
                }
                return null;
              },
              decoration: const InputDecoration(
                  hintText: " Please enter a valid number and press the button ...",
                  hintStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  )),
            ),
          ),
        ),
        body: SafeArea(
          child: FutureBuilder<List<FibonacciModel>>(
              future: DatabaseHelper._instance.fetchAll(),
              builder: (BuildContext context, AsyncSnapshot<List<FibonacciModel>> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: Text("Loading ..."));
                }
                return snapshot.data!.isEmpty
                    ? const Center(child: Text('No result in List.'))
                    : ListView(
                        children: snapshot.data!.map((element) {
                          return ListTile(
                            title: Text(
                              "${element.id} -   Your number ${element.input.toString()}, result : ${element.result.toString()}",
                              maxLines: 1,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(element.time),
                          );
                        }).toList(),
                      );
              }),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.calculate_outlined),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              int firstNumber = 0, secondNumber = 1, nextNumber = 0;
              for (int i = 3; i <= int.parse(_fibonacciLengthController.text); i++) {
                nextNumber = firstNumber + secondNumber;
                firstNumber = secondNumber;
                secondNumber = nextNumber;
              }
              await DatabaseHelper._instance.insert(FibonacciModel(
                result: nextNumber.toString(),
                time: formattedDate!,
                input: _fibonacciLengthController.text,
              ));
              setState(() {
                _fibonacciLengthController.clear();
              });
            }
          },
        ),
      );
}

class FibonacciModel {
  final int? id;
  final String? result;
  final String? input;
  final String time;

  const FibonacciModel({
    this.id,
    required this.input,
    required this.result,
    required this.time,
  });

  factory FibonacciModel.fromMap(Map<String, dynamic> json) => FibonacciModel(
        id: json["id"],
        input: json["input"],
        result: json["result"],
        time: json["time"],
      );

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "input": input,
      "result": result,
      "time": time,
    };
  }
}

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper _instance = DatabaseHelper._();

  static const _dbName = "fibonacci.db";
  static const _dbVersion = 1;
  static const _tableName = "fibonacci";
  static const columnId = "id";
  static const columnInput = "input";
  static const columnResult = "result";
  static const columnTime = "time";

  static Database? _db;

  Future<Database> get database async => _db ?? await _initiateDb();

  _initiateDb() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) {
    return db.execute('''
      CREATE TABLE $_tableName(
      $columnId INTEGER PRIMARY KEY,
      $columnResult TEXT NOT NULL,
      $columnInput TEXT NOT NULL,
      $columnTime TEXT NOT NULL
      ) 
      ''');
  }

  Future<int> insert(FibonacciModel model) async {
    Database db = await _instance.database;
    return await db.insert(_tableName, model.toMap());
  }

  Future<List<FibonacciModel>> fetchAll() async {
    Database db = await _instance.database;
    var result = await db.query(_tableName, orderBy: "id");
    List<FibonacciModel> resultList =
        result.isNotEmpty ? result.map((element) => FibonacciModel.fromMap(element)).toList() : [];
    return resultList;
  }
}
