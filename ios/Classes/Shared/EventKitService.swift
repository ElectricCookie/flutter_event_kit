import Foundation
import EventKit

@available(iOS 6.0, macOS 10.8, *)
public class EventKitService {
    public let eventStore = EKEventStore()
    
    public init() {}
    
    // MARK: - Calendar Access
    
    public func requestCalendarAccess() async -> Result<Bool, Error> {
        if #available(iOS 17.0, macOS 14.0, *) {
            return await withCheckedContinuation { continuation in
                Task {
                    do {
                        let granted = try await eventStore.requestFullAccessToEvents()
                        continuation.resume(returning: .success(granted))
                    } catch {
                        continuation.resume(returning: .failure(error))
                    }
                }
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        continuation.resume(returning: .failure(error))
                    } else {
                        continuation.resume(returning: .success(granted))
                    }
                }
            }
        }
    }
    
    public func getCalendarAuthorizationStatus() -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .event)
    }
    
    // MARK: - Reminder Access
    
    public func requestReminderAccess() async -> Result<Bool, Error> {
        if #available(iOS 17.0, macOS 14.0, *) {
            return await withCheckedContinuation { continuation in
                Task {
                    do {
                        let granted = try await eventStore.requestFullAccessToReminders()
                        continuation.resume(returning: .success(granted))
                    } catch {
                        continuation.resume(returning: .failure(error))
                    }
                }
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .reminder) { granted, error in
                    if let error = error {
                        continuation.resume(returning: .failure(error))
                    } else {
                        continuation.resume(returning: .success(granted))
                    }
                }
            }
        }
    }
    
    public func getReminderAuthorizationStatus() -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .reminder)
    }
    
    // MARK: - Calendars
    
    public func getCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .event)
    }
    
    public func getReminderCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .reminder)
    }
    
    public func getDefaultReminderCalendar() -> EKCalendar? {
        return eventStore.defaultCalendarForNewReminders()
    }
    
    public func getCalendar(withIdentifier identifier: String) -> EKCalendar? {
        return eventStore.calendar(withIdentifier: identifier)
    }
    
    // MARK: - Events
    
    public func getEvents(from startDate: Date, to endDate: Date, calendars: [EKCalendar]? = nil) -> [EKEvent] {
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        return eventStore.events(matching: predicate)
    }
    
    public func getEvent(withIdentifier identifier: String) -> EKEvent? {
        return eventStore.event(withIdentifier: identifier)
    }
    
    public func getEvent(withCalendarItemIdentifier identifier: String) -> EKEvent? {
        return eventStore.calendarItem(withIdentifier: identifier) as? EKEvent
    }

    public func calendarItem(withIdentifier identifier: String) -> EKCalendarItem? {
        return eventStore.calendarItem(withIdentifier: identifier)
    }

    public func calendarItems(withExternalIdentifier identifier: String) -> [EKCalendarItem] {
        return eventStore.calendarItems(withExternalIdentifier: identifier)
    }

    public func calendarItemsWithExternalIdentifier(_ identifier: String) -> [EKEvent] {
        return eventStore.calendarItems(withExternalIdentifier: identifier).compactMap { $0 as? EKEvent }
    }

    public func defaultCalendarForNewEvents() -> EKCalendar? {
        return eventStore.defaultCalendarForNewEvents
    }
    
    public func saveEvent(_ event: EKEvent, span: EKSpan = .thisEvent) throws {
        try eventStore.save(event, span: span, commit: true)
    }
    
    public func removeEvent(_ event: EKEvent, span: EKSpan = .thisEvent) throws {
        try eventStore.remove(event, span: span, commit: true)
    }
    
    // MARK: - Reminders
    
    public func getReminders(matching predicate: NSPredicate?) async -> [EKReminder] {
        guard let predicate = predicate else {
            return []
        }
        
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                let reminderArray = reminders ?? []
                continuation.resume(returning: reminderArray)
            }
        }
    }
    
    public func getAllReminders() async -> [EKReminder] {
        let predicate = eventStore.predicateForReminders(in: nil)
        return await getReminders(matching: predicate)
    }
    
    public func getCompletedReminders(startDate: Date?, endDate: Date?, calendars: [EKCalendar]?) async -> [EKReminder] {
        let predicate = eventStore.predicateForCompletedReminders(withCompletionDateStarting: startDate, ending: endDate, calendars: calendars)
        return await getReminders(matching: predicate)
    }
    
    public func getIncompleteReminders(startDate: Date?, endDate: Date?, calendars: [EKCalendar]?) async -> [EKReminder] {
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: startDate, ending: endDate, calendars: calendars)
        return await getReminders(matching: predicate)
    }
    
    public func saveReminder(_ reminder: EKReminder) throws {
        try eventStore.save(reminder, commit: true)
    }
    
    public func removeReminder(_ reminder: EKReminder) throws {
        try eventStore.remove(reminder, commit: true)
    }
}
