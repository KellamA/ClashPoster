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
    let cardPool = ["P.E.K.K.A", "Hog Rider", "The Log", "Mega Knight", "Electro Wizard", "Princess", "Sparky", "Balloon", "X-Bow", "Giant Skeleton"]
    
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

// --- 3. THE CARD COMPONENT ---
struct CardButton: View {
    @Binding var player: Player
    var secretCard: String
    @State private var isFlipped = false
    
    var body: some View {
        Button(action: {
            isFlipped.toggle()
            player.hasSeenRole = true
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(isFlipped ? Color.white : Color.blue)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.black.opacity(0.2), lineWidth: 2)
                    )
                
                if isFlipped {
                    Text(player.isImposter ? "???" : secretCard)
                        .font(.headline)
                        .foregroundColor(.black)
                } else {
                    Text("Player \(player.index)")
                        .foregroundColor(.white)
                        .bold()
                }
            }
            .frame(height: 100)
            .padding(5)
        }
    }
}
