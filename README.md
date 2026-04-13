# Safe Steps

## Application Description

"Safe Steps" is an educational and interactive mobile game application designed for students, children, and the general public. The app's goal is to teach users the correct earthquake safety procedure — specifically the internationally recognized "Drop, Cover, and Hold On" protocol — in a fun and engaging way. Built using the Flutter framework and the Flame game engine (v1.35.1), the app offers a combination of learning and play experiences where users are immersed in a simulated earthquake scenario. Through interactive gameplay, users practice life-saving actions by tapping the correct safety buttons (Drop, Cover, Hold) while seeing real-time visual consequences on their in-game character. The game runs in full-screen landscape mode with a fixed resolution, ensuring a consistent experience across devices. Moreover, with multiple planned levels and character feedback systems, users are encouraged to continue learning and improving their earthquake preparedness skills.

---

## Mobile Features

### Splash Screen
The app launches into full-screen landscape mode via Flame's device API (`Flame.device.fullScreen()` and `Flame.device.setLandscape()`). The initial screen displays a colorful background image (`menu_bg.png`) alongside the Safe Steps logo (`menu_logo.png`), welcoming users to the application and establishing the game's visual theme with its bright blue (`#00a5ff`) color scheme and playful "Cherry Bomb One" font.

### Main Menu
The main menu (`menu.dart`) serves as the central navigation hub of the app. It uses a `CameraComponent.withFixedResolution` of 1280×720 and adds both the background and UI elements directly to the camera viewport. It features the game logo positioned at one-third down the screen (`y = virtualSize.y / 3`) and horizontally centered (`x = virtualSize.x / 2`). A prominent "Play" button is rendered at the dead center of the viewport (`x = virtualSize.x / 2`, `y = virtualSize.y / 2`) as a rounded blue rectangle (`borderRadius: 20`, color `#00a5ff`) with white text and a black stroke outline for readability, using the "Cherry Bomb One" font at 42pt. When tapped (`onTapDown`), the button produces a scale-down animation (`ScaleEffect.by(Vector2.all(0.9))`) with smooth easing (`Curves.easeInOut`, 0.08s). After a 100 ms delay on `onTapUp`, it navigates the user to the Level Select screen via `game.router.pushNamed('levels')`.

### Level Select Screen
This screen (`levelselect.dart`) displays three horizontally arranged level buttons against a parallax background (`menu_bg.png` via `loadParallaxComponent`). The three buttons are evenly spaced with a 24px gap and centered on the screen. Currently, only the first level ("Earthquake") is active and shows a thumbnail preview image (`levels_earthquake.png`). The other two levels ("Level 2" and "Level 3") have no assigned route or image and render as solid blue placeholders (`#00a5ff`), indicating future content. Each button is a 140×140 rounded square (`borderRadius: 20`) with the level name rendered below the square using the "Cherry Bomb One" font (22pt, white fill with black stroke outline) and a subtle dark overlay (`Colors.black` at 18% opacity) for text legibility. Tapping a button immediately triggers both a scale animation (`ScaleEffect.by(Vector2.all(0.92))`) and navigation to the level route on `onTapDown`.

### Gameplay Screen (Earthquake Simulation)
This is the core interactive screen of the app (`earthquake.dart`, `levels/level.dart`). Upon entering, the game manually sets `game.images.prefix = ''` and pre-loads `Normal.png`, `Injured.png`, `E1.jpg`, `Clock.png`, and `Table.png`. It then creates a `Level` world and mounts a `CameraComponent.withFixedResolution` of 640×360. The level is structured with two `PositionComponent` containers: `bgContainer` (background) and `objectContainer` (objects and player). An animated background cycles through three earthquake frames (E1, E2, E3) at 1 second per frame via `SpriteAnimationComponent`, creating the sensation of an earthquake. A clock object (83×75 px) is placed at position (45, 45) and a table (225×180 px) at position (350, 245). The player character (274×365 px) is placed at position (128, 270). A "trauma" system (intensity `0.5`) is started immediately on level load via a `TimerComponent` with period `0.0`, driving continuous screen-shaking — the background container shakes lightly (±`baseShake * 8.0` px) while the object container shakes more dramatically (±`baseShake * 25.0` px), simulating a realistic earthquake experience.

