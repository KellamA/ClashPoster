import SwiftUI
import Foundation
import AVFoundation

// Shared warm white color used across the UI
let warmWhite: Color = Color(red: 1.0, green: 0.96, blue: 0.85)

// Lightweight click sound player (no background music)
struct SoundPlayer {
    static var clickID: SystemSoundID = 1105 // softer tap
    static func playClick() {
        AudioServicesPlaySystemSound(clickID)
    }
}

// Immutable identity + per-round/player state
struct Player: Identifiable {
    let id = UUID()
    let index: Int
    var isImposter: Bool = false
    var hasSeenRole: Bool = false
    var name: String
    var wins: Int = 0
}

// Central game engine that drives all state (observable by views)
class ClashImposterEngine: ObservableObject {
    // MARK: Persisted game state
    @Published var players: [Player] = []
    @Published var secretCard: String = ""
    @Published var gameState: GameMode = .setup
    @Published var recentWinners: [Player] = []
    @Published var firstPlayerID: UUID? = nil
    // MARK: Persistence keys
    static let savedNamesKey = "savedPlayerNames"
    static let hintsEnabledKey = "hintsEnabled"
    // Hints setting (persisted)
    @Published var hintsEnabled: Bool = UserDefaults.standard.bool(forKey: ClashImposterEngine.hintsEnabledKey) {
        didSet { UserDefaults.standard.set(hintsEnabled, forKey: ClashImposterEngine.hintsEnabledKey) }
    }
    
    func hint(for card: String) -> String? { CardDatabase.hint(for: card) }
    
    // Randomly pick a secret card; fallback ensures a valid default
    private func randomSecretCard() -> String {
        CardDatabase.names.randomElement() ?? "P.E.K.K.A"
    }
    
    // All possible screens/modes of the game
    enum GameMode {
        case setup, nameEntry, distribution, discussion, celebration
    }
    
    // Start a new game with playerCount players.
    func startGame(playerCount: Int) {
        let imposterIndex = Int.random(in: 0..<playerCount)
        secretCard = randomSecretCard()
        
        // Reuse existing names/wins if counts match; else initialize fresh players
        let existing = players
        if existing.count == playerCount {
            players = (0..<playerCount).map { i in
                let old = existing[i]
                return Player(index: i + 1, isImposter: i == imposterIndex, hasSeenRole: false, name: old.name, wins: old.wins)
            }
        } else {
            players = (0..<playerCount).map { i in
                Player(index: i + 1, isImposter: i == imposterIndex, hasSeenRole: false, name: "Player \(i + 1)", wins: 0)
            }
        }
        
        // Prefill from UserDefaults when available
        if let saved = UserDefaults.standard.array(forKey: ClashImposterEngine.savedNamesKey) as? [String] {
            let count = min(players.count, saved.count)
            for i in 0..<count {
                let trimmed = saved[i].trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    players[i].name = trimmed
                }
            }
        }
        // Move to name entry screen and reset first player ID
        gameState = .nameEntry
        firstPlayerID = nil
    }
    
    // Return to setup and clear players (keeps settings like hints)
    func reset() {
        gameState = .setup
        players = []
    }
    
    // Keep names and wins; reassign roles and secret card for the next round
    func prepareNextRound() {
        // If we have players, keep their names and wins, reassign roles and reset per-round flags
        guard !players.isEmpty else { gameState = .setup; return }
        let playerCount = players.count
        let imposterIndex = Int.random(in: 0..<playerCount)
        secretCard = randomSecretCard()
        for i in 0..<playerCount {
            players[i].isImposter = (i == imposterIndex)
            players[i].hasSeenRole = false
        }
        gameState = .distribution
        firstPlayerID = players.randomElement()?.id
    }
    
    // Reset wins but keep players
    func resetWins() {
        for i in players.indices { players[i].wins = 0 }
    }
}

// --- 2. MAIN VIEW ---
// Hosts the entire app UI with a TabView (Game + Settings)
struct ContentView: View {
    @StateObject private var engine = ClashImposterEngine()
    @State private var playerCount = 4
    @State private var showRevealScreen = false
    
    let clashGold = Color(red: 1.0, green: 0.8, blue: 0.2)
    
