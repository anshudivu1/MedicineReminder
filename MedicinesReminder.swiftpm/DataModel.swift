//
//  DataModel.swift
//  Medicines
//
//  Created by Divyanshu on 23/01/25.
//

import SwiftUI
import Foundation

struct Medication: Identifiable, Codable {
    let id = UUID()
    var name: String
    var dosage: String
    var timing: String
    var nextDoseTime: Date
    var isTaken: Bool = false
}

struct User: Codable {
    var name: String
    var age: Int
    var gender: String
    var medicalConditions: [String]
    var breakfastTime: Date
    var lunchTime: Date
    var dinnerTime: Date
    var bedtime: Date
}

struct Reminder {
    var medication: Medication
    var reminderTime: Date
    var isSnoozed: Bool = false
}

struct MedicineCourse: Identifiable, Codable {
    let id: UUID
    var name: String
    var duration: Int
    var medicines: [Medicine]
    var startDate: Date?
    
    init(id: UUID = UUID(), name: String, duration: Int, medicines: [Medicine], startDate: Date = Date()) {
        self.id = id
        self.name = name
        self.duration = duration
        self.medicines = medicines
        self.startDate = startDate
    }
}

struct Medicine: Identifiable, Codable {
    let id: UUID
    var name: String
    var frequency: Frequency
    var timing: Timing
    var whenToTake: WhenToTake
    var customTime: Date?
    var xMinutes: Int?
    var xHours: Int?
    var statusByDate: [String: String]?
    var inventory: MedicineInventory?
    
    func status(for date: Date) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        return statusByDate?[dateString]
    }
    
    mutating func decrementInventory() {
        guard var inventoryData = self.inventory, inventoryData.trackingEnabled else { return }
        
        if inventoryData.currentCount > 0 {
            inventoryData.currentCount -= 1
            self.inventory = inventoryData
        }
    }
    
    var userDefaultsInventory: MedicineInventory? {
        get {
            guard let data = UserDefaults.standard.data(forKey: "inventory_\(id.uuidString)") else {
                return nil
            }
            
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(MedicineInventory.self, from: data)
            } catch {
                print("Error decoding inventory: \(error)")
                return nil
            }
        }
        set {
            if let newValue = newValue {
                do {
                    let encoder = JSONEncoder()
                    let data = try encoder.encode(newValue)
                    UserDefaults.standard.set(data, forKey: "inventory_\(id.uuidString)")
                } catch {
                    print("Error encoding inventory: \(error)")
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "inventory_\(id.uuidString)")
            }
        }
    }
}

enum Frequency: String, Codable, CaseIterable {
    case onceDaily = "Once Daily"
    case twiceDaily = "Twice Daily"
    case thriceDaily = "Thrice Daily"
    case everyXHours = "Every X Hours"
}

enum Timing: String, Codable, CaseIterable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case night = "Night"
    case specificTime = "Specific Time"
}

enum WhenToTake: String, Codable, CaseIterable {
    case beforeMeals = "Before Meals"
    case afterMeals = "After Meals"
    case xMinutesBeforeMeals = "X Minutes Before Meals"
    case xMinutesAfterMeals = "X Minutes After Meals"
    case atBedtime = "At Bedtime"
}

extension MedicineCourse {
    func calculateDaysRemaining(from date: Date = Date()) -> Int {
        guard let startDate = self.startDate else { return self.duration }
        let calendar = Calendar.current
        
        if date < startDate {
            return self.duration
        }
        
        let endDate = calendar.date(byAdding: .day, value: self.duration, to: startDate) ?? date
        
        if date >= endDate {
            return 0
        }
        
        if let remaining = calendar.dateComponents([.day], from: date, to: endDate).day {
            return max(0, remaining)
        }
        
        return 0
    }
    
    func calculateProgress(until date: Date = Date()) -> Double {
        guard let startDate = self.startDate else { return 0 }
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: self.duration - 1, to: startDate) ?? date
        
        if date < startDate { return 0 }
        
        let totalDosesInCourse = self.duration * self.medicines.count
        if totalDosesInCourse == 0 { return 0 }
        
        var takenDoses = 0
        var currentDate = startDate
        let lastDate = min(date, endDate)
        
        while currentDate <= lastDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: currentDate)
            
            for medicine in self.medicines {
                if let status = medicine.statusByDate?[dateString],
                   status.lowercased() == "taken" {
                    takenDoses += 1
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? lastDate
        }
        
        return Double(takenDoses) / Double(totalDosesInCourse)
    }
    
    func isActive(on date: Date = Date()) -> Bool {
        guard let startDate = self.startDate else { return true }
        let calendar = Calendar.current
        
        let endDate = calendar.date(byAdding: .day, value: self.duration, to: startDate) ?? date
        
        return date >= startDate && date < endDate
    }
}

enum MedicineUnitType: String, Codable, CaseIterable {
    case pills = "Pills"
    case tablets = "Tablets"
    case capsules = "Capsules"
    case milliliters = "ml"
    case doses = "Doses"
    case sachets = "Sachets"
    case patches = "Patches"
    case inhalers = "Inhalers"
}

struct MedicineInventory: Codable {
    var trackingEnabled: Bool
    var unitType: MedicineUnitType
    var currentCount: Int
    var fullPackCount: Int
    var lowStockThreshold: Int
    var notifyWhenLow: Bool
    var lastRefillDate: Date?
    
    var isLowStock: Bool {
        return currentCount <= lowStockThreshold
    }
    
    var percentageRemaining: Double {
        guard fullPackCount > 0 else { return 0 }
        return min(1.0, Double(currentCount) / Double(fullPackCount))
    }
}

