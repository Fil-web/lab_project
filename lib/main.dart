import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Инициализация базы данных для разных платформ
void _initDatabase() {
  try {
    // Для веб-платформы используем sqflite_common_ffi_web
    // import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
    // databaseFactory = databaseFactoryFfiWeb;
  } catch (e) {
    // Для других платформ используем стандартную фабрику
    debugPrint('Используем стандартную фабрику базы данных: $e');
  }
}

void main() {
  _initDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Лабораторная работа',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ====================== QUADRATIC CUBIT ======================
// Абстрактный базовый класс состояния
abstract class QuadraticState {}

// Начальное состояние
class QuadraticInitialState extends QuadraticState {}

// Состояние загрузки
class QuadraticLoadingState extends QuadraticState {}

// Состояние результатов расчета
class QuadraticResultState extends QuadraticState {
  final String equation;
  final String discriminant;
  final String message;
  final List<String> roots;
  final String type;
  final CalculationHistory? calculationHistory;

  QuadraticResultState({
    required this.equation,
    required this.discriminant,
    required this.message,
    required this.roots,
    required this.type,
    this.calculationHistory,
  });
}

// Состояние ошибки
class QuadraticErrorState extends QuadraticState {
  final String errorMessage;

  QuadraticErrorState({required this.errorMessage});
}

// Состояние сохранения
class QuadraticSavingState extends QuadraticState {}

// Cubit для управления состояниями
class QuadraticCubit extends Cubit<QuadraticState> {
  QuadraticCubit() : super(QuadraticInitialState());

  // Хранение последних коэффициентов в SharedPreferences
  Future<void> saveLastCoefficients(double a, double b, double c) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_a', a);
    await prefs.setDouble('last_b', b);
    await prefs.setDouble('last_c', c);
  }

  // Загрузка последних коэффициентов из SharedPreferences
  Future<List<double?>> loadLastCoefficients() async {
    final prefs = await SharedPreferences.getInstance();
    return [
      prefs.getDouble('last_a'),
      prefs.getDouble('last_b'),
      prefs.getDouble('last_c'),
    ];
  }

  Future<void> calculateRoots(double a, double b, double c) async {
    // Начинаем расчет
    emit(QuadraticLoadingState());

    // Сохраняем коэффициенты в SharedPreferences
    await saveLastCoefficients(a, b, c);

    // Имитация задержки расчета
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        if (a == 0) {
          emit(QuadraticErrorState(
            errorMessage: 'Коэффициент a не может быть равен 0',
          ));
          return;
        }

        final discriminant = b * b - 4 * a * c;
        final equation =
            '${a.toStringAsFixed(2)}x² ${b >= 0 ? '+' : ''}${b.toStringAsFixed(2)}x ${c >= 0 ? '+' : ''}${c.toStringAsFixed(2)} = 0';

        CalculationHistory? calculationHistory;

        if (discriminant > 0) {
          final x1 = (-b + sqrt(discriminant)) / (2 * a);
          final x2 = (-b - sqrt(discriminant)) / (2 * a);

          // Сохраняем в базу данных
          calculationHistory = CalculationHistory(
            a: a,
            b: b,
            c: c,
            equation: equation,
            discriminant: discriminant.toStringAsFixed(2),
            message: 'Уравнение имеет два различных корня',
            roots: [x1.toStringAsFixed(4), x2.toStringAsFixed(4)],
            type: 'two_roots',
            timestamp: DateTime.now(),
          );

          try {
            await DatabaseProvider.instance
                .insertCalculation(calculationHistory);
          } catch (e) {
            debugPrint('Ошибка сохранения в базу данных: $e');
          }

          emit(QuadraticResultState(
            equation: equation,
            discriminant: discriminant.toStringAsFixed(2),
            message: 'Уравнение имеет два различных корня',
            roots: [x1.toStringAsFixed(4), x2.toStringAsFixed(4)],
            type: 'two_roots',
            calculationHistory: calculationHistory,
          ));
        } else if (discriminant == 0) {
          final x = -b / (2 * a);

          // Сохраняем в базу данных
          calculationHistory = CalculationHistory(
            a: a,
            b: b,
            c: c,
            equation: equation,
            discriminant: discriminant.toStringAsFixed(2),
            message: 'Уравнение имеет один корень',
            roots: [x.toStringAsFixed(4)],
            type: 'one_root',
            timestamp: DateTime.now(),
          );

          try {
            await DatabaseProvider.instance
                .insertCalculation(calculationHistory);
          } catch (e) {
            debugPrint('Ошибка сохранения в базу данных: $e');
          }

          emit(QuadraticResultState(
            equation: equation,
            discriminant: discriminant.toStringAsFixed(2),
            message: 'Уравнение имеет один корень',
            roots: [x.toStringAsFixed(4)],
            type: 'one_root',
            calculationHistory: calculationHistory,
          ));
        } else {
          // Сохраняем в базу данных даже если корней нет
          calculationHistory = CalculationHistory(
            a: a,
            b: b,
            c: c,
            equation: equation,
            discriminant: discriminant.toStringAsFixed(2),
            message: 'Уравнение не имеет действительных корней',
            roots: [],
            type: 'no_roots',
            timestamp: DateTime.now(),
          );

          try {
            await DatabaseProvider.instance
                .insertCalculation(calculationHistory);
          } catch (e) {
            debugPrint('Ошибка сохранения в базу данных: $e');
          }

          emit(QuadraticResultState(
            equation: equation,
            discriminant: discriminant.toStringAsFixed(2),
            message: 'Уравнение не имеет действительных корней',
            roots: [],
            type: 'no_roots',
            calculationHistory: calculationHistory,
          ));
        }
      } catch (e) {
        emit(QuadraticErrorState(
          errorMessage: 'Произошла ошибка при расчете: $e',
        ));
      }
    });
  }

  void reset() {
    emit(QuadraticInitialState());
  }

  // Метод для сохранения текущего расчета
  Future<void> saveCalculation(CalculationHistory calculation) async {
    emit(QuadraticSavingState());
    try {
      await DatabaseProvider.instance.insertCalculation(calculation);
      emit(QuadraticResultState(
        equation: calculation.equation,
        discriminant: calculation.discriminant,
        message: calculation.message,
        roots: calculation.roots,
        type: calculation.type,
        calculationHistory: calculation,
      ));
    } catch (e) {
      emit(QuadraticErrorState(
        errorMessage: 'Ошибка при сохранении: $e',
      ));
    }
  }
}

