extends Resource
class_name ModifierPack

enum StackingMode { REFRESH, STACK, IGNORE }

@export var id: String                          # "water_bucket_basic"
@export var duration_sec: float = 10.0
@export var stacking: StackingMode = StackingMode.REFRESH        # "refresh"|"stack"|"ignore"
@export var mods: Array[StatModifier] = []      # list StatModpass
