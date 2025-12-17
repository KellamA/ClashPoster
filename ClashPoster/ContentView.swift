import SwiftUI

// --- 1. DATA MODELS & LOGIC ---
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
        case setup, distribution, discussion
    }
    
    func startGame(playerCount: Int) {
        let imposterIndex = Int.random(in: 0..<playerCount)
        secretCard = cardPool.randomElement() ?? "P.E.K.K.A"
        
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

// --- 2. MAIN VIEW ---
struct ContentView: View {
    @StateObject private var engine = ClashImposterEngine()
    @State private var playerCount = 4
    @State private var showAlert = false
    @State private var alertContent = ""
    
    let clashBlue = Color(red: 0.05, green: 0.1, blue: 0.25)
    let clashGold = Color(red: 1.0, green: 0.8, blue: 0.2)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium Arena Background
                LinearGradient(gradient: Gradient(colors: [clashBlue, .black]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
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
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
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
                engine.startGame(playerCount: playerCount)
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
                        CardFlipView(player: $engine.players[index], secretCard: engine.secretCard, clashGold: clashGold)
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
                let imposter = engine.players.first(where: { $0.isImposter })
                alertContent = "Player \(imposter?.index ?? 0) was the Imposter!"
                showAlert = true
            }
            .buttonStyle(.borderedProminent).tint(clashGold).foregroundColor(.black)
            
            Button("New Game") { engine.reset() }.tint(.red)
        }
        .alert(alertContent, isPresented: $showAlert) {
            Button("OK", role: .cancel) { engine.reset() }
        }
    }
}

// --- 3. THE 3D CARD FLIP COMPONENT ---
struct CardFlipView: View {
    @Binding var player: Player
    var secretCard: String
    var clashGold: Color
    
    @State private var degree: Double = 0
    @State private var isFlipped: Bool = false
    @State private var isLocked: Bool = false

    var body: some View {
        ZStack {
            // BACK FACE
            CardFace(color: Color(red: 0.1, green: 0.2, blue: 0.4), border: clashGold) {
                VStack(spacing: 8) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 35))
                        .foregroundColor(clashGold)
                    Text("PLAYER \(player.index)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .opacity(isFlipped ? 0 : 1)

            // FRONT FACE (LARGE IMAGE WITH DARK NAMEPLATE)
            CardFace(color: .white, border: .red) {
                ZStack(alignment: .bottom) {
                    if player.isImposter {
                        VStack {
                            Image(systemName: "questionmark.circle.fill")
                                .resizable().scaledToFit().frame(width: 60)
                                .foregroundColor(.red)
                            Text("IMPOSTER")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(.red)
                        }
                    } else {
                        // FULL SCALE IMAGE
                        Image(secretCard)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                        
                        // BLACK TRANSPARENT NAMEPLATE
                        Text(secretCard.uppercased())
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.9)]), startPoint: .top, endPoint: .bottom)
                            )
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
    }

    func flipCard() {
        if !isFlipped {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                degree += 180
                isFlipped = true
                player.hasSeenRole = true
            }
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                degree += 180
                isFlipped = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isLocked = true }
        }
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