// Модель для истории расчетов
class CalculationHistory {
  final int? id;
  final double a;
  final double b;
  final double c;
  final String equation;
  final String discriminant;
  final String message;
  final List<String> roots;
  final String type;
  final DateTime timestamp;

  CalculationHistory({
    this.id,
    required this.a,
    required this.b,
    required this.c,
    required this.equation,
    required this.discriminant,
    required this.message,
    required this.roots,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'a': a,
      'b': b,
      'c': c,
      'equation': equation,
      'discriminant': discriminant,
      'message': message,
      'roots': roots.join('|'),
      'type': type,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CalculationHistory.fromMap(Map<String, dynamic> map) {
    return CalculationHistory(
      id: map['id'],
      a: map['a'],
      b: map['b'],
      c: map['c'],
      equation: map['equation'],
      discriminant: map['discriminant'],
      message: map['message'],
      roots: (map['roots'] as String).split('|'),
      type: map['type'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

// Провайдер для хранения данных (упрощенная версия с SharedPreferences)
class DatabaseProvider {
  static final DatabaseProvider instance = DatabaseProvider._init();

  DatabaseProvider._init();

  // Сохранение расчета
  Future<void> insertCalculation(CalculationHistory calculation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final calculations = await getAllCalculations();
      calculations.insert(0, calculation); // Добавляем в начало

      // Сохраняем как JSON
      final jsonList = calculations.map((c) => c.toMap()).toList();
      await prefs.setString('calculations_history', json.encode(jsonList));
    } catch (e) {
      debugPrint('Ошибка сохранения расчета: $e');
    }
  }

  // Получение всех расчетов
  Future<List<CalculationHistory>> getAllCalculations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('calculations_history');

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = json.decode(jsonString) as List;
      return jsonList.map((json) => CalculationHistory.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Ошибка получения расчетов: $e');
      return [];
    }
  }

  // Удаление расчета по ID
  Future<void> deleteCalculation(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final calculations = await getAllCalculations();
      final updatedCalculations =
          calculations.where((c) => c.id != id).toList();

      final jsonList = updatedCalculations.map((c) => c.toMap()).toList();
      await prefs.setString('calculations_history', json.encode(jsonList));
    } catch (e) {
      debugPrint('Ошибка удаления расчета: $e');
    }
  }

  // Очистка всей истории
  Future<void> clearAllCalculations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('calculations_history');
    } catch (e) {
      debugPrint('Ошибка очистки истории: $e');
    }
  }
}

// Состояния для истории
abstract class HistoryState {}

class HistoryInitialState extends HistoryState {}

class HistoryLoadingState extends HistoryState {}

class HistoryLoadedState extends HistoryState {
  final List<CalculationHistory> calculations;

