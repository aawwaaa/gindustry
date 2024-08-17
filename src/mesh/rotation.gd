class_name Rotation
extends Object

## default facing: `Vector3i.FORWARD`
## default rotation: `0`, up

static var FORWARD_UP = Rotation.new(Vector3i.FORWARD, 0, Basis.IDENTITY)
static var FORWARD_RIGHT = Rotation.new(Vector3i.FORWARD, 1, Basis.IDENTITY)
static var FORWARD_DOWN = Rotation.new(Vector3i.FORWARD, 2, Basis.IDENTITY)
static var FORWARD_LEFT = Rotation.new(Vector3i.FORWARD, 3, Basis.IDENTITY)

static var RIGHT_UP = Rotation.new(Vector3i.RIGHT, 0, \
        Basis.IDENTITY.rotated(Vector3i.UP, TAU * 0.25))
static var RIGHT_RIGHT = Rotation.new(Vector3i.RIGHT, 1, \
        Basis.IDENTITY.rotated(Vector3i.UP, TAU * 0.25))
static var RIGHT_DOWN = Rotation.new(Vector3i.RIGHT, 2, \
        Basis.IDENTITY.rotated(Vector3i.UP, TAU * 0.25))
static var RIGHT_LEFT = Rotation.new(Vector3i.RIGHT, 3, \
        Basis.IDENTITY.rotated(Vector3i.UP, TAU * 0.25))

static var BACK_UP = Rotation.new(Vector3i.BACK, 0, \
        Basis.IDENTITY.rotated(Vector3i.UP, TAU * 0.5))
static var BACK_RIGHT = Rotation.new(Vector3i.BACK, 1, \
        Basis.IDENTITY.rotated(Vector3i.UP, TAU * 0.5))
static var BACK_DOWN = Rotation.new(Vector3i.BACK, 2, \
        Basis.IDENTITY.rotated(Vector3i.UP, TAU * 0.5))
static var BACK_LEFT = Rotation.new(Vector3i.BACK, 3, \
        Basis.IDENTITY.rotated(Vector3i.UP, TAU * 0.5))

static var LEFT_UP = Rotation.new(Vector3i.LEFT, 0, \
        Basis.IDENTITY.rotated(Vector3i.UP, TAU * 0.75))
static var LEFT_RIGHT = Rotation.new(Vector3i.LEFT, 1, \
        Basis.IDENTITY.rotated(Vector3i.UP, TAU * 0.75))
static var LEFT_DOWN = Rotation.new(Vector3i.LEFT, 2, \
        Basis.IDENTITY.rotated(Vector3i.UP, TAU * 0.75))
static var LEFT_LEFT = Rotation.new(Vector3i.LEFT, 3, \
        Basis.IDENTITY.rotated(Vector3i.UP, TAU * 0.75))

static var UP_BACK = Rotation.new(Vector3i.UP, 0, \
        Basis.IDENTITY.rotated(Vector3i.RIGHT, TAU * 0.75))
static var UP_RIGHT = Rotation.new(Vector3i.UP, 1, \
        Basis.IDENTITY.rotated(Vector3i.RIGHT, TAU * 0.75))
static var UP_FORWARD = Rotation.new(Vector3i.UP, 2, \
        Basis.IDENTITY.rotated(Vector3i.RIGHT, TAU * 0.75))
static var UP_LEFT = Rotation.new(Vector3i.UP, 3, \
        Basis.IDENTITY.rotated(Vector3i.RIGHT, TAU * 0.75))

static var DOWN_FORWARD = Rotation.new(Vector3i.DOWN, 0, \
        Basis.IDENTITY.rotated(Vector3i.RIGHT, TAU * 0.25))
static var DOWN_RIGHT = Rotation.new(Vector3i.DOWN, 1, \
        Basis.IDENTITY.rotated(Vector3i.RIGHT, TAU * 0.25))
static var DOWN_BACK = Rotation.new(Vector3i.DOWN, 2, \
        Basis.IDENTITY.rotated(Vector3i.RIGHT, TAU * 0.25))
static var DOWN_LEFT = Rotation.new(Vector3i.DOWN, 3, \
        Basis.IDENTITY.rotated(Vector3i.RIGHT, TAU * 0.25))

static var values_dict: Dictionary

enum Turn{
    LEFT, RIGHT, UP, DOWN, CLOCKWISE, COUNTERCLOCKWISE
}

var facing: Vector3
var rotation: int
var rotation_around_facing: float

var basis: Basis

func _init(f: Vector3i, r: int, b: Basis) -> void:
    facing = f
    rotation = r
    rotation_around_facing = r * TAU * 0.25

    basis = b
    b = b.rotated(Vector3(f), rotation_around_facing)

    if not values_dict.has(facing): values_dict[facing] = {}
    values_dict[facing][rotation] = self

func turned(turn: Turn) -> Rotation:
    match turn:
        Turn.LEFT:
            return values_dict[Vector3i(Vector3(facing).rotated(Vector3.UP, TAU * 0.25).round())] \
                    [rotation]
        Turn.RIGHT:
            return values_dict[Vector3i(Vector3(facing).rotated(Vector3.UP, TAU * -0.25).round())] \
                    [rotation]
        Turn.UP:
            return values_dict[Vector3i(Vector3(facing).rotated(Vector3.RIGHT, TAU * 0.25).round())] \
                    [rotation]
        Turn.DOWN:
            return values_dict[Vector3i(Vector3(facing).rotated(Vector3.RIGHT, TAU * -0.25).round())] \
                    [rotation]
        Turn.CLOCKWISE:
            return values_dict[facing][(rotation + 1) % 4]
        Turn.COUNTERCLOCKWISE:
            return values_dict[facing][(rotation - 1) % 4]
    return null

