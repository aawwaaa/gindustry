class_name MessagePanel
extends CanvasLayer

signal message_added(message: String, node: MessagePanel_Text)
signal prompt_changed(prompt: String)
signal submit(message: String)

@export var max_messages = 200
@export var max_histories = 50

var messages: Array[MessagePanel_Text] = []
var histories: Array[MessagePanel_Text] = []
var history_index = -1

func add_message(message: String) -> void:
    var node = MessagePanel_Text.scene.instantiate()
    node.set_text(message)
    %Messages.add_child(node)
    node.show_short_time()
    messages.push_front(node)
    if messages.size() > max_messages:
        var to_remove = messages.pop_back()
        to_remove.queue_free()
    message_added.emit(message, node)

func _on_confirm_pressed() -> void:
    pass

func _on_prev_pressed() -> void:
    pass

func _on_next_pressed() -> void:
    pass