  HistoryLoadedState({required this.calculations});
}

class HistoryErrorState extends HistoryState {
  final String errorMessage;

  HistoryErrorState({required this.errorMessage});
}

// Cubit для истории
class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit() : super(HistoryInitialState());

  // Загрузка всей истории
  Future<void> loadHistory() async {
    emit(HistoryLoadingState());
    try {
      final calculations = await DatabaseProvider.instance.getAllCalculations();
      emit(HistoryLoadedState(calculations: calculations));
    } catch (e) {
      emit(HistoryErrorState(errorMessage: 'Ошибка загрузки истории: $e'));
    }
  }

  // Удаление расчета
  Future<void> deleteCalculation(int id) async {
    try {
      await DatabaseProvider.instance.deleteCalculation(id);
      // Перезагружаем историю после удаления
      await loadHistory();
    } catch (e) {
      emit(HistoryErrorState(errorMessage: 'Ошибка удаления: $e'));
    }
  }

  // Очистка всей истории
  Future<void> clearHistory() async {
    try {
      await DatabaseProvider.instance.clearAllCalculations();
      emit(HistoryLoadedState(calculations: []));
    } catch (e) {
      emit(HistoryErrorState(errorMessage: 'Ошибка очистки: $e'));
    }
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Лабораторная работа'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(),
                ),
              );
            },
            tooltip: 'История расчетов',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (context) => QuadraticCubit(),
                      child: const QuadraticEquationCubitScreen(),
                    ),
                  ),
                );
              },
              child: const Text('Калькулятор квадратных уравнений (Cubit)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImageGalleryScreen(),
                  ),
                );
              },
              child: const Text('Галерея изображений'),
            ),
          ],
        ),
      ),
    );
  }
}

