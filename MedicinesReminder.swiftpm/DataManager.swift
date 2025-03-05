//
//  DataManager.swift
//  Medicines
//
//  Created by Divyanshu on 24/01/25.
//
import SwiftUI
import Foundation

struct DataManager {
    private static let coursesKey = "medicineCoursesKey"
    
    static func saveCourses(_ courses: [MedicineCourse]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(courses)
            UserDefaults.standard.set(data, forKey: coursesKey)
            print("Courses saved successfully: \(courses.count) courses")
        } catch {
            print("Error saving courses: \(error)")
        }
    }
    
    static func loadCourses() -> [MedicineCourse] {
        guard let data = UserDefaults.standard.data(forKey: coursesKey) else {
            print("No courses found in UserDefaults")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let courses = try decoder.decode([MedicineCourse].self, from: data)
            print("Loaded \(courses.count) courses")
            return courses
        } catch {
            print("Error loading courses: \(error)")
            return []
        }
    }
    
    static func deleteCourse(at index: Int, from courses: inout [MedicineCourse]) {
        courses.remove(at: index)
        saveCourses(courses)
    }
    
    static func updateMedicineStatus(courseId: UUID, medicineId: UUID, status: String, date: Date) {
        var courses = loadCourses()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        if let courseIndex = courses.firstIndex(where: { $0.id == courseId }),
           let medicineIndex = courses[courseIndex].medicines.firstIndex(where: { $0.id == medicineId }) {
            
            let previousStatus = courses[courseIndex].medicines[medicineIndex].statusByDate?[dateString]
            
            if courses[courseIndex].medicines[medicineIndex].statusByDate == nil {
                courses[courseIndex].medicines[medicineIndex].statusByDate = [:]
            }
            courses[courseIndex].medicines[medicineIndex].statusByDate?[dateString] = status
            
            if status.lowercased() == "taken" && previousStatus?.lowercased() != "taken" {
                if var inventory = courses[courseIndex].medicines[medicineIndex].inventory,
                   inventory.trackingEnabled && inventory.currentCount > 0 {
                    inventory.currentCount -= 1
                    
                    courses[courseIndex].medicines[medicineIndex].inventory = inventory
                    
                    if inventory.isLowStock && inventory.notifyWhenLow {
                        Task { @MainActor in
                            NotificationManager.shared.scheduleInventoryAlert(
                                medicineName: courses[courseIndex].medicines[medicineIndex].name,
                                courseName: courses[courseIndex].name,
                                remainingCount: inventory.currentCount,
                                unitType: inventory.unitType.rawValue
                            )
                        }
                    }
                }
            }
            
            saveCourses(courses)
        }
    }
}
