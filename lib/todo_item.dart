class TodoItem {
  String title;
  bool isDone;

  TodoItem({required this.title, this.isDone = false});

  // 🎯 极客封装：一键把对象转成 Map，供 SharedPreferences 消费
  Map<String, dynamic> toMap() {
    return {'title': title, 'isDone': isDone};
  }

  // 🎯 极客封装：从 Map 账本里逆向反序列化出实体对象
  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(title: map['title'] ?? '', isDone: map['isDone'] ?? false);
  }
}
