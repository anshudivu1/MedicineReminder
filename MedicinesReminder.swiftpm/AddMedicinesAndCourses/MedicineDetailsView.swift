//
//  SwiftUIView 2.swift
//  Medicines
//
//  Created by Divyanshu on 24/01/25.
//

import SwiftUI

struct MedicineDetailsView: View {
    let courseName: String
    let numberOfMedicines: Int
    let courseDuration: Int
    @Binding var medicines: [Medicine]
    @Binding var courses: [MedicineCourse]
    @State var currentMedicineIndex: Int
    let onFinish: ([Medicine]) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var frequency: Frequency = .onceDaily
    @State private var timing: Timing = .morning
    @State private var whenToTake: WhenToTake = .beforeMeals
    @State private var customTime: Date = Date()
    @State private var xMinutes: Int = 30
    @State private var xHours: Int = 1
    
    var body: some View {
        Form {
            Section(header: Text("Medicine \(currentMedicineIndex + 1) of \(numberOfMedicines)")) {
                TextField("Medicine Name", text: $name)
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
                if currentMedicineIndex == numberOfMedicines - 1 {
                    Button("Finish") {
                        saveMedicine()
                        onFinish(medicines)
                        NotificationManager.shared.requestPermissionAndSchedule()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                } else {
                    Button("Next Medicine") {
                        saveMedicine()
                        currentMedicineIndex += 1
                        resetForm()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .navigationTitle("Add Medicine Details")
    }
    
    private func saveMedicine() {
          let medicine = Medicine(
              id: UUID(),
              name: name,
              frequency: frequency,
              timing: timing,
              whenToTake: whenToTake,
              customTime: timing == .specificTime ? customTime : nil,
              xMinutes: (whenToTake == .xMinutesBeforeMeals || whenToTake == .xMinutesAfterMeals) ? xMinutes : nil,
              xHours: frequency == .everyXHours ? xHours : nil,
              statusByDate: [:]
          )
          
          if currentMedicineIndex < medicines.count {
              medicines[currentMedicineIndex] = medicine
          } else {
              medicines.append(medicine)
          }
          NotificationManager.shared.requestPermissionAndSchedule()
      }
    
    private func resetForm() {
        name = ""
        frequency = .onceDaily
        timing = .morning
        whenToTake = .beforeMeals
        customTime = Date()
        xMinutes = 30
        xHours = 1
    }
}
