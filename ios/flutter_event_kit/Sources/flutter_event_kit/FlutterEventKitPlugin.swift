
#if os(macOS)
import Cocoa
import FlutterMacOS
import EventKit
import CoreLocation
#elseif os(iOS)
import UIKit
import Flutter
import EventKit
import EventKitUI
import CoreLocation
#endif

public class FlutterEventKitPlugin: NSObject, FlutterPlugin, EventKitHostApi {
    private static var sharedInstance: FlutterEventKitPlugin?

    private let eventKitService = EventKitService()
    private var flutterApi: EventKitFlutterApi?
    private var storeObserver: NSObjectProtocol?
    #if os(iOS)
    private let eventViewPresenter = EventViewPresenter()
    #endif

    public static func register(with registrar: FlutterPluginRegistrar) {
        let plugin = FlutterEventKitPlugin()
        sharedInstance = plugin
        #if os(iOS)
        let messenger = registrar.messenger()
        #else
        let messenger = registrar.messenger
        #endif
        plugin.flutterApi = EventKitFlutterApi(binaryMessenger: messenger)
        EventKitHostApiSetup.setUp(binaryMessenger: messenger, api: plugin)
        plugin.startObservingStoreChanges()
    }

    deinit {
        if let storeObserver {
            NotificationCenter.default.removeObserver(storeObserver)
        }
    }

