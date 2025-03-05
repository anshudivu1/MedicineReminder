//
//  CourseDetailView.swift
//  Medicines
//
//  Created by Divyanshu on 24/01/25.
//

import SwiftUI

struct CourseDetailView: View {
    @Binding var course: MedicineCourse
    @Binding var courses: [MedicineCourse]
    @State private var isEditingCourse: Bool = false
    @State private var isEditingMedicine: Bool = false
    @State private var selectedMedicineIndex: Int = 0
    @State private var isInventoryViewPresented = false

    @Environment(\.dismiss) var dismiss
    
    private var progressValue: Double {
        course.calculateProgress()
    }
    
    private func calculateMedicineProgressValue(for course: MedicineCourse) -> Double {
        let calendar = Calendar.current
        guard let startDate = course.startDate else { return 0 }
        
        let today = Date()
        let endDate = calendar.date(byAdding: .day, value: course.duration, to: startDate) ?? today
        
        if today < startDate { return 0 }
        
        let totalDosesInCourse = course.duration * course.medicines.count
        
        if totalDosesInCourse == 0 { return 0 }
        
        var takenDoses = 0
        var currentDate = startDate
        
        while currentDate <= min(today, endDate) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: currentDate)
            
            for medicine in course.medicines {
                if let status = medicine.statusByDate?[dateString],
                   status.lowercased() == "taken" {
                    takenDoses += 1
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        return Double(takenDoses) / Double(totalDosesInCourse)
    }
    
    private func calculateDosesProgress(for course: MedicineCourse) -> Double {
        let calendar = Calendar.current
        guard let startDate = course.startDate else { return 0 }
        
        let today = Date()
        let endDate = min(calendar.date(byAdding: .day, value: course.duration, to: startDate) ?? today, today)
        
        var totalDoses = 0
        var takenDoses = 0
        
        var currentDate = startDate
        while currentDate <= endDate {
            for medicine in course.medicines {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = dateFormatter.string(from: currentDate)
                
                totalDoses += 1
                
                if let status = medicine.statusByDate?[dateString], status.lowercased() == "taken" {
                    takenDoses += 1
                }
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        return totalDoses > 0 ? Double(takenDoses) / Double(totalDoses) : 0
    }
    
    private func calculateDoseStatistics() -> (total: Int, taken: Int, missed: Int) {
        let calendar = Calendar.current
        guard let startDate = course.startDate else { return (0, 0, 0) }
        
        let today = Date()
        let endDate = min(calendar.date(byAdding: .day, value: course.duration, to: startDate) ?? today, today)
        
        var totalDoses = 0
        var takenDoses = 0
        var missedDoses = 0
        
        var currentDate = startDate
        while currentDate <= endDate {
            for medicine in course.medicines {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = dateFormatter.string(from: currentDate)
                
                totalDoses += 1
                
                if let status = medicine.statusByDate?[dateString] {
                    if status.lowercased() == "taken" {
                        takenDoses += 1
                    } else if status.lowercased() == "missed" {
                        missedDoses += 1
                    }
                } else if currentDate < today {
                    missedDoses += 1
                }
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        return (totalDoses, takenDoses, missedDoses)
    }
    
    
    private var daysRemaining: Int {
        course.calculateDaysRemaining()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Course Progress")
                                .font(.headline)
                            Text("\(Int(progressValue * 100))% Complete until today")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                            Circle()
                                .trim(from: 0, to: progressValue)
                                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            VStack {
                                Text("\(daysRemaining)")
                                    .font(.system(.title3, weight: .bold))
                                Text("days left")
                                    .font(.caption2)
                            }
                            .foregroundColor(.secondary)
                        }
                        .frame(width: 80, height: 80)
                    }
                    CourseProgressBar(value: progressValue)
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                

                VStack(alignment: .leading, spacing: 16) {
                    Text("Course Details")
                        .font(.headline)
                    
                    DetailRow(title: "Start Date", value: course.startDate?.formatted(.dateTime.day().month().year()) ?? "Not set")
                    DetailRow(title: "Duration", value: "\(course.duration) days")
                    DetailRow(title: "Total Medicines", value: "\(course.medicines.count)")
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                let stats = calculateDoseStatistics()
                VStack(alignment: .leading, spacing: 16) {
                    Text("Dose Statistics")
                        .font(.headline)
                    
                    DetailRow(title: "Total Doses", value: "\(stats.total)")
                    DetailRow(title: "Doses Taken", value: "\(stats.taken)")
                    DetailRow(title: "Doses Missed", value: "\(stats.missed)")
                    
                    if stats.total > 0 {
                        Text("Adherence Rate: \(Int(Double(stats.taken) / Double(stats.total) * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Medicines")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(course.medicines.indices, id: \.self) { index in
                        CourseDetailMedicineRow(
                            medicine: course.medicines[index],
                            course: course,
                            onEdit: {
                                selectedMedicineIndex = index
                                isEditingMedicine = true
                            }
                        )
                        if index < course.medicines.count - 1 {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
            }
            .padding()
            
            VStack(spacing: 16) {
                Button(action: {
                    isInventoryViewPresented = true
                }) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 50, height: 50)
                                .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "pills.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Track Your Medicine Storage")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Monitor inventory and get low-stock alerts")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(course.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit Course") {
                        isEditingCourse = true
                    }
                    
                    Button("Manage Inventory") {
                        isInventoryViewPresented = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $isEditingCourse) {
            EditCourseView(course: $course, courses: $courses)
        }
        .sheet(isPresented: $isEditingMedicine) {
            EditMedicineView(
                medicine: $course.medicines[selectedMedicineIndex],
                courses: $courses,
                course: course,
                courseDuration: course.duration
            )
        }.sheet(isPresented: $isInventoryViewPresented) {
            MedicineInventoryView(course: $course, courses: $courses)
        }
        
        
    }
}

struct CourseDetailMedicineRow: View {
    let medicine: Medicine
    let course: MedicineCourse
    let onEdit: () -> Void
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private func calculateMedicineDoses(for medicine: Medicine, in course: MedicineCourse) -> (total: Int, taken: Int) {
        let calendar = Calendar.current
        guard let startDate = course.startDate else { return (0, 0) }
        
        let today = Date()
        let endDate = min(calendar.date(byAdding: .day, value: course.duration, to: startDate) ?? today, today)
        
        var totalDoses = 0
        var takenDoses = 0
        
        var currentDate = startDate
        while currentDate <= endDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: currentDate)
            
            totalDoses += 1
            
            if let status = medicine.statusByDate?[dateString], status.lowercased() == "taken" {
                takenDoses += 1
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        return (totalDoses, takenDoses)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(medicine.name)
                        .font(.system(.body, weight: .semibold))
                    
                    if let status = medicine.status(for: Date()) {
                        Text(status)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(status.lowercased() == "taken" ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            .foregroundColor(status.lowercased() == "taken" ? .green : .red)
                            .cornerRadius(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Frequency: \(medicine.frequency.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if medicine.frequency == .onceDaily {
                        Text("Timing: \(medicine.timing.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Take: \(medicine.whenToTake.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let customTime = medicine.customTime {
                        Text("At: \(customTime, formatter: timeFormatter)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    let doses = calculateMedicineDoses(for: medicine, in: course)
                    if doses.total > 0 {
                        Text("Doses: \(doses.taken)/\(doses.total) (\(Int(Double(doses.taken) / Double(doses.total) * 100))%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
    }
    
    
    
}

struct CourseProgressBar: View {
    let value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.accentColor)
                    .cornerRadius(4)
                    .frame(width: geometry.size.width * value)
            }
        }
        .frame(height: 8)
    }
}

