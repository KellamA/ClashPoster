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
    
    // IMPORTANT: To use real images, ensure the image filenames in your
    // Assets folder match these strings EXACTLY.
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
    
    // Define themed colors
    let clashBlue = Color(red: 0.1, green: 0.2, blue: 0.5)
    let clashGold = Color(red: 1.0, green: 0.8, blue: 0.2)
    
    var body: some View {
        NavigationView {
            ZStack {
                // --- THE BACKGROUND ---
                // A dark gradient to give it an arena feel
                LinearGradient(gradient: Gradient(colors: [clashBlue, .black]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                // --- THE CONTENT ---
                VStack {
                    if engine.gameState == .setup {
                        setupView
                    } else if engine.gameState == .distribution {
                        distributionView
                    } else {
                        discussionView
                    }
                }
                .padding()
            }
            .navigationTitle("") // Hiding default title to use custom header
            .navigationBarHidden(true)
        }
        // Setting the text color for the whole app to white for contrast
        .foregroundColor(.white)
        .preferredColorScheme(.dark)
    }
    
    // Header Component
    var gameHeader: some View {
        Text("CLASHPOSTER")
            .font(.system(size: 28, weight: .black, design: .rounded))
            .foregroundColor(clashGold)
            .shadow(color: .black, radius: 2, x: 1, y: 1)
            .padding(.bottom, 20)
    }
    
    // Setup Screen
    var setupView: some View {
        VStack(spacing: 30) {
            gameHeader
            
            VStack(spacing: 10) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 80))
                    .foregroundColor(clashGold)
                    .shadow(radius: 5)
                Text("Assemble Your Clan")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            VStack {
                Text("Players: \(playerCount)")
                    .font(.headline)
                Stepper("", value: $playerCount, in: 3...10)
                    .labelsHidden()
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(15)
            }
            .padding()
            
            Button(action: { engine.startGame(playerCount: playerCount) }) {
                Text("START BATTLE")
                    .font(.title3).bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(clashGold)
                    .foregroundColor(.black)
                    .cornerRadius(15)
                    .shadow(radius: 5)
            }
        }
        .padding()
    }
    
    // Passing the phone screen
    var distributionView: some View {
        VStack {
            gameHeader
            
            Text("Tap a card to reveal your role.\nTap again to lock it and pass the phone.")
                .multilineTextAlignment(.center)
                .font(.callout)
                .padding(.bottom)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(engine.players.indices, id: \.self) { index in
                        CardButton(player: $engine.players[index], secretCard: engine.secretCard, clashGold: clashGold)
                    }
                }
                .padding(.horizontal)
            }
            
            if engine.players.allSatisfy({ $0.hasSeenRole }) {
                Button(action: { engine.gameState = .discussion }) {
                    Text("BEGIN DISCUSSION")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
                .padding()
            }
        }
    }
    
    // The "Who is it?" screen
    var discussionView: some View {
        VStack(spacing: 30) {
            gameHeader
            
            VStack(spacing: 20) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 60))
                    .foregroundColor(clashGold)
                
                Text("Discuss!")
                    .font(.title).bold()
                
                Text("The Imposter does NOT know the card.\nDescribe the card, but don't give it away!")
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(15)
            }
            
            Spacer()
            
            Button("Reveal Imposter") {
                let imposter = engine.players.first(where: { $0.isImposter })
                alertContent = "Player \(imposter?.index ?? 0) was the Imposter!"
                showAlert = true
            }
            .buttonStyle(.borderedProminent)
            .tint(clashBlue)
            
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

// --- 3. THE CARD COMPONENT (VISUAL UPDATE) ---
struct CardButton: View {
    @Binding var player: Player
    var secretCard: String
    var clashGold: Color // Passed in color
    
    // 0 = Hidden, 1 = Showing, 2 = Locked
    @State private var viewStep = 0
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                if viewStep == 0 { viewStep = 1; player.hasSeenRole = true }
                else if viewStep == 1 { viewStep = 2 }
            }
        }) {
            ZStack {
                // Card Background
                RoundedRectangle(cornerRadius: 15)
                    .fill(cardBgColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(cardBorderColor, lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.5), radius: viewStep == 2 ? 0 : 5, x: 0, y: 5)
                
                // Card Content
                VStack(spacing: 10) {
                    if viewStep == 0 {
                        // HIDDEN STATE
                        Image(systemName: "shield.fill")
                            .font(.system(size: 40))
                            .foregroundColor(clashGold)
                        Text("PLAYER \(player.index)")
                            .font(.headline)
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                            
                    } else if viewStep == 1 {
                        // REVEALED STATE
                        if player.isImposter {
                            Image(systemName: "questionmark.circle.fill")
                                .resizable().scaledToFit().frame(height: 50)
                                .foregroundColor(.red)
                            Text("???").font(.headline).bold()
                            Text("IMPOSTER").font(.caption2).bold().foregroundColor(.red)
                        } else {
                            // --- IMAGE REPLACEMENT AREA ---
                            // Once you have real images in Assets, comment out the
                            // placeholder 'Image(systemName...)' line and uncomment the real line below it:
                            
                            //Image(systemName: "person.crop.square.fill") // Placeholder
                            Image(secretCard) // <--- REAL IMAGE CODE
                                .resizable()
                                .scaledToFit()
                                .frame(height: 50)
                                .cornerRadius(8)

                            Text(secretCard)
                                .font(.headline).bold()
                                .multilineTextAlignment(.center)
                                .foregroundColor(.black)
                        }

                    } else {
                        // LOCKED STATE
                        Image(systemName: "lock.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.gray.opacity(0.7))
                        Text("LOCKED")
                            .font(.caption).bold()
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
                .padding(5)
            }
            // Fixed height ensures they all look uniform in the grid
            .frame(height: 130)
        }
        .disabled(viewStep == 2)
    }
    
    var cardBgColor: Color {
        switch viewStep {
        case 0: return Color(red: 0.2, green: 0.3, blue: 0.6) // Dark Blue
        case 1: return Color.white // White for reveal
        default: return Color.black.opacity(0.5) // Dark gray for locked
        }
    }
    
    var cardBorderColor: Color {
        switch viewStep {
        case 0: return clashGold
        case 1: return Color.red
        default: return Color.gray
        }
    }
}