    var body: some View {
        TabView {
            // GAME TAB
            NavigationView {
                ZStack {
                    // Rich dark gradient background
                    LinearGradient(gradient: Gradient(colors: [
                        Color(red: 0.02, green: 0.08, blue: 0.25),
                        Color(red: 0.00, green: 0.02, blue: 0.12)
                    ]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                    // Screen router based on engine.gameState
                    VStack {
                        if engine.gameState == .setup {
                            setupView
                        } else if engine.gameState == .nameEntry {
                            nameEntryView
                        } else if engine.gameState == .distribution {
                            distributionView
                        } else if engine.gameState == .discussion {
                            discussionView
                        } else if engine.gameState == .celebration {
                            celebrationView
                        }
                    }
                    .padding()
                }
                .navigationBarHidden(true)
            }
            .tabItem { Label("Game", systemImage: "gamecontroller") }

            AppSettingsView()
                .environmentObject(engine)
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .preferredColorScheme(.dark)
        .overlay(revealView) // Global overlay used to present the imposter reveal modal
    }
    
    // --- DESIGNED SETUP SCREEN ---
    var setupView: some View {
            VStack(spacing: 40) {
                // Title
                HStack(spacing: 0) {
                    Text("CLASH")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(clashGold)
                    
                    Text("POSTER")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(warmWhite)
                        .shadow(color: clashGold.opacity(0.5), radius: 10, x: 0, y: 0)
                }
                .padding(.top, 40)
                
            // Decorative emblem
            ZStack {
                Circle()
                    .fill(clashGold.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 70))
                    .foregroundColor(clashGold)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
            }

            // Player count control
            VStack(spacing: 15) {
                Text("CHOOSE CLAN SIZE")
                    .font(.caption).fontWeight(.bold).foregroundColor(.white.opacity(0.6))
                
                HStack(spacing: 30) {
                    Button(action: { if playerCount > 3 { playerCount -= 1 } }) {
                        Image(systemName: "minus.circle.fill").font(.largeTitle).foregroundColor(clashGold)
                    }
                    
                    Text("\(playerCount)")
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .frame(width: 70)
                    
                    Button(action: { if playerCount < 12 { playerCount += 1 } }) {
                        Image(systemName: "plus.circle.fill").font(.largeTitle).foregroundColor(clashGold)
                    }
                }
            }
            .padding(.vertical, 30).padding(.horizontal, 40)
            .background(RoundedRectangle(cornerRadius: 30).fill(Color.white.opacity(0.05)))
            
            Spacer()

            // Start button -> enters name entry (persisted names auto-fill)
            Button(action: {
                SoundPlayer.playClick()
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                engine.startGame(playerCount: playerCount)
            }) {
                Text("ENTER ARENA")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                    .overlay(
                        // Faux outline effect to make the text pop
                        Text("ENTER ARENA")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(.clear)
                            .shadow(color: .black, radius: 0, x: 0, y: 1)
                            .shadow(color: .black, radius: 0, x: 0, y: -1)
                            .shadow(color: .black, radius: 0, x: 1, y: 0)
                            .shadow(color: .black, radius: 0, x: -1, y: 0)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(LinearGradient(gradient: Gradient(colors: [clashGold, Color(red: 0.8, green: 0.6, blue: 0.1)]), startPoint: .top, endPoint: .bottom))
                    .cornerRadius(20)
                    .shadow(color: clashGold.opacity(0.4), radius: 15, x: 0, y: 8)
            }
            .padding(.horizontal, 40).padding(.bottom, 30)
        }
    }
    
    // --- NAME ENTRY VIEW ---
    var nameEntryView: some View {
        VStack(spacing: 20) {
            Text("ENTER PLAYER NAMES")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(clashGold)
                .padding(.top, 8)

            // Editable rows of names
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(engine.players.indices, id: \.self) { index in
                        HStack(spacing: 12) {
                            Text("\(index + 1).")
                                .font(.subheadline).bold()
                                .foregroundColor(clashGold)
                                .frame(width: 24, alignment: .trailing)

                            TextField("Player \((index + 1))", text: $engine.players[index].name)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }

            Spacer()

            // Reset names to defaults and clear persisted storage
            Button("Reset to Defaults", role: .destructive) {
                SoundPlayer.playClick()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                // Clear persisted names and reset current fields to defaults
                UserDefaults.standard.removeObject(forKey: ClashImposterEngine.savedNamesKey)
                for i in engine.players.indices {
                    engine.players[i].name = "Player \(i + 1)"
                }
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .padding(.horizontal, 40)
            .padding(.bottom, 6)

            // Continue -> sanitize names, persist to UserDefaults, and move to distribution
            Button(action: {
                SoundPlayer.playClick()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                // Sanitize names: trim whitespace and restore defaults if empty
                for i in engine.players.indices {
                    let trimmed = engine.players[i].name.trimmingCharacters(in: .whitespacesAndNewlines)
                    engine.players[i].name = trimmed.isEmpty ? "Player \(i + 1)" : trimmed
                }
                let namesToSave = engine.players.map { $0.name }
                UserDefaults.standard.set(namesToSave, forKey: ClashImposterEngine.savedNamesKey)
                engine.gameState = .distribution
                engine.firstPlayerID = engine.players.randomElement()?.id
            }) {
                Text("CONTINUE")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                    .overlay(
                        // Faux outline for legibility
                        Text("CONTINUE")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.clear)
                            .shadow(color: .black, radius: 0, x: 0, y: 1)
                            .shadow(color: .black, radius: 0, x: 0, y: -1)
                            .shadow(color: .black, radius: 0, x: 1, y: 0)
                            .shadow(color: .black, radius: 0, x: -1, y: 0)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient(gradient: Gradient(colors: [clashGold, Color(red: 0.8, green: 0.6, blue: 0.1)]), startPoint: .top, endPoint: .bottom))
                    .cornerRadius(16)
                    .shadow(color: clashGold.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 10)
        }
    }
    
    // --- 2-COLUMN DISTRIBUTION VIEW ---
    var distributionView: some View {
        VStack {
            Text("PASS THE PHONE")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(clashGold)
                .padding(.top)
            
            // Grid of flip cards
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(engine.players.indices, id: \.self) { index in
                        CardFlipView(player: $engine.players[index], secretCard: engine.secretCard, clashGold: clashGold, timedFlipEnabled: true) // Auto flip-back + lock after 5s
                            .frame(width: 140, height: 185)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .environmentObject(engine)
            }
            
            // Continue only when everyone has seen their role
            if engine.players.allSatisfy({ $0.hasSeenRole }) {
                Button(action: {
                    SoundPlayer.playClick()
                    engine.gameState = .discussion
                }) {
                    Text("BEGIN BATTLE")
                        .font(.headline).bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
        }
    }

    var discussionView: some View {
        VStack(spacing: 40) {
            Text("WHO IS THE IMPOSTER?").font(.title).bold().foregroundColor(clashGold)
            
            Image(systemName: "magnifyingglass").font(.system(size: 80)).foregroundColor(clashGold)
            
            // Randomly selected first speaker (set earlier)
            if let firstID = engine.firstPlayerID, let first = engine.players.first(where: { $0.id == firstID }) {
                Text("First to speak: \(first.name)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)))
            }

            Text("The Imposter is trying to blend in.\nDescribe the card, find the traitor!")
                .foregroundColor(warmWhite)
                .multilineTextAlignment(.center).padding().background(Color.white.opacity(0.1)).cornerRadius(15)
            
            Spacer()
            
            // Show reveal overlay
            Button("REVEAL IMPOSTER") {
                SoundPlayer.playClick()
                showRevealScreen = true
            }
            .buttonStyle(.borderedProminent).tint(clashGold).foregroundColor(.black)
            
            Button("New Game") {
                SoundPlayer.playClick()
                engine.reset()
            }.tint(.red)
        }
    }
    
    var celebrationView: some View {
        ZStack {
            // Gradient + soft circles for atmosphere
            LinearGradient(gradient: Gradient(colors: [
                Color(red: 0.02, green: 0.08, blue: 0.25),
                Color(red: 0.00, green: 0.02, blue: 0.12)
            ]), startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            .overlay(
                ZStack {
                    Circle().fill(clashGold.opacity(0.15)).frame(width: 220, height: 220).blur(radius: 40).offset(x: -120, y: -180)
                    Circle().fill(Color.white.opacity(0.06)).frame(width: 260, height: 260).blur(radius: 50).offset(x: 140, y: 160)
                }
            )
            VStack(spacing: 24) {
                Text("🏆").font(.system(size: 54))
                if engine.recentWinners.count == 1 {
                    Text("\(engine.recentWinners.first!.name) Won!")
                        .font(.largeTitle).bold().foregroundColor(clashGold)
                } else {
                    VStack(spacing: 8) {
                        Text("Winners!").font(.title).bold().foregroundColor(clashGold)
                        ForEach(engine.recentWinners, id: \.id) { p in
                            Text(p.name).font(.title3).foregroundColor(warmWhite)
                        }
                    }
                }
                HStack(spacing: 16) {
                    // Same players, new roles
                    Button {
                        SoundPlayer.playClick()
                        // Play again: same players, new roles
                        engine.prepareNextRound()
                    } label: {
                        Text("Play Again").bold().padding(.vertical, 14).padding(.horizontal, 22)
                    }
                    .background(RoundedRectangle(cornerRadius: 14).fill(clashGold))
                    .foregroundColor(.black)

                    // Back to setup and clear wins
                    Button {
                        SoundPlayer.playClick()
                        // Edit players: go to setup and reset wins
                        engine.resetWins()
                        engine.reset()
                    } label: {
                        Text("Edit Players").bold().padding(.vertical, 14).padding(.horizontal, 22)
                    }
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.15)))
                    .foregroundColor(.white)
                }
            }
            .padding()
        }
    }
    

    // --- IMPOSTER REVEAL OVERLAY ---
    // Modal overlay showing the imposter and hint (if enabled)
    private var revealView: some View {
        Group {
            if showRevealScreen {
                ZStack {
                    Color.black.opacity(0.93).ignoresSafeArea()
                    VStack(spacing: 28) {
                        Text("IMPOSTER REVEAL")
                            .font(.largeTitle).bold().foregroundColor(clashGold)
                        // Find the imposter to display
                        let imposter = engine.players.first(where: { $0.isImposter })
                        if let imposter {
                            VStack(spacing: 10) {
                                Text("🏆 \(imposter.wins)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(clashGold)
                                Text(imposter.name).font(.title3).foregroundColor(.red).bold()
                                Image("Imposter Card").resizable().scaledToFit().frame(height: 90).shadow(radius: 8)
                                if engine.hintsEnabled, let hint = engine.hint(for: engine.secretCard) {
                                    Text("HINT: \(hint.uppercased())")
                                        .font(.caption).bold()
                                        .foregroundColor(.white)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 10)
                                        .background(Capsule().fill(Color.black.opacity(0.6)))
                                }
                                Text("IMPOSTER").font(.headline).foregroundColor(.white)
                            }.padding().background(RoundedRectangle(cornerRadius: 18).fill(Color.red.opacity(0.25)))
                        }
                        // Show other players' card art for context
                        Text("Other Players' Cards:").font(.headline).foregroundColor(.white)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 18) {
                                ForEach(engine.players.filter { !$0.isImposter }, id: \.id) { player in
                                    VStack(spacing: 7) {
                                        Text("🏆 \(player.wins)")
                                            .font(.caption2).bold()
                                            .foregroundColor(clashGold)
                                        Image(engine.secretCard).resizable().scaledToFit().frame(height: 70).cornerRadius(8)
                                        Text(player.name).font(.subheadline).foregroundColor(.gray)
                                    }.padding(8).background(RoundedRectangle(cornerRadius: 13).fill(Color.white.opacity(0.13)))
                                }
                            }
                        }.padding(.horizontal)
                        
                        // Tally winners and navigate to celebration
                        Text("Did the Imposter win?").font(.headline).foregroundColor(.white)
                        HStack(spacing: 12) {
                            Button {
                                SoundPlayer.playClick()
                                // Imposter won: add 1 win to imposter, set recent winners and go to celebration
                                if let impIndex = engine.players.firstIndex(where: { $0.isImposter }) {
                                    engine.players[impIndex].wins += 1
                                    engine.recentWinners = [engine.players[impIndex]]
                                } else {
                                    engine.recentWinners = []
                                }
                                showRevealScreen = false
                                engine.gameState = .celebration
                            } label: {
                                Text("Imposter Won").bold().padding(.vertical, 12).padding(.horizontal, 16)
                            }
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.red))
                            .foregroundColor(.white)

                            Button {
                                SoundPlayer.playClick()
                                // Crew won: add 1 win to everyone except imposter, set recent winners and go to celebration
                                var winners: [Player] = []
                                for i in engine.players.indices {
                                    if !engine.players[i].isImposter {
                                        engine.players[i].wins += 1
                                        winners.append(engine.players[i])
                                    }
                                }
                                engine.recentWinners = winners
                                showRevealScreen = false
                                engine.gameState = .celebration
                            } label: {
                                Text("Crew Won").bold().padding(.vertical, 12).padding(.horizontal, 16)
                            }
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.green))
                            .foregroundColor(.white)
                        }
                    }
                    .padding(36)
                }
                .transition(.opacity)
                .zIndex(10) // Ensure overlay sits above everything
            }
        }
    }
}

