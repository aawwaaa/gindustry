class_name AdapterUnit
extends Node2D

var entity: Entity;
var world: World:
    get: return entity.world
var adapter: EntityAdapter;
var adapter_unit_type: AdapterUnitType;

