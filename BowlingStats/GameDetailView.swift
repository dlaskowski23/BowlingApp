import SwiftUI

struct GameDetailView: View {
    var game: BowlingGame
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Game Breakdown")
                        .font(.title3)
                        .bold()
                        .padding(.bottom, 5)
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 5) {
                        BreakdownRow(label: "🏆 Strikes", value: countStrikes())
                        BreakdownRow(label: "🎳 Spares", value: countSpares())
                        BreakdownRow(label: "⭕ Open Frames", value: countOpenFrames())
                        Divider()
                        BreakdownRow(label: "📊 Total Score", value: game.totalScore, isBold: true)
                    }
                    .padding()
                    .background(Color(UIColor.systemGray5)) // Matches GameInputView
                    .cornerRadius(8)
                }
                .padding()
                // **Frames List (Now Horizontal Scroll)**
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Spacer(minLength: 10) // Adds spacing on the left
                        ForEach(0..<10, id: \.self) { frame in
                            FrameView(frame: frame, scores: game.scores, frameTotal: game.frameTotals[frame])
                        }
                        Spacer(minLength: 10) // Adds spacing on the right
                    }
                    .padding(.horizontal, 10) // Ensures frames aren’t cut off
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Game Details")
                        .font(.title3)
                        .bold()
                        .padding(.bottom, 5)
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 5) {
                        if let location = game.location, !location.isEmpty {
                            BreakdownRowString(label: "Location", value: location)
                            Divider()
                        }
                        if let laneNumber = game.laneNumber, !laneNumber.isEmpty {
                            BreakdownRowString(label: "Lane Number", value: laneNumber)
                            Divider()
                        }

                        if let style = game.bowlingStyle, !style.isEmpty {
                            BreakdownRowString(label: "Bowling Style", value: style)
                            Divider()
                        }
                        
                        if let grip = game.gripStyle, !grip.isEmpty {
                            BreakdownRowString(label: "Grip Style", value: grip)
                            Divider()
                        }

                        if let balls = game.bowlingBalls, !balls.isEmpty {
                            BreakdownRowString(label: "Bowling Balls", value: balls.joined(separator: ", "))
                            Divider()
                        }

                        if let notes = game.notes, !notes.isEmpty {
                            BreakdownRowString(label: "Notes", value: notes)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray5)) // Matches Game Breakdown Style
                    .cornerRadius(8)
                }
                .padding()
                
            }
        }
        .navigationTitle("Game Details")
        .background(Color.black.edgesIgnoringSafeArea(.all)) // **Dark Mode Fix**
        .preferredColorScheme(.dark)
    }
    
    // **Strike Counter**
    private func countStrikes() -> Int {
        return game.scores.flatMap { $0 }.filter { $0 == 10 }.count
    }
    
    // **Spare Counter**
    private func countSpares() -> Int {
        return game.scores.enumerated().filter { (index, frame) in
            guard frame.count >= 2, let first = frame[0], let second = frame[1] else { return false }
            return first + second == 10 && first != 10
        }.count
    }
    
    // **Open Frames Counter**
    private func countOpenFrames() -> Int {
        return game.scores.enumerated().filter { (index, frame) in
            guard frame.count >= 2 else { return false }
            let first = frame[0] ?? 0
            let second = frame[1] ?? 0
            return !(first == 10 || first + second == 10)
        }.count
    }
}

// **Breakdown Row Component**
struct BreakdownRowString: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white) // White text for Dark Mode
            Spacer()
            Text(value)
                .foregroundColor(.gray) // Make it slightly dimmer
        }
    }
}
struct BreakdownRow: View {
    let label: String
    let value: Int
    var isBold: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white) // White text for Dark Mode
            Spacer()
            Text("\(value)")
                .fontWeight(isBold ? .bold : .regular)
                .foregroundColor(.green) // Highlighted green values
        }
    }
}

// **Frame Display Component**
struct FrameView: View {
    let frame: Int
    let scores: [[Int?]]
    let frameTotal: Int

    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            Text("Frame \(frame + 1)")
                .font(.headline)
                .bold()
                .foregroundColor(.white)

            HStack(spacing: 8) { // Ensures spacing for 3rd roll
                ScoreBox(score: scores[frame][0], frameIndex: frame, ballIndex: 0, scores: scores)
                    .frame(width: 50, height: 50)
                ScoreBox(score: scores[frame][1], frameIndex: frame, ballIndex: 1, scores: scores)
                    .frame(width: 50, height: 50)
                if frame == 9 && scores[frame].count > 2 {  // Ensure 3rd roll is shown for frame 10
                    ScoreBox(score: scores[frame][2], frameIndex: frame, ballIndex: 2, scores: scores)
                        .frame(width: 50, height: 50)
                }
            }

            Text("Total: \(frameTotal)")
                .font(.footnote)
                .foregroundColor(.orange)
        }
        .frame(width: 140, height: 100) // Adjust width to accommodate 3 boxes in 10th frame
        .padding()
        .cornerRadius(5)
    }
}
// **Score Box for Each Ball in a Frame (Original Spare/Strike Calculation)**
struct ScoreBox: View {
    let score: Int?
    let frameIndex: Int
    let ballIndex: Int
    let scores: [[Int?]]

    var body: some View {
        Text(displayValue(for: score, frameIndex, ballIndex, scores))
            .frame(width: 50, height: 60) // Adjusted size
            .background(Color(UIColor.systemGray3)) // Dark frame color
            .foregroundColor(.white) // White text for dark mode
            .cornerRadius(5)
    }

    private func displayValue(for score: Int?, _ frameIndex: Int, _ ballIndex: Int, _ scores: [[Int?]]) -> String {
        guard let value = score else { return "" }

        // Special handling for the 10th frame
        if frameIndex == 9 {
            if value == 10 {
                return "X"  // Always display "X" for strikes in frame 10
            }
        } else {
            // Normal strike rule (only first ball displays "X")
            if value == 10 {
                return ballIndex == 0 ? "X" : ""
            }
        }

        // Spare handling
        if ballIndex == 1, let firstBall = scores[frameIndex][0], firstBall + value == 10 {
            return "/"
        }

        return String(value)
    }
}
