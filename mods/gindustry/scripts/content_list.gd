extends Node

const collision_type_ground = {
    "collision_type": "ground"
}

const collision_type_water = {
    "collision_type": "water"
}

const collision_type_space = {
    "collision_type": "space"
}

const collision_type_none = {
    "collision_type": "none"
}

const items = {
    # row 1
    "copper": ["test_item", {
        "floor_type": "gindustry_floor_stone"
    }],
    "lead": ["item"],
    "scrap": ["item"],
    "coal": ["item"],
    "sand": ["item"],
    "titanium": ["item"],
    "thorium": ["item"],
    "graphite": ["item"],
    # row 2
    "glass": ["item"],
    "motor": ["item"],
    "silicon": ["item"],
    "chip": ["item"],
    "titanium_thorium_alloy": ["item"],
    "copper_lead_alloy": ["item"],
    "graphite_grid": ["item"],
    "advanced_processor": ["item"],
    # row 3
    "plasma_generator": ["item"],
    "_2": ["skip"],
    "_3": ["skip"],
    "_4": ["skip"],
    "_5": ["skip"],
    "_6": ["skip"],
    "_7": ["skip"],
    "_8": ["skip"],
}

const floors = {
    # row 1
    "grass": ["floor", collision_type_ground],
    "stone": ["floor", collision_type_ground],
    "water": ["floor", collision_type_water],
    "sand": ["floor", collision_type_ground],
    "mud": ["floor", collision_type_ground],
    "space": ["floor", collision_type_space],
    "metrial_1": ["floor", collision_type_ground],
    "metrial_2": ["floor", collision_type_ground],
}

const overlays = {
    # row 1
    "ore_copper": ["overlay", collision_type_none],
    "ore_lead": ["overlay", collision_type_none],
    "ore_titanium": ["overlay", collision_type_none],
    "ore_thorium": ["overlay", collision_type_none],
    "ore_coal": ["overlay", collision_type_none],
    "ore_stone": ["overlay", collision_type_none],
}

const buildings: Array[String] = [
    "/test/building.tres"
]

const entities: Array[String] = [
    "/player/entity.tres",
    "/test_entity_1/entity.tres",
]

const presets: Array[String] = [
    "/test/preset.tres",
]

const translations: Array[String] = [
    "/zh.po",
]
