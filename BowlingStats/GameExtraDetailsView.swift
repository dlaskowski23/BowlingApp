import SwiftUI

struct GameExtraDetailsView: View {
    @Binding var location: String
    @Binding var bowlingStyle: String
    @Binding var gripStyle: String
    @AppStorage("savedLocations") private var savedLocationsData: Data = Data()
    
    @State private var savedLocations: [String] = []
    @State private var newLocation: String = ""
    
    let styles = ["One-Handed", "Two-Handed"]
    let grips = ["3-Finger", "2-Finger"]

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Game Details")
                .font(.title.bold())
                .padding(.top)
            
            // Bowling Style Selection
            VStack(alignment: .leading) {
                Text("Bowling Style").font(.headline)
                Picker("Select Style", selection: $bowlingStyle) {
                    ForEach(styles, id: \.self) { style in
                        Text(style)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Grip Style Selection
            VStack(alignment: .leading) {
                Text("Grip Style").font(.headline)
                Picker("Select Grip", selection: $gripStyle) {
                    ForEach(grips, id: \.self) { grip in
                        Text(grip)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Location Selection with "Add New" Feature
            VStack(alignment: .leading) {
                Text("Bowling Alley").font(.headline)
                Picker("Select Location", selection: $location) {
                    Text("None").tag("")
                    ForEach(savedLocations, id: \.self) { loc in
                        Text(loc).tag(loc)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                // Add New Location Input
                HStack {
                    TextField("New Location", text: $newLocation)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        if !newLocation.isEmpty {
                            savedLocations.append(newLocation)
                            location = newLocation
                            saveLocations()
                            newLocation = ""
                        }
                    }) {
                        Text("Add")
                            .padding(8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                }
            }
            
        }
        .padding()
        .background(Color.black.opacity(0.9))
        .cornerRadius(12)
        .onAppear(perform: loadLocations)
    }
    
    private func saveLocations() {
        if let encoded = try? JSONEncoder().encode(savedLocations) {
            savedLocationsData = encoded
        }
    }

    private func loadLocations() {
        if let decoded = try? JSONDecoder().decode([String].self, from: savedLocationsData) {
            savedLocations = decoded
        }
    }
}
