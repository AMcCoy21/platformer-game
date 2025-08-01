# Platformer Game

A 2D Metroidvania-style platformer built in Godot 4 where you play as a broken robot that must collect body parts to regain abilities and explore an interconnected world.

## 🎮 Game Overview

You begin as a heavily damaged robot with limited mobility. As you explore the world, you'll discover scattered robot parts that restore your abilities, opening up new areas and gameplay possibilities. Each body part unlocks specific abilities that are essential for progression.

## ✨ Current Features

### Core Gameplay Systems
- **Progressive Ability System**: Collect 5 different robot parts, each unlocking unique abilities
- **Interconnected World**: 6 carefully designed rooms with seamless transitions
- **Metroidvania Progression**: Abilities gate access to new areas, encouraging exploration and backtracking
- **Persistent Save System**: Full save/load functionality preserving abilities, health, items, and world state

### Robot Abilities
- **Leg Servos**: Enables basic jumping
- **Arm Cannon**: Allows laser shooting with cooldown system
- **Jump Boosters**: Unlocks double jumping for vertical exploration
- **Dash Thrusters**: High-speed horizontal dash with air dash capability
- **Ground Slam Unit**: Powerful downward attack that damages enemies in radius

### Combat & Health
- Health system with visual UI feedback
- Invulnerability frames after taking damage
- Enemy collision detection and damage
- Fall damage with respawn system

### Technical Features
- Room-based architecture with spawn point system
- Pickup tracking prevents duplicate collection
- Coin collection system
- Manual save/load with S/L keys
- Auto-save on major events

## 🎯 Controls

| Action | Key | Requirement |
|--------|-----|-------------|
| Move Left/Right | Arrow Keys | Always available |
| Jump | Up Arrow | Requires **Leg Servos** |
| Double Jump | Up Arrow (in air) | Requires **Jump Boosters** |
| Shoot Laser | Enter | Requires **Arm Cannon** |
| Dash | Escape | Requires **Dash Thrusters** |
| Ground Slam | Down Arrow (in air) | Requires **Ground Slam Unit** |
| Manual Save | S | Always available |
| Manual Load | L | Always available |

## 🚀 How to Run

1. **Install Godot 4.x** from [godotengine.org](https://godotengine.org/)
2. **Clone this repository**:
   ```bash
   git clone https://github.com/yourusername/metroidvania-robot-game.git
   ```
3. **Open in Godot**:
   - Launch Godot
   - Click "Import"
   - Navigate to the project folder
   - Select `project.godot`
4. **Run the game**: Press F5 or click the play button

## 🛠️ Technical Architecture

### Code Structure
- **GameManager**: Singleton handling persistent game state, save/load, and ability tracking
- **Player Controller**: Comprehensive character controller with state-based abilities
- **Scene Transition System**: Seamless room transitions with spawn point management
- **Modular Ability System**: Clean separation of abilities tied to collected robot parts

### Design Patterns Used
- Singleton pattern for game state management
- Component-based ability system
- Observer pattern for UI updates
- State machine for player movement modes

## 🎯 Current Status

### ✅ Completed
- Core movement physics and character controller
- All 5 robot abilities with visual/mechanical progression
- Save/load system with persistent world state
- Room transition system with proper spawn handling
- Health and combat mechanics
- Enemy interaction and damage systems
- UI systems for health and feedback

### 🔄 In Development
- Additional world areas and rooms
- More enemy types and combat encounters
- Environmental puzzles utilizing abilities
- Audio and visual polish
- Story elements and environmental storytelling

## 🎨 Game Design Philosophy

This project demonstrates understanding of:
- **Metroidvania Design**: Interconnected world with ability-gated progression
- **Player Empowerment**: Each new ability fundamentally changes movement options
- **Persistent Systems**: Robust save system maintaining player progress
- **Scalable Architecture**: Code structure supporting easy content expansion

## 🔧 Built With

- **Engine**: Godot 4.x
- **Language**: GDScript
- **Architecture**: Scene-based with singleton state management
- **Version Control**: Git

## 📝 Notes for Developers

This project showcases practical game development skills including:
- Complex state management across multiple systems
- Event-driven programming for ability unlocks
- Physics-based character controller with multiple movement modes
- Persistent data systems with error handling
- Modular code architecture supporting feature expansion

---

*This is an active development project demonstrating game programming fundamentals, system design, and Metroidvania genre mechanics.*
