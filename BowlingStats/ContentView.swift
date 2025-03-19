import SwiftUI
import Charts

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Main Views
            TabView(selection: $selectedTab) {
                CasualView()
                    .tag(0)
                LeagueView()
                    .tag(1)
                StatsView()
                    .tag(2)
            }

            // Floating Tab Bar
            VStack {
                Spacer()
                
                HStack {
                    Spacer()

                    FloatingTabBar(selectedTab: $selectedTab)
                        .padding(.bottom, 10) // Adjust spacing from bottom edge
                    Spacer()
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // Prevent tab bar from moving when keyboard opens
    }
}

// Floating Tab Bar Component
struct FloatingTabBar: View {
    @Binding var selectedTab: Int

    // Function to determine color based on selected tab
    private var selectedColor: Color {
        switch selectedTab {
        case 0: return .blue  // Casual
        case 1: return .green // League
        case 2: return .red   // Stats
        default: return .gray.opacity(0.6)
        }
    }

    var body: some View {
        HStack(spacing: 80) { // Increased spacing for better balance
            TabBarItem(icon: "list.bullet", tag: 0, selectedTab: $selectedTab, highlightColor: selectedColor)
            TabBarItem(icon: "trophy", tag: 1, selectedTab: $selectedTab, highlightColor: selectedColor)
            TabBarItem(icon: "chart.bar", tag: 2, selectedTab: $selectedTab, highlightColor: selectedColor)
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity) // Full-width bar
        .background(
            BlurView(style: .systemUltraThinMaterialDark) // Frosted glass effect
                .clipShape(RoundedRectangle(cornerRadius: 25)) // Rounded edges
        )
        .padding(.horizontal, 5) // Adjust horizontal padding for better centering
    }
}

// Individual Tab Bar Button
struct TabBarItem: View {
    let icon: String
    let tag: Int
    @Binding var selectedTab: Int
    let highlightColor: Color // ✅ New property for dynamic color

    var body: some View {
        Button(action: {
            selectedTab = tag
        }) {
            Image(systemName: icon)
                .font(.system(size: selectedTab == tag ? 22 : 22, weight: .bold)) // Subtle size increase when active
                .foregroundColor(selectedTab == tag ? highlightColor : .gray.opacity(0.6)) // ✅ Uses dynamic highlight color
                .padding(12)
        }
    }
}

// Frosted Glass Blur Effect
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct CasualView: View {
    @AppStorage("savedGames") private var savedGamesData: Data = Data()
    @State private var savedGames: [BowlingGame] = []
    @State private var showingGameInput = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea(.all) // ✅ Ensures background fully extends to the bottom
                
                VStack {
                    // Top Bar
                    HStack {
                        Text("Casual")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)

                        Spacer()

                        // Filter Button
                        Menu {
                            Button("Most Recent", action: { sortGames(by: .mostRecent) })
                            Button("Least Recent", action: { sortGames(by: .leastRecent) })
                            Button("Highest Score", action: { sortGames(by: .highestScore) })
                            Button("Lowest Score", action: { sortGames(by: .lowestScore) })
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title3) // Smaller icon size
                                .padding(8)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color.blue.opacity(0.5), radius: 5)

                        // Refresh Button
                        Button(action: refreshGames) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3) // Smaller size
                                .padding(8)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color.blue.opacity(0.5), radius: 5)

                        // Add Game Button
                        Button(action: { showingGameInput = true }) {
                            Image(systemName: "plus")
                                .font(.title3) // Smaller size
                                .padding(8)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color.blue.opacity(0.5), radius: 5)
                    }
                    
                    .padding()
                    .background(
                        Color.teal.opacity(0.2)
                            .blur(radius: 10)
                    )
                    .padding()
                    ScrollView {
                        if savedGames.isEmpty {
                            VStack {
                                Text("No games yet")
                                    .font(.title2)
                                    .foregroundColor(.gray.opacity(0.8))
                                    .bold()
                                    .padding(.top, 250)

                                Text("Press the **+** button to add your first game!")
                                    .foregroundColor(.gray.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 30)
                            }
                            .frame(maxHeight: .infinity) // Centers message if no games exist
                            .transition(.opacity) // Smooth fade-in effect
                        } else {
                            VStack(spacing: 12) {
                                ForEach(savedGames) { game in
                                    NavigationLink(destination: GameDetailView(game: game)) {
                                        GlassyGameCard(game: game, deleteAction: { deleteGame(game) })
                                    }
                                    .buttonStyle(PlainButtonStyle()) // ✅ Removes button appearance
                                }
                            }
                            .padding()
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: savedGames.isEmpty) // Smooth animation when adding/removing games
                    Spacer().frame(height: 30) // ✅ Pushes content up to avoid being cut off
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingGameInput) {
                NavigationView {
                    GameInputView()
                }
            }
        }
        .onAppear {
            refreshGames()
            sortGames(by: .mostRecent)
        }
    }
    
    enum SortOption {
        case mostRecent, leastRecent, highestScore, lowestScore
    }

    /// **Move `sortGames` inside `CasualView`**
    private func sortGames(by option: SortOption) {
        withAnimation {
            switch option {
            case .mostRecent:
                savedGames.sort { $0.dateObject > $1.dateObject }
            case .leastRecent:
                savedGames.sort { $0.dateObject < $1.dateObject }
            case .highestScore:
                savedGames.sort { $0.totalScore > $1.totalScore }
            case .lowestScore:
                savedGames.sort { $0.totalScore < $1.totalScore }
            }
        }
    }
    /// Fetch saved games from storage
    private func refreshGames() {
        if let decoded = try? JSONDecoder().decode([BowlingGame].self, from: savedGamesData) {
            withAnimation {
                savedGames = decoded
                sortGames(by: .mostRecent) // ✅ Ensures sorting is reapplied after refresh
            }
        }
    }

    /// Function to delete a game
    private func deleteGame(_ game: BowlingGame) {
        withAnimation {
            savedGames.removeAll { $0.id == game.id }
        }

        if let encoded = try? JSONEncoder().encode(savedGames) {
            savedGamesData = encoded // ✅ Saves updated list
        }
    }
}



