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
  EventKitCalendarAuthorizationStatus _reminderAuthStatus =
      EventKitCalendarAuthorizationStatus.notDetermined;
  List<EventKitCalendar> _calendars = [];
  List<EventKitEvent> _events = [];
  List<EventKitCalendar> _reminderCalendars = [];
  List<EventKitReminder> _reminders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize the plugin before using it
    FlutterEventKit.initialize();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      print('Checking permissions...');
      final calendarStatus =
          await FlutterEventKit.getCalendarAuthorizationStatus();
      print('Calendar status: $calendarStatus');

      final reminderStatus =
          await FlutterEventKit.getReminderAuthorizationStatus();
      print('Reminder status: $reminderStatus');

      setState(() {
        _authStatus = calendarStatus;
        _reminderAuthStatus = reminderStatus;
      });

      if (calendarStatus == EventKitCalendarAuthorizationStatus.authorized) {
        _loadCalendars();
        _loadEvents();
      }

      if (reminderStatus == EventKitCalendarAuthorizationStatus.authorized) {
        _loadReminderCalendars();
        _loadReminders();
      }
    } catch (e) {
      print('Error checking permissions: $e');
      _showSnackBar('Error checking permissions: $e');
    }
  }

  Future<void> _requestAccess() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await FlutterEventKit.requestCalendarAccess();

      if (granted) {
        await _checkPermissions();
      } else {
        _showSnackBar('Calendar access denied');
      }
    } catch (e) {
      _showSnackBar('Error requesting access: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestReminderAccess() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await FlutterEventKit.requestReminderAccess();

      if (granted) {
        await _checkPermissions();
      } else {
        _showSnackBar('Reminder access denied');
      }
    } catch (e) {
      _showSnackBar('Error requesting reminder access: $e');
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

  Future<void> _loadReminderCalendars() async {
    try {
      final calendars = await FlutterEventKit.getReminderCalendars();
      setState(() {
        _reminderCalendars = calendars;
      });
    } catch (e) {
      _showSnackBar('Error loading reminder calendars: $e');
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

  Future<void> _loadReminders() async {
    try {
      final reminders = await FlutterEventKit.getReminders();
      setState(() {
        _reminders = reminders;
      });
    } catch (e) {
      _showSnackBar('Error loading reminders: $e');
    }
  }

  Future<void> _loadIncompleteReminders() async {
    try {
      final reminders = await FlutterEventKit.getAllIncompleteReminders();
      setState(() {
        _reminders = reminders;
      });
      _showSnackBar('Loaded ${reminders.length} incomplete reminders');
    } catch (e) {
      _showSnackBar('Error loading incomplete reminders: $e');
    }
  }

  Future<void> _loadOverdueReminders() async {
    try {
      final reminders = await FlutterEventKit.getAllOverdueReminders();
      setState(() {
        _reminders = reminders;
      });
      _showSnackBar('Loaded ${reminders.length} overdue reminders');
    } catch (e) {
      _showSnackBar('Error loading overdue reminders: $e');
    }
  }

  Future<void> _loadRemindersDueToday() async {
    try {
      final reminders =
          await FlutterEventKit.getRemindersDueTodayInDefaultList();
      setState(() {
        _reminders = reminders;
      });
      _showSnackBar('Loaded ${reminders.length} reminders due today');
    } catch (e) {
      _showSnackBar('Error loading reminders due today: $e');
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

  Future<void> _createSampleReminder() async {
    if (_reminderCalendars.isEmpty) {
      _showSnackBar('No reminder calendars available');
      return;
    }

    try {
      final now = DateTime.now();
      final reminder = FlutterEventKit.createReminder(
        title: 'Sample Reminder',
        dueDate: now.add(const Duration(days: 1)),
        notes:
            'This is a sample reminder created by the Flutter EventKit plugin',
        calendarId: _reminderCalendars.first.identifier,
      );

      final reminderId = await FlutterEventKit.saveReminder(reminder);
      _showSnackBar('Reminder created with ID: $reminderId');
      _loadReminders();
    } catch (e) {
      _showSnackBar('Error creating reminder: $e');
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _createSampleReminder,
            tooltip: 'Create Reminder',
            heroTag: 'reminder',
            child: const Icon(Icons.notifications),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _createSampleEvent,
            tooltip: 'Create Event',
            heroTag: 'event',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasCalendarAccess =
        _authStatus == EventKitCalendarAuthorizationStatus.authorized;
    final hasReminderAccess =
        _reminderAuthStatus == EventKitCalendarAuthorizationStatus.authorized;

    // If both are denied or restricted, show permission denied
    if (_authStatus == EventKitCalendarAuthorizationStatus.denied ||
        _authStatus == EventKitCalendarAuthorizationStatus.restricted) {
      if (_reminderAuthStatus == EventKitCalendarAuthorizationStatus.denied ||
          _reminderAuthStatus ==
              EventKitCalendarAuthorizationStatus.restricted) {
        return _buildPermissionDenied();
      }
    }

    // If neither is determined, show permission request
    if (_authStatus == EventKitCalendarAuthorizationStatus.notDetermined &&
        _reminderAuthStatus ==
            EventKitCalendarAuthorizationStatus.notDetermined) {
      return _buildPermissionRequest();
    }

    // If we have at least one type of access, show main content
    if (hasCalendarAccess || hasReminderAccess) {
      return _buildMainContent();
    }

    // Otherwise show permission request
    return _buildPermissionRequest();
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Calendar & Reminder Access Required',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'This app needs access to your calendar and reminders to manage events and reminders.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              ElevatedButton(
                onPressed: _requestAccess,
                child: const Text('Grant Calendar Access'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _requestReminderAccess,
                child: const Text('Grant Reminder Access'),
              ),
            ],
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
            'Calendar and/or reminder access was denied. Please enable them in Settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              if (_authStatus != EventKitCalendarAuthorizationStatus.authorized)
                ElevatedButton(
                  onPressed: _requestAccess,
                  child: const Text('Request Calendar Access'),
                ),
              if (_authStatus !=
                      EventKitCalendarAuthorizationStatus.authorized &&
                  _reminderAuthStatus !=
                      EventKitCalendarAuthorizationStatus.authorized)
                const SizedBox(height: 12),
              if (_reminderAuthStatus !=
                  EventKitCalendarAuthorizationStatus.authorized)
                ElevatedButton(
                  onPressed: _requestReminderAccess,
                  child: const Text('Request Reminder Access'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final hasCalendarAccess =
        _authStatus == EventKitCalendarAuthorizationStatus.authorized;
    final hasReminderAccess =
        _reminderAuthStatus == EventKitCalendarAuthorizationStatus.authorized;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasCalendarAccess) ...[
            _buildCalendarsSection(),
            const SizedBox(height: 24),
            _buildEventsSection(),
            const SizedBox(height: 24),
          ],
          if (hasReminderAccess) ...[
            _buildReminderCalendarsSection(),
            const SizedBox(height: 24),
            _buildRemindersSection(),
          ],
          if (!hasCalendarAccess || !hasReminderAccess) ...[
            _buildMissingPermissionsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildMissingPermissionsSection() {
    final hasCalendarAccess =
        _authStatus == EventKitCalendarAuthorizationStatus.authorized;
    final hasReminderAccess =
        _reminderAuthStatus == EventKitCalendarAuthorizationStatus.authorized;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Missing Permissions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (!hasCalendarAccess) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.orange),
              title: const Text('Calendar Access Required'),
              subtitle: const Text(
                'Enable calendar access to view and manage events',
              ),
              trailing: ElevatedButton(
                onPressed: _requestAccess,
                child: const Text('Grant Access'),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (!hasReminderAccess) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications, color: Colors.orange),
              title: const Text('Reminder Access Required'),
              subtitle: const Text(
                'Enable reminder access to view and manage reminders',
              ),
              trailing: ElevatedButton(
                onPressed: _requestReminderAccess,
                child: const Text('Grant Access'),
              ),
            ),
          ),
        ],
      ],
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

  Widget _buildReminderCalendarsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reminder Calendars',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: _loadReminderCalendars,
              child: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_reminderCalendars.isEmpty)
          const Text('No reminder calendars found')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reminderCalendars.length,
            itemBuilder: (context, index) {
              final calendar = _reminderCalendars[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    Icons.notifications,
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

  Widget _buildRemindersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reminders',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: _loadReminders, child: const Text('All')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _loadIncompleteReminders,
                child: const Text('Incomplete'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _loadOverdueReminders,
                child: const Text('Overdue'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _loadRemindersDueToday,
                child: const Text('Due Today'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_reminders.isEmpty)
          const Text('No reminders found')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reminders.length,
            itemBuilder: (context, index) {
              final reminder = _reminders[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    reminder.isCompleted
                        ? Icons.check_circle
                        : Icons.notifications,
                    color: reminder.isCompleted ? Colors.green : Colors.purple,
                  ),
                  title: Text(
                    reminder.title,
                    style: TextStyle(
                      decoration: reminder.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reminder.dueDate != null)
                        Text(_formatDateTime(reminder.dueDate!)),
                      if (reminder.notes != null) Text(reminder.notes!),
                      if (reminder.priority != null)
                        Text('Priority: ${reminder.priority}'),
                    ],
                  ),
                  trailing: reminder.isCompleted
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.pending, color: Colors.orange),
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
