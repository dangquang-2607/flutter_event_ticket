import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import '../services/event_service.dart';
import '../model/event.dart';
import 'event_detail_screen.dart';
import 'event_create_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  late Future<List<Event>> _futureEvents;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      _futureEvents = EventService.getEvents();
    });
  }

  Future<void> _deleteEvent(Event event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa sự kiện"),
        content: const Text("Bạn có chắc muốn xóa sự kiện này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await EventService.deleteEvent(event.id!);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Xóa thành công")),
        );
        _loadEvents(); // refresh list
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Xóa thất bại")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final userRole = box.read("role") ?? "User";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Events"),
        actions: [
          if (userRole == "Organizer") // chỉ organizer mới tạo được sự kiện
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventCreateScreen()),
                );
                if (created == true) {
                  _loadEvents();
                }
              },
            ),
        ],
      ),
      body: FutureBuilder<List<Event>>(
        future: _futureEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("❌ Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Không có sự kiện nào"));
          }

          final events = snapshot.data!;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(event.title),
                  subtitle: Text("📍 ${event.location}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event.startTime.toString().substring(0, 10),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (userRole == "Organizer")
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteEvent(event),
                        ),
                    ],
                  ),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailScreen(
                          eventId: event.id!,
                          userRole: userRole,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadEvents();
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