struct GlassyGameCard: View {
    let game: BowlingGame
    let deleteAction: () -> Void
    
    @State private var showDeleteAlert = false

    var body: some View {
        HStack {
            // Left Side: Date
            Text(game.date)
                .font(.headline)
                .bold()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Center: Arrow
            Text(game.location ?? "→") // Displays location if available
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .center)

            // Right Side: Score in Blue
            Text("\(game.totalScore)")
                .font(.title3)
                .bold()
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .shadow(color: Color.blue.opacity(0.2), radius: 5)
        .frame(maxWidth: .infinity)
        .onLongPressGesture {
            showDeleteAlert = true
        }
        .alert("Delete Game?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAction()
            }
        } message: {
            Text("Are you sure you want to delete this game?")
        }
    }
}

// Add Game View
struct AddGameView: View {
    @Binding var games: [String]
    @Environment(\.presentationMode) var presentationMode
    @State private var newGameDate = Date()
    @State private var showingGameInput = false

    var body: some View {
        NavigationStack { // ✅ Replaced NavigationView with NavigationStack
            VStack {
                DatePicker("Select Date", selection: $newGameDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding()

                Button("Save Game") {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .short
                    games.append(formatter.string(from: newGameDate))
                    showingGameInput = true
                }
                .navigationDestination(isPresented: $showingGameInput) {
                    GameInputView()
                }
            }
            .navigationTitle("Add New Game")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct LeagueView: View {
    @AppStorage("savedLeagues") private var leaguesData: Data = Data()
    @State private var leagues: [League] = []
    @State private var showingAddLeague = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack {
                    // **Top Bar**
                    HStack {
                        Text("Leagues")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)

                        Spacer()

                        // Refresh Button
                        Button(action: refreshLeagues) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                                .padding(8)
                                .background(Color.green)
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color.green.opacity(0.5), radius: 5)

                        // Add League Button
                        Button(action: { showingAddLeague = true }) {
                            Image(systemName: "plus")
                                .font(.title3)
                                .padding(8)
                                .background(Color.green)
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color.green.opacity(0.5), radius: 5)
                    }
                    .padding()
                    .background(Color.green.opacity(0.2).blur(radius: 10))
                    .padding()

                    // **Leagues List**
                    ScrollView {
                        if leagues.isEmpty {
                            VStack {
                                Text("No leagues yet")
                                    .font(.title2)
                                    .foregroundColor(.gray.opacity(0.8))
                                    .bold()
                                    .padding(.top, 250)

                                Text("Press the **+** button to create your first league!")
                                    .foregroundColor(.gray.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 30)
                            }
                            .frame(maxHeight: .infinity)
                            .transition(.opacity)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(leagues) { league in
                                    NavigationLink(destination: LeagueGamesView(leagueName: league.name)) {
                                        GlassyLeagueCard(league: league, deleteAction: { deleteLeague(league) })
                                    }
                                    .buttonStyle(PlainButtonStyle()) // Prevents unwanted button styling
                                }
                            }
                            .padding()
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: leagues.isEmpty)
                    Spacer().frame(height: 30)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddLeague) {
                AddLeagueView(leagues: $leagues)
            }
        }
        .onAppear {
            refreshLeagues()
        }
    }

