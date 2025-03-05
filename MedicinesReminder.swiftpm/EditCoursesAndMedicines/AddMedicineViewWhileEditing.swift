//
//  SwiftUIView 2.swift
//  Medicines
//
//  Created by Divyanshu on 23/01/25.
//

import SwiftUI
import UserNotifications


struct AddMedicineViewWhileEditing: View {
    
    @Binding var medicines: [Medicine]
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
                    Button("Save Medicine") {
                        saveMedicine()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("Add Medicine")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveMedicine() {
           let newMedicine = Medicine(
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
           medicines.append(newMedicine)
           NotificationManager.shared.requestPermissionAndSchedule()
       }
}
