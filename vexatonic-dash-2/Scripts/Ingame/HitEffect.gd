class_name HitEffect
extends Node2D

@export_category("Shape")
@export var flash_radius: float = 32.0
@export var ring_radius: float = 54.0
@export_range(0.1, 1.0, 0.01) var inner_ring_ratio: float = 0.62
@export var ring_width: float = 5.0

@export_category("Animation")
@export var effect_duration: float = 0.24
@export var start_scale: float = 0.35
@export var end_scale: float = 1.25

@export_category("Particles")
@export var base_particle_count: int = 14

@onready var sparks: GPUParticles2D = $Sparks

var effect_color: Color = Color.WHITE


func _ready() -> void:
	visible = false


func _draw() -> void:
	var flash_color := Color(effect_color, 0.55)
	var outer_color := Color(effect_color, 0.95)
	var inner_color := Color.WHITE

	draw_circle(Vector2.ZERO, flash_radius, flash_color)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 64, outer_color, ring_width, true)
	draw_arc(
		Vector2.ZERO,
		ring_radius * inner_ring_ratio,
		0.0,
		TAU,
		64,
		inner_color,
		maxf(1.0, ring_width * 0.45),
		true
	)


func play(color: Color, strength: float = 1.0) -> void:
	effect_color = color
	visible = true
	modulate = Color.WHITE
	queue_redraw()

	var clamped_strength := maxf(strength, 0.1)
	sparks.amount = maxi(1, roundi(base_particle_count * clamped_strength))
	sparks.modulate = effect_color
	sparks.emitting = true
	sparks.restart()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		self,
		"scale",
		Vector2.ONE * end_scale * clamped_strength,
		effect_duration
	).from(Vector2.ONE * start_scale).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		effect_duration * 0.75
	).set_delay(effect_duration * 0.25)

	var cleanup_delay := maxf(effect_duration, sparks.lifetime) + 0.06
	await get_tree().create_timer(cleanup_delay).timeout
	queue_free()
