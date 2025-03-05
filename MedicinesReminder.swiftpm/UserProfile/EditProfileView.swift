//
//  SwiftUIView 2.swift
//  Medicines
//
//  Created by Divyanshu on 23/01/25.
//

import SwiftUI

struct EditProfileView: View {
    @Binding var user: User
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var age: Int = 0
    @State private var gender: String = "Male"
    @State private var newMedicalCondition: String = ""
    @State private var medicalConditions: [String] = []
    @State private var breakfastTime: Date = Date()
    @State private var lunchTime: Date = Date()
    @State private var dinnerTime: Date = Date()
    @State private var bedtime: Date = Date()
    
    let genderOptions = ["Male", "Female", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                    Stepper("Age: \(age)", value: $age, in: 0...120)
                    Picker("Gender", selection: $gender) {
                        ForEach(genderOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                }
                
                Section(header: Text("Medical Conditions")) {
                    ForEach(medicalConditions.indices, id: \.self) { index in
                        Text(medicalConditions[index])
                    }
                    .onDelete(perform: deleteMedicalCondition)
                    
                    HStack {
                        TextField("Add a condition", text: $newMedicalCondition)
                        Button(action: addMedicalCondition) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newMedicalCondition.isEmpty)
                    }
                }
                
                Section(header: Text("Meal Timings")) {
                    DatePicker("Breakfast", selection: $breakfastTime, displayedComponents: .hourAndMinute)
                    DatePicker("Lunch", selection: $lunchTime, displayedComponents: .hourAndMinute)
                    DatePicker("Dinner", selection: $dinnerTime, displayedComponents: .hourAndMinute)
                    DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
                }
                
                Section {
                    Button("Save Changes") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = user.name
                age = user.age
                gender = user.gender
                medicalConditions = user.medicalConditions
                breakfastTime = user.breakfastTime
                lunchTime = user.lunchTime
                dinnerTime = user.dinnerTime
                bedtime = user.bedtime
            }
        }
    }
    
    private func addMedicalCondition() {
        medicalConditions.append(newMedicalCondition)
        newMedicalCondition = ""
    }
    
    private func deleteMedicalCondition(at offsets: IndexSet) {
        medicalConditions.remove(atOffsets: offsets)
    }
    
    private func saveChanges() {
        // Update user data
        user.name = name
        user.age = age
        user.gender = gender
        user.medicalConditions = medicalConditions
        user.breakfastTime = breakfastTime
        user.lunchTime = lunchTime
        user.dinnerTime = dinnerTime
        user.bedtime = bedtime
        
        saveUserToUserDefaults(user: user)
        NotificationManager.shared.requestPermissionAndSchedule()
    }
    
    private func saveUserToUserDefaults(user: User) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(user) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
        }
    }
}