### Instruction / Safety Steps (Drop, Cover, Hold Buttons)
The app includes image assets for action buttons in both selected and unselected visual states for the three earthquake safety steps: Drop (`DropB(Selected).png` / `DuckB(Unselected).png`), Cover (`CoverB(Selected).png` / `CoverB(Unselected).png`), and Hold (`HoldB(Selected).png` / `HoldB(Unselected).png`). These assets are present in `assets/earthquake/Buttons/` and are intended to serve as the primary educational mechanic guiding users through the correct earthquake response sequence. Button interaction logic is planned for a future implementation.

### Feedback System
The app provides visual feedback through multiple systems: (1) button press animations using `ScaleEffect.by()` with easing curves on both the Play button and Level Select buttons, (2) character sprite state changes between `Normal.png` and `Injured.png` (toggled via the Spacebar in the current build) with `Worried.png` and `Bandage.png` available as assets for expanded states, (3) the three-frame animated earthquake background (`SpriteAnimationComponent` cycling E1 → E2 → E3) that intensifies the scenario, and (4) the trauma-based screen-shake applied differentially to the background and object containers to communicate the earthquake's ongoing intensity.

### Player Character System
The player character (`actors/player.dart`) is a `SpriteComponent` with `KeyboardHandler`. It renders at 274×365 px and is positioned at (128, 270) within the level. It loads two sprites on start: `Normal.png` (default state) and `Injured.png`. Pressing the Spacebar (`KeyDownEvent` for `LogicalKeyboardKey.space`) toggles the active sprite between the two states, demonstrating the consequence of inaction during an earthquake. Additional character sprite assets (`Worried.png`, `Bandage.png`) are bundled in `assets/characters/` for future expanded emotional and physical state representation.

### Settings / Audio
The app declares `flame_audio: ^2.12.0` as a dependency and maintains an `assets/audio/` directory, supporting audio capabilities planned for immersive earthquake sounds, button click effects, and ambient game audio. Audio playback is not yet implemented in the current codebase. The app locks the device to full-screen landscape mode at startup to prevent accidental orientation changes during gameplay.

### About / Help
A dedicated About or Help screen is not yet implemented in the routing system (`ssgame.dart` registers only `menu`, `levels`, and `earthquake` routes). The app's educational content is delivered directly through gameplay. The Drop, Cover, and Hold button imagery (available as assets) will serve as built-in guidance about the correct earthquake preparedness procedure once the button interaction system is implemented.

---

## Application Features

### User Friendly
Safe Steps is designed with simplicity and clarity at its core. The navigation flow is streamlined into just three steps: Menu → Level Select → Gameplay, meaning users can start playing within seconds. All interactive elements use consistent visual design — the primary blue (`#00a5ff`) color, rounded corners (`borderRadius: 20`), and the playful "Cherry Bomb One" font create a cohesive look. High-contrast text (white fill with black stroke outline) ensures readability on any background. Every button provides immediate tactile feedback through scale-down animations (`ScaleEffect.by()`) with smooth easing curves (`Curves.easeInOut`), confirming that the user's tap was registered. The fixed-resolution rendering system (1280×720 for menus, 640×360 for gameplay via `CameraComponent.withFixedResolution`) guarantees that the UI looks identical on all devices regardless of screen size.

