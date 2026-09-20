# Lane Dodge

Day-1 mobile MVP: a 3-lane endless dodge game built in **Godot 4** (GDScript, 2D). Shapes and colors only — no accounts, shop, story, or store submission.

## How to open

1. Install [Godot 4.3+](https://godotengine.org/download) (4.7.x is fine).
2. Open the Godot Project Manager.
3. Choose **Import**, then select `project.godot` in this folder.
4. Open the project. The main scene is `scenes/main.tscn`.

## How to play

Press **F5** (or **Play**) in the editor.

- **Tap / click** the left half of the screen to move one lane left.
- **Tap / click** the right half to move one lane right.
- Keyboard: **A / Left** and **D / Right**.
- Dodge the red diamonds. Speed and density increase over time.
- A hit ends the run. The overlay shows your score and best score. Press **Restart**.
- **II** (or **Esc** / **P**) opens a pause stub. **Settings** is an empty stub.

Best score is saved locally in Godot user data (`user://lane_dodge.cfg`).

## Project layout

```
project.godot          # Godot 4 project
scenes/main.tscn       # Playable layout + HUD
scenes/player.tscn     # Cyan rounded marker
scenes/hazard.tscn     # Red diamond
scripts/               # Game loop, player, hazards, best score
docs/screenshots/      # Store-brief stills (see below)
```

The tap hint fades after the first steer or 2.5s, then stays hidden on later runs.

## Store stills

Exportable 720×1280 frames of the live scene (no extra art):

1. `docs/screenshots/01_title_start.png` — clean 3-lane field, tap hint, no HUD clutter
2. `docs/screenshots/02_mid_run.png` — player in lane, 1–2 hazards, score readable
3. `docs/screenshots/03_near_miss.png` — hazard just past the player
4. `docs/screenshots/04_game_over_best.png` — score + best + Restart (hero)
5. `docs/screenshots/05_pause_settings.png` — pause stub with Settings

Regenerate: `godot --path . -s res://tools/capture_store_stills.gd --resolution 720x1280`

Portrait viewport is 720×1280. The window stretch mode is `canvas_items` / `keep`, so it plays on a phone-shaped window or a desktop preview.

## Out of scope (Day 1)

No App Store / Apple signing, ads, IAP, accounts, or export-store setup. Those can stay future stubs.
