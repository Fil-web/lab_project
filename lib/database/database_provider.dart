import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Квадратное уравнение',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const QuadraticScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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

  String? _resultMessage;
  List<String> _roots = [];
  String? _discriminant;
  String? _equation;

  String? _validate(String? value) {
    if (value == null || value.isEmpty) return 'Введите коэффициент';
    if (double.tryParse(value) == null) return 'Введите число';
    return null;
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final a = double.parse(_aController.text);
    final b = double.parse(_bController.text);
    final c = double.parse(_cController.text);

    if (a == 0) {
      setState(() {
        _resultMessage = 'Коэффициент a не может быть 0';
        _roots = [];
        _discriminant = null;
        _equation = null;
      });
      return;
    }

    final d = b * b - 4 * a * c;
    final eq =
        '${a.toStringAsFixed(2)}x² ${b >= 0 ? '+' : ''}${b.toStringAsFixed(2)}x ${c >= 0 ? '+' : ''}${c.toStringAsFixed(2)} = 0';

    String msg;
    List<String> roots;

    if (d > 0) {
      final x1 = (-b + sqrt(d)) / (2 * a);
      final x2 = (-b - sqrt(d)) / (2 * a);
      roots = [x1.toStringAsFixed(4), x2.toStringAsFixed(4)];
      msg = 'Два различных корня';
    } else if (d == 0) {
      final x = -b / (2 * a);
      roots = [x.toStringAsFixed(4)];
      msg = 'Один корень';
    } else {
      roots = [];
      msg = 'Нет действительных корней';
    }

    setState(() {
      _equation = eq;
      _discriminant = d.toStringAsFixed(2);
      _resultMessage = msg;
      _roots = roots;
    });
  }

  void _reset() {
    _aController.clear();
    _bController.clear();
    _cController.clear();
    setState(() {
      _resultMessage = null;
      _roots = [];
      _discriminant = null;
      _equation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Калькулятор квадратных уравнений')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _aController,
                decoration: const InputDecoration(labelText: 'a (a ≠ 0)'),
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
                    child: const Text('Сбросить'),
                  ),
                ],
              ),
              if (_equation != null) ...[
                const SizedBox(height: 20),
                Text(_equation!, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Дискриминант: $_discriminant'),
                Text(_resultMessage!,
                    style: TextStyle(
                        color: _roots.isEmpty ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold)),
                if (_roots.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  if (_roots.length == 2)
                    Row(
                      children: [
                        Text('x₁ = ${_roots[0]}   '),
                        Text('x₂ = ${_roots[1]}'),
                      ],
                    )
                  else
                    Text('x = ${_roots[0]}'),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}