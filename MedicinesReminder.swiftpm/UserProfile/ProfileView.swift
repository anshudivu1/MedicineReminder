//
//  SwiftUIView.swift
//  Medicines
//
//  Created by Divyanshu on 23/01/25.
//

import SwiftUI

struct ProfileView: View {
    @State private var user: User = User(
        name: "",
        age: 30,
        gender: "Female",
        medicalConditions: [],
        breakfastTime: Date(),
        lunchTime: Date(),
        dinnerTime: Date(),
        bedtime: Date()
    )
    @State private var isEditProfileViewPresented = false
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(user.name)
                        .foregroundColor(.gray)
                }
                HStack {
                    Text("Age")
                    Spacer()
                    Text("\(user.age)")
                        .foregroundColor(.gray)
                }
                HStack {
                    Text("Gender")
                    Spacer()
                    Text(user.gender)
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("Medical Conditions")) {
                ForEach(user.medicalConditions, id: \.self) { condition in
                    Text(condition)
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("Meal Timings")) {
                HStack {
                    Text("Breakfast")
                    Spacer()
                    Text(user.breakfastTime.formatted(date: .omitted, time: .shortened))
                        .foregroundColor(.gray)
                }
                HStack {
                    Text("Lunch")
                    Spacer()
                    Text(user.lunchTime.formatted(date: .omitted, time: .shortened))
                        .foregroundColor(.gray)
                }
                HStack {
                    Text("Dinner")
                    Spacer()
                    Text(user.dinnerTime.formatted(date: .omitted, time: .shortened))
                        .foregroundColor(.gray)
                }
                HStack {
                    Text("Bedtime")
                    Spacer()
                    Text(user.bedtime.formatted(date: .omitted, time: .shortened))
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isEditProfileViewPresented = true
                }) {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $isEditProfileViewPresented) {
            EditProfileView(user: $user)
        }
        .onAppear {
            loadUserFromUserDefaults()
        }
    }
    
    private func loadUserFromUserDefaults() {
        if let savedUser = UserDefaults.standard.data(forKey: "userProfile") {
            let decoder = JSONDecoder()
            if let loadedUser = try? decoder.decode(User.self, from: savedUser) {
                user = loadedUser
            }
        }
    }
}