    private func startObservingStoreChanges() {
        storeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventKitService.eventStore,
            queue: .main
        ) { [weak self] _ in
            self?.flutterApi?.onEventsChanged { _ in }
        }
    }

    // MARK: - Calendar Access

    func requestCalendarAccess(completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            let result = await eventKitService.requestCalendarAccess()
            switch result {
            case .success(let granted):
                let status = convertAuthorizationStatus(
                    eventKitService.getCalendarAuthorizationStatus()
                )
                flutterApi?.onCalendarAccessChanged(status: status) { _ in }
                completion(.success(granted))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getCalendarAuthorizationStatus(
        completion: @escaping (Result<EventKitCalendarAuthorizationStatus, Error>) -> Void
    ) {
        let status = convertAuthorizationStatus(eventKitService.getCalendarAuthorizationStatus())
        completion(.success(status))
    }

    func requestReminderAccess(completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            let result = await eventKitService.requestReminderAccess()
            switch result {
            case .success(let granted):
                completion(.success(granted))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getReminderAuthorizationStatus(
        completion: @escaping (Result<EventKitCalendarAuthorizationStatus, Error>) -> Void
    ) {
        let status = convertAuthorizationStatus(eventKitService.getReminderAuthorizationStatus())
        completion(.success(status))
    }

    // MARK: - Calendars

    func getCalendars(completion: @escaping (Result<[EventKitCalendar], Error>) -> Void) {
        let calendars = eventKitService.getCalendars().map { convertCalendar($0) }
        completion(.success(calendars))
    }

    func getCalendar(
        identifier: String,
        completion: @escaping (Result<EventKitCalendar?, Error>) -> Void
    ) {
        guard let ekCalendar = eventKitService.getCalendar(withIdentifier: identifier) else {
            completion(.success(nil))
            return
        }
        completion(.success(convertCalendar(ekCalendar)))
    }

    func getReminderCalendars(completion: @escaping (Result<[EventKitCalendar], Error>) -> Void) {
        let calendars = eventKitService.getReminderCalendars().map { convertCalendar($0) }
        completion(.success(calendars))
    }

    func getDefaultReminderCalendar(
        completion: @escaping (Result<EventKitCalendar?, Error>) -> Void
    ) {
        guard let ekCalendar = eventKitService.getDefaultReminderCalendar() else {
            completion(.success(nil))
            return
        }
        completion(.success(convertCalendar(ekCalendar)))
    }

    // MARK: - Events

    func getEvents(
        startDate: EventKitDateTime,
        endDate: EventKitDateTime,
        calendarIdentifiers: [String]?,
        completion: @escaping (Result<[EventKitEvent], Error>) -> Void
    ) {
        let start = convertDateTime(startDate, timeZoneIdentifier: nil)
        let end = convertDateTime(endDate, timeZoneIdentifier: nil)
        let calendars = calendarIdentifiers?.compactMap {
            eventKitService.getCalendar(withIdentifier: $0)
        }
        let events = eventKitService.getEvents(from: start, to: end, calendars: calendars)
            .map { convertEvent($0) }
        completion(.success(events))
    }

    func getEvent(
        identifier: String,
        completion: @escaping (Result<EventKitEvent?, Error>) -> Void
    ) {
        guard let ekEvent = eventKitService.getEvent(withIdentifier: identifier) else {
            completion(.success(nil))
            return
        }
        completion(.success(convertEvent(ekEvent)))
    }

    func getEventByCalendarItemIdentifier(
        identifier: String,
        completion: @escaping (Result<EventKitEvent?, Error>) -> Void
    ) {
        guard let ekEvent = eventKitService.calendarItem(withIdentifier: identifier) as? EKEvent else {
            completion(.success(nil))
            return
        }
        completion(.success(convertEvent(ekEvent)))
    }

    func getCalendarItemsWithExternalIdentifier(
        externalIdentifier: String,
        completion: @escaping (Result<[EventKitEvent], Error>) -> Void
    ) {
        let events = eventKitService.calendarItems(withExternalIdentifier: externalIdentifier)
            .compactMap { $0 as? EKEvent }
            .map { convertEvent($0) }
        completion(.success(events))
    }

    func saveEvent(
        event: EventKitEvent,
        span: EventKitSpan,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        do {
            let ekEvent = resolveOrCreateEvent(event)
            applyEventFields(event, to: ekEvent)
            try eventKitService.saveEvent(ekEvent, span: convertSpan(span))
            completion(.success(ekEvent.eventIdentifier ?? ""))
        } catch {
            completion(.failure(error))
        }
    }

    func removeEvent(
        identifier: String,
        span: EventKitSpan,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        do {
            guard let ekEvent = eventKitService.getEvent(withIdentifier: identifier)
                ?? eventKitService.calendarItem(withIdentifier: identifier) as? EKEvent
            else {
                completion(.success(false))
                return
            }
            try eventKitService.removeEvent(ekEvent, span: convertSpan(span))
            completion(.success(true))
        } catch {
            completion(.failure(error))
        }
    }

    func presentEventView(
        eventIdentifier: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        #if os(iOS)
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                completion(.success(false))
                return
            }
            guard let ekEvent = self.eventKitService.getEvent(withIdentifier: eventIdentifier)
                ?? self.eventKitService.calendarItem(withIdentifier: eventIdentifier) as? EKEvent
            else {
                completion(.success(false))
                return
            }
            guard let presenter = self.topViewController() else {
                completion(.success(false))
                return
            }
            let eventViewController = EKEventViewController()
            eventViewController.event = ekEvent
            eventViewController.allowsEditing = ekEvent.calendar?.allowsContentModifications ?? false
            eventViewController.allowsCalendarPreview = true
            eventViewController.delegate = self.eventViewPresenter
            let navigationController = UINavigationController(rootViewController: eventViewController)
            navigationController.modalPresentationStyle = .pageSheet
            navigationController.presentationController?.delegate = self.eventViewPresenter
            self.eventViewPresenter.completePreviousIfNeeded()
            self.eventViewPresenter.onDismissed = {
                completion(.success(true))
            }
            presenter.present(navigationController, animated: true)
        }
        #else
        completion(.success(false))
        #endif
    }

    // MARK: - Reminders

    func getReminders(
        predicate: String?,
        completion: @escaping (Result<[EventKitReminder], Error>) -> Void
    ) {
        Task {
            let ekReminders: [EKReminder]
            if let predicate {
                let calendars = predicate.isEmpty
                    ? nil
                    : [eventKitService.getCalendar(withIdentifier: predicate)].compactMap { $0 }
                let nsPredicate = eventKitService.eventStore.predicateForReminders(in: calendars)
                ekReminders = await eventKitService.getReminders(matching: nsPredicate)
            } else {
                ekReminders = await eventKitService.getAllReminders()
            }
            completion(.success(ekReminders.map { convertReminder($0) }))
        }
    }

    func saveReminder(
        reminder: EventKitReminder,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        do {
            let ekReminder = resolveOrCreateReminder(reminder)
            applyReminderFields(reminder, to: ekReminder)
            try eventKitService.saveReminder(ekReminder)
            completion(.success(ekReminder.calendarItemIdentifier))
        } catch {
            completion(.failure(error))
        }
    }

    func removeReminder(
        identifier: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        do {
            guard let ekReminder = eventKitService.calendarItem(withIdentifier: identifier) as? EKReminder else {
                completion(.success(false))
                return
            }
            try eventKitService.removeReminder(ekReminder)
            completion(.success(true))
        } catch {
            completion(.failure(error))
        }
    }

    func getIncompleteReminders(
        calendarIdentifiers: [String]?,
        startDate: EventKitDateTime?,
        endDate: EventKitDateTime?,
        completion: @escaping (Result<[EventKitReminder], Error>) -> Void
    ) {
        Task {
            let start = startDate.map { convertDateTime($0, timeZoneIdentifier: nil) }
            let end = endDate.map { convertDateTime($0, timeZoneIdentifier: nil) }
            let calendars = calendarIdentifiers?.compactMap {
                eventKitService.getCalendar(withIdentifier: $0)
            }
            let reminders = await eventKitService.getIncompleteReminders(
                startDate: start,
                endDate: end,
                calendars: calendars
            )
            completion(.success(reminders.map { convertReminder($0) }))
        }
    }

    func getCompletedReminders(
        calendarIdentifiers: [String]?,
        startDate: EventKitDateTime?,
        endDate: EventKitDateTime?,
        completion: @escaping (Result<[EventKitReminder], Error>) -> Void
    ) {
        Task {
            let start = startDate.map { convertDateTime($0, timeZoneIdentifier: nil) }
            let end = endDate.map { convertDateTime($0, timeZoneIdentifier: nil) }
            let calendars = calendarIdentifiers?.compactMap {
                eventKitService.getCalendar(withIdentifier: $0)
            }
            let reminders = await eventKitService.getCompletedReminders(
                startDate: start,
                endDate: end,
                calendars: calendars
            )
            completion(.success(reminders.map { convertReminder($0) }))
        }
    }

    // MARK: - Resolve / apply

    private func resolveOrCreateEvent(_ event: EventKitEvent) -> EKEvent {
        if let identifier = event.eventIdentifier ?? event.identifier, !identifier.isEmpty,
           let existing = eventKitService.getEvent(withIdentifier: identifier) {
            return existing
        }
        if let calendarItemId = event.calendarItemIdentifier, !calendarItemId.isEmpty,
           let existing = eventKitService.calendarItem(withIdentifier: calendarItemId) as? EKEvent {
            return existing
        }
        return EKEvent(eventStore: eventKitService.eventStore)
    }

    private func applyEventFields(_ event: EventKitEvent, to ekEvent: EKEvent) {
        ekEvent.title = event.title
        ekEvent.notes = event.notes
        ekEvent.location = event.location
        ekEvent.isAllDay = event.isAllDay
        ekEvent.availability = convertToEKAvailability(event.availability)

        if let urlString = event.url, let url = URL(string: urlString) {
            ekEvent.url = url
        } else {
            ekEvent.url = nil
        }

        if let timeZoneId = event.timeZone, !timeZoneId.isEmpty,
           let timeZone = TimeZone(identifier: timeZoneId) {
            ekEvent.timeZone = timeZone
        } else if event.isAllDay {
            ekEvent.timeZone = nil
        }

        ekEvent.startDate = dateFromEvent(
            unixMs: event.startDateUnixMs,
            dateTime: event.startDate,
            timeZoneIdentifier: event.timeZone
        )
        ekEvent.endDate = dateFromEvent(
            unixMs: event.endDateUnixMs,
            dateTime: event.endDate,
            timeZoneIdentifier: event.timeZone
        )

        if let calendarId = event.calendarId,
           let calendar = eventKitService.getCalendar(withIdentifier: calendarId) {
            ekEvent.calendar = calendar
        } else if ekEvent.calendar == nil {
            ekEvent.calendar = eventKitService.defaultCalendarForNewEvents()
        }

        if let structured = event.structuredLocation {
            ekEvent.structuredLocation = convertToEKStructuredLocation(structured)
        }

        if event.alarms != nil {
            ekEvent.alarms = event.alarms?.compactMap { alarm in
                guard let alarm else { return nil }
                return convertToEKAlarm(alarm, timeZoneIdentifier: event.timeZone)
            }
        }

        let rulesToWrite = event.recurrenceRules ?? event.recurrenceRule.map { [$0] }
        if let rulesToWrite {
            if let existing = ekEvent.recurrenceRules {
                for rule in existing {
                    ekEvent.removeRecurrenceRule(rule)
                }
            }
            for rule in rulesToWrite.compactMap({ $0 }) {
                ekEvent.addRecurrenceRule(convertToEKRecurrenceRule(rule, timeZoneIdentifier: event.timeZone))
            }
        }
    }

    private func resolveOrCreateReminder(_ reminder: EventKitReminder) -> EKReminder {
        if let identifier = reminder.identifier, !identifier.isEmpty,
           let existing = eventKitService.calendarItem(withIdentifier: identifier) as? EKReminder {
            return existing
        }
        return EKReminder(eventStore: eventKitService.eventStore)
    }

    private func applyReminderFields(_ reminder: EventKitReminder, to ekReminder: EKReminder) {
        ekReminder.title = reminder.title
        ekReminder.notes = reminder.notes
        ekReminder.isCompleted = reminder.isCompleted
        ekReminder.priority = Int(reminder.priority ?? 0)
        if let dueDate = reminder.dueDate {
            let date = convertDateTime(dueDate, timeZoneIdentifier: nil)
            ekReminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            )
        }
        if let calendarId = reminder.calendarId,
           let calendar = eventKitService.getCalendar(withIdentifier: calendarId) {
            ekReminder.calendar = calendar
        } else if ekReminder.calendar == nil {
            ekReminder.calendar = eventKitService.getDefaultReminderCalendar()
        }
    }

    // MARK: - EventKit → Pigeon

    private func convertEvent(_ ekEvent: EKEvent) -> EventKitEvent {
        let timeZone = ekEvent.timeZone
        let attendees: [EventKitParticipant?]? = ekEvent.attendees?.map { convertParticipant($0) }
        let rules: [EventKitRecurrenceRule?]? = ekEvent.recurrenceRules?.map { convertRecurrenceRule($0) }
        return EventKitEvent(
            identifier: ekEvent.eventIdentifier,
            eventIdentifier: ekEvent.eventIdentifier,
            calendarItemIdentifier: ekEvent.calendarItemIdentifier,
            calendarItemExternalIdentifier: ekEvent.calendarItemExternalIdentifier,
            title: ekEvent.title ?? "",
            notes: ekEvent.notes,
            location: ekEvent.location,
            url: ekEvent.url?.absoluteString,
            structuredLocation: ekEvent.structuredLocation.map { convertStructuredLocation($0) },
            startDate: convertDate(ekEvent.startDate, timeZone: timeZone)!,
            endDate: convertDate(ekEvent.endDate, timeZone: timeZone)!,
            timeZone: timeZone?.identifier,
            startDateUnixMs: unixMs(ekEvent.startDate),
            endDateUnixMs: unixMs(ekEvent.endDate),
            isAllDay: ekEvent.isAllDay,
            occurrenceDate: convertDate(ekEvent.occurrenceDate, timeZone: timeZone),
            occurrenceDateUnixMs: unixMsOrNil(ekEvent.occurrenceDate),
            isDetached: ekEvent.isDetached,
            availability: convertAvailability(ekEvent.availability),
            status: convertStatus(ekEvent.status),
            creationDateUnixMs: ekEvent.creationDate.map { unixMs($0) },
            creationDate: convertDate(ekEvent.creationDate, timeZone: timeZone),
            lastModifiedDateUnixMs: ekEvent.lastModifiedDate.map { unixMs($0) },
            lastModifiedDate: convertDate(ekEvent.lastModifiedDate, timeZone: timeZone),
            birthdayContactIdentifier: ekEvent.birthdayContactIdentifier,
            calendarId: ekEvent.calendar?.calendarIdentifier,
            organizer: ekEvent.organizer.map { convertParticipant($0) },
            attendees: attendees,
            alarms: ekEvent.alarms?.map { convertAlarm($0, timeZone: timeZone) as EventKitAlarm? },
            recurrenceRules: rules,
            attendeeEmails: attendees?.compactMap { $0?.email },
            recurrenceRule: rules?.compactMap { $0 }.first
        )
    }

    private func convertCalendar(_ ekCalendar: EKCalendar) -> EventKitCalendar {
        var colorHex: String?
        if let cgColor = ekCalendar.cgColor, let components = cgColor.components, components.count >= 3 {
            let red = Int(components[0] * 255)
            let green = Int(components[1] * 255)
            let blue = Int(components[2] * 255)
            colorHex = String(format: "#%02X%02X%02X", red, green, blue)
        }
        let sourceTitle = ekCalendar.source.title
        return EventKitCalendar(
            identifier: ekCalendar.calendarIdentifier,
            title: ekCalendar.title,
            color: colorHex,
            type: convertCalendarType(ekCalendar.type),
            source: sourceTitle,
            sourceTitle: sourceTitle,
            sourceIdentifier: ekCalendar.source.sourceIdentifier,
            sourceType: convertSourceType(ekCalendar.source.sourceType),
            isEditable: ekCalendar.allowsContentModifications,
            isSubscribed: ekCalendar.isSubscribed,
            isImmutable: ekCalendar.isImmutable,
            externalId: nil
        )
    }

    private func convertReminder(_ ekReminder: EKReminder) -> EventKitReminder {
        return EventKitReminder(
            identifier: ekReminder.calendarItemIdentifier,
            title: ekReminder.title ?? "",
            notes: ekReminder.notes,
            dueDate: convertDate(ekReminder.dueDateComponents?.date, timeZone: TimeZone.current),
            completionDate: convertDate(ekReminder.completionDate, timeZone: TimeZone.current),
            isCompleted: ekReminder.isCompleted,
            calendarId: ekReminder.calendar?.calendarIdentifier,
            priority: Int64(ekReminder.priority)
        )
    }

    private func convertParticipant(_ participant: EKParticipant) -> EventKitParticipant {
        let urlString = participant.url.absoluteString
        var email: String?
        if participant.url.scheme?.lowercased() == "mailto" {
            email = String(urlString.dropFirst("mailto:".count))
        }
        return EventKitParticipant(
            name: participant.name,
            url: urlString,
            email: email,
            status: convertParticipantStatus(participant.participantStatus),
            role: convertParticipantRole(participant.participantRole),
            type: convertParticipantType(participant.participantType),
            isCurrentUser: participant.isCurrentUser
        )
    }

    private func convertAlarm(_ alarm: EKAlarm, timeZone: TimeZone?) -> EventKitAlarm {
        EventKitAlarm(
            relativeOffsetSeconds: alarm.absoluteDate == nil ? alarm.relativeOffset : nil,
            absoluteDate: convertDate(alarm.absoluteDate, timeZone: timeZone),
            proximity: convertAlarmProximity(alarm.proximity),
            structuredLocation: alarm.structuredLocation.map { convertStructuredLocation($0) }
        )
    }

    private func convertStructuredLocation(_ location: EKStructuredLocation) -> EventKitStructuredLocation {
        EventKitStructuredLocation(
            title: location.title,
            latitude: location.geoLocation?.coordinate.latitude,
            longitude: location.geoLocation?.coordinate.longitude,
            radius: location.radius
        )
    }

    private func convertRecurrenceRule(_ rule: EKRecurrenceRule) -> EventKitRecurrenceRule {
        EventKitRecurrenceRule(
            frequency: convertFrequency(rule.frequency),
            interval: Int64(rule.interval),
            endDate: convertDate(rule.recurrenceEnd?.endDate, timeZone: TimeZone.current),
            occurrenceCount: {
                guard let count = rule.recurrenceEnd?.occurrenceCount, count > 0 else {
                    return nil
                }
                return Int64(count)
            }(),
            daysOfTheWeek: rule.daysOfTheWeek?.map {
                EventKitRecurrenceDayOfWeek(
                    dayOfTheWeek: Int64($0.dayOfTheWeek.rawValue),
                    weekNumber: Int64($0.weekNumber)
                ) as EventKitRecurrenceDayOfWeek?
            },
            daysOfTheMonth: rule.daysOfTheMonth?.map { $0.int64Value as Int64? },
            daysOfTheYear: rule.daysOfTheYear?.map { $0.int64Value as Int64? },
            weeksOfTheYear: rule.weeksOfTheYear?.map { $0.int64Value as Int64? },
            monthsOfTheYear: rule.monthsOfTheYear?.map { $0.int64Value as Int64? },
            setPositions: rule.setPositions?.map { $0.int64Value as Int64? },
            firstDayOfTheWeek: Int64(rule.firstDayOfTheWeek)
        )
    }

    // MARK: - Pigeon → EventKit

    private func convertToEKStructuredLocation(_ location: EventKitStructuredLocation) -> EKStructuredLocation {
        let ekLocation = EKStructuredLocation(title: location.title ?? "")
        if let latitude = location.latitude, let longitude = location.longitude {
            ekLocation.geoLocation = CLLocation(latitude: latitude, longitude: longitude)
        }
        if let radius = location.radius {
            ekLocation.radius = radius
        }
        return ekLocation
    }

    private func convertToEKAlarm(_ alarm: EventKitAlarm, timeZoneIdentifier: String?) -> EKAlarm {
        let ekAlarm: EKAlarm
        if let absoluteDate = alarm.absoluteDate {
            ekAlarm = EKAlarm(absoluteDate: convertDateTime(absoluteDate, timeZoneIdentifier: timeZoneIdentifier))
        } else if let offset = alarm.relativeOffsetSeconds {
            ekAlarm = EKAlarm(relativeOffset: offset)
        } else {
            ekAlarm = EKAlarm(relativeOffset: 0)
        }
        ekAlarm.proximity = convertToEKAlarmProximity(alarm.proximity)
        if let structured = alarm.structuredLocation {
            ekAlarm.structuredLocation = convertToEKStructuredLocation(structured)
        }
        return ekAlarm
    }

    private func convertToEKRecurrenceRule(
        _ rule: EventKitRecurrenceRule,
        timeZoneIdentifier: String?
    ) -> EKRecurrenceRule {
        var end: EKRecurrenceEnd?
        if let count = rule.occurrenceCount, count > 0 {
            end = EKRecurrenceEnd(occurrenceCount: Int(count))
        } else if let endDate = rule.endDate {
            end = EKRecurrenceEnd(end: convertDateTime(endDate, timeZoneIdentifier: timeZoneIdentifier))
        }
        let daysOfTheWeek = rule.daysOfTheWeek?.compactMap { day -> EKRecurrenceDayOfWeek? in
            guard let day, let weekday = EKWeekday(rawValue: Int(day.dayOfTheWeek)) else {
                return nil
            }
            if day.weekNumber == 0 {
                return EKRecurrenceDayOfWeek(weekday)
            }
            return EKRecurrenceDayOfWeek(weekday, weekNumber: Int(day.weekNumber))
        }
        return EKRecurrenceRule(
            recurrenceWith: convertToEKFrequency(rule.frequency),
            interval: Int(rule.interval),
            daysOfTheWeek: daysOfTheWeek,
            daysOfTheMonth: nsNumbers(rule.daysOfTheMonth),
            monthsOfTheYear: nsNumbers(rule.monthsOfTheYear),
            weeksOfTheYear: nsNumbers(rule.weeksOfTheYear),
            daysOfTheYear: nsNumbers(rule.daysOfTheYear),
            setPositions: nsNumbers(rule.setPositions),
            end: end
        )
    }

    // MARK: - Dates

    private func unixMs(_ date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000.0).rounded())
    }

    private func unixMsOrNil(_ date: Date?) -> Int64? {
        guard let date else { return nil }
        return unixMs(date)
    }

    private func dateFromUnixMs(_ ms: Int64) -> Date {
        Date(timeIntervalSince1970: Double(ms) / 1000.0)
    }

    private func dateFromEvent(
        unixMs: Int64?,
        dateTime: EventKitDateTime,
        timeZoneIdentifier: String?
    ) -> Date {
        if let unixMs {
            return dateFromUnixMs(unixMs)
        }
        return convertDateTime(dateTime, timeZoneIdentifier: timeZoneIdentifier)
    }

    private func convertDate(_ date: Date?, timeZone: TimeZone?) -> EventKitDateTime? {
        guard let date else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone ?? TimeZone.current
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond],
            from: date
        )
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

    private func convertDateTime(_ dateTime: EventKitDateTime, timeZoneIdentifier: String?) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        if let timeZoneIdentifier, !timeZoneIdentifier.isEmpty,
           let timeZone = TimeZone(identifier: timeZoneIdentifier) {
            calendar.timeZone = timeZone
        }
        var components = DateComponents()
        components.year = Int(dateTime.year)
        components.month = Int(dateTime.month)
        components.day = Int(dateTime.day)
        components.hour = Int(dateTime.hour)
        components.minute = Int(dateTime.minute)
        components.second = Int(dateTime.second)
        components.nanosecond = Int(dateTime.millisecond) * 1_000_000
        return calendar.date(from: components) ?? Date()
    }

    // MARK: - Enums

    private func convertSpan(_ span: EventKitSpan) -> EKSpan {
        switch span {
        case .thisEvent:
            return .thisEvent
        case .futureEvents:
            return .futureEvents
        }
    }

    private func convertAuthorizationStatus(
        _ status: EKAuthorizationStatus
    ) -> EventKitCalendarAuthorizationStatus {
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
            if #available(iOS 17.0, macOS 14.0, *) {
                if status == .fullAccess || status == .writeOnly {
                    return .authorized
                }
            }
            return .notDetermined
        }
    }

    private func convertCalendarType(_ type: EKCalendarType) -> EventKitCalendarType {
        switch type {
        case .local:
            return .local
        case .calDAV:
            return .calDAV
        case .exchange:
            return .exchange
        case .subscription:
            return .subscription
        case .birthday:
            return .birthday
        @unknown default:
            return .local
        }
    }

    private func convertSourceType(_ type: EKSourceType) -> EventKitSourceType {
        switch type {
        case .local:
            return .local
        case .calDAV:
            return .calDAV
        case .exchange:
            return .exchange
        case .mobileMe:
            return .mobileMe
        case .subscribed:
            return .subscribed
        case .birthdays:
            return .birthdays
        @unknown default:
            return .local
        }
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

    private func convertFrequency(_ frequency: EKRecurrenceFrequency) -> EventKitRecurrenceFrequency {
        switch frequency {
        case .daily:
            return .daily
        case .weekly:
            return .weekly
        case .monthly:
            return .monthly
        case .yearly:
            return .yearly
        @unknown default:
            return .daily
        }
    }

    private func convertToEKFrequency(_ frequency: EventKitRecurrenceFrequency) -> EKRecurrenceFrequency {
        switch frequency {
        case .daily:
            return .daily
        case .weekly:
            return .weekly
        case .monthly:
            return .monthly
        case .yearly:
            return .yearly
        }
    }

    private func convertParticipantStatus(_ status: EKParticipantStatus) -> EventKitParticipantStatus {
        switch status {
        case .unknown:
            return .unknown
        case .pending:
            return .pending
        case .accepted:
            return .accepted
        case .declined:
            return .declined
        case .tentative:
            return .tentative
        case .delegated:
            return .delegated
        case .completed:
            return .completed
        case .inProcess:
            return .inProcess
        @unknown default:
            return .unknown
        }
    }

    private func convertParticipantRole(_ role: EKParticipantRole) -> EventKitParticipantRole {
        switch role {
        case .unknown:
            return .unknown
        case .required:
            return .required
        case .optional:
            return .optional
        case .chair:
            return .chair
        case .nonParticipant:
            return .nonParticipant
        @unknown default:
            return .unknown
        }
    }

    private func convertParticipantType(_ type: EKParticipantType) -> EventKitParticipantType {
        switch type {
        case .unknown:
            return .unknown
        case .person:
            return .person
        case .room:
            return .room
        case .resource:
            return .resource
        case .group:
            return .group
        @unknown default:
            return .unknown
        }
    }

    private func convertAlarmProximity(_ proximity: EKAlarmProximity) -> EventKitAlarmProximity {
        switch proximity {
        case .none:
            return .none
        case .enter:
            return .enter
        case .leave:
            return .leave
        @unknown default:
            return .none
        }
    }

    private func convertToEKAlarmProximity(_ proximity: EventKitAlarmProximity) -> EKAlarmProximity {
        switch proximity {
        case .none:
            return .none
        case .enter:
            return .enter
        case .leave:
            return .leave
        }
    }

    private func nsNumbers(_ values: [Int64?]?) -> [NSNumber]? {
        guard let values else { return nil }
        return values.compactMap { value in
            guard let value else { return nil }
            return NSNumber(value: value)
        }
    }

    #if os(iOS)
    private func topViewController() -> UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
        return Self.topViewController(from: root)
    }

    private static func topViewController(from controller: UIViewController?) -> UIViewController? {
        if let navigation = controller as? UINavigationController {
            return topViewController(from: navigation.visibleViewController)
        }
        if let tab = controller as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        if let presented = controller?.presentedViewController {
            return topViewController(from: presented)
        }
        return controller
    }
    #endif
}

#if os(iOS)
private final class EventViewPresenter: NSObject, EKEventViewDelegate,
    UIAdaptivePresentationControllerDelegate
{
    var onDismissed: (() -> Void)?

    func completePreviousIfNeeded() {
        finish()
    }

    func eventViewController(
        _ controller: EKEventViewController,
        didCompleteWith action: EKEventViewAction
    ) {
        let dismissed = controller.navigationController ?? controller
        dismissed.dismiss(animated: true) { [weak self] in
            self?.finish()
        }
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        finish()
    }

    private func finish() {
        let callback = onDismissed
        onDismissed = nil
        callback?()
    }
}
#endif
