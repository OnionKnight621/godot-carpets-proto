# Repository Guidelines

## Project Structure & Module Organization
- `project.godot` targets Godot 4.5; open the project via `res://` paths.
- Gameplay scenes live in `scenes/`, grouped by feature (`scenes/Levels`, `scenes/UI`, etc.); keep paired scripts alongside their scene.
- Autoload singletons in `globals/` (e.g. `game_state.gd`) store persistent run data—update the Autoload list when adding new managers.
- Data-driven resources reside in `resources/`; commit both `.tres` files and their `.uid` companions.
- Narrative assets sit under `Dialogues/`, and art/shaders are organised in `graphics/` and `shaders/`.
- Third-party helpers live in `addons/`; test editor tooling after upgrading or adding plugins.

## Build, Test, and Development Commands
- `godot4 --editor --path .` opens the editor with this project.
- `godot4 --path .` launches the configured main scene (`TransitionLayer` intro flow by default).
- `godot4 --path . scenes/Hub/hub.tscn` runs a specific scene for feature-focused testing.
- Use the Dialogue Manager panels to reimport `.dialogue` files after edits.

## Coding Style & Naming Conventions
- GDScript 4 scripts use tab indentation, snake_case filenames, and `PascalCase` class names (`class_name GameState`).
- Signals, exports, and functions stay in lower_snake_case; constants stay in UPPER_SNAKE.
- Keep preload paths relative to `res://` and emit explicit signals when global state changes.
- Add short comments or docstrings only where intent is non-obvious (complex transitions, resource mutations).

## Testing Guidelines
- There is no automated suite yet; perform manual passes via `godot4 --path .` and exercise hub, level, and intro scenes.
- Verify autoload behaviour by restarting runs and checking `GameState`/`RunState` signal emissions.
- When adding systems, supply reproduction steps or checklists in PR descriptions; attach save files if needed.

## Commit & Pull Request Guidelines
- Follow the existing convention `<type>: <concise summary>` (`feat: intro scene + transition layer`, `upd: shmol tweaks`).
- Scope commits to one behaviour change; include relevant `.tscn`, `.gd`, and `.tres` assets in the same commit.
- PRs should outline gameplay impact, reference related issues, and include test steps or screenshots for UI-facing work.