    // **Function to Delete a League**
    private func deleteLeague(_ league: League) {
        withAnimation {
            leagues.removeAll { $0.id == league.id }
        }

        if let encoded = try? JSONEncoder().encode(leagues) {
            leaguesData = encoded // ✅ Saves updated list
        }
    }

    // **Refresh Leagues from Storage**
    private func refreshLeagues() {
        if let decoded = try? JSONDecoder().decode([League].self, from: leaguesData) {
            withAnimation {
                leagues = decoded.sorted { $0.dateAdded > $1.dateAdded }
            }
        }
    }
}

struct GlassyLeagueCard: View {
    let league: League
    let deleteAction: () -> Void
    
    @State private var showDeleteAlert = false

    var body: some View {
        HStack {
            // League Name (Left)
            Text(league.name)
                .font(.headline)
                .bold()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Emoji (Right)
            Text(league.emoji)
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .shadow(color: Color.green.opacity(0.2), radius: 5)
        .frame(maxWidth: .infinity)
        .onLongPressGesture {
            showDeleteAlert = true
        }
        .alert("Delete League?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAction()
            }
        } message: {
            Text("Are you sure you want to delete this league? All its games will also be removed.")
        }
    }
}

struct AddLeagueView: View {
    @Binding var leagues: [League]
    @Environment(\.presentationMode) var presentationMode

    @State private var newLeagueName = ""
    @State private var leagueEmoji = "🏆" // Default emoji
    @State private var showEmojiPicker = false

    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                // Title
                Text("Create New League")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top, 20)

                // League Name Input Field
                TextField("Enter League Name", text: $newLeagueName)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green.opacity(0.7), lineWidth: 1))
                    .padding(.horizontal)

                // Emoji Input Field
                TextField("Enter an Emoji", text: $leagueEmoji)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green.opacity(0.7), lineWidth: 1))
                    .padding(.horizontal)
                    .frame(width: 100) // Limit the width since only one emoji is needed

                // Save Button
                Button(action: saveLeague) {
                    Text("Save League")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .shadow(color: Color.green.opacity(0.5), radius: 5)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Add League")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }

    private func saveLeague() {
        guard !newLeagueName.isEmpty else { return }

        let newLeague = League(name: newLeagueName, emoji: leagueEmoji, dateAdded: Date())
        leagues.append(newLeague)

        if let encoded = try? JSONEncoder().encode(leagues) {
            UserDefaults.standard.set(encoded, forKey: "savedLeagues")
        }

        presentationMode.wrappedValue.dismiss()
    }
}

struct LeagueGamesView: View {
    var leagueName: String
    @AppStorage("leagueGames") private var leagueGamesData: Data = Data()
    @State private var games: [BowlingGame] = []
    @State private var showingGameInput = false
    @State private var gameToDelete: BowlingGame? = nil
    @State private var showingDeleteAlert = false
    
    // Stats Variables
    @State private var averageScore: Int = 0
    @State private var avgStrikesPerGame: Double = 0.0
    @State private var avgSparesPerGame: Double = 0.0
    @State private var highScore: Int = 0
    @State private var totalGames: Int = 0
    @State private var totalStrikes: Int = 0
    @State private var totalSpares: Int = 0
    
    @Environment(\.presentationMode) var presentationMode // ✅ Manages custom back button
    
