# Carpet Cleaner Clicker — Project Overview (updated)

> A meditative clicker with rogue-lite elements in a dark fantasy setting: you are a member of the Guild of Carpet Cleaners. Every run serves a different carpet, dirt layer stack, and set of tools or buffs.

---

## 1) Status Snapshot

* **Engine:** Godot 4.5 (Forward+ renderer, `project.godot`).
* **Loop:** MainMenu → **Hub** → LevelBase (cleaning) → perk selection → **Hub** → next carpet.
* **Autoloads:** `globals/game_state.gd` (meta progression) + `globals/run_state.gd` (current run, exclusive drag management).
* **Procedural dirt:** multi-layer grid generation bounded by the carpet collision; top-of-cell mechanic governs what can be cleaned.
* **Tools:** multiple tools with exclusive drag control; cursor speed converts into a damage multiplier.
* **Damage channels:** `mech / fluid / solvent / holy / occult` balanced against dirt layer resistances.
* **Data-driven:** `.tres` resources define carpets, dirt layers, modifier packs, and buffs.
* **FX/UX:** foam appears only while cleaning; outline shader handles hover/buff feedback; fades handled by scenes in `scenes/TransitionScreens`.

---

## 2) Scene Flow & Topology

```
MainMenu (CanvasLayer)
  └─ TransitionLayer (CanvasLayer)        # global fade, change_scene_packed
  └─ IntroDialogueTransition              # smooth intro dialogue handoff
  └─ Hub (Node2D)                         # guild room staging area
	  ├─ Room (Sprite2D)                  # background plate
	  ├─ CarpetArea (Area2D)              # interactive carpet (hover → outline, click → Level)
	  ├─ NPC / Interaction stubs          # future upgrade/quest anchor points
	  └─ Buff spawners (e.g., bucket)

LevelBase / LevelTest (PackedScene)
  ├─ CarpetRoot → DirtyCarpetBase         # primary dirt logic
  ├─ ToolsLocations/Marker2D[*]           # spawn slots for tools
  ├─ ToolBase instances                   # active tools
  └─ HUD (progress bar, hints)
```

*Tip:* keep `.gd` scripts next to their corresponding `.tscn` scenes for faster navigation.

---

## 3) Core Systems (code tour)

### 3.1 Run & Meta State

`globals/run_state.gd` manages seeds (not implemented yet), the active tool, and run-wide progress (`run_started`, `progress_change` signals). `globals/game_state.gd` holds meta currency and unlocked tools (not implemented yet); update the Autoloads list when introducing new managers.

### 3.2 Dirty Carpet & Dirt Stack

`scenes/Carpets/dirty_carpet_base.tscn` + `DirtyCarpetBase.gd` build the layered grid, track chunk state, and compute progress. The algorithm follows the carpet collision and supports varied `tile_px`, `tile_scale`, `density`, `hp`, and `resist_*` values supplied by `DirtLayerData.tres` resources.

### 3.3 Tool Arsenal

`scenes/Tools/*` + `ToolBase.gd` share pickup behavior (root Area2D, child `HitArea`, drag follow). Cleaning effectiveness is derived from movement and damage channels:

```gdscript
var dot := mech*(1.0 - res_mech) + fluid*(1.0 - res_fluid) + solvent*(1.0 - res_solvent) + holy*(1.0 - res_holy) + occult*(1.0 - res_occult)
var effective := clean_power * move_factor * dot
```

Particles, foam, and SFX fire only when `effective > 0`.

### 3.4 Dialogue & Narrative Flow

`Dialogues/*.dialogue` assets plus `addons/dialogue_manager` drive the intro flow (`intro_dialogue_transition.tscn`). Re-import `.dialogue` files through the editor after editing text.

---

## 4) Buff System (new)

### 4.1 Data Model

`resources/stat_modifier.gd` defines a single modifier (`path`, `value`). `resources/modifier_pack.gd` groups modifiers, exposes `StackingMode { REFRESH, STACK, IGNORE }`, and stores `duration_sec`.

### 4.2 ToolBase Integration

* `_active_mods` tracks active packs with expiry timestamps.
* `_tick_mods()` (called in `_physics_process`) expires finished packs.
* `_rebuild_stat_cache()` applies additive and multiplicative modifiers in stages atop base stats.
* `apply_modifier_pack(pack, source="pickup")` succeeds only when `run_state.active_tool == self`.

### 4.3 BuffBase Scenes

`scenes/Buffs/buff_base.tscn/gd` exposes an Area2D that listens for `area_entered` and applies buffs only to the active tool:

```gdscript
if tool != run_state.active_tool:
	return
tool.apply_modifier_pack(modifier_pack, modifier_source)
```

