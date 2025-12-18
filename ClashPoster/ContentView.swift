import SwiftUI
import Foundation

// --- 1. DATA MODELS & LOGIC ---
struct Player: Identifiable {
    let id = UUID()
    let index: Int
    var isImposter: Bool = false
    var hasSeenRole: Bool = false
    var name: String
}

class ClashImposterEngine: ObservableObject {
    @Published var players: [Player] = []
    @Published var secretCard: String = ""
    @Published var gameState: GameMode = .setup
    static let savedNamesKey = "savedPlayerNames"
    
    // Ensure these match your Asset names exactly!
    let cardPool = ["Archer Queen", "Archers", "Arrows", "Baby Dragon", "Balloon", "Bandit", "Barbarian Barrel",
                    "Barbarian Hut", "Barbarians", "Bats", "Battle Healer", "Battle Ram", "Berserker", "Bomb Tower",
                    "Bomber", "Boss Bandit", "Bowler", "Cannon", "Cannon Cart", "Clone", "Dark Prince", "Dart Goblin",
                    "Earthquake", "Electro Dragon", "Electro Giant", "Electro Spirit", "Electro Wizard",
                    "Elite Barbarians", "Elixir Collector", "Elixir Golem", "Executioner", "Fire Spirit",
                    "Fireball", "Firecracker", "Fisherman", "Flying Machine", "Freeze", "Furnace", "Giant",
                    "Giant Skeleton", "Giant Snowball", "Goblin Barrel", "Goblin Cage", "Goblin Curse",
                    "Goblin Demolisher", "Goblin Drill", "Goblin Gang", "Goblin Giant", "Goblin Hut",
                    "Goblin Machine", "Goblins", "Goblinstein", "Golden Knight", "Golem", "Graveyard",
                        "Guards", "Heal Spirit", "Hog Rider", "Hunter", "Ice Golem", "Ice Spirit", "Ice Wizard",
                        "Inferno Dragon", "Inferno Tower", "Knight", "Lava Hound", "Lightning", "Little Prince",
                        "Lumberjack", "Magic Archer", "Mega Knight", "Mega Minion", "Mighty Miner", "Miner",
                        "Mini P.E.K.K.A", "Minion Horde", "Minions", "Mirror", "Monk", "Mortar", "Mother Witch",
                        "Musketeer", "Night Witch", "P.E.K.K.A", "Phoenix", "Poison", "Prince", "Princess",
                        "Rage", "Ram Rider", "Rascals", "Rocket", "Royal Delivery", "Royal Ghost",
                        "Royal Giant", "Royal Hogs", "Royal Recruits", "Rune Giant", "Skeleton Army", "Skeleton Barrel",
                        "Skeleton Dragons", "Skeleton King", "Skeletons", "Sparky", "Spear Goblins", "Spirit Empress",
                        "Suspicious Bush", "Tesla", "The Log", "Three Musketeers", "Tombstone", "Tornado", "Valkyrie",
                        "Vines", "Void", "Wall Breakers", "Witch", "Wizard", "X-Bow", "Zap", "Zappies"]
    
    enum GameMode {
        case setup, nameEntry, distribution, discussion
    }
    
    func startGame(playerCount: Int, requiresNameEntry: Bool) {
        let imposterIndex = Int.random(in: 0..<playerCount)
        secretCard = cardPool.randomElement() ?? "P.E.K.K.A"
        
        players = (0..<playerCount).map { i in
            Player(index: i + 1, isImposter: i == imposterIndex, hasSeenRole: false, name: "Player \((i + 1))")
        }
        if requiresNameEntry, let saved = UserDefaults.standard.array(forKey: ClashImposterEngine.savedNamesKey) as? [String] {
            let count = min(players.count, saved.count)
            for i in 0..<count {
                let trimmed = saved[i].trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    players[i].name = trimmed
                }
            }
        }
        gameState = requiresNameEntry ? .nameEntry : .distribution
    }
    
    func reset() {
        gameState = .setup
        players = []
    }
}

