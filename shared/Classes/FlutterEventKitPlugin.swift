
#if os(macOS)
import Cocoa
import FlutterMacOS
import EventKit
#elseif os(iOS)
import UIKit
import Flutter
import EventKit
#endif

public class FlutterEventKitPlugin: NSObject, FlutterPlugin, EventKitHostApi {
    // MARK: - EventKitHostApi Implementation
    
    func requestCalendarAccess(completion: @escaping (Result<Bool, any Error>) -> Void) {
        Task {
            do {
                let result = await eventKitService.requestCalendarAccess()
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getCalendarAuthorizationStatus(completion: @escaping (Result<EventKitCalendarAuthorizationStatus, any Error>) -> Void) {
        Task {
            do {
                let status = eventKitService.getCalendarAuthorizationStatus()
                let convertedStatus = convertAuthorizationStatus(status)
                completion(.success(convertedStatus))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func requestReminderAccess(completion: @escaping (Result<Bool, any Error>) -> Void) {
        Task {
            do {
                let result = await eventKitService.requestReminderAccess()
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getReminderAuthorizationStatus(completion: @escaping (Result<EventKitCalendarAuthorizationStatus, any Error>) -> Void) {
        Task {
            do {
                let status = eventKitService.getReminderAuthorizationStatus()
                let convertedStatus = convertAuthorizationStatus(status)
                completion(.success(convertedStatus))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getCalendars(completion: @escaping (Result<[EventKitCalendar], any Error>) -> Void) {
        Task {
            do {
                let ekCalendars = eventKitService.getCalendars()
                let calendars = ekCalendars.map { convertCalendar($0) }
                completion(.success(calendars))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getCalendar(identifier: String, completion: @escaping (Result<EventKitCalendar?, any Error>) -> Void) {
        Task {
            do {
                guard let ekCalendar = eventKitService.getCalendar(withIdentifier: identifier) else {
                    completion(.success(nil))
                    return
                }
                let calendar = convertCalendar(ekCalendar)
                completion(.success(calendar))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getReminderCalendars(completion: @escaping (Result<[EventKitCalendar], any Error>) -> Void) {
        Task {
            do {
                let ekCalendars = eventKitService.getReminderCalendars()
                let calendars = ekCalendars.map { convertCalendar($0) }
                completion(.success(calendars))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getDefaultReminderCalendar(completion: @escaping (Result<EventKitCalendar?, any Error>) -> Void) {
        Task {
            do {
                guard let ekCalendar = eventKitService.getDefaultReminderCalendar() else {
                    completion(.success(nil))
                    return
                }
                let calendar = convertCalendar(ekCalendar)
                completion(.success(calendar))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getEvents(startDate: EventKitDateTime, endDate: EventKitDateTime, calendarIdentifiers: [String]?, completion: @escaping (Result<[EventKitEvent], any Error>) -> Void) {
        Task {
            do {
                let start = convertDateTime(startDate)
                let end = convertDateTime(endDate)
                
                let calendars = calendarIdentifiers?.compactMap { eventKitService.getCalendar(withIdentifier: $0) }
                let ekEvents = eventKitService.getEvents(from: start, to: end, calendars: calendars)
                
                let events = ekEvents.map { convertEvent($0) }
                completion(.success(events))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getEvent(identifier: String, completion: @escaping (Result<EventKitEvent?, any Error>) -> Void) {
        Task {
            do {
                guard let ekEvent = eventKitService.getEvent(withIdentifier: identifier) else {
                    completion(.success(nil))
                    return
                }
                let event = convertEvent(ekEvent)
                completion(.success(event))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func saveEvent(event: EventKitEvent, completion: @escaping (Result<String, any Error>) -> Void) {
        Task {
            do {
                let ekEvent = convertToEKEvent(event)
                try eventKitService.saveEvent(ekEvent)
                let identifier = ekEvent.eventIdentifier ?? ""
                completion(.success(identifier))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func removeEvent(identifier: String, completion: @escaping (Result<Bool, any Error>) -> Void) {
        Task {
            do {
                guard let ekEvent = eventKitService.getEvent(withIdentifier: identifier) else {
                    completion(.success(false))
                    return
                }
                
                try eventKitService.removeEvent(ekEvent)
                completion(.success(true))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getReminders(predicate: String?, completion: @escaping (Result<[EventKitReminder], any Error>) -> Void) {
        Task {
            do {
                let ekReminders: [EKReminder]
                
                if let predicate = predicate {
                    // For custom predicates, we need to use predicateForReminders(in:) method
                    // The predicate string should be a calendar identifier or nil for all calendars
                    let calendars = predicate.isEmpty ? nil : [eventKitService.getCalendar(withIdentifier: predicate)].compactMap { $0 }
                    let nsPredicate = eventKitService.eventStore.predicateForReminders(in: calendars)
                    ekReminders = await eventKitService.getReminders(matching: nsPredicate)
                } else {
                    // Get all reminders
                    ekReminders = await eventKitService.getAllReminders()
                }
                
                let reminders = ekReminders.map { convertReminder($0) }
                completion(.success(reminders))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func saveReminder(reminder: EventKitReminder, completion: @escaping (Result<String, any Error>) -> Void) {
        Task {
            do {
                let ekReminder = convertToEKReminder(reminder)
                try eventKitService.saveReminder(ekReminder)
                let identifier = ekReminder.calendarItemIdentifier
                completion(.success(identifier))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func removeReminder(identifier: String, completion: @escaping (Result<Bool, any Error>) -> Void) {
        Task {
            do {
                // Note: EKReminder doesn't have a direct getter by identifier
                // In a real implementation, you'd need to search for it
                // For now, return false as the current implementation does
                completion(.success(false))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getIncompleteReminders(calendarIdentifiers: [String]?, startDate: EventKitDateTime?, endDate: EventKitDateTime?, completion: @escaping (Result<[EventKitReminder], any Error>) -> Void) {
        Task {
            do {
                let start = startDate != nil ? convertDateTime(startDate!) : nil
                let end = endDate != nil ? convertDateTime(endDate!) : nil
                let calendars = calendarIdentifiers?.compactMap { eventKitService.getCalendar(withIdentifier: $0) }
                
                let ekReminders = await eventKitService.getIncompleteReminders(startDate: start, endDate: end, calendars: calendars)
                let reminders = ekReminders.map { convertReminder($0) }
                completion(.success(reminders))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getCompletedReminders(calendarIdentifiers: [String]?, startDate: EventKitDateTime?, endDate: EventKitDateTime?, completion: @escaping (Result<[EventKitReminder], any Error>) -> Void) {
        Task {
            do {
                let start = startDate != nil ? convertDateTime(startDate!) : nil
                let end = endDate != nil ? convertDateTime(endDate!) : nil
                let calendars = calendarIdentifiers?.compactMap { eventKitService.getCalendar(withIdentifier: $0) }
                
                let ekReminders = await eventKitService.getCompletedReminders(startDate: start, endDate: end, calendars: calendars)
                let reminders = ekReminders.map { convertReminder($0) }
                completion(.success(reminders))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private let eventKitService = EventKitService()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
        let messenger = registrar.messenger()
        #else
        let messenger = registrar.messenger
        #endif
        EventKitHostApiSetup.setUp(binaryMessenger: messenger, api: FlutterEventKitPlugin())
    }
    
    // MARK: - Conversion Methods
    
    private func convertAuthorizationStatus(_ status: EKAuthorizationStatus) -> EventKitCalendarAuthorizationStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        default:
            return .notDetermined
        }
    }
    
    private func convertCalendar(_ ekCalendar: EKCalendar) -> EventKitCalendar {
        var colorHex: String? = nil
        if let cgColor = ekCalendar.cgColor {
            let components = cgColor.components
            if let components = components, components.count >= 3 {
                let red = Int(components[0] * 255)
                let green = Int(components[1] * 255)
                let blue = Int(components[2] * 255)
                colorHex = String(format: "#%02X%02X%02X", red, green, blue)
            }
        }
        
        return EventKitCalendar(
            identifier: ekCalendar.calendarIdentifier,
            title: ekCalendar.title,
            source: ekCalendar.source.title,
            color: colorHex,
            isEditable: ekCalendar.allowsContentModifications,
            isSubscribed: ekCalendar.isSubscribed,
        )
    }
    
    private func convertEvent(_ ekEvent: EKEvent) -> EventKitEvent {
        return EventKitEvent(
            identifier: ekEvent.eventIdentifier,
            title: ekEvent.title,
            notes: ekEvent.notes,
            startDate: convertDate(ekEvent.startDate)!,
            endDate: convertDate(ekEvent.endDate)!,
            isAllDay: ekEvent.isAllDay,
            location: ekEvent.location,
            url: ekEvent.url?.absoluteString,
            availability: convertAvailability(ekEvent.availability),
            status: convertStatus(ekEvent.status),
            calendarId: ekEvent.calendar.calendarIdentifier,
            attendeeEmails: nil, // ekEvent.attendees?.compactMap { $0.emailAddress },
            recurrenceRule: ekEvent.recurrenceRules?.first.map { convertRecurrenceRule($0) }
        )
    }
    
    private func convertToEKEvent(_ event: EventKitEvent) -> EKEvent {
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
        // ekEvent.status = convertToEKStatus(event.status) // Status is read-only
        
        if let calendarId = event.calendarId {
            ekEvent.calendar = eventKitService.getCalendar(withIdentifier: calendarId) ?? EKCalendar()
        }
        
        return ekEvent
    }
    
    private func convertReminder(_ ekReminder: EKReminder) -> EventKitReminder {
        return EventKitReminder(
            identifier: ekReminder.calendarItemIdentifier,
            title: ekReminder.title,
            notes: ekReminder.notes,
            dueDate: convertDate(ekReminder.dueDateComponents?.date),
            completionDate: convertDate(ekReminder.completionDate),
            isCompleted: ekReminder.isCompleted,
            calendarId: ekReminder.calendar.calendarIdentifier,
            priority: Int64(ekReminder.priority)
        )
    }
    
    private func convertToEKReminder(_ reminder: EventKitReminder) -> EKReminder {
        let ekReminder = EKReminder(eventStore: eventKitService.eventStore)
        ekReminder.title = reminder.title
        ekReminder.notes = reminder.notes
        if let dueDate = reminder.dueDate {
            ekReminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: convertDateTime(dueDate))
        }
        ekReminder.isCompleted = reminder.isCompleted
        ekReminder.priority = Int(Int64(reminder.priority ?? 0))
        
        if let calendarId = reminder.calendarId {
            ekReminder.calendar = eventKitService.getCalendar(withIdentifier: calendarId) ?? eventKitService.getDefaultReminderCalendar() ?? EKCalendar()
        } else {
            // Default to the default reminder calendar if no calendar is specified
            ekReminder.calendar = eventKitService.getDefaultReminderCalendar() ?? EKCalendar()
        }
        
        return ekReminder
    }
    
    private func convertAvailability(_ availability: EKEventAvailability) -> EventKitEventAvailability {
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
    
    private func convertToEKAvailability(_ availability: EventKitEventAvailability) -> EKEventAvailability {
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
    
    private func convertStatus(_ status: EKEventStatus) -> EventKitEventStatus {
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
    
    private func convertToEKStatus(_ status: EventKitEventStatus) -> EKEventStatus {
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
    
    private func convertRecurrenceRule(_ rule: EKRecurrenceRule) -> EventKitRecurrenceRule {
        let frequency: EventKitRecurrenceFrequency
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
        
        return EventKitRecurrenceRule(
            frequency: frequency,
            interval: Int64(rule.interval),
            endDate: rule.recurrenceEnd?.endDate.map { convertDate($0)! },
            daysOfTheWeek: rule.daysOfTheWeek?.compactMap { Int64($0.dayOfTheWeek.rawValue) },
            daysOfTheMonth: rule.daysOfTheMonth?.compactMap { Int64($0.intValue) },
            monthsOfTheYear: rule.monthsOfTheYear?.compactMap { Int64($0.intValue) }
        )
    }
    
    private func convertDate(_ date: Date?) -> EventKitDateTime? {
        
        if(date == nil){
            return nil
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: date!)
        
        return EventKitDateTime(
            year: Int64(components.year ?? 0),
            month: Int64(components.month ?? 0),
            day: Int64(components.day ?? 0),
            hour: Int64(components.hour ?? 0),
            minute: Int64(components.minute ?? 0),
            second: Int64(components.second ?? 0),
            millisecond: Int64((components.nanosecond ?? 0) / 1_000_000)
        )
    }
    
    private func convertDateTime(_ dateTime: EventKitDateTime) -> Date {
        
        
        
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