Layer/mask guidance: buff layer → `"buff"`, mask → `"tool"`; ensure `ToolBase/HitArea` includes `"buff"` in its collision mask.

### 4.4 Example: Bucket of Water

* `resources/res_water_mul.tres` → `damage.fluid.mul = +0.3`.
* `resources/res_water_bucket_mods.tres` → modifier pack `water_bucket_basic`, `duration_sec = 10`, `stacking = REFRESH`.
* `scenes/Buffs/bucket_of_water.tscn` inherits BuffBase and references the pack.
* Tool outline shader `_update_buff_fx()` adjusts color/alpha based on remaining buff time.

---

## 5) Data Resources & Asset Pipeline

* `resources/CarpetData.tres` — links to `clean_carpet_scene`, `dirt_layers[]`, `difficulty`, and `tags`.
* `resources/DirtLayerData.tres` — grid parameters, atlas data, HP, resistances.
* Always commit `.tres` files with their `.uid` companions.
* `graphics/sprites/*` — categorized sprites (carpets, dirt, hub, tools) sharing consistent scale.
* `shaders/` — outline shader plus foam/FX materials.
* Add-ons in use: `dialogue_manager`, `copilot`, `godot-git-plugin` (test editor tooling after upgrades).

---

## 6) UX & Transitions

* **MainMenu → Hub:** `_on_start_btn_pressed()` in `main_menu.gd` calls `TransitionLayer.change_scene_packed(INTRO_SCENE)`.
* **Hub → Level:** clicking `CarpetArea` triggers fade-out and loads LevelBase with the selected carpet set.
* Hover outlines reuse the same shader between hub interactables and tools; future interactable props should hook in here.
* Foam/particle feedback activates only during actual cleaning to reduce visual noise.

---

## 7) Dev Workflow & Testing

* Launch the editor: `godot4 --editor --path .`
* Full gameplay loop: `godot4 --path .` (Intro → Hub → Level).
* Jump straight to the hub: `godot4 --path . scenes/Hub/hub.tscn`.
* Scene verification: open `LevelBase.tscn`, adjust `ToolsLocations` markers and `carpet_pool` arrays via the inspector.
* No automated tests yet; perform manual passes covering hub interactions, level cleaning, buff pickups, and dialogue flow.
* For reproducible QA, seed runs via `RunState.start_new_run(seed)` (temporary call or debug helper).

---

## 8) Performance & Tech Notes

* Smaller `tile_px` values drastically increase chunk counts—balance with `density` and `tile_scale`.
* Route all RNG through `RunState.rng` to keep runs deterministic.
* Do not scale the `ToolBase` root node; adjust sprites or child nodes to maintain correct hitboxes.
* Consider promoting `TransitionLayer` to an Autoload to avoid duplicated instances across scenes.

---

## 9) Roadmap (short)

1. **Layer content:** add new `DirtLayerData` variants (mud, grease, blood, curse, ash) with unique resist profiles.
2. **Buff variety:** area buffs that lower resistances (`ModifierPack` applied to `DirtChunk`), longer-lived run perks.
3. **Perk screen:** three-card post-level selection using global run-level modifier packs.
4. **HUD indicators:** buff icons and timers on tools and/or HUD.
5. **Persistence:** serialize run seeds, chosen tools, and global modifiers.
6. **Narrative beats:** additional hub dialogues via Dialogue Manager.

---

## 10) Glossary

* **tile_px** — pixel size of a grid cell.
* **tile_scale** — chunk size in cells (1 = 1×1, 2 = 2×2, ...).
* **chunk** — individual dirt segment (`DirtChunk`).
* **top-of-cell** — the uppermost chunk in a cell; only this can be cleaned.
* **HitArea** — child `Area2D` on a tool that interacts with dirt and buffs.
* **ModifierPack** — resource containing `StatModifier` entries that temporarily or permanently alter tool stats.

---

### Quick file anchors

* `main_menu.gd`
* `scenes/Hub/hub.tscn`
* `scenes/Levels/level_base.tscn`
* `globals/run_state.gd`, `globals/game_state.gd`
* `scenes/Carpets/dirty_carpet_base.tscn`, `DirtyCarpetBase.gd`
* `scenes/Tools/tool_base.gd` plus tool-specific scenes
* `resources/carpet_data.gd`, `resources/dirt_layer_data.gd`
* `resources/stat_modifier.gd`, `resources/modifier_pack.gd`
* `scenes/Buffs/buff_base.tscn`, `scenes/Buffs/bucket_of_water.tscn`
* `Dialogues/intro.dialogue`
* `shaders/outline_shader.tres` (and related FX)
