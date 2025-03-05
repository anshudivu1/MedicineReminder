//
//  HomeView.swift
//  Medicines
//
//  Created by Divyanshu on 23/01/25.
//

import SwiftUI

struct HomeView: View {
    @State private var courses: [MedicineCourse] = []
    @State private var isAddCourseViewPresented = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedTab = "active"
    @State private var appearAnimation = false
    @State private var showDeleteAlert = false
    @State private var courseToDelete: MedicineCourse?
    
    init() {
        _courses = State(initialValue: DataManager.loadCourses())
    }
    
    private var filteredCourses: [MedicineCourse] {
        if selectedTab == "active" {
            return courses.filter { $0.isActive() }
        } else {
            return courses.filter { !$0.isActive() }
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(UIColor.systemBackground),
                    Color(UIColor.systemGroupedBackground)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    TabButton(title: "Active", isSelected: selectedTab == "active") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = "active"
                        }
                    }
                    TabButton(title: "Completed", isSelected: selectedTab == "completed") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = "completed"
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if filteredCourses.isEmpty {
                            EmptyStateView(
                                systemImage: selectedTab == "active" ? "pills.circle.fill" : "checkmark.circle.fill",
                                title: selectedTab == "active" ? "No Active Courses" : "No Completed Courses",
                                message: selectedTab == "active" ? "Start by adding a new medicine course" : "Completed courses will appear here"
                            )
                            .padding(.top, 40)
                            .transition(.opacity)
                        } else {
                            ForEach(filteredCourses) { course in
                                NavigationLink(
                                    destination: CourseDetailView(
                                        course: binding(for: course),
                                        courses: $courses
                                    )
                                ) {
                                    MedicineCourseCard(course: course)
                                        .opacity(appearAnimation ? 1 : 0)
                                        .offset(y: appearAnimation ? 0 : 20)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(role: .destructive) {
                                        courseToDelete = course
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Delete Course", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .refreshable {
                    loadCourses()
                }
            }
        }
        .navigationTitle("Medicine Courses")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isAddCourseViewPresented = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .sheet(isPresented: $isAddCourseViewPresented) {
            FillCourseDetailsView(courses: $courses)
        }
        .alert("Delete Course", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let courseToDelete = courseToDelete {
                    deleteCourse(courseToDelete)
                }
            }
        } message: {
            Text("Are you sure you want to delete this course? This action cannot be undone.")
        }
        .onAppear {
            loadCourses()
            DispatchQueue.main.async {
                       withAnimation(.easeOut(duration: 0.5)) {
                           appearAnimation = true
                       }
            }
        } .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MedicineStatusUpdated"))) { _ in
            loadCourses()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MedicineStatusUpdateCompleted"))) { _ in
            loadCourses()
        }
    }
    
    private func loadCourses() {
        courses = DataManager.loadCourses()
    }
    
    private func binding(for course: MedicineCourse) -> Binding<MedicineCourse> {
        guard let index = courses.firstIndex(where: { $0.id == course.id }) else {
            fatalError("Course not found")
        }
        return $courses[index]
    }
    
    private func deleteCourse(_ course: MedicineCourse) {
        withAnimation {
            if let index = courses.firstIndex(where: { $0.id == course.id }) {
                courses.remove(at: index)
                DataManager.saveCourses(courses)
            }
        }
    }
}



struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.subheadline, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.accentColor.opacity(0.15))
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                )
                .animation(.spring(response: 0.3), value: isSelected)
        }
    }
}

struct MedicineCourseCard: View {
    let course: MedicineCourse
    @State private var showProgress = false
    
    private var progressValue: Double {
        course.calculateProgress()
    }
    
    private func calculateProgressValue() -> Double {
        guard let startDate = course.startDate else { return 0 }
        let calendar = Calendar.current
        let today = Date()
        let endDate = calendar.date(byAdding: .day, value: course.duration, to: startDate) ?? today
        
        if today < startDate { return 0 }
        if today > endDate { return 1.0 }
        
        let totalDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        let elapsedDays = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
        return min(Double(elapsedDays) / Double(totalDays), 1.0)
    }
    
    private var daysRemaining: Int {
        course.calculateDaysRemaining()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(course.name)
                        .font(.system(.title3, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "pills.fill")
                            .foregroundColor(.accentColor)
                            .font(.subheadline)
                        
                        Text("\(course.medicines.count) medicine\(course.medicines.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(
                            Color.secondary.opacity(0.15),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                    
                    Circle()
                        .trim(from: 0, to: showProgress ? progressValue : 0)
                        .stroke(
                            Color.accentColor,
                            style: StrokeStyle(lineWidth: 9, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1), value: showProgress)
                    
                    VStack(spacing: 2) {
                        Text("\(daysRemaining)")
                            .font(.system(.title3, weight: .bold))
                        Text("Days left")
                            .font(.system(.caption, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 80, height: 80)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(course.medicines) { medicine in
                        MedicinePill(
                            medicine: medicine,
                            status: medicine.status(for: Date())
                        )
                    }
                }
                .padding(.bottom, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1)) {
                showProgress = true
            }
        }
    }
}

struct MedicinePill: View {
    let medicine: Medicine
    let status: String?
    @State private var isPressed = false
    
    private var pillColor: Color {
        guard let status = status else { return .accentColor }
        switch status.lowercased() {
        case "taken": return .green
        case "missed": return .red
        default: return .accentColor
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Text(medicine.name)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundColor(pillColor)
            
            if let status = status {
                Circle()
                    .fill(pillColor)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(pillColor.opacity(0.15))
                .shadow(color: pillColor.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .spring(response: 1, dampingFraction: 0.5)
                    .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .onAppear {
            isAnimating = true
        }
    }
}
