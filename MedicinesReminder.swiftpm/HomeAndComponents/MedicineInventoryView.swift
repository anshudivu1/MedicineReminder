//
//  MedicineInventoryView.swift
//  Medicines
//
//  Created by Divyanshu on 19/02/25.
//

import SwiftUI

struct MedicineInventoryView: View {
    @Binding var course: MedicineCourse
    @Binding var courses: [MedicineCourse]
    @Environment(\.dismiss) var dismiss
    @State private var showLowStockAlert = false
    @State private var lowStockMedicine: Medicine?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Medicine Inventory Management")) {
                    ForEach($course.medicines) { $medicine in
                        NavigationLink {
                            EditInventoryView(medicine: $medicine, courses: $courses, course: course)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(medicine.name)
                                        .font(.headline)
                                    
                                    if let inventory = medicine.inventory {
                                        Group {
                                            if inventory.trackingEnabled {
                                                HStack(spacing: 4) {
                                                    Text("\(inventory.currentCount) \(inventory.unitType.rawValue) left")
                                                        .foregroundColor(inventory.isLowStock ? .red : .secondary)
                                                        .font(.subheadline)
                                                    
                                                    if inventory.isLowStock {
                                                        Image(systemName: "exclamationmark.triangle.fill")
                                                            .foregroundColor(.red)
                                                            .font(.caption)
                                                    }
                                                }
                                            } else {
                                                Text("Inventory tracking disabled")
                                                    .foregroundColor(.secondary)
                                                    .font(.subheadline)
                                            }
                                        }
                                    } else {
                                        Text("No inventory data")
                                            .foregroundColor(.secondary)
                                            .font(.subheadline)
                                    }
                                }
                                
                                Spacer()
                                
                                if let inventory = medicine.inventory, inventory.trackingEnabled {
                                    InventoryIndicator(currentCount: inventory.currentCount, maxCount: inventory.fullPackCount)
                                }
                            }
                        }
                    }
                }
                
                Section(footer: Text("Medicines with low inventory will trigger notifications when they reach your configured threshold.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Medicine Inventory")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                checkForLowInventory()
            }
            .alert("Low Medicine Inventory", isPresented: $showLowStockAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                if let medicine = lowStockMedicine, let inventory = medicine.inventory {
                    Text("You only have \(inventory.currentCount) \(inventory.unitType.rawValue) of \(medicine.name) left. Consider refilling soon.")
                } else {
                    Text("Some medicines are running low. Please check your inventory.")
                }
            }
        }
    }
    
    private func checkForLowInventory() {
        for medicine in course.medicines {
            if let inventory = medicine.inventory, 
               inventory.trackingEnabled,
               inventory.isLowStock {
                lowStockMedicine = medicine
                showLowStockAlert = true
                break
            }
        }
    }
}

struct InventoryIndicator: View {
    let currentCount: Int
    let maxCount: Int
    
    private var percentage: Double {
        guard maxCount > 0 else { return 0 }
        return min(1.0, Double(currentCount) / Double(maxCount))
    }
    
    private var color: Color {
        if percentage <= 0.2 {
            return .red
        } else if percentage <= 0.5 {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 50, height: 8)
            
            Capsule()
                .fill(color)
                .frame(width: 50 * CGFloat(percentage), height: 8)
        }
    }
}

struct EditInventoryView: View {
    @Binding var medicine: Medicine
    @Binding var courses: [MedicineCourse]
    let course: MedicineCourse
    @Environment(\.dismiss) var dismiss
    
    @State private var trackingEnabled: Bool
    @State private var unitType: MedicineUnitType
    @State private var currentCount: Double
    @State private var fullPackCount: Double
    @State private var lowStockThreshold: Double
    @State private var notifyWhenLow: Bool
    
    init(medicine: Binding<Medicine>, courses: Binding<[MedicineCourse]>, course: MedicineCourse) {
        self._medicine = medicine
        self._courses = courses
        self.course = course
        
        if let inventory = medicine.wrappedValue.inventory {
            self._trackingEnabled = State(initialValue: inventory.trackingEnabled)
            self._unitType = State(initialValue: inventory.unitType)
            self._currentCount = State(initialValue: Double(inventory.currentCount))
            self._fullPackCount = State(initialValue: Double(inventory.fullPackCount))
            self._lowStockThreshold = State(initialValue: Double(inventory.lowStockThreshold))
            self._notifyWhenLow = State(initialValue: inventory.notifyWhenLow)
        } else {
            self._trackingEnabled = State(initialValue: false)
            self._unitType = State(initialValue: .pills)
            self._currentCount = State(initialValue: 30)
            self._fullPackCount = State(initialValue: 30)
            self._lowStockThreshold = State(initialValue: 5)
            self._notifyWhenLow = State(initialValue: true)
        }
    }
    
    var body: some View {
        Form {
            Section {
                Toggle("Track Inventory", isOn: $trackingEnabled)
                    .tint(.accentColor)
            } footer: {
                Text("Enable inventory tracking to keep track of your medicine supply")
            }
            
            if trackingEnabled {
                Section(header: Text("Inventory Details")) {
                    Picker("Unit Type", selection: $unitType) {
                        ForEach(MedicineUnitType.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Current Count")
                            Spacer()
                            Text("\(Int(currentCount)) \(unitType.rawValue)")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $currentCount, in: 0...Double(max(100, Int(fullPackCount))), step: 1)
                            .tint(.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Full Package Count")
                            Spacer()
                            Text("\(Int(fullPackCount)) \(unitType.rawValue)")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $fullPackCount, in: 1...100, step: 1)
                            .tint(.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Low Stock Threshold")
                            Spacer()
                            Text("\(Int(lowStockThreshold)) \(unitType.rawValue)")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $lowStockThreshold, in: 1...50, step: 1)
                            .tint(.accentColor)
                    }
                    
                    Toggle("Notify When Low", isOn: $notifyWhenLow)
                        .tint(.accentColor)
                }
                
                Section {
                    Button(action: {
                        currentCount = fullPackCount
                        saveInventory()
                        dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.clockwise.circle.fill")
                            Text("Refill to Full Package")
                            Spacer()
                        }
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
        .navigationTitle(medicine.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveInventory()
                    dismiss()
                }
            }
        }
    }
    
    private func saveInventory() {
        let inventory = MedicineInventory(
            trackingEnabled: trackingEnabled,
            unitType: unitType,
            currentCount: Int(currentCount),
            fullPackCount: Int(fullPackCount),
            lowStockThreshold: Int(lowStockThreshold),
            notifyWhenLow: notifyWhenLow
        )
        
        medicine.inventory = inventory
        
        DataManager.saveCourses(courses)
        
        if trackingEnabled && notifyWhenLow && inventory.isLowStock {
            scheduleInventoryAlert()
        }
        
        print("Saved inventory for \(medicine.name): \(inventory.currentCount)/\(inventory.fullPackCount) \(inventory.unitType.rawValue)")
    }
    
    private func scheduleInventoryAlert() {
        NotificationManager.shared.scheduleInventoryAlert(
            medicineName: medicine.name,
            courseName: course.name,
            remainingCount: Int(currentCount),
            unitType: unitType.rawValue
        )
    }
}
