//
//  NotificationManager.swift
//  Medicines
//
//  Created by Divyanshu on 06/02/25.
//

import SwiftUI
import Foundation
import UserNotifications

class NotificationManager: NSObject, @preconcurrency UNUserNotificationCenterDelegate {
    @MainActor static let shared = NotificationManager()
    
    private var courses: [MedicineCourse] = []
    private var medicines: [Medicine] = []
    private var timings: [String] = []
    private var user: User?
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    private func loadUser() {
        if let savedUser = UserDefaults.standard.data(forKey: "userProfile") {
            let decoder = JSONDecoder()
            if let loadedUser = try? decoder.decode(User.self, from: savedUser) {
                user = loadedUser
            }
        }
    }
    
    private func loadCourses() {
        courses = DataManager.loadCourses()
        medicines = []
        for course in courses {
            medicines.append(contentsOf: course.medicines)
        }
    }
    
    private func setupNotificationCategories() {
        let markAsTakenAction = UNNotificationAction(
            identifier: "MARK_AS_TAKEN",
            title: "Mark as Taken",
            options: []
        )
        
        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "Remind after 10 min",
            options: []
        )
        
        let medicineCategory = UNNotificationCategory(
            identifier: "DAILY_REMINDER",
            actions: [markAsTakenAction, remindLaterAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([medicineCategory])
    }
    
    private func calculateNotificationTimes() {
        timings = []
        loadUser()
        loadCourses()
        
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        var uniqueTimes = Set<String>()
        
        for medicine in medicines {
            switch medicine.frequency {
            case .onceDaily:
                if let time = getOnceDailyTime(medicine, calendar, dateFormatter) {
                    uniqueTimes.insert(time)
                }
            case .twiceDaily:
                getTwiceDailyTimes(medicine, calendar, dateFormatter).forEach { uniqueTimes.insert($0) }
            case .thriceDaily:
                getThriceDailyTimes(medicine, calendar, dateFormatter).forEach { uniqueTimes.insert($0) }
            case .everyXHours:
                getEveryXHoursTimes(medicine, calendar, dateFormatter).forEach { uniqueTimes.insert($0) }
            }
        }
        
        timings = Array(uniqueTimes).sorted()
        print("Calculated notification times: \(timings)")
    }
    
    private func getOnceDailyTime(_ medicine: Medicine, _ calendar: Calendar, _ dateFormatter: DateFormatter) -> String? {
        guard let user = user else { return nil }
        
        let baseTime: Date
        switch medicine.timing {
        case .morning:
            baseTime = user.breakfastTime
        case .afternoon:
            baseTime = user.lunchTime
        case .night:
            baseTime = user.dinnerTime
        case .specificTime:
            guard let customTime = medicine.customTime else { return nil }
            baseTime = customTime
        }
        
        let adjustedTime = adjustTimeBasedOnPreference(baseTime, medicine.whenToTake, medicine.xMinutes)
        return dateFormatter.string(from: adjustedTime)
    }
    
    private func getTwiceDailyTimes(_ medicine: Medicine, _ calendar: Calendar, _ dateFormatter: DateFormatter) -> [String] {
        guard let user = user else { return [] }
        
        let morningTime = adjustTimeBasedOnPreference(user.breakfastTime, medicine.whenToTake, medicine.xMinutes)
        let nightTime = adjustTimeBasedOnPreference(user.dinnerTime, medicine.whenToTake, medicine.xMinutes)
        
        return [dateFormatter.string(from: morningTime),
                dateFormatter.string(from: nightTime)]
    }
    
    private func getThriceDailyTimes(_ medicine: Medicine, _ calendar: Calendar, _ dateFormatter: DateFormatter) -> [String] {
        guard let user = user else { return [] }
        
        let morningTime = adjustTimeBasedOnPreference(user.breakfastTime, medicine.whenToTake, medicine.xMinutes)
        let afternoonTime = adjustTimeBasedOnPreference(user.lunchTime, medicine.whenToTake, medicine.xMinutes)
        let nightTime = adjustTimeBasedOnPreference(user.dinnerTime, medicine.whenToTake, medicine.xMinutes)
        
        return [dateFormatter.string(from: morningTime),
                dateFormatter.string(from: afternoonTime),
                dateFormatter.string(from: nightTime)]
    }
    
    private func getEveryXHoursTimes(_ medicine: Medicine, _ calendar: Calendar, _ dateFormatter: DateFormatter) -> [String] {
        guard let xHours = medicine.xHours,
              let user = user else { return [] }
        
        var times: [String] = []
        let startTime = user.breakfastTime
        let hoursInDay = 24
        let numberOfDoses = hoursInDay / xHours
        
        for i in 0..<numberOfDoses {
            if let notificationTime = calendar.date(byAdding: .hour, value: i * xHours, to: startTime) {
                times.append(dateFormatter.string(from: notificationTime))
            }
        }
        
        return times
    }
    
    private func adjustTimeBasedOnPreference(_ baseTime: Date, _ whenToTake: WhenToTake, _ xMinutes: Int?) -> Date {
        let calendar = Calendar.current
        
        switch whenToTake {
        case .beforeMeals:
            return calendar.date(byAdding: .minute, value: -30, to: baseTime) ?? baseTime
        case .afterMeals:
            return calendar.date(byAdding: .minute, value: 30, to: baseTime) ?? baseTime
        case .xMinutesBeforeMeals:
            if let minutes = xMinutes {
                return calendar.date(byAdding: .minute, value: -minutes, to: baseTime) ?? baseTime
            }
            return baseTime
        case .xMinutesAfterMeals:
            if let minutes = xMinutes {
                return calendar.date(byAdding: .minute, value: minutes, to: baseTime) ?? baseTime
            }
            return baseTime
        case .atBedtime:
            guard let user = user else { return baseTime }
            return user.bedtime
        }
    }
    
    func requestPermissionAndSchedule(title: String = "Medicine Reminder", body: String = "Time to take your medicine") {
        calculateNotificationTimes()
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
                self.setupNotificationCategories()
                self.scheduleDailyNotifications()
                self.scheduleDailyLowStockReminders()
                self.scheduleWeeklyInventoryReminder()
            } else {
                print("Notification permission denied: \(String(describing: error))")
            }
        }
    }
    
    private func getMedicinesForTime(_ time: String, calendar: Calendar, dateFormatter: DateFormatter) -> [Medicine] {
        return medicines.filter { medicine in
            let medicineTimes = getMedicineNotificationTimes(medicine)
            return medicineTimes.contains(time)
        }
    }
    
    private func getMedicineNotificationTimes(_ medicine: Medicine) -> [String] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        switch medicine.frequency {
        case .onceDaily:
            if let time = getOnceDailyTime(medicine, calendar, dateFormatter) {
                return [time]
            }
        case .twiceDaily:
            return getTwiceDailyTimes(medicine, calendar, dateFormatter)
        case .thriceDaily:
            return getThriceDailyTimes(medicine, calendar, dateFormatter)
        case .everyXHours:
            return getEveryXHoursTimes(medicine, calendar, dateFormatter)
        }
        
        return []
    }
    
    private func scheduleDailyNotifications() {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let now = Date()
        
        let maxDuration = courses.map { $0.duration }.max() ?? 1
        
        for dayOffset in 0..<maxDuration {
            for time in timings {
                let components = time.split(separator: ":")
                guard components.count == 2,
                      let hour = Int(components[0]),
                      let minute = Int(components[1]) else {
                    print("Invalid time format: \(time)")
                    continue
                }
                
                var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
                dateComponents.hour = hour
                dateComponents.minute = minute
                
                guard let baseDate = calendar.date(from: dateComponents),
                      let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: baseDate) else { continue }
                
                let finalDate = targetDate <= now ? calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate : targetDate
                let finalComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalDate)
                
                let medicinesForTime = getMedicinesForTime(time, calendar: calendar, dateFormatter: dateFormatter)
                
                let validMedicines = medicinesForTime.filter { medicine in
                    if let course = courses.first(where: { $0.medicines.contains(where: { $0.id == medicine.id }) }) {
                        return dayOffset < course.duration
                    }
                    return false
                }
                
                if validMedicines.isEmpty { continue }
                
                let medicineNames = validMedicines.map { $0.name }
                
                let content = UNMutableNotificationContent()
                content.title = "Medicine Reminder"
                if medicineNames.count > 1 {
                    content.body = "Time to take: " + medicineNames.joined(separator: ", ")
                } else if let medicineName = medicineNames.first {
                    content.body = "Time to take: " + medicineName
                } else {
                    content.body = "Time to take your medicine"
                }
                
                content.sound = .default
                content.badge = 1
                content.categoryIdentifier = "DAILY_REMINDER"
                
                let identifier = "notification_\(dayOffset)_\(time)"
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: finalComponents, repeats: false)
                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling notification for \(time) on day \(dayOffset): \(error.localizedDescription)")
                    } else {
                        print("Successfully scheduled notification for \(time) on day \(dayOffset) - Medicines: \(medicineNames)")
                    }
                }
            }
        }
    }
    
    func userNotificationCenter( _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void ) {
        completionHandler([.banner, .sound, .badge, .list])
    }
    
    @MainActor func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                         withCompletionHandler completionHandler: @escaping () -> Void ) {
        switch response.actionIdentifier {
        case "MARK_AS_TAKEN":
            handleMarkAsTakenAction(response.notification)
        case "REMIND_LATER":
            handleRemindLaterAction(response.notification)
        case UNNotificationDefaultActionIdentifier:
            print("Notification tapped")
        case UNNotificationDismissActionIdentifier:
            print("Notification dismissed")
        default:
            break
        }
        print("Notification received with identifier: \(response.notification.request.identifier)")
        completionHandler()
    }
    
    private func handleRemindLaterAction(_ notification: UNNotification) {
        // Create new content from original
        let content = UNMutableNotificationContent()
        content.title = "Reminder: Medicine Time"
        content.body = notification.request.content.body
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "DAILY_REMINDER"
        
        // Set 10-minute snooze interval
        let snoozeInterval: TimeInterval = 600 // 10 minutes in seconds
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: snoozeInterval, repeats: false)
        
        let requestId = "snooze_\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: requestId,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule snooze reminder: \(error)")
            } else {
                print("Snoozed notification for 10 minutes")
            }
        }
    }

    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings:")
            print("Authorization status: \(settings.authorizationStatus.rawValue)")
            print("Alert setting: \(settings.alertSetting.rawValue)")
            print("Sound setting: \(settings.soundSetting.rawValue)")
            print("Badge setting: \(settings.badgeSetting.rawValue)")
        }
    }
    
    private func handleMarkAsTakenAction(_ notification: UNNotification) {
        print("✅ Medicine marked as taken")
        
        let identifier = notification.request.identifier
        let isSnoozeNotification = identifier.starts(with: "snooze_")
        
        
        let notificationBody = notification.request.content.body
        let medicineNames = extractMedicineNames(from: notificationBody)
        
        guard let courses = try? DataManager.loadCourses() else {
            print("❌ Failed to load courses")
            return
        }
        
        let today = Date()
        var updatedAnyMedicine = false
        
        for course in courses {
            for medicine in course.medicines {
                if medicineNames.contains(medicine.name) {
                    DataManager.updateMedicineStatus(
                        courseId: course.id,
                        medicineId: medicine.id,
                        status: "taken",
                        date: today
                    )
                    updatedAnyMedicine = true
                }
            }
        }
        
        if updatedAnyMedicine {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("MedicineStatusUpdateCompleted"),
                    object: nil
                )
            }
        }
    }

    private func extractMedicineNames(from notificationBody: String) -> [String] {
        let text = notificationBody.lowercased()
        if text.starts(with: "time to take: ") {
            let medicinesText = notificationBody.replacingOccurrences(of: "Time to take: ", with: "")
            return medicinesText.components(separatedBy: ", ")
        } else {
           
            let medicinesText = notificationBody.replacingOccurrences(of: "Reminder: Medicine Time", with: "")
                .trimmingCharacters(in: .whitespaces)
            return medicinesText.components(separatedBy: ", ")
        }
    }
                    }

                    extension NotificationManager {
                        func scheduleInventoryAlert(medicineName: String, courseName: String, remainingCount: Int, unitType: String) {
                            let content = UNMutableNotificationContent()
                            content.title = "Low Medicine Inventory"
                            content.body = "You only have \(remainingCount) \(unitType) of \(medicineName) left in your \(courseName) course."
                            content.sound = .default
                            content.categoryIdentifier = "INVENTORY_ALERT"
                            
                            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
                            
                            let request = UNNotificationRequest(
                                identifier: "inventory_\(medicineName)_\(UUID().uuidString)",
                                content: content,
                                trigger: trigger
                            )
                            
                            UNUserNotificationCenter.current().add(request) { error in
                                if let error = error {
                                    print("Error scheduling inventory notification: \(error)")
                                }
                            }
                        }
                        
                        func scheduleWeeklyInventoryReminder() {
                            let content = UNMutableNotificationContent()
                            content.title = "Weekly Medicine Inventory Check"
                            content.body = "It's time to check your medicine inventory. Make sure you have enough medication for the week."
                            content.sound = .default
                            
                            var dateComponents = DateComponents()
                            dateComponents.weekday = 2
                            dateComponents.hour = 9
                            dateComponents.minute = 0
                            
                            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                            
                            let request = UNNotificationRequest(
                                identifier: "weekly_inventory_reminder",
                                content: content,
                                trigger: trigger
                            )
                            
                            UNUserNotificationCenter.current().add(request) { error in
                                if let error = error {
                                    print("Error scheduling weekly inventory reminder: \(error)")
                                }
                            }
                        }
                        
                        func scheduleDailyLowStockReminders() {
                            let courses = DataManager.loadCourses()
                            var lowStockMedicines: [(name: String, courseName: String, count: Int, unitType: String)] = []
                            
                            for course in courses {
                                for medicine in course.medicines {
                                    if let inventory = medicine.inventory,
                                       inventory.trackingEnabled &&
                                       inventory.isLowStock &&
                                       inventory.notifyWhenLow {
                                        lowStockMedicines.append((
                                            name: medicine.name,
                                            courseName: course.name,
                                            count: inventory.currentCount,
                                            unitType: inventory.unitType.rawValue
                                        ))
                                    }
                                }
                            }
                            
                            if lowStockMedicines.isEmpty {
                                return
                            }
                            
                            let content = UNMutableNotificationContent()
                            content.title = "Medicine Refill Reminder"
                            
                            if lowStockMedicines.count == 1 {
                                let medicine = lowStockMedicines[0]
                                content.body = "You only have \(medicine.count) \(medicine.unitType) of \(medicine.name) left. Please refill soon."
                            } else {
                                let medicineNames = lowStockMedicines.map { $0.name }.joined(separator: ", ")
                                content.body = "Multiple medicines are running low: \(medicineNames). Please check your inventory."
                            }
                            content.sound = .default
                            
                            var dateComponents = DateComponents()
                            dateComponents.hour = 9
                            dateComponents.minute = 0
                            
                            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                            let request = UNNotificationRequest(
                                identifier: "daily_low_stock_reminder",
                                content: content,
                                trigger: trigger
                            )
                            
                            UNUserNotificationCenter.current().add(request) { error in
                                if let error = error {
                                    print("Error scheduling daily low stock reminder: \(error)")
                                }
                            }
                        }
                    }
