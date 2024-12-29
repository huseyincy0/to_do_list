import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gelişmiş ToDo List',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TodoListScreen(),
    );
  }
}

class Category {
  final String name;
  final List<String> subCategories;
  final IconData icon;

  Category({required this.name, required this.subCategories, required this.icon});
}

class Todo {
  String title;
  String description;
  bool isCompleted;
  DateTime? dueDate;
  Priority priority;
  String category;
  String? subCategory;
  DateTime createdAt;
  List<String> tags;

  Todo({
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.dueDate,
    this.priority = Priority.normal,
    this.category = 'Genel',
    this.subCategory,
    List<String>? tags,
  }) : createdAt = DateTime.now(),
       tags = tags ?? [];
}

enum Priority { low, normal, high }

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<Todo> _todos = [];
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  final List<Category> _categories = [
    Category(
      name: 'Genel',
      subCategories: ['Diğer'],
      icon: Icons.list,
    ),
    Category(
      name: 'İş',
      subCategories: ['Toplantılar', 'Projeler', 'Görevler', 'Raporlar'],
      icon: Icons.work,
    ),
    Category(
      name: 'Kişisel',
      subCategories: ['Sağlık', 'Spor', 'Hobiler', 'Eğitim'],
      icon: Icons.person,
    ),
    Category(
      name: 'Alışveriş',
      subCategories: ['Market', 'Giyim', 'Elektronik', 'Ev'],
      icon: Icons.shopping_cart,
    ),
    Category(
      name: 'Önemli',
      subCategories: ['Acil', 'Kritik', 'Takip'],
      icon: Icons.star,
    ),
  ];

  String _selectedCategory = 'Genel';
  String? _selectedSubCategory;
  Priority _selectedPriority = Priority.normal;
  DateTime? _selectedDate;
  String _searchQuery = '';
  Priority? _filterPriority;
  String? _filterCategory;

  List<Todo> get _filteredTodos {
    return _todos.where((todo) {
      final matchesSearch = todo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          todo.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          todo.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      
      final matchesPriority = _filterPriority == null || todo.priority == _filterPriority;
      final matchesCategory = _filterCategory == null || todo.category == _filterCategory;

      return matchesSearch && matchesPriority && matchesCategory;
    }).toList();
  }

  void _addTodo(String title) {
    if (title.isNotEmpty) {
      setState(() {
        _todos.add(Todo(
          title: title,
          description: _descriptionController.text,
          dueDate: _selectedDate,
          priority: _selectedPriority,
          category: _selectedCategory,
          subCategory: _selectedSubCategory,
          tags: _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        ));
        _resetForm();
      });
    }
  }

  void _resetForm() {
    _controller.clear();
    _descriptionController.clear();
    _tagsController.clear();
    setState(() {
      _selectedDate = null;
      _selectedPriority = Priority.normal;
      _selectedCategory = 'Genel';
      _selectedSubCategory = null;
    });
  }

  void _removeTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
  }

  void _toggleTodoStatus(int index) {
    setState(() {
      _todos[index].isCompleted = !_todos[index].isCompleted;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _showTaskDetails(Todo todo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              todo.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Açıklama:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(todo.description.isEmpty ? 'Açıklama yok' : todo.description),
            const SizedBox(height: 8),
            Text(
              'Kategori: ${todo.category}${todo.subCategory != null ? ' > ${todo.subCategory}' : ''}',
            ),
            if (todo.dueDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Tarih: ${DateFormat('dd/MM/yyyy HH:mm').format(todo.dueDate!)}',
              ),
            ],
            if (todo.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: todo.tags.map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                )).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Oluşturulma: ${DateFormat('dd/MM/yyyy HH:mm').format(todo.createdAt)}',
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red.shade100;
      case Priority.normal:
        return Colors.blue.shade50;
      case Priority.low:
        return Colors.green.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelişmiş ToDo List'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => StatefulBuilder(
                  builder: (context, setModalState) => Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Filtrele', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        DropdownButton<Priority?>(
                          value: _filterPriority,
                          isExpanded: true,
                          hint: const Text('Öncelik Seç'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Tümü')),
                            ...Priority.values.map((priority) => DropdownMenuItem(
                              value: priority,
                              child: Text(priority.toString().split('.').last),
                            )),
                          ],
                          onChanged: (value) {
                            setModalState(() {
                              setState(() {
                                _filterPriority = value;
                              });
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<String?>(
                          value: _filterCategory,
                          isExpanded: true,
                          hint: const Text('Kategori Seç'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Tümü')),
                            ..._categories.map((category) => DropdownMenuItem(
                              value: category.name,
                              child: Text(category.name),
                            )),
                          ],
                          onChanged: (value) {
                            setModalState(() {
                              setState(() {
                                _filterCategory = value;
                              });
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Görev ara...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Yeni görev ekle',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Açıklama',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    hintText: 'Etiketler (virgülle ayırın)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        items: _categories.map((Category category) {
                          return DropdownMenuItem<String>(
                            value: category.name,
                            child: Row(
                              children: [
                                Icon(category.icon),
                                const SizedBox(width: 8),
                                Text(category.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedCategory = value ?? 'Genel';
                            _selectedSubCategory = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String?>(
                        value: _selectedSubCategory,
                        isExpanded: true,
                        hint: const Text('Alt Kategori'),
                        items: _categories
                            .firstWhere((cat) => cat.name == _selectedCategory)
                            .subCategories
                            .map((String subCategory) {
                          return DropdownMenuItem<String>(
                            value: subCategory,
                            child: Text(subCategory),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedSubCategory = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<Priority>(
                        value: _selectedPriority,
                        isExpanded: true,
                        items: Priority.values.map((Priority priority) {
                          return DropdownMenuItem<Priority>(
                            value: priority,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.flag,
                                  color: priority == Priority.high
                                      ? Colors.red
                                      : priority == Priority.normal
                                          ? Colors.blue
                                          : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(priority.toString().split('.').last),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (Priority? value) {
                          setState(() {
                            _selectedPriority = value ?? Priority.normal;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _selectedDate == null
                              ? 'Tarih Seç'
                              : DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _addTodo(_controller.text),
                    icon: const Icon(Icons.add),
                    label: const Text('Ekle'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _filteredTodos.length,
              itemBuilder: (context, index) {
                final todo = _filteredTodos[index];
                return Card(
                  color: _getPriorityColor(todo.priority),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Checkbox(
                      value: todo.isCompleted,
                      onChanged: (bool? value) => _toggleTodoStatus(index),
                    ),
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${todo.category}${todo.subCategory != null ? ' > ${todo.subCategory}' : ''}'),
                        if (todo.dueDate != null)
                          Text('Tarih: ${DateFormat('dd/MM/yyyy HH:mm').format(todo.dueDate!)}'),
                        if (todo.tags.isNotEmpty)
                          Wrap(
                            spacing: 4,
                            children: todo.tags.map((tag) => Chip(
                              label: Text(tag, style: const TextStyle(fontSize: 10)),
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            )).toList(),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => _showTaskDetails(todo),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeTodo(index),
                        ),
                      ],
                    ),
                    onTap: () => _showTaskDetails(todo),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}
