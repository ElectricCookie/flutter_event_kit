import Flutter
import UIKit
import EventKit

public class FlutterEventKitPlugin: NSObject, FlutterPlugin, EventKitHostApi {
    private let eventKitService = EventKitService()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()
        EventKitHostApiSetup.setUp(binaryMessenger: messenger, api: FlutterEventKitPlugin())
    }
    
    // MARK: - EventKitHostApi Implementation
    
    public func requestCalendarAccess() async -> Bool {
        return await eventKitService.requestCalendarAccess()
    }
    
    public func getCalendarAuthorizationStatus() async -> CalendarAuthorizationStatus {
        let status = eventKitService.getCalendarAuthorizationStatus()
        
        return convertAuthorizationStatus(status)
    }
    
    public func getCalendars() async -> [Calendar] {
        let ekCalendars = eventKitService.getCalendars()
        return ekCalendars.map { convertCalendar($0) }
    }
    
    public func getCalendar(identifier: String) async -> Calendar? {
        guard let ekCalendar = eventKitService.getCalendar(withIdentifier: identifier) else {
            return nil
        }
        return convertCalendar(ekCalendar)
    }
    
    public func getEvents(startDate: DateTime, endDate: DateTime, calendarIdentifiers: [String]?) async -> [Event] {
        let start = convertDateTime(startDate)
        let end = convertDateTime(endDate)
        
        let calendars = calendarIdentifiers?.compactMap { eventKitService.getCalendar(withIdentifier: $0) }
        let ekEvents = eventKitService.getEvents(from: start, to: end, calendars: calendars)
        
        return ekEvents.map { convertEvent($0) }
    }
    
    public func getEvent(identifier: String) async -> Event? {
        guard let ekEvent = eventKitService.getEvent(withIdentifier: identifier) else {
            return nil
        }
        return convertEvent(ekEvent)
    }
    
    public func saveEvent(event: Event) async -> String {
        let ekEvent = convertToEKEvent(event)
        
        do {
            try eventKitService.saveEvent(ekEvent)
            return ekEvent.eventIdentifier ?? ""
        } catch {
            // In a real implementation, you'd want to handle errors properly
            return ""
        }
    }
    
    public func removeEvent(identifier: String) async -> Bool {
        guard let ekEvent = eventKitService.getEvent(withIdentifier: identifier) else {
            return false
        }
        
        do {
            try eventKitService.removeEvent(ekEvent)
            return true
        } catch {
            return false
        }
    }
    
    public func getReminders(predicate: String?) async -> [Reminder] {
        let nsPredicate = predicate != nil ? NSPredicate(format: predicate!) : nil
        let ekReminders = eventKitService.getReminders(matching: nsPredicate)
        return ekReminders.map { convertReminder($0) }
    }
    
    public func saveReminder(reminder: Reminder) async -> String {
        let ekReminder = convertToEKReminder(reminder)
        
        do {
            try eventKitService.saveReminder(ekReminder)
            return ekReminder.calendarItemIdentifier ?? ""
        } catch {
            return ""
        }
    }
    
    public func removeReminder(identifier: String) async -> Bool {
        // Note: EKReminder doesn't have a direct getter by identifier
        // In a real implementation, you'd need to search for it
        return false
    }
    
    // MARK: - Conversion Methods
    
    private func convertAuthorizationStatus(_ status: EKAuthorizationStatus) -> CalendarAuthorizationStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }
    
    private func convertCalendar(_ ekCalendar: EKCalendar) -> Calendar {
        return Calendar(
            identifier: ekCalendar.calendarIdentifier,
            title: ekCalendar.title,
            source: ekCalendar.source.title,
            color: ekCalendar.CGColor?.components.map { String(format: "#%02X%02X%02X", Int($0 * 255), Int($1 * 255), Int($2 * 255)) }.first,
            isEditable: ekCalendar.allowsContentModifications,
            isSubscribed: ekCalendar.isSubscribed,
            externalId: ekCalendar.externalID
        )
    }
    
    private func convertEvent(_ ekEvent: EKEvent) -> Event {
        return Event(
            identifier: ekEvent.eventIdentifier,
            title: ekEvent.title,
            notes: ekEvent.notes,
            startDate: convertDate(ekEvent.startDate),
            endDate: convertDate(ekEvent.endDate),
            isAllDay: ekEvent.isAllDay,
            location: ekEvent.location,
            url: ekEvent.url?.absoluteString,
            availability: convertAvailability(ekEvent.availability),
            status: convertStatus(ekEvent.status),
            calendarId: ekEvent.calendar.calendarIdentifier,
            attendeeEmails: ekEvent.attendees?.compactMap { $0.emailAddress },
            recurrenceRule: ekEvent.recurrenceRules?.first.map { convertRecurrenceRule($0) }
        )
    }
    
    private func convertToEKEvent(_ event: Event) -> EKEvent {
        let ekEvent = EKEvent(eventStore: eventKitService.eventStore)
        ekEvent.title = event.title
        ekEvent.notes = event.notes
        ekEvent.startDate = convertDateTime(event.startDate)
        ekEvent.endDate = convertDateTime(event.endDate)
        ekEvent.isAllDay = event.isAllDay
        ekEvent.location = event.location
        if let urlString = event.url {
            ekEvent.url = URL(string: urlString)
        }
        ekEvent.availability = convertToEKAvailability(event.availability)
        ekEvent.status = convertToEKStatus(event.status)
        
        if let calendarId = event.calendarId {
            ekEvent.calendar = eventKitService.getCalendar(withIdentifier: calendarId) ?? EKCalendar()
        }
        
        return ekEvent
    }
    
    private func convertReminder(_ ekReminder: EKReminder) -> Reminder {
        return Reminder(
            identifier: ekReminder.calendarItemIdentifier,
            title: ekReminder.title,
            notes: ekReminder.notes,
            dueDate: ekReminder.dueDateComponents?.date,
            completionDate: ekReminder.completionDate != nil ? convertDate(ekReminder.completionDate!) : nil,
            isCompleted: ekReminder.isCompleted,
            calendarId: ekReminder.calendar.calendarIdentifier,
            priority: ekReminder.priority
        )
    }
    
    private func convertToEKReminder(_ reminder: Reminder) -> EKReminder {
        let ekReminder = EKReminder(eventStore: eventKitService.eventStore)
        ekReminder.title = reminder.title
        ekReminder.notes = reminder.notes
        if let dueDate = reminder.dueDate {
            ekReminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        }
        ekReminder.isCompleted = reminder.isCompleted
        ekReminder.priority = reminder.priority ?? 0
        
        if let calendarId = reminder.calendarId {
            ekReminder.calendar = eventKitService.getCalendar(withIdentifier: calendarId) ?? EKCalendar()
        }
        
        return ekReminder
    }
    
    private func convertAvailability(_ availability: EKEventAvailability) -> EventAvailability {
        switch availability {
        case .notSupported:
            return .notSupported
        case .busy:
            return .busy
        case .free:
            return .free
        case .tentative:
            return .tentative
        case .unavailable:
            return .unavailable
        @unknown default:
            return .notSupported
        }
    }
    
    private func convertToEKAvailability(_ availability: EventAvailability) -> EKEventAvailability {
        switch availability {
        case .notSupported:
            return .notSupported
        case .busy:
            return .busy
        case .free:
            return .free
        case .tentative:
            return .tentative
        case .unavailable:
            return .unavailable
        }
    }
    
    private func convertStatus(_ status: EKEventStatus) -> EventStatus {
        switch status {
        case .none:
            return .none
        case .confirmed:
            return .confirmed
        case .tentative:
            return .tentative
        case .canceled:
            return .canceled
        @unknown default:
            return .none
        }
    }
    
    private func convertToEKStatus(_ status: EventStatus) -> EKEventStatus {
        switch status {
        case .none:
            return .none
        case .confirmed:
            return .confirmed
        case .tentative:
            return .tentative
        case .canceled:
            return .canceled
        }
    }
    
    private func convertRecurrenceRule(_ rule: EKRecurrenceRule) -> RecurrenceRule {
        let frequency: RecurrenceFrequency
        switch rule.frequency {
        case .daily:
            frequency = .daily
        case .weekly:
            frequency = .weekly
        case .monthly:
            frequency = .monthly
        case .yearly:
            frequency = .yearly
        @unknown default:
            frequency = .daily
        }
        
        return RecurrenceRule(
            frequency: frequency,
            interval: rule.interval,
            endDate: rule.recurrenceEnd?.endDate.map { convertDate($0) },
            occurrenceCount: rule.recurrenceEnd?.count,
            daysOfTheWeek: rule.daysOfTheWeek?.compactMap { $0.dayOfTheWeek.rawValue },
            daysOfTheMonth: rule.daysOfTheMonth?.compactMap { $0.intValue },
            monthsOfTheYear: rule.monthsOfTheYear?.compactMap { $0.intValue }
        )
    }
    
    private func convertDate(_ date: Date) -> DateTime {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: date)
        
        return DateTime(
            year: Int64(components.year ?? 0),
            month: Int64(components.month ?? 0),
            day: Int64(components.day ?? 0),
            hour: Int64(components.hour ?? 0),
            minute: Int64(components.minute ?? 0),
            second: Int64(components.second ?? 0),
            millisecond: Int64((components.nanosecond ?? 0) / 1_000_000)
        )
    }
    
    private func convertDateTime(_ dateTime: DateTime) -> Date {
        var components = DateComponents()
        components.year = Int(dateTime.year)
        components.month = Int(dateTime.month)
        components.day = Int(dateTime.day)
        components.hour = Int(dateTime.hour)
        components.minute = Int(dateTime.minute)
        components.second = Int(dateTime.second)
        components.nanosecond = Int(dateTime.millisecond * 1_000_000)
        
        return Calendar.current.date(from: components) ?? Date()
    }
}
