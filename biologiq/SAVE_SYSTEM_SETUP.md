# Save system setup

The save system is already wired into this project:

- `Scripts/save_manager.gd` is registered as the `SaveManager` Autoload in `project.godot`.
- `Scenes/save_select_screen.tscn` contains the centered selector UI and binds **New Save**, **Upload Save**, and **Next**, plus the status label and uploaded-save remove button.
- **New Save** creates slot 1 and opens `Scenes/employee_orientation.tscn` for onboarding and study program selection. **Next** loads a valid slot and opens `Scenes/main_map.tscn`.
- After upload, **Upload Save** is disabled and the adjacent × removes that uploaded slot so another file can be chosen. **Next** continues to the map.
- The selector is reached from the existing Story Mode button in `Scenes/select_screen.tscn`.

To add the same system to another project, copy `Scripts/save_manager.gd` and add it through **Project > Project Settings > Globals > Autoload**. Choose the script, set the node name to `SaveManager`, and enable it. Copy the existing save selector scene and controller, or add the same named controls before using the controller. Its status messages are written to `StatusLabel`.

## Connect RPG state

The current Biologiq project has no RPG player, inventory, quest, or world-state scripts. The manager supplies the requested schema and default values, but the game must connect its runtime state to the manager for real character progress to persist. Register a node that implements these two methods:

```gdscript
func capture_save_state() -> Dictionary:
	return {
		"player": {
			"level": int(player.level),
			"hp": int(player.hp),
			"mp": int(player.mp),
			"stats": player.stats,
			"position": player.global_position,
		},
		"inventory": inventory.to_save_data(),
		"active_quests": quests.active_ids,
		"completed_quests": quests.completed_ids,
		"world_flags": world.flags,
	}

func restore_save_state(data: Dictionary) -> void:
	var player_data: Dictionary = data["player"]
	player.level = int(player_data["level"])
	player.hp = int(player_data["hp"])
	player.mp = int(player_data["mp"])
	player.stats = player_data["stats"]
	player.global_position = player_data["position"]
	inventory.load_save_data(data["inventory"])
	quests.load_save_data(data["active_quests"], data["completed_quests"])
	world.flags = data["world_flags"]
```

Then call `SaveManager.register_state_provider(self)` from the provider's `_ready()`. Replace the example property names and adapter calls with the actual RPG systems. The provider is autosaved every 120 seconds once a slot exists; `SaveManager.create_new_save()` creates slot 1, and Next restores slot 1 through `restore_save_state()` before entering the map.

## Storage and browser transfer

Local saves use `user://slot_1.sav`, which Godot maps to its browser virtual filesystem backed by IndexedDB in Web exports. GitHub Pages must serve the export over HTTPS. Browser storage can be cleared by the player or unavailable in private browsing, so encrypted file upload remains available as a portable restore path. The browser must permit IndexedDB for local persistence.

The pause menu's **Save game** button captures the current map position, study program, degree status, inventory, and the rest of the save state. It writes the encrypted local slot and, in Web builds, downloads the same `.sav` file accepted by **Upload Save**. Native builds save locally. The upload picker accepts `.sav` and `.json` filenames, but plain JSON is rejected: only a valid encrypted save using this build's format key can replace slot 1. Imported data is parsed and schema-checked before it is applied and saved.

`SAVE_PASSWORD` in `Scripts/save_manager.gd` is the password used by Godot's encrypted `FileAccess`. It keeps save contents out of plaintext and discourages casual inspection, but a password embedded in a client-side game is recoverable from the published build. This is not strong confidentiality or tamper-proof storage. If changing the key, keep it consistent across every build that must share save files; old saves cannot be decrypted with a different key.
