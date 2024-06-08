class_name EntityComponent
extends Node

static var NAME: StringName:
    get = _get_default_component_name_static

var entity: Entity
var component_name: StringName
var component_id: int = -1

var parent_component: EntityComponent
var child_components: Array[EntityComponent] = []

func init(ent: Entity, comp_name: StringName = _get_default_component_name(), \
        parent_comp: EntityComponent = null) -> void:
    entity = ent
    component_name = comp_name
    parent_component = parent_comp

    name = comp_name
    if component_id == -1:
        component_id = comp_name.hash()
    ent.add_child(self)
    if parent_comp: parent_comp.add_child_component(self)

static func _get_default_component_name_static() -> StringName:
    return &"EntityComponent"
func _get_default_component_name() -> StringName:
    return &"EntityComponent"

func add_child_component(comp: EntityComponent) -> void:
    child_components.append(comp)
    comp.parent_component = self

func sync(method: StringName, args: Array[Variant]) -> void:
    Vars.server.sync_node(self, method, args)

func _load_data(_stream: Stream) -> Error:
    return OK
func load_data(stream: Stream) -> Error: return _load_data(stream)

func _save_data(_stream: Stream) -> void:
    pass
func save_data(stream: Stream) -> void: _save_data(stream)

func _component_init() -> void:
    pass

func _component_deinit() -> void:
    pass
