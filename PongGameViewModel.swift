import Foundation
import SwiftUI

final class PongGameViewModel: ObservableObject {
    enum Mode: Hashable {
        case singlePlayer
        case twoPlayer
    }

    @Published var mode: Mode = .singlePlayer
    @Published var level = 1
    @Published var playerOneScore = 0
    @Published var playerTwoScore = 0
    @Published var statusText = "First to 9 points wins. Beat your opponent to level up."

    @Published var ballPosition: CGPoint = .zero
    @Published var playerOneX: CGFloat = 0
    @Published var playerTwoX: CGFloat = 0

    var playerOneY: CGFloat { sceneSize.height - (paddleHeight * 2) }
    var playerTwoY: CGFloat { paddleHeight * 2 }
    var midY: CGFloat { sceneSize.height / 2 }

    let ballDiameter: CGFloat = 16
    let paddleHeight: CGFloat = 14

    var currentPaddleWidth: CGFloat {
        let reduced = basePaddleWidth - CGFloat(level - 1) * 10
        return max(70, reduced)
    }

    var timer = Timer.publish(every: 1.0 / 120.0, on: .main, in: .common).autoconnect()

    private let basePaddleWidth: CGFloat = 140
    private var ballVelocity: CGVector = .zero
    private var sceneSize: CGSize = .zero
    private var waitingForServe = true

    func configureScene(size: CGSize) {
        guard size.width > 20, size.height > 20 else { return }
        sceneSize = size

        if playerOneX == 0 { playerOneX = size.width / 2 }
        if playerTwoX == 0 { playerTwoX = size.width / 2 }
        if ballPosition == .zero {
            ballPosition = CGPoint(x: size.width / 2, y: size.height / 2)
        }

        clampPaddles()
    }

    func resetMatch(keepLevel: Bool) {
        playerOneScore = 0
        playerTwoScore = 0
        level = keepLevel ? level : 1
        waitingForServe = true
        statusText = "First to 9 points wins. Beat your opponent to level up."

        playerOneX = sceneSize.width / 2
        playerTwoX = sceneSize.width / 2
        ballPosition = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        ballVelocity = .zero
    }

    func launchBallTowardLoser() {
        guard sceneSize != .zero else { return }
        waitingForServe = false

        let speed = baseBallSpeed + CGFloat(level - 1) * 40
        let randomX = CGFloat.random(in: -0.8...0.8)
        let directionY: CGFloat = playerOneScore >= playerTwoScore ? -1 : 1
        let normalized = CGVector(dx: randomX, dy: directionY).normalized()
        ballVelocity = CGVector(dx: normalized.dx * speed, dy: normalized.dy * speed)

        if ballPosition == .zero || ballPosition.x <= 1 {
            ballPosition = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        }

        statusText = mode == .singlePlayer
            ? "Win this race to 9 to reach level \(level + 1)!"
            : "Two-player mode: race to 9 points."
    }

    func tick() {
        guard sceneSize != .zero else { return }

        if waitingForServe {
            if ballVelocity == .zero {
                ballPosition = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
            }
            return
        }

        let dt: CGFloat = 1.0 / 120.0

        if mode == .singlePlayer {
            runSimpleAI(dt: dt)
        }

        ballPosition.x += ballVelocity.dx * dt
        ballPosition.y += ballVelocity.dy * dt

        handleWallCollision()
        handlePaddleCollision()
        handleGoalCheck()
        clampPaddles()
    }

    private let baseBallSpeed: CGFloat = 330

    private func runSimpleAI(dt: CGFloat) {
        let targetX = ballPosition.x
        let maxMove = (240 + CGFloat(level - 1) * 20) * dt

        if abs(playerTwoX - targetX) <= maxMove {
            playerTwoX = targetX
        } else if playerTwoX < targetX {
            playerTwoX += maxMove
        } else {
            playerTwoX -= maxMove
        }
    }

    private func handleWallCollision() {
        let radius = ballDiameter / 2

        if ballPosition.x <= radius {
            ballPosition.x = radius
            ballVelocity.dx = abs(ballVelocity.dx)
        } else if ballPosition.x >= sceneSize.width - radius {
            ballPosition.x = sceneSize.width - radius
            ballVelocity.dx = -abs(ballVelocity.dx)
        }
    }