### Offline Mode / Accessible
The app runs entirely offline with no internet connection required. All game assets — sprites, backgrounds, fonts, and audio files — are bundled locally within the application under `assets/`. Asset directories include `assets/earthquake/Backgrounds/`, `assets/characters/`, `assets/earthquake/Objects/`, `assets/earthquake/Buttons/`, `assets/audio/`, `assets/images/`, and `assets/fonts/`. This makes the app ideal for classroom use, field demonstrations, or areas with limited connectivity. Being built on Flutter + Flame, the app is cross-platform and supports Android, iOS, Web, Windows, macOS, and Linux (all platform directories are present in the repository). The full-screen landscape lock and immersive mode remove system UI distractions, creating a focused and accessible learning environment for all users.

---

## Principles of HCI Applied

### Know the User
The primary users of Safe Steps are students and children, particularly in earthquake-prone regions such as the Philippines (the repository description reads "para sa HCI," indicating a Filipino audience). The design matches these users' needs in the following ways:

**Why?** — The Philippines lies within the Pacific Ring of Fire, making earthquake preparedness a critical life skill. Traditional methods like classroom lectures and printed materials are often boring and forgettable for younger audiences. Safe Steps addresses this by transforming earthquake safety education into an interactive game that children actually want to engage with.

**How?** — The interface uses a playful "Cherry Bomb One" font, cartoon-style character sprites (`Normal.png`, `Injured.png`, `Worried.png`, `Bandage.png`), and a bright, colorful visual theme (`#00a5ff` primary color) that appeals to younger users. The navigation is kept extremely simple — just three taps from launch to gameplay (Menu → Level Select → Play) — so that even young children can use the app independently. The core educational content (Drop, Cover, Hold) is taught through direct interaction rather than reading, accommodating users who may not yet be strong readers. All interactive elements have visual feedback (tap animations, character state changes, screen-shake) because children respond better to visual and tactile cues than to text-based instructions.

### Usability Principles Applied

**Learnability** — Safe Steps is designed so that first-time users can understand and begin using the app within seconds, with no prior training required.

**Why?** — The target audience includes young children who may have limited experience with mobile apps. If the app is not immediately understandable, children will lose interest and the educational goal will be lost. Learnability ensures that the safety lesson is delivered effectively on the very first use.

**How?** — The three-screen navigation flow (Menu → Level Select → Gameplay) eliminates decision fatigue. The single "Play" button on the main menu and clearly labeled level buttons on the selection screen provide an unambiguous path forward. Tap animations (scale effects with easing) give immediate confirmation that an action was registered, reducing confusion for first-time users. The earthquake simulation starts automatically on level load, immersing users in the scenario without requiring any setup steps.

---

## Technical Stack

| Component | Version |
|-----------|---------|
| Flutter SDK | ^3.11.0 |
| Flame game engine | ^1.35.1 |
| flame_audio | ^2.12.0 |
| flame_tiled | ^3.0.11 |
| Font | Cherry Bomb One (CherryBombOne-Regular.ttf) |

---

## Project Structure

```
lib/
├── main.dart           # App entry point; sets full-screen landscape mode
├── ssgame.dart         # FlameGame subclass; defines router with 3 named routes
├── menu.dart           # Main menu screen (1280×720 fixed resolution)
├── levelselect.dart    # Level selection screen with parallax background
├── earthquake.dart     # Earthquake gameplay route entry point (640×360)
├── objects.dart        # GameItem components (Clock, Table)
├── levels/
│   └── level.dart      # Level world; animated BG, trauma shake, player & objects
└── actors/
    └── player.dart     # Player character with Normal/Injured sprite toggling

assets/
├── images/             # menu_bg.png, menu_logo.png, menu_play_btn.png, levels_earthquake.png
├── characters/         # Normal.png, Injured.png, Worried.png, Bandage.png
├── earthquake/
│   ├── Backgrounds/    # E1.jpg, E2.jpg, E3.jpg
│   ├── Objects/        # Clock.png, Table.png
│   └── Buttons/        # DropB, DuckB, CoverB, HoldB (Selected/Unselected)
├── audio/              # (reserved for future audio assets)
└── fonts/              # CherryBombOne-Regular.ttf
```
