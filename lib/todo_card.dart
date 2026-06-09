import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'todo_item.dart';

class TodoCard extends StatelessWidget {
  final TodoItem item;
  final VoidCallback onCheckChanged;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  const TodoCard({
    super.key,
    required this.item,
    required this.onCheckChanged,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 2,
      child: ListTile(
        // 左边：复选框
        leading: Checkbox(
          activeColor: Colors.deepPurple,
          value: item.isDone,
          onChanged: (bool? _) => onCheckChanged(),
        ),
        // 中间：文字 + 到期时间
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 16,
            decoration: item.isDone ? TextDecoration.lineThrough : null,
            color: item.isDone ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: item.dueDate != null
            ? Text(
                'Due: ${DateFormat('yyyy-MM-dd').format(item.dueDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: item.dueDate!.isBefore(DateTime.now()) && !item.isDone
                      ? Colors.redAccent
                      : Colors.grey,
                ),
              )
            : null,
        // 右边：多个动作按钮（Row 闭环）
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: onEditPressed),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: onDeletePressed,
            ),
          ],
        ),
      ),
    );
  }
}
