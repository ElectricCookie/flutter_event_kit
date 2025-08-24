import Foundation
import EventKit

@available(iOS 6.0, macOS 10.8, *)
public class EventKitService {
    public let eventStore = EKEventStore()
    
    public init() {}
    
    // MARK: - Calendar Access
    
    public func requestCalendarAccess() async -> Bool {
        if #available(iOS 17.0, macOS 14.0, *) {
            return await withCheckedContinuation { continuation in
                Task {
                    let granted = await eventStore.requestFullAccessToEvents()
                    continuation.resume(returning: granted)
                }
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    public func getCalendarAuthorizationStatus() -> EKAuthorizationStatus {
        if #available(iOS 17.0, macOS 14.0, *) {
            return eventStore.fullAccessStatus
        } else {
            return EKEventStore.authorizationStatus(for: .event)
        }
    }
    
    // MARK: - Calendars
    
    public func getCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .event)
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
    
    public func saveEvent(_ event: EKEvent) throws {
        try eventStore.save(event, span: .thisEvent, commit: true)
    }
    
    public func removeEvent(_ event: EKEvent) throws {
        try eventStore.remove(event, span: .thisEvent, commit: true)
    }
    
    // MARK: - Reminders
    
    public func getReminders(matching predicate: NSPredicate?) -> [EKReminder] {
        return eventStore.reminders(matching: predicate)
    }
    
    public func saveReminder(_ reminder: EKReminder) throws {
        try eventStore.save(reminder, commit: true)
    }
    
    public func removeReminder(_ reminder: EKReminder) throws {
        try eventStore.remove(reminder, commit: true)
    }
}
