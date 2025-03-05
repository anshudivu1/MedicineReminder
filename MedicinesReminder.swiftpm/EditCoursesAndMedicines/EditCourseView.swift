//
//  SwiftUIView 2.swift
//  Medicines
//
//  Created by Divyanshu on 24/01/25.
//

import SwiftUI

struct EditCourseView: View {
    @Binding var course: MedicineCourse
    @Binding var courses: [MedicineCourse]
    @Environment(\.dismiss) var dismiss
    
    @State private var courseName: String = ""
    @State private var courseDuration: Int = 7
    @State private var numberOfMedicines: Int = 1
    @State private var isAddingMedicine: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                courseDetailsSection()
                medicinesSection()
                saveChangesSection()
            }
            .navigationTitle("Edit Course")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                courseName = course.name
                courseDuration = course.duration
                numberOfMedicines = course.medicines.count
            }
            .onChange(of: numberOfMedicines) { newValue in
                updateNumberOfMedicines(newValue)
            }
            .sheet(isPresented: $isAddingMedicine) {
                AddMedicineViewWhileEditing(medicines: $course.medicines)
            }
        }
    }
    
    private func courseDetailsSection() -> some View {
        Section(header: Text("Course Details")) {
            TextField("Course Name", text: $courseName)
            Stepper("Duration (Days): \(courseDuration)", value: $courseDuration, in: 1...365)
            Stepper("Number of Medicines: \(numberOfMedicines)", value: $numberOfMedicines, in: 0...10, step: 1)
        }
    }
    
    private func medicinesSection() -> some View {
        Section(header: Text("Medicines")) {
            ForEach(course.medicines.indices, id: \.self) { index in
                medicineRow(for: index)
            }
            .onDelete(perform: deleteMedicine)
            
            Button("Add New Medicine") {
                isAddingMedicine = true
            }
        }
    }
    
    private func saveChangesSection() -> some View {
        Section {
            Button("Save Changes") {
                saveChanges()
                dismiss()
            }
        }
    }
    
    private func medicineRow(for index: Int) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(course.medicines[index].name)
                    .font(.headline)
                Spacer()
                Button(action: {
                    deleteMedicine(at: IndexSet(integer: index))
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            Text("Frequency: \(course.medicines[index].frequency.rawValue)")
            Text("Timing: \(course.medicines[index].timing.rawValue)")
            if let customTime = course.medicines[index].customTime {
                Text("Specific Time: \(customTime, formatter: timeFormatter)")
            }
        }
    }
    
    private func saveChanges() {
        course.name = courseName
        course.duration = courseDuration
        
        if let index = courses.firstIndex(where: { $0.id == course.id }) {
            courses[index] = course
            DataManager.saveCourses(courses)
        }
        
        NotificationManager.shared.requestPermissionAndSchedule()
    }
    
    private func deleteMedicine(at offsets: IndexSet) {
        course.medicines.remove(atOffsets: offsets)
        numberOfMedicines = course.medicines.count
        
        if let index = courses.firstIndex(where: { $0.id == course.id }) {
            courses[index] = course
            DataManager.saveCourses(courses)
        }
    }
    
    private func updateNumberOfMedicines(_ newValue: Int) {
          if newValue > course.medicines.count {
              for _ in course.medicines.count..<newValue {
                  let newMedicine = Medicine(
                      id: UUID(),
                      name: "New Medicine",
                      frequency: .onceDaily,
                      timing: .morning,
                      whenToTake: .beforeMeals,
                      customTime: nil,
                      xMinutes: nil,
                      xHours: nil,
                      statusByDate: [:]  
                  )
                  course.medicines.append(newMedicine)
              }
          } else if newValue < course.medicines.count {
              course.medicines.removeLast(course.medicines.count - newValue)
          }
          
          if let index = courses.firstIndex(where: { $0.id == course.id }) {
              courses[index] = course
              DataManager.saveCourses(courses)
          }
      }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}
