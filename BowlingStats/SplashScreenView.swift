import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false

    var body: some View {
        if isActive {
            ContentView() // After the splash screen, show the main app
        } else {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack {
                    Text("Bowlytics")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .background(Color.blue.opacity(0.01))
                        .shadow(color: Color.blue.opacity(0.9), radius: 30, x: 0, y: 0) // Neon blue glow effect
                        .padding(.bottom, 10)
                    
                    Image("BowlyticsIcon") // Replace with your logo's asset name
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 30)) // Apply rounded corners
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { // Adjust time as needed
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}
