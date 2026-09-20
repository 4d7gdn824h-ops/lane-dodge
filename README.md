# Lane Dodge

Day-1 mobile MVP: a 3-lane endless dodge game. Shapes and colors only — no accounts, shop, story, or store submission.

## Play in the browser

**Live demo:** https://4d7gdn824h-ops.github.io/lane-dodge/

Open that URL on a phone or desktop. Godot export templates are not required for the web build; `docs/` is a Canvas/JS port of the same day-1 loop.

## How to play

- **Tap / click** the left half of the screen to move one lane left.
- **Tap / click** the right half to move one lane right.
- Keyboard: **A / Left** and **D / Right**.
- Dodge the red diamonds. Speed and density increase over time.
- A hit ends the run. The overlay shows your score and best score. Press **Restart**.
- **II** (or **Esc** / **P**) opens a pause stub. **Settings** is an empty stub.

Best score is stored in `localStorage` on web (`lane_dodge_best_score`). The Godot build still uses `user://lane_dodge.cfg`.

## Godot project

The original **Godot 4** project lives on branch `cursor/lane-dodge-mvp-d8c2` (`project.godot`, `scenes/`, `scripts/`). This web build ports that same day-1 loop.

## Project layout

```
docs/index.html        # GitHub Pages entry (playable Canvas/JS game)
docs/game.js           # Loop, spawn, collision, score
docs/styles.css        # Portrait HUD overlays
tests/game.test.js     # Node checks for formulas and input
```

Portrait viewport is 720×1280. The web build letterboxes to keep that aspect.

## Out of scope (Day 1)

No App Store / Apple signing, ads, IAP, accounts, or export-store setup. Those can stay future stubs.
