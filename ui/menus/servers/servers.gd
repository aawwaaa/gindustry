extends LayerWindow

func _on_create_pressed() -> void:
    Vars.server.create_server(int(%CreatePort.text))

func _on_join_pressed() -> void:
    Vars.client.connect_to(%Host.text, int(%Port.text))
