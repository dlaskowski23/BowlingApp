import SwiftUI

extension UIApplication {
    func endEditing(_ force: Bool) {
        self.sendAction(#selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil)
    }
}

struct GameInputView: View {
    @Environment(\.presentationMode) var presentationMode // Allows dismissal
    var leagueName: String? = nil // Optional League Name
    init(leagueName: String? = nil) {
        self.leagueName = leagueName

        // Load Saved Locations
        if let data = UserDefaults.standard.data(forKey: "savedLocations"),
           let decodedLocations = try? JSONDecoder().decode([String].self, from: data) {
            self._savedLocations = State(initialValue: decodedLocations)
            print("Loaded Locations: \(decodedLocations)")
        } else {
            print("No savedLocations found in UserDefaults")
        }

        // Load Saved Bowling Balls
        if let data = UserDefaults.standard.data(forKey: "savedBowlingBalls"),
           let decodedBalls = try? JSONDecoder().decode([String].self, from: data) {
            self._savedBowlingBalls = State(initialValue: decodedBalls)
            print("Loaded Bowling Balls: \(decodedBalls)")
        } else {
            print("No savedBowlingBalls found in UserDefaults")
        }
    }
    @State private var scores: [[Int?]] = Array(repeating: [nil, nil], count: 9) + [[nil, nil, nil]] // 10th frame has 3 possible rolls
    @State private var frameTotals: [Int] = Array(repeating: 0, count: 10)
    @State private var currentFrame = 0
    @State private var currentBall = 0
    @State private var totalScore = 0
    @State private var showMoreInfo = false
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var showLocationInput = false
    @State private var showNewBallInput = false
    @State private var bowlingStyle: String = "One-Handed"
    @State private var gripStyle: String = "3-Finger"
    @State private var savedLocations: [String] = []
    @State private var newLocation: String = ""
    @State private var selectedBowlingBalls: [String] = []
    @State private var savedBowlingBalls: [String] = []
    @State private var newBowlingBall: String = ""
    @State private var laneNumber: String = ""
    @State private var ballToDelete: String? = nil
    @State private var showDeleteAlert = false
    @State private var selectedBowlingBall: String = ""
    @State private var selectedPins: Set<Int> = []

    
    @AppStorage("savedLocations") private var savedLocationsData: Data = Data()
    @AppStorage("savedGames") private var savedGamesData: Data = Data()
    @AppStorage("leagueGames") private var leagueGamesData: Data = Data()