// --- 3. THE 3D CARD FLIP COMPONENT ---
// Handles flip animation, timed auto-hide, and lockout per player card
struct CardFlipView: View {
    // MARK: Bindings & Inputs
    @Binding var player: Player
    var secretCard: String
    var clashGold: Color
    let timedFlipEnabled: Bool
    
    @EnvironmentObject private var engine: ClashImposterEngine
    
    // MARK: Flip state
    @State private var degree: Double = 0
    @State private var isFlipped: Bool = false
    @State private var isLocked: Bool = false
    @State private var flipTimer: Timer? // Added timer state
    @State private var remainingProgress: CGFloat = 0 // Progress for visual timer (1 -> 0)
    
    var body: some View {
        ZStack {
            // BACK FACE (default)
            CardFace(color: Color(red: 0.1, green: 0.2, blue: 0.4), border: clashGold) {
                VStack(spacing: 8) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 35))
                        .foregroundColor(clashGold)
                    Text("🏆 \(player.wins)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(clashGold)
                    Text(player.name.uppercased())
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(warmWhite)
                }
            }
            .opacity(isFlipped ? 0 : 1)
            
            // FRONT FACE (shows secret or imposter card)
            CardFace(color: .white, border: .red) {
                ZStack(alignment: .bottom) {
                    if player.isImposter {
                        VStack(spacing: 0) {
                            HStack {
                                Text("🏆 \(player.wins)")
                                    .font(.caption2).bold()
                                    .foregroundColor(clashGold)
                                Spacer()
                            }
                            .padding(.top, 6)
                            .padding(.leading, 6)
                            Spacer(minLength: 0)
                            Image("Imposter Card")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 108)
                                .cornerRadius(5)
                            // Imposter-only hint (if enabled)
                            if engine.hintsEnabled, let hint = engine.hint(for: secretCard) {
                                Text("HINT: \(hint.uppercased())")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 12)
                                    .background(Capsule().fill(Color.black.opacity(0.6)))
                                    .padding(.top, 6)
                            }
                            Spacer(minLength: 0)
                            Text("IMPOSTER")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 18)
                                .background(
                                    Capsule()
                                        .fill(Color.red)
                                        .shadow(color: Color.red.opacity(0.3), radius: 7, x: 0, y: 2)
                                )
                                .padding(.bottom, 8)
                        }
                    }
                    else {
                        VStack(spacing: 0) {
                            HStack {
                                Text("🏆 \(player.wins)")
                                    .font(.caption2).bold()
                                    .foregroundColor(clashGold)
                                Spacer()
                            }
                            .padding(.top, 6)
                            .padding(.leading, 6)
                            Spacer(minLength: 0)
                            Image(secretCard)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 110)
                                .cornerRadius(5)
                            // Crew front: shows the secret card art + label
                            Spacer(minLength: 0)
                            Text(secretCard.uppercased())
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 18)
                                .background(
                                    Capsule()
                                        .fill(clashGold)
                                        .shadow(color: clashGold.opacity(0.3), radius: 7, x: 0, y: 2)
                                )
                                .padding(.bottom, 8)
                        }
                    }
                }
            }
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            
            // Lock overlay prevents re-flipping after viewing
            if isLocked {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.85))
                    .overlay(
                        VStack(spacing: 5) {
                            Image(systemName: "lock.fill").font(.title3).foregroundColor(.gray)
                            Text("LOCKED").font(.caption2).bold().foregroundColor(.gray)
                        }
                    )
            }
        }
        .aspectRatio(0.75, contentMode: .fit)
        .rotation3DEffect(.degrees(degree), axis: (x: 0, y: 1, z: 0))
        .onTapGesture { flipCard() }
        .disabled(isLocked)
        .overlay(alignment: .topTrailing) {
            // Animated 5s ring shown while front is visible
            if timedFlipEnabled && isFlipped && !isLocked {
                TinyTimerRing(progress: remainingProgress, color: clashGold)
                    .padding(8)
            }
        }
        .onDisappear {
            // Ensure timers and animations are stopped when view leaves screen
            withAnimation(nil) { remainingProgress = 0 }
            flipTimer?.invalidate()
            flipTimer = nil
        }
    }
    
    // --- Updated flipCard to support timed flip and locking ---
    // First tap flips to front; after 5s auto-flips back and locks. Manual flip-back also locks.
    func flipCard() {
        SoundPlayer.playClick()
        if !isFlipped {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                degree += 180
                isFlipped = true
                player.hasSeenRole = true
            }
            // Start timer if timedFlipEnabled is true
            if timedFlipEnabled {
                flipTimer?.invalidate()
                withAnimation(nil) { remainingProgress = 1.0 }
                withAnimation(.linear(duration: 5)) { remainingProgress = 0.0 }
                flipTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                    withAnimation(nil) { remainingProgress = 0 }
                    if isFlipped && !isLocked {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        // Auto flip back
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            degree += 180
                            isFlipped = false
                        }
                        // Lock shortly after the flip finishes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            isLocked = true
                        }
                    }
                    flipTimer?.invalidate()
                    flipTimer = nil
                }
            }
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            // Manual flip back (user taps again) -> then lock
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                degree += 180
                isFlipped = false
            }
            // Invalidate timer if flipping back manually
            flipTimer?.invalidate()
            flipTimer = nil
            withAnimation(nil) { remainingProgress = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isLocked = true }
        }
    }
    
    
    // MARK: - Card visual building blocks
    // Helper view for Card Faces
    struct CardFace<Content: View>: View {
        let color: Color
        let border: Color
        let content: () -> Content
        
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(color)
                content()
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(border, lineWidth: 4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }
    }
    
    struct TinyTimerRing: View {
        var progress: CGFloat
        var color: Color
        var body: some View {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: max(0, min(1, progress)))
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 24, height: 24)
            .background(Circle().fill(Color.black.opacity(0.5)))
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 0)
        }
    }
}

