import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const MyApp());

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

// ============= МОДЕЛЬ =============
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

// ============= ХРАНИЛИЩЕ =============
class DatabaseProvider {
  static final DatabaseProvider instance = DatabaseProvider._init();
  DatabaseProvider._init();

  Future<void> insertCalculation(CalculationHistory calc) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAllCalculations();
    list.insert(0, calc);
    final jsonList = list.map((c) => c.toMap()).toList();
    await prefs.setString('history', json.encode(jsonList));
  }

  Future<List<CalculationHistory>> getAllCalculations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('history');
    if (data == null || data.isEmpty) return [];
    final List decoded = json.decode(data);
    return decoded.map((e) => CalculationHistory.fromMap(e)).toList();
  }

  Future<void> deleteCalculation(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAllCalculations();
    list.removeWhere((c) => c.id == id);
    final jsonList = list.map((c) => c.toMap()).toList();
    await prefs.setString('history', json.encode(jsonList));
  }

  Future<void> clearAllCalculations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('history');
  }
}

// ============= CUBIT для уравнения =============
abstract class QuadraticState {}

class QuadraticInitialState extends QuadraticState {}

class QuadraticLoadingState extends QuadraticState {}

class QuadraticResultState extends QuadraticState {
  final String equation, discriminant, message;
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

class QuadraticErrorState extends QuadraticState {
  final String errorMessage;
  QuadraticErrorState({required this.errorMessage});
}

class QuadraticCubit extends Cubit<QuadraticState> {
  QuadraticCubit() : super(QuadraticInitialState());

  Future<void> saveLastCoefficients(double a, double b, double c) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_a', a);
    await prefs.setDouble('last_b', b);
    await prefs.setDouble('last_c', c);
  }

  Future<List<double?>> loadLastCoefficients() async {
    final prefs = await SharedPreferences.getInstance();
    return [
      prefs.getDouble('last_a'),
      prefs.getDouble('last_b'),
      prefs.getDouble('last_c'),
    ];
  }

  Future<void> calculateRoots(double a, double b, double c) async {
    emit(QuadraticLoadingState());
    await saveLastCoefficients(a, b, c);

    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        if (a == 0) {
          emit(QuadraticErrorState(errorMessage: 'a не может быть 0'));
          return;
        }

        final d = b * b - 4 * a * c;
        final eq =
            '${a.toStringAsFixed(2)}x² ${b >= 0 ? '+' : ''}${b.toStringAsFixed(2)}x ${c >= 0 ? '+' : ''}${c.toStringAsFixed(2)} = 0';

        CalculationHistory? history;

        if (d > 0) {
          final x1 = (-b + sqrt(d)) / (2 * a);
          final x2 = (-b - sqrt(d)) / (2 * a);
          history = CalculationHistory(
            a: a, b: b, c: c, equation: eq, discriminant: d.toStringAsFixed(2),
            message: 'Два различных корня', roots: [x1.toStringAsFixed(4), x2.toStringAsFixed(4)],
            type: 'two_roots', timestamp: DateTime.now(),
          );
          await DatabaseProvider.instance.insertCalculation(history);
          emit(QuadraticResultState(
            equation: eq, discriminant: d.toStringAsFixed(2),
            message: 'Два различных корня', roots: [x1.toStringAsFixed(4), x2.toStringAsFixed(4)],
            type: 'two_roots', calculationHistory: history,
          ));
        } else if (d == 0) {
          final x = -b / (2 * a);
          history = CalculationHistory(
            a: a, b: b, c: c, equation: eq, discriminant: d.toStringAsFixed(2),
            message: 'Один корень', roots: [x.toStringAsFixed(4)],
            type: 'one_root', timestamp: DateTime.now(),
          );
          await DatabaseProvider.instance.insertCalculation(history);
          emit(QuadraticResultState(
            equation: eq, discriminant: d.toStringAsFixed(2),
            message: 'Один корень', roots: [x.toStringAsFixed(4)],
            type: 'one_root', calculationHistory: history,
          ));
        } else {
          history = CalculationHistory(
            a: a, b: b, c: c, equation: eq, discriminant: d.toStringAsFixed(2),
            message: 'Нет действительных корней', roots: [],
            type: 'no_roots', timestamp: DateTime.now(),
          );
          await DatabaseProvider.instance.insertCalculation(history);
          emit(QuadraticResultState(
            equation: eq, discriminant: d.toStringAsFixed(2),
            message: 'Нет действительных корней', roots: [],
            type: 'no_roots', calculationHistory: history,
          ));
        }
      } catch (e) {
        emit(QuadraticErrorState(errorMessage: 'Ошибка: $e'));
      }
    });
  }

  void reset() => emit(QuadraticInitialState());
}

