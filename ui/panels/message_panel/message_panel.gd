class_name MessagePanel
extends CanvasLayer

signal message_added(message: String, node: MessagePanel_Message)
signal prompt_changed(prompt: String)
signal submit(message: String)
signal request_auto_complete(message: String)

static var scene: PackedScene = load("res://ui/panels/message_panel/message_panel.tscn")

@export var max_messages = 200
@export var max_histories = 50
@export var auto_complete_allowed: bool = false

var messages: Array[MessagePanel_Message] = []
var histories: Array[String] = []
var history_index = -2

var showing: bool = false

func _ready() -> void:
    %AutoComplete.visible = auto_complete_allowed
    hide_input()

func add_message(message: String) -> void:
    var node = MessagePanel_Message.scene.instantiate()
    %Messages.add_child(node)
    node.set_message(message)
    node.show_short_time()
    if showing: node.show_message()
    messages.push_front(node)
    if messages.size() > max_messages:
        var to_remove = messages.pop_back()
        to_remove.queue_free()
    message_added.emit(message, node)
    var vscroll = %MessagesScroll.get_v_scroll_bar()
    await get_tree().process_frame
    vscroll.value = vscroll.max_value

func set_input(message: String) -> void:
    %Text.text = message
    add_history(message)

func _on_confirm_pressed() -> void:
    add_history(%Text.text)
    submit.emit(%Text.text)
    %Text.text = ""
    history_index = -2
    hide_input()

func _on_prev_pressed() -> void:
    if history_index >= histories.size() - 1:
        return
    if history_index == -2:
        history_index = -1
    history_index += 1
    %Text.text = histories[history_index]

func _on_next_pressed() -> void:
    if history_index < 0:
        return
    if history_index == 0:
        history_index = -2
        %Text.text = ""
        return
    history_index -= 1
    %Text.text = histories[history_index]

func _on_auto_complete_pressed() -> void:
    request_auto_complete.emit(%Text.text)

func add_history(message: String, repeat_check = true) -> void:
    if repeat_check and histories.size() > 0 and histories[0] == message:
        return
    histories.push_front(message)
    history_index = -1
    if histories.size() > max_histories:
        histories.pop_back()

func _on_text_text_changed(new_text:String) -> void:
    if history_index != -1:
        add_history(new_text, false)
        history_index = -1
    if histories.size() <= 0:
        histories.push_front(new_text)
    histories[0] = new_text

func _on_text_text_submitted(_new_text:String) -> void:
    _on_confirm_pressed()

func set_prompt(prompt: String) -> void:
    %Prompt.text = prompt
    prompt_changed.emit(prompt)

func show_input() -> void:
    if showing: return
    showing = true
    %InputPanel.show()
    for message in messages:
        message.show_message()
    %MessagesScroll.mouse_filter = Control.MOUSE_FILTER_PASS

func hide_input() -> void:
    if not showing: return
    showing = false
    %InputPanel.hide()
    for message in messages:
        message.hide_message()
    %MessagesScroll.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_text_gui_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_up"):
        _on_prev_pressed()
        get_viewport().set_input_as_handled()
    if event.is_action_pressed("ui_down"):
        _on_next_pressed()
        get_viewport().set_input_as_handled()
    if event.is_action_pressed("ui_text_completion_replace") and auto_complete_allowed:
        _on_auto_complete_pressed()
        get_viewport().set_input_as_handled()
    if event.is_action_pressed("ui_cancel"):
        hide_input()
        get_viewport().set_input_as_handled()