// --- 2. MAIN VIEW ---
struct ContentView: View {
    @StateObject private var engine = ClashImposterEngine()
    @State private var playerCount = 4
    @State private var showRevealScreen = false
    @AppStorage("timedFlipEnabled") private var timedFlipEnabled: Bool = false // Added @AppStorage toggle
    @AppStorage("customPlayerNamesEnabled") private var customPlayerNamesEnabled: Bool = false
    
    let clashBlue = Color(red: 0.05, green: 0.1, blue: 0.25)
    let clashGold = Color(red: 1.0, green: 0.8, blue: 0.2)
    
    var body: some View {
        // --- Changed: Wrap current UI inside a TabView with two tabs: Game and Settings ---
        TabView {
            NavigationView {
                ZStack {
                    // Premium Arena Background
                    LinearGradient(gradient: Gradient(colors: [clashBlue, .black]), startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                    
                    VStack {
                        if engine.gameState == .setup {
                            setupView
                        } else if engine.gameState == .nameEntry {
                            nameEntryView
                        } else if engine.gameState == .distribution {
                            distributionView
                        } else {
                            discussionView
                        }
                    }
                    .padding()
                }
                .navigationBarHidden(true)
            }
            .tabItem {
                Label("Game", systemImage: "house")
            }
            .preferredColorScheme(.dark)
            .overlay(revealView)
            
            GameSettingsView(timedFlipEnabled: $timedFlipEnabled, customPlayerNamesEnabled: $customPlayerNamesEnabled)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
    
    // --- DESIGNED SETUP SCREEN ---
    var setupView: some View {
            VStack(spacing: 40) {
                // THE NEW COMBINED TITLE
                HStack(spacing: 0) {
                    Text("CLASH")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(clashGold)
                    
                    Text("POSTER")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: clashGold.opacity(0.5), radius: 10, x: 0, y: 0)
                }
                .padding(.top, 40)
                
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

            Button(action: {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                engine.startGame(playerCount: playerCount, requiresNameEntry: customPlayerNamesEnabled)
            }) {
                Text("ENTER ARENA")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.black)
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

            Button("Reset to Defaults", role: .destructive) {
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

            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                // Sanitize names: trim whitespace and restore defaults if empty
                for i in engine.players.indices {
                    let trimmed = engine.players[i].name.trimmingCharacters(in: .whitespacesAndNewlines)
                    engine.players[i].name = trimmed.isEmpty ? "Player \(i + 1)" : trimmed
                }
                let namesToSave = engine.players.map { $0.name }
                UserDefaults.standard.set(namesToSave, forKey: ClashImposterEngine.savedNamesKey)
                engine.gameState = .distribution
            }) {
                Text("CONTINUE")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.black)
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
            
            ScrollView {
                // REVERTED TO 2 COLUMNS
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(engine.players.indices, id: \.self) { index in
                        // --- Changed: Pass timedFlipEnabled to CardFlipView ---
                        CardFlipView(player: $engine.players[index], secretCard: engine.secretCard, clashGold: clashGold, timedFlipEnabled: timedFlipEnabled)
                            .frame(width: 140, height: 185) // increased size here
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            
            if engine.players.allSatisfy({ $0.hasSeenRole }) {
                Button(action: { engine.gameState = .discussion }) {
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

            Text("The Imposter is trying to blend in.\nDescribe the card, find the traitor!")
                .multilineTextAlignment(.center).padding().background(Color.white.opacity(0.1)).cornerRadius(15)
            
            Spacer()
            
            Button("REVEAL IMPOSTER") {
                showRevealScreen = true
            }
            .buttonStyle(.borderedProminent).tint(clashGold).foregroundColor(.black)
            
            Button("New Game") { engine.reset() }.tint(.red)
        }
    }
    
    private var revealView: some View {
        Group {
            if showRevealScreen {
                ZStack {
                    Color.black.opacity(0.93).ignoresSafeArea()
                    VStack(spacing: 28) {
                        Text("IMPOSTER REVEAL")
                            .font(.largeTitle).bold().foregroundColor(clashGold)
                        let imposter = engine.players.first(where: { $0.isImposter })
                        if let imposter {
                            VStack(spacing: 10) {
                                Text(imposter.name).font(.title3).foregroundColor(.red).bold()
                                Image("Imposter Card").resizable().scaledToFit().frame(height: 90).shadow(radius: 8)
                                Text("IMPOSTER").font(.headline).foregroundColor(.white)
                            }.padding().background(RoundedRectangle(cornerRadius: 18).fill(Color.red.opacity(0.25)))
                        }
                        Text("Other Players' Cards:").font(.headline).foregroundColor(.white)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 18) {
                                ForEach(engine.players.filter { !$0.isImposter }, id: \.id) { player in
                                    VStack(spacing: 7) {
                                        Image(engine.secretCard).resizable().scaledToFit().frame(height: 70).cornerRadius(8)
                                        Text(player.name).font(.subheadline).foregroundColor(.gray)
                                    }.padding(8).background(RoundedRectangle(cornerRadius: 13).fill(Color.white.opacity(0.13)))
                                }
                            }
                        }.padding(.horizontal)
                        Button(action: { showRevealScreen = false; engine.reset() }) {
                            Text("Start New Game").font(.title3).bold().padding(.vertical, 14).padding(.horizontal, 44).background(RoundedRectangle(cornerRadius: 20).fill(clashGold)).foregroundColor(.black)
                        }.padding(.top, 14)
                    }
                    .padding(36)
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
    }
}

// --- 3. THE 3D CARD FLIP COMPONENT ---
struct CardFlipView: View {
    @Binding var player: Player
    var secretCard: String
    var clashGold: Color
    var timedFlipEnabled: Bool // Added parameter
    
    @State private var degree: Double = 0
    @State private var isFlipped: Bool = false
    @State private var isLocked: Bool = false
    @State private var flipTimer: Timer? // Added timer state
    @State private var remainingProgress: CGFloat = 0 // Progress for visual timer (1 -> 0)
    
    var body: some View {
        ZStack {
            // BACK FACE
            CardFace(color: Color(red: 0.1, green: 0.2, blue: 0.4), border: clashGold) {
                VStack(spacing: 8) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 35))
                        .foregroundColor(clashGold)
                    Text(player.name.uppercased())
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .opacity(isFlipped ? 0 : 1)
            
            // FRONT FACE (LARGE IMAGE WITH DARK NAMEPLATE)
            CardFace(color: .white, border: .red) {
                ZStack(alignment: .bottom) {
                    if player.isImposter {
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            Image("Imposter Card")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 108)
                                .cornerRadius(5)
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
                            Spacer(minLength: 0)
                            Image(secretCard)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 110) // changed from 90 to 110
                                .cornerRadius(5)
                            Spacer(minLength: 0)
                            Text(secretCard.uppercased())
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.9)]), startPoint: .top, endPoint: .bottom)
                                )
                                .padding(.bottom, 8)
                        }
                    }
                }
            }
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            
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
            if timedFlipEnabled && isFlipped && !isLocked {
                TinyTimerRing(progress: remainingProgress, color: clashGold)
                    .padding(8)
            }
        }
        .onDisappear {
            // Invalidate timer when view disappears
            withAnimation(nil) { remainingProgress = 0 }
            flipTimer?.invalidate()
            flipTimer = nil
        }
    }
    
    // --- Updated flipCard to support timed flip and locking ---
    func flipCard() {
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
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            degree += 180
                            isFlipped = false
                        }
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

// --- 4. SETTINGS VIEW ---
struct GameSettingsView: View {
    @Binding var timedFlipEnabled: Bool
    @Binding var customPlayerNamesEnabled: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Game Options")) {
                    Toggle("Enable Timed Flip (5 sec)", isOn: $timedFlipEnabled)
                    Toggle("Custom Player Names", isOn: $customPlayerNamesEnabled)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

