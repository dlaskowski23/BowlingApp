import SwiftUI

struct GameExtraDetailsView: View {
    @Binding var gameLocation: String
    @Binding var gameNotes: String
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 📍 Location Field
                TextField("Enter Bowling Alley", text: $gameLocation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                // 📝 Notes Field
                VStack(alignment: .leading) {
                    Text("Notes")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextEditor(text: $gameNotes)
                        .frame(height: 120)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Extra Game Details")
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .preferredColorScheme(.dark)
        }
    }
}


