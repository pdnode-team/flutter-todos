import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class TodoItem {
  String title;
  bool isDone;

  TodoItem({required this.title, this.isDone = false});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pdnode Todos',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
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
  Future<void> _saveTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 💡 核心大招：利用 .map() 把每一个 TodoItem 对象，手动拆解成标准的 Map<String, dynamic>
      // 这样 jsonEncode 拿到的就是一个纯粹的 List<Map>，它就能完美识别并序列化了！
      final List<Map<String, dynamic>> pureMapList = _todoList.map((item) {
        return {'title': item.title, 'isDone': item.isDone};
      }).toList();

      // 此时再丢给 jsonEncode，稳如老狗，绝对不会再报错
      String jsonStr = jsonEncode(pureMapList);

      await prefs.setString('pdnode_todos_key', jsonStr);
    } catch (e) {
      print("Save Failed, ERROR: $e");
    }
  }

  Future<void> _loadTodos() async {
    try {
      // 1. 从全平台通用的持久化仓库里把字符串捞出来
      final prefs = await SharedPreferences.getInstance();
      String? jsonStr = prefs.getString('pdnode_todos_key');

      if (jsonStr != null) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);

        // 2. 💡 完美保留你原来的循环转换逻辑，指针不变，只清空并重新灌入
        setState(() {
          _todoList.clear(); // 清空旧的内存列表
          for (var item in jsonList) {
            _todoList.add(
              TodoItem(title: item['title'], isDone: item['isDone']),
            );
          }
        });
      }
    } catch (e) {
      print("读取本地共享存储失败: $e");
    }
  }

  // ➕ 让函数接收一个 int 类型的 index 参数
  void _showDeleteConfirmDialog(int index) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          // 💡 动态展示：你可以直接在文案里引用传进来的参数，获取当前这条任务的标题
          content: Text(
            'Are you sure you want to delete "${_todoList[index].title}"?',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(), // 一行搞定关闭
            ),
            TextButton(
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () {
                // 💡 业务逻辑：精准删除传进来的那一条
                setState(() {
                  _todoList.removeAt(index);
                });
                _saveTodos(); // 同步进硬盘
                Navigator.of(context).pop(); // 关闭弹窗
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(int index) {
    _editController.text = _todoList[index].title;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Todo'),
          // 💡 动态展示：你可以直接在文案里引用传进来的参数，获取当前这条任务的标题
          content: TextField(
            controller: _editController,
            decoration: const InputDecoration(hintText: 'Enter a new text...'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(), // 一行搞定关闭
            ),
            TextButton(
              child: const Text(
                'Update',
                style: TextStyle(color: Colors.blueAccent),
              ),
              onPressed: () {
                // 💡 业务逻辑：精准删除传进来的那一条
                setState(() {
                  _todoList[index].title = _editController.text;
                  _editController.text = "";
                });
                _saveTodos(); // 同步进硬盘
                Navigator.of(context).pop(); // 关闭弹窗
              },
            ),
          ],
        );
      },
    );
  }

  // Flutter 组件的生命周期函数：当页面一打开，就自动去读文件
  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  final List<TodoItem> _todoList = [
    TodoItem(title: 'Using Pdnode Todos', isDone: true), // 这条默认做完了
    TodoItem(title: 'Create a new Todo'),
  ];

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _editController = TextEditingController();

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Setting'),
          content: SizedBox(
            width: 300, // 给弹窗一个固定宽度，防止不同系统下缩成一团
            child: Column(
              mainAxisSize: MainAxisSize.min, // 💡 关键：让弹窗高度刚好包裹内容，不要撑满全屏
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever,
                    color: Colors.redAccent,
                  ), // 左侧危险红图标
                  title: const Text(
                    'Delete All Data',
                    style: TextStyle(color: Colors.redAccent),
                  ), // 红色警告文字
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ), // 右侧小箭头
                  onTap: () {
                    // 💡 以后点击这里，去弹第二个“你确定要真的清空吗”的二次确认窗
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: Colors.blueGrey,
                  ),
                  title: const Text('About Application'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.of(context).pop(); // 先关掉当前的设置弹窗
                    // 瞬间弹出官方的、高大上的法律合规与开源协议声明弹窗
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
              onPressed: () => Navigator.of(context).pop(), // 一行搞定关闭
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () {
              _showSettingsDialog();
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          // 【上半部分】：输入框 + 添加按钮的一行 (Row)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      hintText: 'Enter a new to-do item...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.deepPurple),
                  onPressed: () {
                    if (_inputController.text.isNotEmpty) {
                      setState(() {
                        // 往数组里添加一个新模型，并清空输入框
                        _todoList.add(TodoItem(title: _inputController.text));
                        _inputController.clear();
                      });
                    }
                    _saveTodos();
                  },
                ),
              ],
            ),
          ),

          // 【下半部分】：这也就是你要找的 ListView.builder！
          // 它被包裹在 Expanded 里面，用来占据屏幕剩下的所有空间
          Expanded(
            child: ListView.builder(
              itemCount: _todoList.length, // 告诉我总共有几条 Todo
              itemBuilder: (context, index) {
                final item = _todoList[index]; // 拿到当前这一行的 Todo 数据

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 6.0,
                  ),
                  elevation: 2,
                  child: ListTile(
                    // 左边：复选框
                    leading: Checkbox(
                      activeColor: Colors.deepPurple,
                      value: item.isDone,
                      onChanged: (bool? newValue) {
                        setState(() {
                          item.isDone = newValue ?? false; // 切换勾选状态
                        });
                        _saveTodos();
                      },
                    ),
                    // 中间：文字，如果是 true 就加横线，颜色变灰
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 16,
                        decoration: item.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: item.isDone ? Colors.grey : Colors.black87,
                      ),
                    ),
                    // 右边：红色的删除垃圾桶
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            _showEditDialog(index);
                          },
                          icon: Icon(Icons.edit),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            // setState(() {
                            //   _todoList.removeAt(index); // 从数组中剔除
                            // });
                            // _saveTodosToFile();
                            _showDeleteConfirmDialog(index);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
