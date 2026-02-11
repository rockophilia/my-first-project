# Without A Paddle iPhone App (SwiftUI)

This repository now contains a playable Pong clone for iPhone written in SwiftUI.

## Features

- **Single-player mode** against a computer paddle AI.
- **Two-player mode** where each player controls one paddle with touch input.
- **Finger controls**: drag in the **bottom half** to move Player 1, and drag in the **top half** to move Player 2 in two-player mode.
- **Level progression** in single-player:
  - Be the **first to 9 points** against the CPU to advance.
  - Each new level makes paddles shorter and ball speed faster.
- Retro-inspired score and status HUD.

## Files

- `Pong1970sApp.swift` — app entry point.
- `ContentView.swift` — full game UI and touch controls.
- `PongGameViewModel.swift` — game loop, collision rules, AI, scoring, levels.

## Run in Xcode

1. Create a new **iOS App** project in Xcode.
2. Replace generated app/content files with the files in this repo.
3. Build and run on **iPhone Simulator** or a real iPhone.

> The game logic is self-contained and does not require external dependencies.
