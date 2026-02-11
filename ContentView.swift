import SwiftUI

struct ContentView: View {
    @StateObject private var game = PongGameViewModel()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 12) {
                    header
                    gameArea(size: proxy.size)
                    controls
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("WITHOUT A PADDLE")
                .font(.system(size: 30, weight: .black, design: .monospaced))
                .foregroundStyle(.green)

            HStack(spacing: 24) {
                scoreCard(title: "YOU", score: game.playerOneScore)
                scoreCard(title: game.mode == .singlePlayer ? "CPU" : "P2", score: game.playerTwoScore)
            }

            Text("Level \(game.level)")
                .font(.system(.headline, design: .monospaced))
                .foregroundStyle(.white)

            Text(game.statusText)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.yellow)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private func scoreCard(title: String, score: Int) -> some View {
        VStack {
            Text(title)
            Text("\(score)")
                .font(.system(size: 38, weight: .bold, design: .monospaced))
        }
        .foregroundStyle(.white)
    }

    private func gameArea(size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 2, dash: [8, 8]))

            Rectangle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 2)

            Circle()
                .fill(.white)
                .frame(width: game.ballDiameter, height: game.ballDiameter)
                .position(x: game.ballPosition.x, y: game.ballPosition.y)

            RoundedRectangle(cornerRadius: 8)
                .fill(.white)
                .frame(width: game.currentPaddleWidth, height: game.paddleHeight)
                .position(x: game.playerOneX, y: game.playerOneY)

            RoundedRectangle(cornerRadius: 8)
                .fill(game.mode == .singlePlayer ? .gray : .white)
                .frame(width: game.currentPaddleWidth, height: game.paddleHeight)
                .position(x: game.playerTwoX, y: game.playerTwoY)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .onAppear {
            game.configureScene(size: size)
        }
        .onChange(of: size) { _, newSize in
            game.configureScene(size: newSize)
        }
        .onReceive(game.timer) { _ in
            game.tick()
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Picker("Mode", selection: $game.mode) {
                Text("Single Player").tag(PongGameViewModel.Mode.singlePlayer)
                Text("Two Player").tag(PongGameViewModel.Mode.twoPlayer)
            }
            .pickerStyle(.segmented)
            .onChange(of: game.mode) { _, _ in
                game.resetMatch(keepLevel: false)
            }

            HStack(spacing: 10) {
                Button("Restart Match") {
                    game.resetMatch(keepLevel: false)
                }
                .buttonStyle(.borderedProminent)

                Button("Next Serve") {
                    game.launchBallTowardLoser()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let location = value.location
                if location.y >= game.midY {
                    game.playerOneX = location.x
                } else if game.mode == .twoPlayer {
                    game.playerTwoX = location.x
                }
            }
    }
}

#Preview {
    ContentView()
}