    var body: some View {
        GeometryReader { geometry in
            VStack {
                fullScoreboardView
//                    .padding(.bottom, 5)
                    .padding(.top, 25)
                
                VStack {
                    zoomedFrameView
                        .padding(.bottom, UIScreen.main.bounds.width > 390 ? geometry.size.height * 0.06 : geometry.size.height * 0.02)
                        .frame(maxWidth: .infinity, alignment: .center) // Ensure centering
                    
                    // Live Score Counter
                    Text("Total Score: \(totalScore)")
                        .font(.title2.bold())
                        .foregroundColor(.green)
                        .minimumScaleFactor(0.8)
                        .padding(.bottom, 8)
                        .padding(.vertical, 5)
                    
                    ballInputSection
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                    
                    // Strike, Spare, Clear Frame Buttons
                    HStack(spacing: 12) {
                        Button(action: recordStrike) {
                            Text("Strike")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: recordSpare) {
                            Text("Spare")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: clearFrame) {
                            Text("Clear")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                    
                    frameNavigationButtons
                        .padding(.top, 5)
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea(edges: .all)) // Fixes dark mode covering top/bottom
            //        .navigationTitle("Enter Scores")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showMoreInfo.toggle() }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Enter Scores")
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGame()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Discard") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showMoreInfo) {
                VStack {
                    HStack {
                        Text("Game Details")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.bottom, 5)
                        
                        Spacer() // Pushes the close button to the right
                        
                        Button(action: { showMoreInfo = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                    List {
                        Picker("Bowling Style", selection: $bowlingStyle) {
                            Text("One-Handed").tag("One-Handed")
                            Text("Two-Handed").tag("Two-Handed")
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Picker("Grip Style", selection: $gripStyle) {
                            Text("3-Finger").tag("3-Finger")
                            Text("2-Finger").tag("2-Finger")
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Picker("Location", selection: $location) {
                            Text("None").tag("")
                            ForEach(savedLocations, id: \.self) { loc in
                                Text(loc).tag(loc)
                            }
                            Text("+ Add New Location").tag("Add New Location")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: location) { oldValue, newValue in
                            showLocationInput = (newValue == "Add New Location")
                            if newValue != "Add New Location" {
                                newLocation = ""
                            }
                        }
                        
                        if showLocationInput {
                            TextField("Enter new location", text: $newLocation, onCommit: {
                                if !newLocation.isEmpty {
                                    DispatchQueue.main.async {
                                        savedLocations.append(newLocation)
                                        if let encoded = try? JSONEncoder().encode(savedLocations) {
                                            UserDefaults.standard.set(encoded, forKey: "savedLocations")
                                        }
                                        location = newLocation
                                        newLocation = ""
                                        showLocationInput = false
                                    }
                                }
                            })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        Picker("Lane Number", selection: $laneNumber) {
                            Text("None").tag("")
                            ForEach(1...40, id: \.self) { lane in
                                Text("Lane \(lane)").tag("\(lane)") // Convert to string for selection
                            }
                        }
                        .pickerStyle(MenuPickerStyle()) // Change to Menu Picker
                        
                        Section(header: Text("Bowling Balls").font(.headline))
                        {
                            Picker("Select Bowling Ball", selection: $selectedBowlingBall) {
                                Text("None").tag("")
                                ForEach(savedBowlingBalls, id: \.self) { ball in
                                    Text(ball).tag(ball)
                                }
                                Text("+ Add New Ball").tag("Add New Ball")
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: selectedBowlingBall) { oldValue, newValue in
                                showNewBallInput = (newValue == "Add New Ball")
                                if newValue != "Add New Ball" {
                                    newBowlingBall = ""
                                }
                            }
                            
                            if showNewBallInput {
                                TextField("Enter new bowling ball", text: $newBowlingBall, onCommit: {
                                    if !newBowlingBall.isEmpty {
                                        DispatchQueue.main.async {
                                            savedBowlingBalls.append(newBowlingBall)
                                            if let encoded = try? JSONEncoder().encode(savedBowlingBalls) {
                                                UserDefaults.standard.set(encoded, forKey: "savedBowlingBalls")
                                            }
                                            selectedBowlingBall = newBowlingBall
                                            newBowlingBall = ""
                                            showNewBallInput = false
                                        }
                                    }
                                })
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        
                        Section(header: Text("Notes").font(.headline)) {
                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .onTapGesture {
                                    // Ensure TextEditor is active and prevents background tap dismissal
                                }
                        }
                    }
                    .overlay(Color.clear.allowsHitTesting(false))
                    .scrollContentBackground(.hidden)
                    .background(Color.black)
                }
                .overlay(Color.clear.allowsHitTesting(false))
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.ignoresSafeArea())
                .preferredColorScheme(.dark) // Ensures dark mode appearance
                .onTapGesture {
                    // Dismiss keyboard when tapping outside
                    UIApplication.shared.endEditing(true)
                }
                .alert("Delete Bowling Ball?", isPresented: $showDeleteAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        if let ball = ballToDelete, let index = savedBowlingBalls.firstIndex(of: ball) {
                            savedBowlingBalls.remove(at: index)
                            ballToDelete = nil
                            
                            // Update UserDefaults
                            if let encoded = try? JSONEncoder().encode(savedBowlingBalls) {
                                UserDefaults.standard.set(encoded, forKey: "savedBowlingBalls")
                            }
                        }
                    }
                } message: {
                    Text("This will remove \(ballToDelete ?? "this ball") permanently.")
                }
            }
            .onTapGesture {
                // Dismiss keyboard when tapping outside
                UIApplication.shared.endEditing(true)
            }
        }
    }


    // MARK: - Functions

    /// Handles Text Input for Ball 1 and Ball 2
    private func handleInput(_ newValue: String, ball: Int) {
        guard let value = Int(newValue), value >= 0, value <= 10 else { return }

        if currentFrame < 9 { // Frames 1-9 validation
            if ball == 1 { // Checking second ball entry
                let firstBall = scores[currentFrame][0] ?? 0
                if firstBall + value > 10 {
                    return // Prevents illegal score entry
                }
            }
        }

        // Frame 10 logic (No restriction on sum)
        scores[currentFrame][ball] = value
        updateScore()
    }
    private func showDeleteConfirmation(for ball: String) {
        ballToDelete = ball
        showDeleteAlert = true
    }

    /// Clears the current frame’s inputs
    private func clearFrame() {
        scores[currentFrame] = (currentFrame == 9) ? [nil, nil, nil] : [nil, nil]
        updateScore()
    }

    /// Displays the score properly (handles Strikes & Spares)
    private func displayScore(for frame: Int, ball: Int) -> String {
        guard let score = scores[frame][ball] else { return "" }

        // STRIKE LOGIC (Handles first ball strike normally)
        if score == 10 && ball == 0 { return "X" }
        
        // Special Handling for 10th Frame
        if frame == 9 {
            if ball == 0 && score == 10 { return "X" } // First strike
            if ball == 1 && score == 10 { return "X" } // Second strike
            if ball == 2 && score == 10 { return "X" } // Third strike
            if ball == 1 && (scores[frame][0] ?? 0) + score == 10 { return "/" } // Spare in 10th frame
            if ball == 2 && (scores[frame][1] ?? 0) + score == 10 { return "/" } // Spare for Ball 3
        }

        // Spare Logic (Frames 1-9)
        if frame < 9, let firstBall = scores[frame][0], let secondBall = scores[frame][1], firstBall + secondBall == 10 {
            return ball == 1 ? "/" : "\(firstBall)"
        }

        return "\(score)"
    }

    /// Records a Strike
    private func recordStrike() {
        scores[currentFrame][currentBall] = 10
        if currentFrame == 9 {
            if currentBall < 2 {
                currentBall += 1
            }
        } else {
            moveToNextFrame()
        }
        updateScore()
    }

    /// Records a Spare
    private func recordSpare() {
        if currentFrame == 9 {
            if currentBall == 1 {
                scores[currentFrame][1] = 10 - (scores[currentFrame][0] ?? 0)
                currentBall += 1
            } else if currentBall == 2 {
                scores[currentFrame][2] = 10 - (scores[currentFrame][1] ?? 0)
            }
        } else {
            scores[currentFrame][1] = 10 - (scores[currentFrame][0] ?? 0)
            moveToNextFrame()
        }
        updateScore()
    }

    /// Moves to the next frame with smooth scrolling
    private func moveToNextFrame() {
        if currentFrame < 9 {
            withAnimation {
                currentFrame += 1
            }
        }
        updateScore()
    }

    /// Moves to the previous frame with smooth scrolling
    private func moveToPreviousFrame() {
        if currentFrame > 0 {
            withAnimation {
                currentFrame -= 1
            }
        }
    }

    /// Updates Score and Handles Special Bowling Rules
    private func updateScore() {
        totalScore = 0

        for frame in 0..<10 {
            let ball1 = scores[frame][0] ?? 0
            let ball2 = scores[frame][1] ?? 0
            let ball3 = (frame == 9) ? (scores[frame][2] ?? 0) : 0  // Ball 3 only in 10th frame

            if frame == 9 {
                // Special 10th Frame Scoring
                frameTotals[frame] = ball1 + ball2 + ball3
            } else if ball1 == 10 {
                // STRIKE: Add next two balls as bonus
                let bonus1 = (frame + 1 < 10) ? (scores[frame + 1][0] ?? 0) : 0
                let bonus2: Int
                if frame + 1 < 10 {
                    if scores[frame + 1][0] == 10 {
                        // If next frame is also a strike, take next frame's first roll
                        bonus2 = (frame + 2 < 10) ? (scores[frame + 2][0] ?? 0) : (scores[frame + 1][1] ?? 0)
                    } else {
                        bonus2 = scores[frame + 1][1] ?? 0
                    }
                } else {
                    bonus2 = 0
                }
                frameTotals[frame] = 10 + bonus1 + bonus2
            } else if ball1 + ball2 == 10 {
                // SPARE: Add next ball as bonus
                let bonus = (frame + 1 < 10) ? (scores[frame + 1][0] ?? 0) : 0
                frameTotals[frame] = 10 + bonus
            } else {
                // OPEN FRAME
                frameTotals[frame] = ball1 + ball2
            }

            totalScore += frameTotals[frame]
        }
    }

    /// Saves the game
    private func saveGame() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d/yyyy"
            let date = dateFormatter.string(from: Date())
        

        let gameData = BowlingGame(date: date, scores: scores, totalScore: totalScore, frameTotals: frameTotals, bowlingStyle: bowlingStyle, gripStyle: gripStyle, bowlingBalls: selectedBowlingBalls, location: location, laneNumber: laneNumber, notes: notes)

            if let league = leagueName {
                // Save to the specific league
                var allLeagueGames = (try? JSONDecoder().decode([String: [BowlingGame]].self, from: leagueGamesData)) ?? [:]
                allLeagueGames[league, default: []].append(gameData)

                if let encoded = try? JSONEncoder().encode(allLeagueGames) {
                    leagueGamesData = encoded
                }
            } else {
                // Save as a casual game
                var savedGames = (try? JSONDecoder().decode([BowlingGame].self, from: savedGamesData)) ?? []
                savedGames.append(gameData)
                if let encoded = try? JSONEncoder().encode(savedGames) {
                    savedGamesData = encoded
                }
            }

            print("Game saved: \(gameData)")
        }

        /// Loads saved games from AppStorage
        private func loadSavedGames() -> [BowlingGame] {
            if let decoded = try? JSONDecoder().decode([BowlingGame].self, from: savedGamesData) {
                return decoded
            }
            return []
        }
    
    private var fullScoreboardView: some View {
        GeometryReader { geometry in
            let isLargeScreen = geometry.size.width > 430
            let frameWidth = min(geometry.size.width / 12.4, 26)
            let adjustedFrameWidth = isLargeScreen ? frameWidth * 1.1 : frameWidth

            HStack(spacing: 2) { // Reduced spacing for better alignment
                ForEach(0..<10, id: \.self) { frame in
                    VStack(spacing: 2) { // Reduced internal spacing for better layout
                        Text("F\(frame + 1)")
                            .bold()
                            .foregroundColor(.white)
                            .font(.caption2)
                            .minimumScaleFactor(0.7)

                        VStack(spacing: 2) {
                            ForEach(0..<(frame == 9 ? 3 : 2), id: \.self) { ball in
                                Text(displayScore(for: frame, ball: ball))
                                    .frame(width: adjustedFrameWidth, height: adjustedFrameWidth)
                                    .background(currentFrame == frame ? Color.blue.opacity(0.6) : Color.gray.opacity(0.3))
                                    .cornerRadius(4)
                                    .font(.caption2)
                            }
                        }

                        Text("\(frameTotals[frame])")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption2)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(4)
                    .background(currentFrame == frame ? Color.blue.opacity(0.3) : Color.clear)
                    .cornerRadius(4)
                }
            }
            .frame(width: geometry.size.width, height: 100)
        }
        .padding(.horizontal, 2) // Reduced padding slightly
    }
    
    private var zoomedFrameView: some View {
        GeometryReader { geometry in
            let screenWidth = UIScreen.main.bounds.width
            let isLargeScreen = screenWidth > 430 // Adjust threshold for different devices
            
            // Adjusting size of the zoomed-in frame dynamically
            let frameSize = isLargeScreen ? geometry.size.width * 0.28 : geometry.size.width * 0.17
            let horizontalPadding: CGFloat = isLargeScreen ? 6 : 8
            
            VStack(spacing: 5) {
                Text("Frame \(currentFrame + 1)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
                
                HStack(spacing: 4) {
                    ForEach(0..<(currentFrame == 9 ? 3 : 2), id: \.self) { ball in
                        Text(displayScore(for: currentFrame, ball: ball))
                            .frame(width: frameSize, height: frameSize) // Apply dynamic frame size
                            .background(Color.blue.opacity(0.6))
                            .cornerRadius(6)
                            .font(.headline)
                            .minimumScaleFactor(0.7)
                    }
                }
                Text("\(frameTotals[currentFrame])")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.headline)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.3))
            .cornerRadius(8)
            .frame(maxWidth: geometry.size.width * 1.75, alignment: .center)
            .frame(maxWidth: .infinity, alignment: .center) // Ensure centering
            .transition(.move(edge: .bottom))
            .animation(.easeInOut, value: currentFrame)
        }
        .frame(height: 120)
    }
    
    private var ballInputSection: some View {
        VStack {
            HStack(spacing: 7) {
                VStack {
                    Text("Ball 1").foregroundColor(.white)
                    Picker("Ball 1", selection: Binding(
                        get: { scores[currentFrame][0] ?? 0 },
                        set: { newValue in
                            scores[currentFrame][0] = newValue
                            if currentFrame < 9 { scores[currentFrame][1] = nil }
                            updateScore()
                        }
                    )) {
                        ForEach(0...10, id: \.self) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                VStack {
                    Text("Ball 2").foregroundColor(.white)
                    Picker("Ball 2", selection: Binding(
                        get: { scores[currentFrame][1] ?? 0 },
                        set: { newValue in
                            scores[currentFrame][1] = newValue
                            updateScore()
                        }
                    )) {
                    ForEach(0...(currentFrame == 9 && scores[currentFrame][0] == 10 ? 10 : (10 - (scores[currentFrame][0] ?? 0))), id: \.self) { number in
                        Text("\(number)").tag(number)
                    }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .disabled(scores[currentFrame][0] == 10 && currentFrame < 9) // Disable if first ball is a strike, except for frame 10
                }

                if currentFrame == 9 { // Third ball for 10th frame
                    VStack {
                        Text("Ball 3").foregroundColor(.white)
                        Picker("Ball 3", selection: Binding(
                            get: { scores[currentFrame][2] ?? 0 },
                            set: { newValue in
                                scores[currentFrame][2] = newValue
                                updateScore()
                            }
                        )) {
                                let maxBall3 = (scores[currentFrame][0] == 10 || ((scores[currentFrame][0] ?? 0) + (scores[currentFrame][1] ?? 0) == 10)) ? 10 : (10 - (scores[currentFrame][1] ?? 0))
                                ForEach(0...maxBall3, id: \.self) { number in
                                    Text("\(number)").tag(number)
                                }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: 75) // Increase width to match Ball 1 & 2
                        .disabled(scores[currentFrame][1] == nil) // Enable only if Ball 2 has a value
                    }
                }
            }
        }
    }
    private var frameNavigationButtons: some View {
        HStack(spacing: 20) {
            Button(action: moveToPreviousFrame) {
                Text("Back")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(currentFrame == 0 ? Color.gray : Color.teal)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(currentFrame == 0)
            
            Button(action: moveToNextFrame) {
                Text("Next Frame")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
        .padding(.top)
        .padding(.bottom, UIScreen.main.bounds.width > 390 ? 100 : 1)    }
}

struct BowlingGame: Codable, Identifiable {
    var id = UUID()
    var date: String
    var scores: [[Int?]]
    var totalScore: Int
    var frameTotals: [Int]
    
    var bowlingStyle: String? // One-Handed, Two-Handed
    var gripStyle: String?     // 3-Finger, 2-Finger
    var bowlingBalls: [String]? // 🏆 Multiple bowling balls used
    var location: String?  // 🏠 Where the game was played
    var laneNumber: String?
    var notes: String?     // 📝 Additional details

    var isLeagueGame: Bool = false
    var leagueName: String?
}

struct League: Codable, Identifiable {
    var id = UUID()
    var name: String
    var emoji: String
    var dateAdded: Date
}

