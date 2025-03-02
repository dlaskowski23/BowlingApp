import SwiftUI

struct GameInputView: View {
    @Environment(\.presentationMode) var presentationMode // Allows dismissal
    var leagueName: String? // Optional League Name

    @State private var scores: [[Int?]] = Array(repeating: [nil, nil], count: 9) + [[nil, nil, nil]] // 10th frame has 3 possible rolls
    @State private var frameTotals: [Int] = Array(repeating: 0, count: 10)
    @State private var currentFrame = 0
    @State private var currentBall = 0
    @State private var totalScore = 0
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var showMoreInfo = false
    
    @AppStorage("savedGames") private var savedGamesData: Data = Data()
    @AppStorage("leagueGames") private var leagueGamesData: Data = Data()

    var body: some View {
        VStack {
            // Title
            Text("Enter Scores")
                .font(.title.bold())
                .foregroundColor(.white)
                .padding(.top, 10)

            // Scoreboard UI - Enlarged to fit 2 frames per scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) { // Increased spacing for clarity
                    ForEach(0..<10, id: \.self) { frame in
                        VStack {
                            Text("F\(frame + 1)")
                                .bold()
                                .foregroundColor(.white)
                                .frame(width: 100) // Increased frame width

                            HStack(spacing: 8) {
                                ForEach(0..<(frame == 9 ? 3 : 2), id: \.self) { ball in // 10th frame allows 3 rolls
                                    Text(displayScore(for: frame, ball: ball))
                                        .frame(width: 50, height: 50) // Increased size
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(width: frame == 9 ? 160 : 130) // Extra width for 10th frame

                            Text("\(frameTotals[frame])")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(width: frame == 9 ? 160 : 130, height: 140) // Adjust height
                        .padding(8)
                        .background(Color.black.opacity(0.9)) // Darker frame background
                        .cornerRadius(12)
                    }
                }
            }
            .frame(height: 160) // Adjust height to prevent cutoff
            .padding()
            .frame(height: 140) // Increased height for better visibility
            .padding()

            // Live Score Counter
            Text("Total Score: \(totalScore)")
                .font(.title2.bold())
                .foregroundColor(.green)
                .padding(.bottom, 8)

            // Frame and Ball Input Section
            Text("Frame \(currentFrame + 1)")
                .font(.headline)
                .foregroundColor(.white)

            // Ball Inputs (Frame by Frame)
            HStack(spacing: 20) {
                ForEach(0..<scores[currentFrame].count, id: \.self) { ball in
                    VStack {
                        Text("Ball \(ball + 1)")
                            .foregroundColor(.white)
                        TextField("0", text: Binding(
                            get: { scores[currentFrame][ball]?.description ?? "" },
                            set: { newValue in handleInput(newValue, ball: ball) }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60, height: 40) // Adjusted size
                        .keyboardType(.numberPad)
                        .background(Color.black.opacity(0.3)) // Ensures dark mode visibility
                        .foregroundColor(.black)
                        .accentColor(.black) // Ensures cursor is white
                        .cornerRadius(8)
                    }
                }
            }
            .padding()

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
                    Text("Clear Frame")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.top)

            // Navigation Buttons
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

            // Save / Discard Buttons
            HStack(spacing: 15) {
                Button(action: {
                    saveGame()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save Game")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("Discard Game")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 15)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea(edges: .all)) // Fixes dark mode covering top/bottom
        .navigationTitle("Enter Scores")
        .toolbar {
            // Close Button (Upper Right)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                }
            }

            // More Info Button (Upper Left)
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showMoreInfo.toggle() }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showMoreInfo) {
            VStack {
                Text("Game Details")
                    .font(.title2.bold())
                    .padding(.top)

                // Location Input
                VStack(alignment: .leading) {
                    Text("📍 Location")
                        .font(.headline)
                        .foregroundColor(.white)
                    TextField("Enter bowling alley", text: $location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
                .padding()

                // Notes Input
                VStack(alignment: .leading) {
                    Text("📝 Notes")
                        .font(.headline)
                        .foregroundColor(.white)
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
                .padding()

                // Close Button
                Button(action: { showMoreInfo = false }) {
                    Text("Close")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
        }
    }


    // MARK: - Functions

    /// Handles Text Input for Ball 1 and Ball 2
    private func handleInput(_ newValue: String, ball: Int) {
        if let value = Int(newValue), value >= 0, value <= 10 {
            scores[currentFrame][ball] = value
            updateScore()
        }
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

    /// Moves to the next frame
    private func moveToNextFrame() {
        if currentFrame < 9 {
            currentFrame += 1
            currentBall = 0
        }
        updateScore()
    }

    /// Moves to the previous frame
    private func moveToPreviousFrame() {
        if currentFrame > 0 {
            currentFrame -= 1
            currentBall = 0
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
        

        let gameData = BowlingGame(date: date, scores: scores, totalScore: totalScore, frameTotals: frameTotals, location: location, notes: notes)

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
}

struct BowlingGame: Codable, Identifiable {
    var id = UUID()
    var date: String
    var scores: [[Int?]]
    var totalScore: Int
    var frameTotals: [Int]
    
    var location: String?  // 🏠 Where the game was played
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

// MARK: - Preview
#Preview {
    GameInputView()
}
