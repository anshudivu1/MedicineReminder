//
//  CalendarView.swift
//  Medicines
//
//  Created by Divyanshu on 23/01/25.
//
import SwiftUI

struct CalendarView: View {
    @State private var courses: [MedicineCourse] = []
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var refreshTrigger = false
    @State private var showMonthPicker = false
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                monthHeader
                    .padding(.top, 1)
                
                calendarGrid
                    .padding(.top, 8)
                
                medicinesList
                    .padding(.top, 12)
                    .padding(.bottom)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Medication Tracker")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .onChange(of: selectedDate) { _ in
            loadCourses()
            refreshTrigger.toggle()
        }
        .onAppear {
            loadCourses()
        }
    }
    
    private var monthHeader: some View {
        VStack(spacing: 8) {
            Button(action: { showMonthPicker.toggle() }) {
                HStack {
                    Text(monthFormatter.string(from: currentMonth))
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.blue)
                        .rotationEffect(showMonthPicker ? .degrees(180) : .degrees(0))
                }
                .padding(.vertical, 6)
            }
            
            if showMonthPicker {
                MonthPickerView(currentMonth: $currentMonth, showPicker: $showMonthPicker)
                    .transition(.opacity)
            }
            
            HStack {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(daysInMonth(), id: \.self) { date in
                if let date = date {
                    ModernDayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        hasMedicines: hasMedicinesForDate(date),
                        onSelect: { selectDate(date) }
                    )
                } else {
                    Color.clear
                        .frame(height: 40)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private var medicinesList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Medicines for \(dateFormatter.string(from: selectedDate))")
                .font(.headline)
                .padding(.horizontal)
            
            if hasMedicinesForDate(selectedDate) {
                ForEach(getMedicinesForDate(selectedDate), id: \.medicine.id) { medicineInfo in
                    ModernMedicineCellView(
                        medicine: medicineInfo.medicine,
                        date: selectedDate,
                        courseName: medicineInfo.courseName,
                        onStatusUpdate: { updateMedicineStatus(courseId: $0, medicineId: $1, status: $2) }
                    )
                    .id(refreshTrigger)
                }
            } else {
                EmptyMedicineView()
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private func loadCourses() {
        courses = DataManager.loadCourses()
    }
    
    private func selectDate(_ date: Date) {
        selectedDate = date
    }
    
    private func daysInMonth() -> [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func hasMedicinesForDate(_ date: Date) -> Bool {
        !getMedicinesForDate(date).isEmpty
    }
    
    private func getMedicinesForDate(_ date: Date) -> [(medicine: Medicine, courseName: String)] {
        var medicinesWithCourse: [(medicine: Medicine, courseName: String)] = []
        
        for course in courses {
            guard let startDate = course.startDate else { continue }
            let endDate = calendar.date(byAdding: .day, value: course.duration - 1, to: startDate)!
            
            if calendar.isDate(date, inSameDayAs: startDate) ||
               (date > startDate && date <= endDate) {
                for medicine in course.medicines {
                    medicinesWithCourse.append((medicine: medicine, courseName: course.name))
                }
            }
        }
        
        return medicinesWithCourse
    }
    
    private func updateMedicineStatus(courseId: UUID, medicineId: UUID, status: String) {
        if calendar.isDateInToday(selectedDate) {
            DataManager.updateMedicineStatus(
                courseId: courseId,
                medicineId: medicineId,
                status: status,
                date: selectedDate
            )
            loadCourses()
        }
    }
}

struct ModernDayCell: View {
    let date: Date
    let isSelected: Bool
    let hasMedicines: Bool
    let onSelect: () -> Void
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        Button(action: onSelect) {
            VStack {
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundColor(textColor)
                
                if hasMedicines {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 45)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
            )
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        }
        return .clear
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        }
        if calendar.isDateInToday(date) {
            return .blue
        }
        if calendar.isDateInWeekend(date) {
            return .secondary
        }
        return .primary
    }
}

struct MonthPickerView: View {
    @Binding var currentMonth: Date
    @Binding var showPicker: Bool
    private let calendar = Calendar.current
    
    var body: some View {
        VStack {
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .padding()
                }
                
                Spacer()
                
                Button(action: { currentMonth = Date() }) {
                    Text("Today")
                        .foregroundColor(.blue)
                        .padding()
                }
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .padding()
                }
            }
        }
    }
    
    private func previousMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
}

struct EmptyMedicineView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pills.circle")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No medicines scheduled")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Medicines scheduled for this date will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
