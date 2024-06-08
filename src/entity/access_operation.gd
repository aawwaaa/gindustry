class_name AccessOperation

func _init(_deleted: AccessOperation) -> void:
    push_error("Constructor deleted!")

class AccessSource extends RefCounted:
    func get_object() -> Variant: return null
    func is_type(_type: StringName) -> bool: return false
    func as_type(_type: StringName) -> Variant: return null

class EntityAccessSource extends AccessSource:
    var entity: Entity
    func _init(e: Entity) -> void: entity = e
    func get_object() -> Variant: return entity
    func is_type(type: StringName) -> bool: return \
            true if type == Entity.TYPE_ID else \
            true if entity.has_component(type) else \
            false
    func as_type(type: StringName) -> Variant: return \
            entity if type == Entity.TYPE_ID else \
            entity.get_component(type) if entity.has_component(type) else \
            null

class EntityComponentAccessSource extends AccessSource:
    var entity_component: EntityComponent
    func _init(e: EntityComponent) -> void: entity_component = e
    func get_object() -> Variant: return entity_component
    func is_type(type: StringName) -> bool: return \
            true if type == Entity.TYPE_ID else\
            true if type == EntityComponent.NAME else \
            true if type == entity_component._get_default_component_name() else \
            false
    @warning_ignore("incompatible_ternary")
    func as_type(type: StringName) -> Variant: return \
            entity_component.entity if type == Entity.TYPE_ID else \
            entity_component if type == EntityComponent.NAME else \
            entity_component if type == entity_component._get_default_component_name() else \
            null

static func handle_access(source: AccessSource, target: Variant, method: StringName, args: Array[Variant]) -> void:
    if not target._check_access(source, method, args): return
    target._handle_access(source, method, args)
