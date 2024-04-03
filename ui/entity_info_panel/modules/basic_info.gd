class_name BasicInfoModule
extends EntityInfoModule

# <icon> <name>

var entity_icon: TextureRect
var entity_name: Label

func create_nodes() -> void:
    entity_icon = TextureRect.new()
    entity_icon.custom_minimum_size = Vector2(32, 32)
    add_child(entity_icon)

    entity_name = Label.new()
    entity_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_child(entity_name)

func _load_module() -> void:
    create_nodes()
    entity_icon.texture = entity.get_icon()
    entity_name.text = entity.get_localized_name()
