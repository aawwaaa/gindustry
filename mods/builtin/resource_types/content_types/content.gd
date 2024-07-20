extends ContentType

func _data() -> void:
    super._data()
    id = "content"

func _assign() -> void:
    super._assign()
    ContentType.CONTENT = self