    private func handlePaddleCollision() {
        let radius = ballDiameter / 2
        let p1Rect = CGRect(
            x: playerOneX - currentPaddleWidth / 2,
            y: playerOneY - paddleHeight / 2,
            width: currentPaddleWidth,
            height: paddleHeight
        )
        let p2Rect = CGRect(
            x: playerTwoX - currentPaddleWidth / 2,
            y: playerTwoY - paddleHeight / 2,
            width: currentPaddleWidth,
            height: paddleHeight
        )
        let ballRect = CGRect(
            x: ballPosition.x - radius,
            y: ballPosition.y - radius,
            width: ballDiameter,
            height: ballDiameter
        )

        if ballRect.intersects(p1Rect), ballVelocity.dy > 0 {
            ballPosition.y = playerOneY - paddleHeight / 2 - radius
            reflectBall(from: playerOneX, upward: true)
        }

        if ballRect.intersects(p2Rect), ballVelocity.dy < 0 {
            ballPosition.y = playerTwoY + paddleHeight / 2 + radius
            reflectBall(from: playerTwoX, upward: false)
        }
    }

    private func reflectBall(from paddleCenterX: CGFloat, upward: Bool) {
        let relative = (ballPosition.x - paddleCenterX) / (currentPaddleWidth / 2)
        let clamped = max(-1, min(1, relative))
        let angle = clamped * (.pi / 3)

        let speed = sqrt(ballVelocity.dx * ballVelocity.dx + ballVelocity.dy * ballVelocity.dy)
        let dySign: CGFloat = upward ? -1 : 1

        ballVelocity.dx = sin(angle) * speed
        ballVelocity.dy = cos(angle) * speed * dySign
    }

    private func handleGoalCheck() {
        if ballPosition.y < -20 {
            pointToPlayerOne()
        } else if ballPosition.y > sceneSize.height + 20 {
            pointToPlayerTwo()
        }
    }

    private func pointToPlayerOne() {
        playerOneScore += 1
        concludePoint(scoringPlayerOne: true)
    }

    private func pointToPlayerTwo() {
        playerTwoScore += 1
        concludePoint(scoringPlayerOne: false)
    }

    private func concludePoint(scoringPlayerOne: Bool) {
        waitingForServe = true
        ballVelocity = .zero
        ballPosition = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)

        if playerOneScore >= 9 || playerTwoScore >= 9 {
            finalizeGame()
        } else {
            statusText = scoringPlayerOne ? "Point You. Tap Next Serve." : "Point \(mode == .singlePlayer ? "CPU" : "P2"). Tap Next Serve."
        }
    }

    private func finalizeGame() {
        if mode == .singlePlayer {
            if playerOneScore == 9 {
                level += 1
                statusText = "You won! Welcome to level \(level): faster ball, smaller paddles."
                resetForNextLevel()
            } else {
                statusText = "CPU wins. Try again from level \(level)."
                resetScoresOnly()
            }
        } else {
            statusText = playerOneScore == 9 ? "Player One wins!" : "Player Two wins!"
            resetScoresOnly()
        }
    }

    private func resetForNextLevel() {
        playerOneScore = 0
        playerTwoScore = 0
        waitingForServe = true
        ballVelocity = .zero
        ballPosition = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
    }

    private func resetScoresOnly() {
        playerOneScore = 0
        playerTwoScore = 0
        waitingForServe = true
        ballVelocity = .zero
        ballPosition = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
    }

    private func clampPaddles() {
        let half = currentPaddleWidth / 2
        playerOneX = min(max(half, playerOneX), sceneSize.width - half)
        playerTwoX = min(max(half, playerTwoX), sceneSize.width - half)
    }
}

private extension CGVector {
    func normalized() -> CGVector {
        let magnitude = sqrt(dx * dx + dy * dy)
        guard magnitude > 0 else { return CGVector(dx: 0, dy: -1) }
        return CGVector(dx: dx / magnitude, dy: dy / magnitude)
    }
}
