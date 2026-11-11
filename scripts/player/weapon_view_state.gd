extends RefCounted
class_name FRONTLINEWeaponViewState

## Кадровое состояние для визуала оружия. Заполняется игроком,
## читается PlayerWeaponView. Никаких Dictionary и строковых ключей.

var delta := 0.0
var aim_blend := 0.0
var aiming := false
var weapon_kick := 0.0
var look_sway := Vector2.ZERO
var bob_time := 0.0
var breathing_time := 0.0
var sprint_anim := 0.0
var landing_anim := 0.0
var stance := 0
var strafe_x := 0.0
var is_reloading := false
var reload_progress := 0.0
var allow_arms := true
var action_offset := Vector3.ZERO
var weapon_visible := true