    // Sorting
    enum SortOption {
        case mostRecent, leastRecent, highestScore, lowestScore
    }
    @State private var selectedSortOption: SortOption = .mostRecent
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack {
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss() // ✅ Go back to LeagueView
                        }) {
                            HStack {
                                Image(systemName: "chevron.left") // Back Arrow Icon
                                    .font(.title3)
                                Text("Back")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                        }
                        Spacer() // ✅ Pushes everything else to the right
                    }
                    .padding(.leading) // ✅ Ensures spacing from left edge
                    HStack {
                        Text(leagueName)
                            .bold()
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Filter Button
                        Menu {
                            Button("Most Recent", action: { sortGames(by: .mostRecent) })
                            Button("Least Recent", action: { sortGames(by: .leastRecent) })
                            Button("Highest Score", action: { sortGames(by: .highestScore) })
                            Button("Lowest Score", action: { sortGames(by: .lowestScore) })
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title3)
                                .padding(8)
                                .background(Color.green)
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color.green.opacity(0.5), radius: 5)
                        
                        // Refresh Button
                        Button(action: refreshGames) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                                .padding(8)
                                .background(Color.green)
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color.green.opacity(0.5), radius: 5)
                        
                        // Add Game Button
                        Button(action: { showingGameInput = true }) {
                            Image(systemName: "plus")
                                .font(.title3)
                                .padding(8)
                                .background(Color.green)
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color.green.opacity(0.5), radius: 5)
                    }
                    .padding()
                    .background(Color.green.opacity(0.2).blur(radius: 10))
                    
                    HStack {
                        StatBox(title: "Avg Score", value: "\(averageScore)")
                        StatBox(title: "Avg Strikes", value: String(format: "%.2f", avgStrikesPerGame))
                        StatBox(title: "Avg Spares", value: String(format: "%.2f", avgSparesPerGame))
                        StatBox(title: "High Score", value: "\(highScore)")
                    }
                    .padding()
                    // **Games List**
                    ScrollView {
                        if games.isEmpty {
                            VStack {
                                Text("No games yet")
                                    .font(.title2)
                                    .foregroundColor(.gray.opacity(0.8))
                                    .bold()
                                    .padding(.top, 250)
                                
                                Text("Press the **+** button to add your first game!")
                                    .foregroundColor(.gray.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 30)
                            }
                            .frame(maxHeight: .infinity)
                            .transition(.opacity)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(games) { game in
                                    NavigationLink(destination: GameDetailView(game: game)) {
                                        GlassyGameCardLeagueGame(game: game, deleteAction: { deleteGame(game) })
                                    }
                                    .buttonStyle(PlainButtonStyle()) // ✅ Removes button appearance
                                }
                            }
                            .padding()
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: games.isEmpty)
                    Spacer().frame(height: 30) // ✅ Pushes content up to avoid being cut off
                }
            }
        }
        .sheet(isPresented: $showingGameInput) {
            NavigationView {
                GameInputView(leagueName: leagueName)
            }
        }
        .onAppear {
            refreshGames()
            sortGames(by: .mostRecent)
            computeStats()
        }
        .navigationBarHidden(true)

    }
    
    private func computeStats() {
        guard !games.isEmpty else {
            // Reset stats when no games exist
            averageScore = 0
            avgStrikesPerGame = 0.0
            avgSparesPerGame = 0.0
            highScore = 0
            return
        }
        
        totalGames = games.count
        let totalScores = games.map { $0.totalScore }.reduce(0, +)
        highScore = games.map { $0.totalScore }.max() ?? 0
        
        let allFrames = games.flatMap { $0.scores }
        
        // Count total strikes
        totalStrikes = allFrames.flatMap { $0 }.filter { $0 == 10 }.count
        
        // Count total spares
        let spares = allFrames.filter { frame in
            frame.count > 1 && (frame[0] ?? 0) + (frame[1] ?? 0) == 10 && (frame[0] ?? 0) != 10
        }
        totalSpares = spares.count
        
        // Calculate averages
        averageScore = totalScores / totalGames
        avgStrikesPerGame = Double(totalStrikes) / Double(totalGames)
        avgSparesPerGame = Double(totalSpares) / Double(totalGames)
    }
    
    // **Sorting Function**
    private func sortGames(by option: SortOption) {
        withAnimation {
            switch option {
            case .mostRecent:
                games.sort { $0.dateObject > $1.dateObject }
            case .leastRecent:
                games.sort { $0.dateObject < $1.dateObject }
            case .highestScore:
                games.sort { $0.totalScore > $1.totalScore }
            case .lowestScore:
                games.sort { $0.totalScore < $1.totalScore }
            }
            computeStats() // ✅ Ensures stats update after sorting
        }
    }
    
    // **Fetch saved games for this league**
    private func refreshGames() {
        if let decoded = try? JSONDecoder().decode([String: [BowlingGame]].self, from: leagueGamesData),
           let leagueSpecificGames = decoded[leagueName] {
            withAnimation {
                games = leagueSpecificGames
                sortGames(by: selectedSortOption)
                computeStats() // ✅ Ensures stats update when games refresh
            }
        }
    }
    
    // **Delete a game from the league**
    private func deleteGame(_ game: BowlingGame) {
        var allLeagueGames = (try? JSONDecoder().decode([String: [BowlingGame]].self, from: leagueGamesData)) ?? [:]
        allLeagueGames[leagueName]?.removeAll { $0.id == game.id }
        
        if let encoded = try? JSONEncoder().encode(allLeagueGames) {
            leagueGamesData = encoded
        }
        
        refreshGames()
        computeStats() // ✅ Ensures stats update after deleting a game
    }
}

