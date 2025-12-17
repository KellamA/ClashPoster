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
    let cardPool = ["P.E.K.K.A", "Hog Rider", "The Log", "Mega Knight", "Electro Wizard", "Princess", "Sparky", "Balloon", "X-Bow", "Giant Skeleton"]
    
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
            VStack(spacing: 5) {
                Text("CLASH")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .tracking(8)
                    .foregroundColor(clashGold.opacity(0.8))
                
                Text("UNDERCOVER")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: clashGold.opacity(0.5), radius: 10, x: 0, y: 0)
            }
            .padding(.top, 40)

            ZStack {
                Circle()
                    .fill(clashGold.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                Circle()
                    .stroke(clashGold.opacity(0.3), lineWidth: 2)
                    .frame(width: 140, height: 140)
                
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
                    
                    Button(action: { if playerCount < 10 { playerCount += 1 } }) {
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
    
    var distributionView: some View {
        VStack {
            Text("TAP TO FLIP").font(.headline).foregroundColor(clashGold).padding(.top)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(engine.players.indices, id: \.self) { index in
                        CardFlipView(player: $engine.players[index], secretCard: engine.secretCard, clashGold: clashGold)
                    }
                }
                .padding()
            }
            
            if engine.players.allSatisfy({ $0.hasSeenRole }) {
                Button(action: { engine.gameState = .discussion }) {
                    Text("BEGIN BATTLE")
                        .bold().frame(maxWidth: .infinity).padding().background(Color.green).cornerRadius(15)
                }
                .padding()
            }
        }
    }

    var discussionView: some View {
        VStack(spacing: 40) {
            Text("WHO IS THE SPY?").font(.title).bold().foregroundColor(clashGold)
            
            Image(systemName: "magnifyingglass").font(.system(size: 80)).foregroundColor(clashGold)

            Text("The Imposter is trying to blend in.\nAsk questions, find the traitor!")
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
            // BACK OF CARD (Hidden State)
            CardFace(color: Color(red: 0.1, green: 0.2, blue: 0.4), border: clashGold) {
                VStack {
                    Image(systemName: "shield.fill").font(.largeTitle).foregroundColor(clashGold)
                    Text("PLAYER \(player.index)").font(.caption).bold().foregroundColor(.white)
                }
            }
            .opacity(isFlipped ? 0 : 1)

            // FRONT OF CARD (Revealed State)
            CardFace(color: .white, border: .red) {
                VStack {
                    if player.isImposter {
                        Image(systemName: "questionmark.circle.fill").resizable().frame(width: 50, height: 50).foregroundColor(.red)
                        Text("IMPOSTER").font(.caption).bold().foregroundColor(.red)
                    } else {
                        Image(secretCard) // Load from Assets
                            .resizable().scaledToFit().frame(height: 70).cornerRadius(5)
                        Text(secretCard).font(.caption).bold().foregroundColor(.black).multilineTextAlignment(.center)
                    }
                }
            }
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))

            // OVERLAY: LOCKED STATE
            if isLocked {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.8))
                    .overlay(Image(systemName: "lock.fill").foregroundColor(.gray))
            }
        }
        .aspectRatio(0.75, contentMode: .fit)
        .rotation3DEffect(.degrees(degree), axis: (x: 0, y: 1, z: 0))
        .onTapGesture {
            flipCard()
        }
        .disabled(isLocked)
    }

    func flipCard() {
        if !isFlipped {
            // Flip to see role
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                degree += 180
                isFlipped = true
                player.hasSeenRole = true
            }
        } else {
            // Flip back and lock
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                degree += 180
                isFlipped = false
            }
            // Small delay to let the flip finish before locking
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isLocked = true
            }
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
            RoundedRectangle(cornerRadius: 15).fill(color)
            RoundedRectangle(cornerRadius: 15).stroke(border, lineWidth: 3)
            content()
        }
    }
}
