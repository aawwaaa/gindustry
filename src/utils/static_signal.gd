class_name StaticSignal
extends RefCounted

signal emited(args: Array[Variant])

func connect_to(callable: Callable) -> void:
    emited.connect(func(args): callable.callv(args))

func emit(args: Array[Variant]) -> void:
    emited.emit(args)
