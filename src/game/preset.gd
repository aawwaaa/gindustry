class_name Preset
extends ResourceType

## Preset

## Resource type of Preset
const TYPE = preload("res://contents/resource_types/preset.tres")

func _get_type() -> ResourceType:
    return TYPE

## Show description in new_game menu
## Call when be selected in new_game menu
func _show_description(_node: ScrollContainer) -> void:
    pass

## Call when clicked "confirm" in new_game menu
## It will be await to wait for user input
## When returns true, it will continue load preset
## When returns false, it will back to new_game menu
func _pre_config_preset() -> bool:
    return true

## Call when preset is loaded to create a new game, before _enable_preset
## Check and assign default value of preset's data
func _pre_init_preset() -> void:
    pass

## Call when preset is loaded to create a new game, after _enable_preset
## Do world operations in this method
func _init_preset() -> void:
    pass

## Call when preset is loaded to create a new game, after join_local
## Vars.game.player is available when in a client
func _init_after_local_player_join() -> void:
    pass

## Call when world is ready, after _apply_preset
func _load_after_world_load() -> void:
    pass

## Call when game ready
func _after_ready() -> void:
    pass

## Call when preset is enabled, after _init_preset(if runned), before _load_after_world_load
func _apply_preset() -> void:
    pass

## Call when game reset
## Reset datas of preset in this method
## Free objects in this method
func _reset_preset() -> void:
    pass

## Get the translation name of preset, will be as argument to `tr`
func get_tr_name() -> String:
    return Content.to_full_id(mod.mod_info.id, name, "preset")

## Call when preset is loaded, after _load_preset_data
## Datas of preset is ready
## Enable preset in this method
func _enable_preset() -> void:
    pass

## Call when game reset, before _reset_preset
## Disable preset in this method
func _disable_preset() -> void:
    pass

## Call when game load
## Load preset data in this method
func _load_preset_data(_stream: Stream) -> Error:
    return OK

## Call when game save
## Save preset data in this method
func _save_preset_data(_stream: Stream) -> void:
    pass

"""
pre_config -> true -> enable -> init -> load -> ...
           -> false -> back_to_menu
load_preset_data -> enable -> load -> ...
... -> save_preset_data -> ... -> disable_preset

"""