// **Glassy Game Card for League Games**
struct GlassyGameCardLeagueGame: View {
    let game: BowlingGame
    let deleteAction: () -> Void
    
    @State private var showDeleteAlert = false

    var body: some View {
        HStack {
            // Left Side: Date
            Text(game.date)
                .font(.headline)
                .bold()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Center: Arrow
            Text(game.location ?? "→") // Displays location if available
                .font(.subheadline)
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, alignment: .center)

            // Right Side: Score in Green
            Text("\(game.totalScore)")
                .font(.title3)
                .bold()
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .shadow(color: Color.green.opacity(0.2), radius: 5)
        .frame(maxWidth: .infinity)
        .onLongPressGesture {
            showDeleteAlert = true
        }
        .alert("Delete Game?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAction()
            }
        } message: {
            Text("Are you sure you want to delete this game?")
        }
    }
}

// **Stat Box for League Games**
struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.headline)
                .bold()
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

struct StatsView: View {
    @State private var selectedMode: String = "Overall" // Overall, Casual, League
    @State private var selectedLeague: String = "" // Selected league for filtering
    @State private var availableLeagues: [String] = [] // List of saved leagues
    
    @AppStorage("savedGames") private var savedGamesData: Data = Data() // Casual games
    @AppStorage("leagueGames") private var leagueGamesData: Data = Data() // League games

    @State private var allGames: [BowlingGame] = []
    @State private var filteredGames: [BowlingGame] = []

    @State private var totalGames = 0
    @State private var averageScore = 0
    @State private var highScore = 0
    @State private var totalStrikes = 0
    @State private var totalSpares = 0
    @State private var avgStrikesPerGame = 0.0
    @State private var avgSparesPerGame = 0.0

    @State private var monthlyScores: [MonthlyScore] = []

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    // **Title**
                    HStack {
                        Text("Statistics")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .background(Color.red.opacity(0.2).blur(radius: 10))
                    .padding()

                    List {
                        // **Game Stats Section**
                        Section() {
                            Picker("Select Mode", selection: $selectedMode) {
                                Text("Overall").tag("Overall")
                                Text("Casual").tag("Casual")
                                Text("League").tag("League")
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: selectedMode) {
                                filterGames()
                            }
                            .foregroundColor(.red)

                            if selectedMode == "League" {
                                Picker("Select League", selection: $selectedLeague) {
                                    ForEach(availableLeagues, id: \.self) { league in
                                        Text(league)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .onChange(of: selectedLeague) {
                                    filterGames()
                                }
                                .foregroundColor(.red)
                            }

                            // **Monthly Average Score Chart**
                            Chart(monthlyScores) { score in
                                BarMark(
                                    x: .value("Month", score.month),
                                    y: .value("Avg Score", score.averageScore)
                                )
                                .foregroundStyle(.red)
                            }
                            .frame(height: 200)
                            .padding(.top, 10)
                            .background(Color.black) // ✅ Ensures black background

                            StatRow(title: "Total Games", value: "\(totalGames)", color: .red)
                            StatRow(title: "Average Score", value: "\(averageScore)", color: .red)
                            StatRow(title: "Highest Score", value: "\(highScore)", color: .red)
                        }
                        .listRowBackground(Color.black)
                        .listRowBackground(Color.black.opacity(0.2))

                        // **Performance Stats Section**
                        Section(header: Text("PERFORMANCE STATS").foregroundColor(.red)) {
                            StatRow(title: "Total Strikes", value: "\(totalStrikes)", color: .red)
                            StatRow(title: "Total Spares", value: "\(totalSpares)", color: .red)
                            StatRow(title: "Avg Strikes per Game", value: String(format: "%.2f", avgStrikesPerGame), color: .red)
                            StatRow(title: "Avg Spares per Game", value: String(format: "%.2f", avgSparesPerGame), color: .red)
                        }
                        .listRowBackground(Color.black) // ✅ Ensures consistency
                        .listRowBackground(Color.black.opacity(0.2))
                    }
                    .scrollContentBackground(.hidden) // ✅ Hides default background
                    .background(Color.black) // ✅ Ensures black background
                    .listStyle(PlainListStyle()) // ✅ Keeps the sleek grouped list look
                    Spacer().frame(height: 30) // ✅ Pushes content up to avoid being cut off

                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadAllGames()
            }
        }
    }
    // MARK: - Load Games from Storage
    private func loadAllGames() {
        var games: [BowlingGame] = []

        // Load Casual Games
        if let decodedCasual = try? JSONDecoder().decode([BowlingGame].self, from: savedGamesData) {
            games.append(contentsOf: decodedCasual)
        }

        // Load League Games (Fix)
        let decodedLeagues = (try? JSONDecoder().decode([String: [BowlingGame]].self, from: leagueGamesData)) ?? [:]
        for (league, leagueGames) in decodedLeagues {
            for var game in leagueGames {
                game.isLeagueGame = true
                game.leagueName = league
                games.append(game)
            }
        }

        allGames = games
        extractLeagues(from: decodedLeagues) // ✅ Ensure decodedLeagues exists
        filterGames()
    }

