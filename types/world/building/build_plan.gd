class_name BuildPlan
extends RefCounted

var world_id: int
var world: World:
    get: return Game.get_world_or_null(world_id)
    set(v): world_id = v.world_id if v else 0
var pos: Vector2

var breaking: bool = false

var building_type_index: int
var building_type: BuildingType:
    get: return Contents.get_content_by_index(building_type_index)
    set(v): building_type_index = v.index if v else 0
var building_config: Variant

var check_passed: bool = true
var building: bool = false
var build_progress: float = 0
var build_finished: bool = false

func load_data(stream: Stream) -> void:
    pass

func save_data(stream: Stream) -> void:
    pass
