import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'todo_card.dart'; // 引入切分出去的卡片
import 'todo_item.dart'; // 引入模型

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pdnode Todos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: 'NotoSansSC',
      ),
      home: const TodoPage(title: 'Pdnode Todos'),
    );
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key, required this.title});
  final String title;

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  // 保持你原有的数据结构，指针锁定
  final List<TodoItem> _todoList = [
    TodoItem(title: 'Using Pdnode Todos', isDone: true),
    TodoItem(title: 'Create a new Todo'),
  ];

  final TextEditingController _dialogTitleController = TextEditingController();
  final TextEditingController _editController = TextEditingController();

  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  // ==================== 数据持久化持久化控制大坝 ====================

  Future<void> _saveTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 💡 优雅调用模型里的 toMap，代码读起来极其丝滑
      final List<Map<String, dynamic>> pureMapList = _todoList
          .map((item) => item.toMap())
          .toList();

      await prefs.setString('pdnode_todos_key', jsonEncode(pureMapList));
    } catch (e) {
      print("Save Failed, ERROR: $e");
    }
  }

  Future<void> _loadTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonStr = prefs.getString('pdnode_todos_key');

      if (jsonStr != null) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        setState(() {
          _todoList.clear();
          for (var item in jsonList) {
            // 💡 优雅调用模型里的 fromMap 构造工厂
            _todoList.add(TodoItem.fromMap(item));
          }
        });
      }
    } catch (e) {
      print("读取本地共享存储失败: $e");
    }
  }

  // ==================== 弹窗交互控流区 ====================

  Future<bool> _showDeleteAllDataConfirmDialog() async {
    bool? isConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete all data?'),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Yes', style: TextStyle(color: Colors.redAccent)),
            onPressed: () {
              setState(() => _todoList.clear());
              _saveTodos();
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
    return isConfirmed ?? false;
  }

  void _showDeleteConfirmDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete "${_todoList[index].title}"?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Yes', style: TextStyle(color: Colors.redAccent)),
            onPressed: () {
              setState(() => _todoList.removeAt(index));
              _saveTodos();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _pickDate(
    BuildContext context,
    DateTime? initialDate,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    return date;
  }

  void _showAddDialog() {
    _dialogTitleController.clear();
    _selectedDueDate = null;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Todo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _dialogTitleController,
                decoration: const InputDecoration(
                  hintText: 'Enter a new to-do item...',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    _selectedDueDate != null
                        ? 'Due: ${DateFormat('yyyy-MM-dd').format(_selectedDueDate!)}'
                        : 'No due date',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Pick Date'),
                    onPressed: () async {
                      final date = await _pickDate(context, _selectedDueDate);
                      if (date != null) {
                        setDialogState(() => _selectedDueDate = date);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text(
                'Add',
                style: TextStyle(color: Colors.deepPurple),
              ),
              onPressed: () {
                if (_dialogTitleController.text.isNotEmpty) {
                  setState(() {
                    _todoList.add(
                      TodoItem(
                        title: _dialogTitleController.text,
                        dueDate: _selectedDueDate,
                      ),
                    );
                  });
                  _saveTodos();
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(int index) {
    _editController.text = _todoList[index].title;
    DateTime? tempDueDate = _todoList[index].dueDate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Todo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editController,
                decoration: const InputDecoration(
                  hintText: 'Enter a new text...',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    tempDueDate != null
                        ? 'Due: ${DateFormat('yyyy-MM-dd').format(tempDueDate!)}'
                        : 'No due date',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Pick Date'),
                    onPressed: () async {
                      final date = await _pickDate(context, tempDueDate);
                      if (date != null) {
                        setDialogState(() => tempDueDate = date);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text(
                'Update',
                style: TextStyle(color: Colors.blueAccent),
              ),
              onPressed: () {
                if (_editController.text.isNotEmpty) {
                  setState(() {
                    _todoList[index].title = _editController.text;
                    _todoList[index].dueDate = tempDueDate;
                    _editController.clear();
                  });
                  _saveTodos();
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setting'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.delete_forever,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Delete All Data',
                  style: TextStyle(color: Colors.redAccent),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () async {
                  bool isConfirm = await _showDeleteAllDataConfirmDialog();
                  if (!context.mounted) {
                    return;
                  }
                  if (isConfirm) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.blueGrey),
                title: const Text('About Application'),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.of(context).pop();
                  showAboutDialog(
                    context: context,
                    applicationName: 'Pdnode Todos',
                    applicationVersion: '1.0.0',
                    applicationLegalese:
                        '© 2026 Pdnode LLC. All rights reserved.',
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ==================== UI 主渲染骨架 ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _showSettingsDialog,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _todoList.length,
        itemBuilder: (context, index) {
          // 🎯 核心看点：直接调用解耦后的 TodoCard，干净到无法自拔！
          return TodoCard(
            item: _todoList[index],
            onCheckChanged: () {
              setState(
                () => _todoList[index].isDone = !_todoList[index].isDone,
              );
              _saveTodos();
            },
            onEditPressed: () => _showEditDialog(index),
            onDeletePressed: () => _showDeleteConfirmDialog(index),
          );
        },
      ),
      // 右下角悬浮的 + 号
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
