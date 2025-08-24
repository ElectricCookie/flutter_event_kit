import 'package:flutter/material.dart';
import 'package:flutter_event_kit/flutter_event_kit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventKit Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const EventKitExample(),
    );
  }
}

class EventKitExample extends StatefulWidget {
  const EventKitExample({super.key});

  @override
  State<EventKitExample> createState() => _EventKitExampleState();
}

class _EventKitExampleState extends State<EventKitExample> {
  EventKitCalendarAuthorizationStatus _authStatus =
      EventKitCalendarAuthorizationStatus.notDetermined;
  List<EventKitCalendar> _calendars = [];
  List<EventKitEvent> _events = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await FlutterEventKit.getCalendarAuthorizationStatus();
    print('status: $status');
    setState(() {
      _authStatus = status;
    });

    if (status == EventKitCalendarAuthorizationStatus.authorized) {
      _loadCalendars();
    }
  }

  Future<void> _requestAccess() async {
    print('requestAccess');
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await FlutterEventKit.requestCalendarAccess();
      print('granted: $granted');
      if (granted) {
        await _checkPermissions();
      } else {
        _showSnackBar('Calendar access denied');
      }
    } catch (e) {
      print('error: $e');
      _showSnackBar('Error requesting access: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCalendars() async {
    try {
      final calendars = await FlutterEventKit.getCalendars();
      setState(() {
        _calendars = calendars;
      });
    } catch (e) {
      _showSnackBar('Error loading calendars: $e');
    }
  }

  Future<void> _loadEvents() async {
    if (_calendars.isEmpty) return;

    try {
      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 7));

      final events = await FlutterEventKit.getEvents(now, endDate);
      setState(() {
        _events = events;
      });
    } catch (e) {
      _showSnackBar('Error loading events: $e');
    }
  }

  Future<void> _createSampleEvent() async {
    if (_calendars.isEmpty) {
      _showSnackBar('No calendars available');
      return;
    }

    try {
      final now = DateTime.now();
      final event = FlutterEventKit.createEvent(
        title: 'Sample Event',
        startDate: now.add(const Duration(hours: 1)),
        endDate: now.add(const Duration(hours: 2)),
        notes: 'This is a sample event created by the Flutter EventKit plugin',
        location: 'Sample Location',
        calendarId: _calendars.first.identifier,
      );

      final eventId = await FlutterEventKit.saveEvent(event);
      _showSnackBar('Event created with ID: $eventId');
      _loadEvents();
    } catch (e) {
      _showSnackBar('Error creating event: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('EventKit Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPermissions,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createSampleEvent,
        tooltip: 'Create Event',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_authStatus) {
      case EventKitCalendarAuthorizationStatus.notDetermined:
        return _buildPermissionRequest();
      case EventKitCalendarAuthorizationStatus.denied:
      case EventKitCalendarAuthorizationStatus.restricted:
        return _buildPermissionDenied();
      case EventKitCalendarAuthorizationStatus.authorized:
        return _buildMainContent();
    }
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Calendar Access Required',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'This app needs access to your calendar to manage events and reminders.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _requestAccess,
            child: const Text('Grant Access'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Access Denied',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Calendar access was denied. Please enable it in Settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCalendarsSection(),
          const SizedBox(height: 24),
          _buildEventsSection(),
        ],
      ),
    );
  }

  Widget _buildCalendarsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Calendars',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: _loadCalendars, child: const Text('Refresh')),
          ],
        ),
        const SizedBox(height: 8),
        if (_calendars.isEmpty)
          const Text('No calendars found')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _calendars.length,
            itemBuilder: (context, index) {
              final calendar = _calendars[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: _parseColor(calendar.color),
                  ),
                  title: Text(calendar.title),
                  subtitle: Text(calendar.source ?? 'Unknown source'),
                  trailing: calendar.isEditable
                      ? const Icon(Icons.edit, color: Colors.green)
                      : const Icon(Icons.lock, color: Colors.grey),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Events (Next 7 Days)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: _loadEvents, child: const Text('Refresh')),
          ],
        ),
        const SizedBox(height: 8),
        if (_events.isEmpty)
          const Text('No events found')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _events.length,
            itemBuilder: (context, index) {
              final event = _events[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    event.isAllDay ? Icons.all_inclusive : Icons.event,
                    color: Colors.blue,
                  ),
                  title: Text(event.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatDateTime(event.startDate)),
                      if (event.location != null) Text(event.location!),
                    ],
                  ),
                  trailing: Icon(
                    _getEventStatusIcon(event.status),
                    color: _getEventStatusColor(event.status),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Color _parseColor(String? colorString) {
    if (colorString == null || !colorString.startsWith('#')) {
      return Colors.blue;
    }
    try {
      return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.blue;
    }
  }

  String _formatDateTime(EventKitDateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  IconData _getEventStatusIcon(EventKitEventStatus status) {
    switch (status) {
      case EventKitEventStatus.confirmed:
        return Icons.check_circle;
      case EventKitEventStatus.tentative:
        return Icons.help;
      case EventKitEventStatus.canceled:
        return Icons.cancel;
      case EventKitEventStatus.none:
        return Icons.event;
    }
  }

  Color _getEventStatusColor(EventKitEventStatus status) {
    switch (status) {
      case EventKitEventStatus.confirmed:
        return Colors.green;
      case EventKitEventStatus.tentative:
        return Colors.orange;
      case EventKitEventStatus.canceled:
        return Colors.red;
      case EventKitEventStatus.none:
        return Colors.grey;
    }
  }
}