// New reusable checkerboard background view (not currently used on main screens)
// Left in case you want to reintroduce the style later.
struct CheckerboardBackground: View {
    let color1: Color
    let color2: Color
    let squareSize: CGFloat

    init(color1: Color, color2: Color, squareSize: CGFloat = 56) {
        self.color1 = color1
        self.color2 = color2
        self.squareSize = squareSize
    }

    var body: some View {
        GeometryReader { geo in
            let cols = Int(ceil(geo.size.width / squareSize))
            let rows = Int(ceil(geo.size.height / squareSize))
            ZStack {
                // Base checker pattern with beveled squares
                Canvas { context, size in
                    for row in 0..<rows {
                        for col in 0..<cols {
                            let isAlt = (row + col) % 2 == 0
                            let base = isAlt ? color1 : color2
                            let rect = CGRect(x: CGFloat(col) * squareSize,
                                              y: CGFloat(row) * squareSize,
                                              width: squareSize,
                                              height: squareSize)

                            // Fill base
                            context.fill(Path(rect), with: .color(base))

                            // Add a subtle inner bevel: light highlight on top/left, shadow on bottom/right
                            let highlight = Color.white.opacity(0.18)
                            let shadow = Color.black.opacity(0.25)

                            // Top edge highlight
                            let topRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 1.0)
                            context.fill(Path(topRect), with: .color(highlight))
                            // Left edge highlight
                            let leftRect = CGRect(x: rect.minX, y: rect.minY, width: 1.0, height: rect.height)
                            context.fill(Path(leftRect), with: .color(highlight))

                            // Bottom edge shadow
                            let bottomRect = CGRect(x: rect.minX, y: rect.maxY - 1.0, width: rect.width, height: 1.0)
                            context.fill(Path(bottomRect), with: .color(shadow))
                            // Right edge shadow
                            let rightRect = CGRect(x: rect.maxX - 1.0, y: rect.minY, width: 1.0, height: rect.height)
                            context.fill(Path(rightRect), with: .color(shadow))

                            // Soft vignette inside square to add depth
                            let insetRect = rect.insetBy(dx: 2, dy: 2)
                            let endR = min(insetRect.width, insetRect.height) * 0.7
                            let center = CGPoint(x: insetRect.midX, y: insetRect.midY)
                            let radial = GraphicsContext.Shading.radialGradient(
                                Gradient(colors: [Color.black.opacity(0.10), Color.clear]),
                                center: center,
                                startRadius: 0,
                                endRadius: endR
                            )
                            context.fill(Path(insetRect), with: radial)
                        }
                    }
                }
                .ignoresSafeArea()

                // Global vertical gradient over the checkerboard to add depth and unify the palette
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.22),
                        Color.clear,
                        Color.white.opacity(0.12)
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .blendMode(.overlay)
                .ignoresSafeArea()
            }
        }
    }
}