// ============= CUBIT для истории =============
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

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit() : super(HistoryInitialState());

  Future<void> loadHistory() async {
    emit(HistoryLoadingState());
    try {
      final list = await DatabaseProvider.instance.getAllCalculations();
      emit(HistoryLoadedState(calculations: list));
    } catch (e) {
      emit(HistoryErrorState(errorMessage: 'Ошибка загрузки: $e'));
    }
  }

  Future<void> deleteCalculation(int id) async {
    await DatabaseProvider.instance.deleteCalculation(id);
    await loadHistory();
  }

  Future<void> clearHistory() async {
    await DatabaseProvider.instance.clearAllCalculations();
    emit(HistoryLoadedState(calculations: []));
  }
}

// ============= ГЛАВНЫЙ ЭКРАН =============
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Лабораторная работа'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => QuadraticCubit(),
                    child: const QuadraticScreen(),
                  ),
                ),
              ),
              child: const Text('Калькулятор'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => HistoryCubit()..loadHistory(),
                    child: const HistoryScreen(),
                  ),
                ),
              ),
              child: const Text('История'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============= ЭКРАН КАЛЬКУЛЯТОРА =============
class QuadraticScreen extends StatefulWidget {
  const QuadraticScreen({super.key});

  @override
  State<QuadraticScreen> createState() => _QuadraticScreenState();
}

class _QuadraticScreenState extends State<QuadraticScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aController = TextEditingController();
  final _bController = TextEditingController();
  final _cController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLast();
  }

  Future<void> _loadLast() async {
    final cubit = context.read<QuadraticCubit>();
    final coeffs = await cubit.loadLastCoefficients();
    if (coeffs[0] != null && coeffs[1] != null && coeffs[2] != null) {
      _aController.text = coeffs[0]!.toStringAsFixed(2).replaceAll('.00', '');
      _bController.text = coeffs[1]!.toStringAsFixed(2).replaceAll('.00', '');
      _cController.text = coeffs[2]!.toStringAsFixed(2).replaceAll('.00', '');
    }
  }

  String? _validate(String? value) {
    if (value == null || value.isEmpty) return 'Введите коэффициент';
    if (double.tryParse(value) == null) return 'Введите число';
    return null;
  }

  void _calculate() {
    if (_formKey.currentState!.validate()) {
      final a = double.parse(_aController.text);
      final b = double.parse(_bController.text);
      final c = double.parse(_cController.text);
      context.read<QuadraticCubit>().calculateRoots(a, b, c);
    }
  }

  void _reset() {
    _aController.clear();
    _bController.clear();
    _cController.clear();
    context.read<QuadraticCubit>().reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Квадратное уравнение'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reset),
        ],
      ),
      body: BlocConsumer<QuadraticCubit, QuadraticState>(
        listener: (context, state) {},
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _aController,
                    decoration: const InputDecoration(labelText: 'a (a≠0)'),
                    keyboardType: TextInputType.number,
                    validator: _validate,
                  ),
                  TextFormField(
                    controller: _bController,
                    decoration: const InputDecoration(labelText: 'b'),
                    keyboardType: TextInputType.number,
                    validator: _validate,
                  ),
                  TextFormField(
                    controller: _cController,
                    decoration: const InputDecoration(labelText: 'c'),
                    keyboardType: TextInputType.number,
                    validator: _validate,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _calculate,
                          child: const Text('Рассчитать'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _reset,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                        child: const Text('Сброс'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  if (state is QuadraticLoadingState)
                    const Center(child: CircularProgressIndicator())
                  else if (state is QuadraticErrorState)
                    Text(state.errorMessage, style: const TextStyle(color: Colors.red))
                  else if (state is QuadraticResultState) ...[
                    Text(state.equation, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('D = ${state.discriminant}'),
                    Text(state.message,
                        style: TextStyle(
                            color: state.roots.isEmpty ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold)),
                    if (state.roots.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      if (state.roots.length == 2)
                        Row(
                          children: [
                            Text('x₁ = ${state.roots[0]}  '),
                            Text('x₂ = ${state.roots[1]}'),
                          ],
                        )
                      else
                        Text('x = ${state.roots[0]}'),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============= ЭКРАН ИСТОРИИ =============
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История'),
        actions: [
          BlocBuilder<HistoryCubit, HistoryState>(
            builder: (context, state) {
              if (state is HistoryLoadedState && state.calculations.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _showClearDialog(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HistoryErrorState) {
            return Center(child: Text(state.errorMessage));
          }
          if (state is HistoryLoadedState) {
            if (state.calculations.isEmpty) {
              return const Center(child: Text('История пуста'));
            }
            return ListView.builder(
              itemCount: state.calculations.length,
              itemBuilder: (ctx, i) {
                final h = state.calculations[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(h.equation),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('D = ${h.discriminant}'),
                        Text(h.message),
                        if (h.roots.isNotEmpty) Text('Корни: ${h.roots.join(' ; ')}'),
                        Text(_formatDate(h.timestamp),
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteDialog(context, h.id!),
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить запись?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<HistoryCubit>().deleteCalculation(id);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Очистить историю?'),
        content: const Text('Все записи будут удалены'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<HistoryCubit>().clearHistory();
            },
            child: const Text('Очистить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}