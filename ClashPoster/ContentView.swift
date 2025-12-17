import SwiftUI

// --- 1. THE GAME LOGIC ---
struct Player: Identifiable {
    let id = UUID()
    let index: Int
    var isImposter: Bool = false
    var hasSeenRole: Bool = false
}

class ClashImposterEngine: ObservableObject {
    @Published var players: [Player] = []
    @Published var secretCard: String = ""
    @Published var gameState: GameMode = .setup
    
    // You can add more Clash cards here!
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
        case setup, distribution, discussion
    }
    
    func startGame(playerCount: Int) {
        let imposterIndex = Int.random(in: 0..<playerCount)
        secretCard = cardPool.randomElement() ?? "Barbarians"
        
        players = (0..<playerCount).map { i in
            Player(index: i + 1, isImposter: i == imposterIndex)
        }
        gameState = .distribution
    }
    
    func reset() {
        gameState = .setup
        players = []
    }
}

// --- 2. THE MAIN VIEW ---
struct ContentView: View {
    @StateObject private var engine = ClashImposterEngine()
    @State private var playerCount = 4
    @State private var showAlert = false
    @State private var alertContent = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if engine.gameState == .setup {
                    setupView
                } else if engine.gameState == .distribution {
                    distributionView
                } else {
                    discussionView
                }
            }
            .navigationTitle("Clash Undercover")
            .padding()
        }
    }
    
    // Setup Screen
    var setupView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("How many players?")
                .font(.headline)
            
            Stepper("\(playerCount) Players", value: $playerCount, in: 3...10)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            Button("START GAME") {
                engine.startGame(playerCount: playerCount)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
    
    // Passing the phone screen
    var distributionView: some View {
        VStack {
            Text("Pass the phone around.\nTap your card to see your role.")
                .multilineTextAlignment(.center)
                .padding()
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(engine.players.indices, id: \.self) { index in
                        CardButton(player: $engine.players[index], secretCard: engine.secretCard)
                    }
                }
            }
            
            if engine.players.allSatisfy({ $0.hasSeenRole }) {
                Button("START DISCUSSION") {
                    engine.gameState = .discussion
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding()
            }
        }
    }
    
    // The "Who is it?" screen
    var discussionView: some View {
        VStack(spacing: 30) {
            Text("BATTLE COMMENCED")
                .font(.title).bold()
            
            Text("The Imposter does NOT know the card. Take turns describing it!")
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button("Reveal Imposter") {
                let imposter = engine.players.first(where: { $0.isImposter })
                alertContent = "Player \(imposter?.index ?? 0) was the Imposter!"
                showAlert = true
            }
            .buttonStyle(.bordered)
            
            Button("New Game") {
                engine.reset()
            }
            .tint(.red)
        }
        .alert(alertContent, isPresented: $showAlert) {
            Button("OK", role: .cancel) { engine.reset() }
        }
    }
}

// --- UPDATED CARD COMPONENT WITH ANTI-CHEAT ---
struct CardButton: View {
    @Binding var player: Player
    var secretCard: String
    
    // Track 3 states: 0 = Hidden, 1 = Showing, 2 = Locked
    @State private var viewStep = 0
    
    var body: some View {
        Button(action: {
            if viewStep == 0 {
                // First tap: Show the card
                viewStep = 1
                player.hasSeenRole = true
            } else if viewStep == 1 {
                // Second tap: Hide and lock forever
                viewStep = 2
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.black.opacity(0.1), lineWidth: 2)
                    )
                    .shadow(radius: viewStep == 2 ? 0 : 3)
                
                VStack(spacing: 8) {
                    if viewStep == 0 {
                        // STATE: HIDDEN
                        Text("Player \(player.index)")
                            .foregroundColor(.white)
                            .bold()
                        Text("Tap to Reveal")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                            
                    } else if viewStep == 1 {
                        // STATE: SHOWING
                        Text(player.isImposter ? "???" : secretCard)
                            .font(.headline)
                            .foregroundColor(.black)
                        Text("Tap to Hide")
                            .font(.caption2)
                            .foregroundColor(.red)
                            
                    } else {
                        // STATE: LOCKED
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                        Text("PLAYER \(player.index)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(height: 100)
            .padding(5)
        }
        .disabled(viewStep == 2) // Disable the button entirely once locked
    }
    
    // Helper to change color based on state
    var cardColor: Color {
        switch viewStep {
        case 0: return .blue
        case 1: return .white
        default: return Color.gray.opacity(0.2)
        }
    }
}
