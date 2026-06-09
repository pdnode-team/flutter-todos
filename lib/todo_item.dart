class TodoItem {
  String title;
  bool isDone;
  DateTime? dueDate;

  TodoItem({required this.title, this.isDone = false, this.dueDate});

  // 🎯 极客封装：一键把对象转成 Map，供 SharedPreferences 消费
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isDone': isDone,
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  // 🎯 极客封装：从 Map 账本里逆向反序列化出实体对象
  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      title: map['title'] ?? '',
      isDone: map['isDone'] ?? false,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
    );
  }
}
