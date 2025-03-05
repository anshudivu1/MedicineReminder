//
//  SwiftUIView 2.swift
//  Medicines
//
//  Created by Divyanshu on 24/01/25.
//


// This is to add new courses


import SwiftUI

struct FillCourseDetailsView: View {
    @Binding var courses: [MedicineCourse]
    @Environment(\.dismiss) var dismiss
    
    @State private var courseName: String = ""
    @State private var numberOfMedicines: Int = 1
    @State private var courseDuration: Int = 7
    @State private var medicines: [Medicine] = []
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Course Details")) {
                    TextField("Course Name", text: $courseName)
                        .textInputAutocapitalization(.words)
                    
                    Stepper(value: $numberOfMedicines, in: 1...10) {
                        HStack {
                            Text("Number of Medicines")
                            Spacer()
                            Text("\(numberOfMedicines)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Stepper(value: $courseDuration, in: 1...365) {
                        HStack {
                            Text("Course Duration")
                            Spacer()
                            Text("\(courseDuration) days")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    NavigationLink {
                        MedicineDetailsView(
                            courseName: courseName,
                            numberOfMedicines: numberOfMedicines,
                            courseDuration: courseDuration,
                            medicines: $medicines,
                            courses: $courses,
                            currentMedicineIndex: 0
                        ) { completedMedicines in
                            let newCourse = MedicineCourse(
                                name: courseName,
                                duration: courseDuration,
                                medicines: completedMedicines,
                                startDate: Date()  
                            )
                            courses.append(newCourse)
                            DataManager.saveCourses(courses)
                            NotificationManager.shared.requestPermissionAndSchedule()
                            dismiss()
                        }
                    } label: {
                        Text("Add Medicines")
                    }
                    .disabled(courseName.isEmpty)
                }
            }
            .navigationTitle("New Course")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct MedicineRow: View {
    let medicine: Medicine
    let onEdit: () -> Void
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
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

struct ProgressBar: View {
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
