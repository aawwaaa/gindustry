class_name ConsumerStateMachine
extends StateMachine

enum States{
    IDLE,
    PROCESS,
    FINISH,
}

@export var building: Building

@export var consumers: Array[Consumer] = []
@export var providers: Array[Provider] = []
@export var process_speed: float = 1
@export var total_progress: float = 1

var progress: float = 0

func _ready() -> void:
    set_consumers(consumers, providers)

func set_consumers(consumers: Array[Consumer], providers: Array[Provider]) -> void:
    handle_break()
    self.consumers = consumers
    self.providers = providers

func handle_break() -> void:
    if state == States.IDLE:
        return
    for consumer in consumers:
        consumer.process_break(building)
    for provider in providers:
        provider.process_break(building)
    progress = 0
    set_state(States.IDLE)

func get_base_effectity() -> float:
    return 1

func check_begin() -> bool:
    if consumers.size() == 0: return false
    for consumer in consumers:
        if not consumer.should_begin(building):
            return false
    for provider in providers:
        if not provider.should_begin(building):
            return false
    return true

func get_effectity(delta: float) -> float:
    var effectity = get_base_effectity()
    for consumer in consumers:
        effectity = minf(effectity, consumer.get_effectity(building, delta))
    for provider in providers:
        effectity = minf(effectity, provider.get_effectity(building, delta))
    return effectity

func _get_next_state(state: States, delta: float) -> int:
    match state:
        States.IDLE:
            if check_begin():
                for consumer in consumers:
                    consumer.process_begin(building)
                for provider in providers:
                    provider.process_begin(building)
                return States.PROCESS

        States.PROCESS:
            var effectity = get_effectity(delta)
            for consumer in consumers:
                consumer.process_update(building, delta, effectity)
            for provider in providers:
                provider.process_update(building, delta, effectity)
            progress += effectity * process_speed * delta
            if progress >= total_progress:
                return States.FINISH

        States.FINISH:
            for consumer in consumers:
                consumer.process_finish(building)
            for provider in providers:
                provider.process_finish(building)
            progress = 0
            return States.IDLE

    return KEEP_CURRENT_STATE