// ЭКРАН ИСТОРИИ РАСЧЕТОВ
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  void _showClearConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Очистить историю?'),
          content: const Text(
              'Вы уверены, что хотите удалить всю историю расчетов?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                final cubit = context.read<HistoryCubit>();
                cubit.clearHistory();
                Navigator.pop(context);
              },
              child:
                  const Text('Очистить', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HistoryCubit()..loadHistory(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('История расчетов'),
          centerTitle: true,
          actions: [
            BlocBuilder<HistoryCubit, HistoryState>(
              builder: (context, state) {
                if (state is HistoryLoadedState &&
                    state.calculations.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    onPressed: () {
                      _showClearConfirmationDialog(context);
                    },
                    tooltip: 'Очистить историю',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: const _HistoryScreenBody(),
      ),
    );
  }
}

class _HistoryScreenBody extends StatelessWidget {
  const _HistoryScreenBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        if (state is HistoryLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is HistoryErrorState) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 50),
                const SizedBox(height: 10),
                Text(
                  state.errorMessage,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    context.read<HistoryCubit>().loadHistory();
                  },
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        if (state is HistoryLoadedState) {
          final calculations = state.calculations;

          if (calculations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 50, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'История расчетов пуста',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Выполните расчеты в калькуляторе,\nчтобы они появились здесь',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: calculations.length,
            itemBuilder: (context, index) {
              final calculation = calculations[index];
              return _buildHistoryCard(context, calculation, index);
            },
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildHistoryCard(
      BuildContext context, CalculationHistory calculation, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Расчет #${index + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDate(calculation.timestamp),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              calculation.equation,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Коэффициенты: a = ${calculation.a}, b = ${calculation.b}, c = ${calculation.c}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 5),
            Text(
              'Дискриминант: D = ${calculation.discriminant}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 5),
            Text(
              calculation.message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color:
                    calculation.type == 'no_roots' ? Colors.red : Colors.green,
              ),
            ),
            if (calculation.roots.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Корни уравнения:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (calculation.type == 'two_roots')
                      Row(
                        children: [
                          _buildRootChip(
                              'x₁ = ${calculation.roots[0]}', Colors.blue),
                          const SizedBox(width: 10),
                          _buildRootChip(
                              'x₂ = ${calculation.roots[1]}', Colors.green),
                        ],
                      )
                    else if (calculation.type == 'one_root')
                      _buildRootChip(
                          'x = ${calculation.roots[0]}', Colors.blue),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 22),
                onPressed: () {
                  if (calculation.id != null) {
                    _showDeleteConfirmationDialog(context, calculation.id!);
                  }
                },
                tooltip: 'Удалить запись',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRootChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить запись?'),
          content: const Text(
              'Вы уверены, что хотите удалить эту запись из истории?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                final cubit = context.read<HistoryCubit>();
                cubit.deleteCalculation(id);
                Navigator.pop(context);
              },
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'Сегодня, ${_formatTime(date)}';
    } else if (dateDay == yesterday) {
      return 'Вчера, ${_formatTime(date)}';
    } else {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// НОВАЯ ВЕРСИЯ (с Cubit) - КВАДРАТНОЕ УРАВНЕНИЕ С CUBIT
class QuadraticEquationCubitScreen extends StatefulWidget {
  const QuadraticEquationCubitScreen({super.key});

  @override
  State<QuadraticEquationCubitScreen> createState() =>
      _QuadraticEquationCubitScreenState();
}

class _QuadraticEquationCubitScreenState
    extends State<QuadraticEquationCubitScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _aController = TextEditingController();
  final TextEditingController _bController = TextEditingController();
  final TextEditingController _cController = TextEditingController();
  late BuildContext _screenContext;

  @override
  void initState() {
    super.initState();
    // Загружаем коэффициенты после небольшой задержки
    Future.delayed(Duration.zero, () {
      if (mounted) {
        _loadLastCoefficients();
      }
    });
  }

  Future<void> _loadLastCoefficients() async {
    if (!mounted) return;

    try {
      final coefficients =
          await BlocProvider.of<QuadraticCubit>(_screenContext, listen: false)
              .loadLastCoefficients();

      if (mounted &&
          coefficients[0] != null &&
          coefficients[1] != null &&
          coefficients[2] != null) {
        setState(() {
          _aController.text =
              coefficients[0]!.toStringAsFixed(2).replaceAll('.00', '');
          _bController.text =
              coefficients[1]!.toStringAsFixed(2).replaceAll('.00', '');
          _cController.text =
              coefficients[2]!.toStringAsFixed(2).replaceAll('.00', '');
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки коэффициентов: $e');
    }
  }

  String? _validateCoefficient(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите коэффициент';
    }
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Введите число';
    }
    return null;
  }

  void _calculate() {
    if (_formKey.currentState!.validate()) {
      final a = double.parse(_aController.text);
      final b = double.parse(_bController.text);
      final c = double.parse(_cController.text);

      BlocProvider.of<QuadraticCubit>(_screenContext, listen: false)
          .calculateRoots(a, b, c);
    }
  }

  void _reset() {
    _aController.clear();
    _bController.clear();
    _cController.clear();
    BlocProvider.of<QuadraticCubit>(_screenContext, listen: false).reset();
  }

  @override
  Widget build(BuildContext context) {
    // Сохраняем контекст в переменную класса
    _screenContext = context;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Квадратное уравнение (Cubit)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
            tooltip: 'Сбросить',
          ),
        ],
      ),
      body: BlocConsumer<QuadraticCubit, QuadraticState>(
        listener: (context, state) {
          // Можно добавить дополнительные действия при изменении состояния
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Введите коэффициенты квадратного уравнения:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('ax² + bx + c = 0'),
                    const SizedBox(height: 30),

                    // Поле для коэффициента a
                    TextFormField(
                      controller: _aController,
                      decoration: const InputDecoration(
                        labelText: 'Коэффициент a (a ≠ 0)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.abc),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _validateCoefficient,
                    ),
                    const SizedBox(height: 20),

                    // Поле для коэффициента b
                    TextFormField(
                      controller: _bController,
                      decoration: const InputDecoration(
                        labelText: 'Коэффициент b',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.abc),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите коэффициент';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Введите число';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Поле для коэффициента c
                    TextFormField(
                      controller: _cController,
                      decoration: const InputDecoration(
                        labelText: 'Коэффициент c',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.abc),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите коэффициент';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Введите число';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Кнопки управления
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _calculate,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: const Icon(Icons.calculate),
                            label: const Text(
                              'Рассчитать корни',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _reset,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                            backgroundColor: Colors.grey,
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text(
                            'Сбросить',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Отображение состояния
                    _buildStateWidget(state),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStateWidget(QuadraticState state) {
    if (state is QuadraticInitialState) {
      return const SizedBox.shrink();
    }

    if (state is QuadraticLoadingState) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is QuadraticErrorState) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                state.errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    if (state is QuadraticResultState) {
      return _buildResultCard(state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildResultCard(QuadraticResultState state) {
    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Результаты расчета:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Уравнение: ${state.equation}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Дискриминант: D = ${state.discriminant}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              state.message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: state.type == 'no_roots' ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            if (state.type == 'two_roots')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Корни уравнения:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildRootCard('x₁', state.roots[0], Colors.blue),
                      const SizedBox(width: 20),
                      _buildRootCard('x₂', state.roots[1], Colors.green),
                    ],
                  ),
                ],
              )
            else if (state.type == 'one_root')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Корень уравнения:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildRootCard('x', state.roots[0], Colors.blue),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Уравнение не имеет действительных корней',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRootCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        color: Colors.white,
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ЭКРАН: ГАЛЕРЕЯ ИЗОБРАЖЕНИЙ
class ImageGalleryScreen extends StatelessWidget {
  const ImageGalleryScreen({super.key});

  final List<String> imageUrls = const [
    'https://sun9-8.userapi.com/s/v1/ig2/GljuQvQvVz1tVb0BlzP5S2WvFfGvptAyfdXud24DkKpfI3REPKNTS1W-4JraaVzyjtlfmL2ElG29ChpbahKOLDtZ.jpg?quality=95&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,540x540,640x640,720x720,1080x1080,1280x1280,1440x1440,2560x2560&from=bu&cs=2560x0',
    'https://sun9-80.userapi.com/s/v1/ig2/3Rnc3tq9A8AvShtsKfPzUeThjHqcmeE7lT4V3CI2vCyAj4Ca6_ni7WsiAKH0-UJZt92XMnjqwd81iCGc7NtLhIpG.jpg?quality=95&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,540x540,640x640,720x720,1080x1080,1280x1280,1440x1440,2560x2560&from=bu&cs=2560x0',
    'https://sun9-35.userapi.com/s/v1/ig2/xUSYnCj2klXri4TgAnMAM46SpjebzyJESPIiFNkeXK8b0kTs9MMYfzzMKyd6hNKhVVu0kx0ZXivtN_0DTdrj4GTT.jpg?quality=95&as=32x39,48x58,72x87,108x131,160x194,240x290,360x436,480x581,540x653,640x774,720x871,1080x1307,1280x1549,1440x1742,2116x2560&from=bu&cs=2116x0',
    'https://sun9-29.userapi.com/s/v1/ig2/RxJUM-nXWWMcei5Qgb0y-dtm9Yj7h5BX_65-uU-gTJLvsVJdK9kVp548d-6nL3y2v33usWs7rTnjxMT11NKGehbs.jpg?quality=95&as=32x48,48x72,72x108,108x162,160x240,240x361,360x541,480x721,540x811,640x962,720x1082,1080x1623,1280x1923,1440x2164,1472x2212&from=bu&cs=1472x0',
    'https://sun9-54.userapi.com/s/v1/ig2/UYYQxLH0M_dbXXNBbdwC_fYxd45hBexAv5K7rrvAInUs2fRGnOBxGj_s5e01MilY-vbx_RVptVDrMre4ZPWIujHw.jpg?quality=95&as=32x35,48x52,72x78,108x117,160x174,240x260,360x390,480x521,540x586,640x694,720x781,1080x1172,1280x1388,1440x1562,2360x2560&from=bu&cs=2360x0',
    'https://sun9-67.userapi.com/s/v1/ig2/e-yfLZ6zpNuVv5G_jNaXFaTOUjuTa5PEfIL1QWVYHgA_6C7c2ROFk-06LUHRM3eEBviY1_NkAqAkiPpLxpLRMxpp.jpg?quality=95&as=32x48,48x72,72x108,108x162,160x240,240x360,360x540,480x720,540x810,640x960,720x1080,1080x1620,1280x1920,1440x2160,1472x2208&from=bu&cs=1472x0',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Галерея изображений')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Контейнер 1: Простой квадрат с отступом
            Container(
              margin: const EdgeInsets.all(16.0),
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrls[0],
                  width: 350,
                  height: 350,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 50),
                            SizedBox(height: 10),
                            Text('Ошибка загрузки'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Контейнер 2: С тенью и закругленными углами
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  imageUrls[1],
                  width: 350,
                  height: 350,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Контейнер 3: С рамкой
            Container(
              margin: const EdgeInsets.all(24),
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrls[2],
                  width: 350,
                  height: 350,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Контейнер 4: С градиентным наложением на белом фоне
            Container(
              margin: const EdgeInsets.fromLTRB(32, 16, 32, 8),
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      imageUrls[3],
                      width: 350,
                      height: 350,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7)
                        ],
                      ),
                    ),
                    child: const Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Градиентное наложение',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Контейнер 5: С прозрачной рамкой и внутренним отступом
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Container(
                width: 350,
                height: 350,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrls[4],
                      width: 326,
                      height: 326,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            // Контейнер 6: Круглое изображение на белом фоне
            Container(
              margin: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 32,
              ),
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  imageUrls[5],
                  width: 350,
                  height: 350,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
