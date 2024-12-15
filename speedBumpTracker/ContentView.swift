//
//  ContentView.swift
//  speedBumpTracker
//
//  Created by Gerrie Diaz on 12/14/24.
//

import SwiftUI

struct TrackingEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    var vehicleModel: String
    var isEntry: Bool
    
    init(id: UUID = UUID(), 
         timestamp: Date = Date(), 
         vehicleModel: String = "", 
         isEntry: Bool = true) {
        self.id = id
        self.timestamp = timestamp
        self.vehicleModel = vehicleModel
        self.isEntry = isEntry
    }
}

struct EventDetailView: View {
    @Binding var event: TrackingEvent
    @Environment(\.dismiss) private var dismiss
    var onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Vehicle Model", text: $event.vehicleModel)
                    
                    Picker("Event Type", selection: $event.isEntry) {
                        Text("Entry").tag(true)
                        Text("Exit").tag(false)
                    }
                    .pickerStyle(.segmented)
                    
                    Text("Time: \(event.timestamp.formatted(date: .abbreviated, time: .complete))")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    @State private var events: [TrackingEvent] = []
    @State private var showingClearConfirmation = false  // For confirmation dialog
    @State private var currentDateIndex = 0

    // Add this saveEvents function
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: "trackingEvents")
        }
    }
    
    // Load events from UserDefaults when the view appears
    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: "trackingEvents"),
           let decodedEvents = try? JSONDecoder().decode([TrackingEvent].self, from: data) {
            events = decodedEvents
        }
    }
    
    private var groupedEvents: [(Date, [TrackingEvent])] {
        let grouped = Dictionary(grouping: events) { event in
            Calendar.current.startOfDay(for: event.timestamp)
        }
        return grouped.sorted { $0.key > $1.key } // Sort by date, most recent first
    }
    
    private var currentDateEvents: (Date, [TrackingEvent])? {
        guard !groupedEvents.isEmpty else { return nil }
        return groupedEvents[currentDateIndex]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // App icon/logo placeholder
                Image(systemName: "car.fill")
                    .imageScale(.large)
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)
                
                Text("Speed Bump Tracker")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Track Event button
                Button(action: {
                    let newEvent = TrackingEvent()
                    events.insert(newEvent, at: 0)
                    currentDateIndex = 0  // Reset to most recent date
                    saveEvents()
                }) {
                    Label("Track Event", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Date Navigation
                if !groupedEvents.isEmpty {
                    HStack {
                        Button(action: {
                            if currentDateIndex < groupedEvents.count - 1 {
                                currentDateIndex += 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .opacity(currentDateIndex < groupedEvents.count - 1 ? 1 : 0.3)
                        }
                        .disabled(currentDateIndex >= groupedEvents.count - 1)
                        
                        Spacer()
                        
                        if let (date, _) = currentDateEvents {
                            Text(date.formatted(date: .complete, time: .omitted))
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if currentDateIndex > 0 {
                                currentDateIndex -= 1
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .opacity(currentDateIndex > 0 ? 1 : 0.3)
                        }
                        .disabled(currentDateIndex <= 0)
                    }
                    .padding(.horizontal)
                }
                
                // Event List
                if let (_, eventsForDate) = currentDateEvents {
                    List {
                        ForEach(eventsForDate) { event in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "car.fill")
                                        .foregroundStyle(.tint)
                                    Text(event.timestamp.formatted(date: .abbreviated, time: .complete))
                                        .foregroundStyle(.secondary)
                                }
                                
                                HStack {
                                    TextField("Vehicle Model", 
                                        text: Binding(
                                            get: { event.vehicleModel },
                                            set: { newValue in
                                                if let index = events.firstIndex(where: { $0.id == event.id }) {
                                                    events[index].vehicleModel = newValue
                                                    saveEvents()
                                                }
                                            }
                                        )
                                    )
                                    .textFieldStyle(.roundedBorder)
                                    
                                    Picker("Event Type", selection: Binding(
                                        get: { event.isEntry },
                                        set: { newValue in
                                            if let index = events.firstIndex(where: { $0.id == event.id }) {
                                                events[index].isEntry = newValue
                                                saveEvents()
                                            }
                                        }
                                    )) {
                                        Text("Entry").tag(true)
                                        Text("Exit").tag(false)
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 120)
                                    
                                    Button(action: {
                                        if let index = events.firstIndex(where: { $0.id == event.id }) {
                                            events.remove(at: index)
                                            saveEvents()
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } else {
                    Text("No events recorded")
                        .foregroundStyle(.secondary)
                        .padding()
                }
                
                // Clear History button
                if !events.isEmpty {
                    Button(role: .destructive, action: {
                        showingClearConfirmation = true
                    }) {
                        Label("Clear History", systemImage: "trash")
                            .font(.subheadline)
                    }
                    .padding(.bottom)
                }
            }
            .padding(.top)
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(
                "Clear History",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear All", role: .destructive) {
                    events.removeAll()
                    currentDateIndex = 0
                    saveEvents()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to clear all tracked events? This cannot be undone.")
            }
        }
        .onAppear(perform: loadEvents)
    }
}

#Preview {
    ContentView()
        .onAppear {
            // Add sample data for preview
            UserDefaults.standard.removeObject(forKey: "trackingEvents")
            let sampleEvents = [
                TrackingEvent(id: UUID(),
                             timestamp: Date(),
                             vehicleModel: "Tesla Model 3",
                             isEntry: true),
                TrackingEvent(id: UUID(),
                             timestamp: Date().addingTimeInterval(-3600),
                             vehicleModel: "Ford F-150",
                             isEntry: false)
            ]
            if let encoded = try? JSONEncoder().encode(sampleEvents) {
                UserDefaults.standard.set(encoded, forKey: "trackingEvents")
            }
        }
}
