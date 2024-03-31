class_name BuildPlan
extends RefCounted

var world_id: int
var world: World:
    get: return Game.get_world_or_null(world_id)
    set(v): world_id = v.world_id if v else 0
var position: Vector2i
var rotation: int

var breaking: bool = false
var preview_name: String = ""

var building_type_index: int
var building_type: BuildingType:
    get: return Contents.get_content_by_index(building_type_index)
    set(v): building_type_index = v.index if v else 0
var building_config: Variant = null

# locals
var check_passed: bool = true
var building: bool = false
var build_progress: float = 0
var build_finished: bool = false

static func load_from(stream: Stream) -> BuildPlan:
    var plan = BuildPlan.new()
    plan.world_id = stream.get_32()
    plan.position = stream.get_var()
    plan.rotation = stream.get_8()
    plan.breaking = stream.get_8() == 1
    plan.building_type_index = stream.get_64()
    plan.building_config = plan.building_type.load_config(stream) if plan.building_type else null
    plan.preview_name = stream.get_string()
    return plan

func save_to(stream: Stream) -> void:
    stream.store_32(world_id)
    stream.store_var(position, true)
    stream.store_8(rotation)
    stream.store_8(1 if breaking else 0)
    stream.store_64(building_type_index)
    if building_type: building_type.save_config(building_config, stream)
    stream.store_string(preview_name)

