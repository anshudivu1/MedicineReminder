//
//  EditMedicineView.swift
//  Medicines
//
//  Created by Divyanshu on 26/01/25.
//

import SwiftUI

struct EditMedicineView: View {
    @Binding var medicine: Medicine
    @Binding var courses: [MedicineCourse]  
    let course: MedicineCourse
    let courseDuration: Int
    
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var frequency: Frequency = .onceDaily
    @State private var timing: Timing = .morning
    @State private var whenToTake: WhenToTake = .beforeMeals
    @State private var customTime: Date = Date()
    @State private var xMinutes: Int = 30
    @State private var xHours: Int = 1
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medicine Details")) {
                    TextField("Name", text: $name)
                    Picker("Frequency", selection: $frequency) {
                        ForEach(Frequency.allCases, id: \.self) { option in
                            Text(option.rawValue)
                        }
                    }
                    
                    if frequency == .onceDaily {
                        Picker("Timing", selection: $timing) {
                            ForEach(Timing.allCases, id: \.self) { option in
                                Text(option.rawValue)
                            }
                        }
                    }
                    
                    if frequency == .everyXHours {
                        Stepper("Every \(xHours) hour(s)", value: $xHours, in: 1...24)
                    }
                    
                    Picker("When to Take", selection: $whenToTake) {
                        ForEach(WhenToTake.allCases, id: \.self) { option in
                            Text(option.rawValue)
                        }
                    }
                    
                    if timing == .specificTime {
                        DatePicker("Specific Time", selection: $customTime, displayedComponents: .hourAndMinute)
                    }
                    
                    if whenToTake == .xMinutesBeforeMeals || whenToTake == .xMinutesAfterMeals {
                        Stepper("X Minutes: \(xMinutes)", value: $xMinutes, in: 1...120)
                    }
                }
                
                Section {
                    Button("Save Changes") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Medicine")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = medicine.name
                frequency = medicine.frequency
                timing = medicine.timing
                whenToTake = medicine.whenToTake
                customTime = medicine.customTime ?? Date()
                xMinutes = medicine.xMinutes ?? 30
                xHours = medicine.xHours ?? 1
            }
        }
    }
    
    func saveChanges() {
            medicine.name = name
            medicine.frequency = frequency
            medicine.timing = timing
            medicine.whenToTake = whenToTake
            medicine.customTime = timing == .specificTime ? customTime : nil
            medicine.xMinutes = (whenToTake == .xMinutesBeforeMeals || whenToTake == .xMinutesAfterMeals) ? xMinutes : nil
            medicine.xHours = frequency == .everyXHours ? xHours : nil
            
            if let courseIndex = courses.firstIndex(where: { $0.id == course.id }) {
                if let medicineIndex = courses[courseIndex].medicines.firstIndex(where: { $0.id == medicine.id }) {
                    let existingStatus = courses[courseIndex].medicines[medicineIndex].statusByDate
                    var updatedMedicine = medicine
                    updatedMedicine.statusByDate = existingStatus
                    
                    courses[courseIndex].medicines[medicineIndex] = updatedMedicine
                    DataManager.saveCourses(courses)
                }
            }
            NotificationManager.shared.requestPermissionAndSchedule()
        }
}
