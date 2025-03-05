//
//  ModernMedicineCellView.swift
//  Medicines
//
//  Created by Divyanshu on 15/02/25.
//


import SwiftUI

struct ModernMedicineCellView: View {
    let medicine: Medicine
       let date: Date
       let courseName: String
       let onStatusUpdate: (UUID, UUID, String) -> Void
       
       @State private var isExpanded = false
       @State private var isUpdating = false
       @Environment(\.calendar) private var calendar
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func getStatusForDate() -> String {
        if let status = medicine.status(for: date) {
            return status
        } else if calendar.isDateInToday(date) || date > Date() {
            return "pending"
        } else {
            return "missed"
        }
    }
    
    private var statusColor: Color {
        switch getStatusForDate() {
        case "taken":
            return .green
        case "pending":
            return .orange
        case "missed":
            return .red
        default:
            return .gray
        }
    }
    
    private func getMedicineTimings() -> [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        switch medicine.frequency {
        case .onceDaily:
            if let customTime = medicine.customTime {
                return [dateFormatter.string(from: customTime)]
            }
            return getOnceDailyTime()
        case .twiceDaily:
            return getTwiceDailyTimes()
        case .thriceDaily:
            return getThriceDailyTimes()
        case .everyXHours:
            return getEveryXHoursTimes()
        }
    }
    
    private func markAsTaken() {
           guard calendar.isDateInToday(date) else { return }
           
           isUpdating = true
           
           if let courses = try? DataManager.loadCourses() {
               if let course = courses.first(where: { $0.name == courseName }) {
                   onStatusUpdate(course.id, medicine.id, "taken")
               }
           }
           
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
               isUpdating = false
           }
       }
    
    var body: some View {
        VStack(spacing: 0) {

            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 16) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(medicine.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(courseName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    StatusBadge(status: getStatusForDate())
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .rotationEffect(isExpanded ? .degrees(90) : .degrees(0))
                }
                .padding()
                .background(Color(UIColor.systemBackground))
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(icon: "clock", title: "Frequency", value: medicine.frequency.rawValue)
                    
                    let timings = getMedicineTimings()
                    if !timings.isEmpty {
                        DetailRow(icon: "bell", title: "Scheduled times", value: timings.joined(separator: ", "))
                    }
                    
                    DetailRow(icon: "calendar", title: "When to take", value: medicine.whenToTake.rawValue)
                    
                    if let xMinutes = medicine.xMinutes {
                        DetailRow(
                            icon: "timer",
                            title: "Timing",
                            value: "\(xMinutes) minutes \(medicine.whenToTake == .xMinutesBeforeMeals ? "before" : "after") meals"
                        )
                    }
                    
                    if calendar.isDateInToday(date) && getStatusForDate() != "taken" {
                                           Button(action: markAsTaken) {
                                               HStack {
                                                   Image(systemName: "checkmark.circle.fill")
                                                   Text("Mark as taken")
                                               }
                                               .frame(maxWidth: .infinity)
                                               .padding(.vertical, 12)
                                               .background(isUpdating ? Color.gray : Color.green)
                                               .foregroundColor(.white)
                                               .cornerRadius(10)
                                           }
                                           .disabled(isUpdating)
                                           .padding(.top, 8)
                                       }
                }
                .padding()
                .background(Color(UIColor.systemBackground).opacity(0.5))
            }
        }
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    struct DetailRow: View {
        let icon: String
        let title: String
        let value: String
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    struct StatusBadge: View {
        let status: String
        
        var backgroundColor: Color {
            switch status {
            case "taken":
                return .green.opacity(0.2)
            case "pending":
                return .orange.opacity(0.2)
            case "missed":
                return .red.opacity(0.2)
            default:
                return .gray.opacity(0.2)
            }
        }
        
        var textColor: Color {
            switch status {
            case "taken":
                return .green
            case "pending":
                return .orange
            case "missed":
                return .red
            default:
                return .gray
            }
        }
        
        var body: some View {
            Text(status.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(backgroundColor)
                .foregroundColor(textColor)
                .cornerRadius(6)
        }
    }
    
    private func getOnceDailyTime() -> [String] {
        guard let userData = UserDefaults.standard.data(forKey: "userProfile"),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return []
        }

        let baseTime: Date
        switch medicine.timing {
        case .morning:
            baseTime = user.breakfastTime
        case .afternoon:
            baseTime = user.lunchTime
        case .night:
            baseTime = user.dinnerTime
        case .specificTime:
            guard let customTime = medicine.customTime else { return [] }
            baseTime = customTime
        }

        let adjustedTime = adjustTimeBasedOnPreference(baseTime)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return [dateFormatter.string(from: adjustedTime)]
    }

    private func getTwiceDailyTimes() -> [String] {
        guard let userData = UserDefaults.standard.data(forKey: "userProfile"),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return []
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"

        let morningTime = adjustTimeBasedOnPreference(user.breakfastTime)
        let nightTime = adjustTimeBasedOnPreference(user.dinnerTime)

        return [
            dateFormatter.string(from: morningTime),
            dateFormatter.string(from: nightTime)
        ]
    }

    private func getThriceDailyTimes() -> [String] {
        guard let userData = UserDefaults.standard.data(forKey: "userProfile"),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return []
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"

        let morningTime = adjustTimeBasedOnPreference(user.breakfastTime)
        let afternoonTime = adjustTimeBasedOnPreference(user.lunchTime)
        let nightTime = adjustTimeBasedOnPreference(user.dinnerTime)

        return [
            dateFormatter.string(from: morningTime),
            dateFormatter.string(from: afternoonTime),
            dateFormatter.string(from: nightTime)
        ]
    }

    private func getEveryXHoursTimes() -> [String] {
        guard let xHours = medicine.xHours,
              let userData = UserDefaults.standard.data(forKey: "userProfile"),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return []
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"

        let startTime = user.breakfastTime
        let hoursInDay = 24
        let numberOfDoses = hoursInDay / xHours
        var times: [String] = []

        for i in 0..<numberOfDoses {
            if let notificationTime = calendar.date(byAdding: .hour, value: i * xHours, to: startTime) {
                times.append(dateFormatter.string(from: notificationTime))
            }
        }

        return times
    }

    private func adjustTimeBasedOnPreference(_ baseTime: Date) -> Date {
        switch medicine.whenToTake {
        case .beforeMeals:
            return calendar.date(byAdding: .minute, value: -30, to: baseTime) ?? baseTime
        case .afterMeals:
            return calendar.date(byAdding: .minute, value: 30, to: baseTime) ?? baseTime
        case .xMinutesBeforeMeals:
            if let minutes = medicine.xMinutes {
                return calendar.date(byAdding: .minute, value: -minutes, to: baseTime) ?? baseTime
            }
            return baseTime
        case .xMinutesAfterMeals:
            if let minutes = medicine.xMinutes {
                return calendar.date(byAdding: .minute, value: minutes, to: baseTime) ?? baseTime
            }
            return baseTime
        case .atBedtime:
            if let userData = UserDefaults.standard.data(forKey: "userProfile"),
               let user = try? JSONDecoder().decode(User.self, from: userData) {
                return user.bedtime
            }
            return baseTime
        }
    }

}