    // MARK: - Extract Available Leagues
    private func extractLeagues(from leaguesData: [String: [BowlingGame]]) {
        availableLeagues = Array(leaguesData.keys)
        if selectedLeague.isEmpty, let firstLeague = availableLeagues.first {
            selectedLeague = firstLeague
        }
    }

    // MARK: - Filter Games Based on Selection
    private func filterGames() {
        switch selectedMode {
        case "Casual":
            filteredGames = allGames.filter { !$0.isLeagueGame } // Only casual games
        case "League":
            filteredGames = allGames.filter { $0.leagueName == selectedLeague }
        default:
            filteredGames = allGames
        }
        computeStats()
    }

    // MARK: - Compute Statistics
    private func computeStats() {
        guard !filteredGames.isEmpty else {
            totalGames = 0
            averageScore = 0
            highScore = 0
            totalStrikes = 0
            totalSpares = 0
            avgStrikesPerGame = 0
            avgSparesPerGame = 0
            monthlyScores = []
            return
        }

        totalGames = filteredGames.count
        let totalScores = filteredGames.map { $0.totalScore }.reduce(0, +)
        highScore = filteredGames.map { $0.totalScore }.max() ?? 0

        let allFrames = filteredGames.flatMap { $0.scores }
        totalStrikes = allFrames.flatMap { $0 }.filter { $0 == 10 }.count

        let spares = allFrames.filter { frame in
            frame.count > 1 && (frame[0] ?? 0) + (frame[1] ?? 0) == 10 && (frame[0] ?? 0) != 10
        }

        totalSpares = spares.count

        averageScore = totalScores / totalGames
        avgStrikesPerGame = Double(totalStrikes) / Double(totalGames)
        avgSparesPerGame = Double(totalSpares) / Double(totalGames) // Corrected spare calculation

        computeMonthlyAverages()
    }

    // MARK: - Compute Monthly Averages
    private func computeMonthlyAverages() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"

        var monthlyTotals: [String: (total: Int, count: Int)] = [:]

        for game in filteredGames {
            let month = dateFormatter.string(from: game.dateObject)
            if var existing = monthlyTotals[month] {
                existing.total += game.totalScore
                existing.count += 1
                monthlyTotals[month] = existing
            } else {
                monthlyTotals[month] = (game.totalScore, 1)
            }
        }

        monthlyScores = monthlyTotals.map { key, value in
            MonthlyScore(month: key, averageScore: value.total / value.count)
        }.sorted { $0.month < $1.month }
    }
}

// MARK: - Struct for Monthly Data
struct MonthlyScore: Identifiable {
    var id = UUID()
    var month: String
    var averageScore: Int
}

// MARK: - Helper Extension for Date Conversion
extension BowlingGame {
    var dateObject: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy"
        return formatter.date(from: self.date) ?? Date()
    }
}

// MARK: - Reusable Stat Row
struct StatRow: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}
