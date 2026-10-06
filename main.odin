package main

// BLEED ARENA
// ARENA, but every shot costs you health, and kills drop health orbs
// that you have to walk out and collect before they fade.

import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

// ---------------------------------------------------------------------------
// Tuning constants. Change these to rebalance the game.
// ---------------------------------------------------------------------------

SCREEN_W :: 960
SCREEN_H :: 640

ARENA_X :: 40
ARENA_Y :: 80
ARENA_W :: 880
ARENA_H :: 520

WIN_TIME :: 60.0 // seconds you must survive

MAX_HP        :: 100.0
PLAYER_R      :: 12.0
PLAYER_SPEED  :: 240.0
HURT_COOLDOWN :: 0.6 // invulnerability after being hit (seconds)

SHOT_COST    :: 2.0  // HP spent per bullet
FIRE_RATE    :: 0.16 // seconds between shots
BULLET_SPEED :: 620.0
BULLET_R     :: 4.0
BULLET_LIFE  :: 1.2

ORB_LIFE :: 5.0 // seconds before an orb fades away
ORB_R    :: 8.0

CHASER_HP     :: 2
CHASER_R      :: 15.0
CHASER_SPEED  :: 95.0
CHASER_DAMAGE :: 8.0
CHASER_HEAL   :: 6.0 // HP in the orb it drops

RUNNER_HP     :: 1
RUNNER_R      :: 9.0
RUNNER_SPEED  :: 190.0
RUNNER_DAMAGE :: 5.0
RUNNER_HEAL   :: 4.0

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

Phase :: enum {
	Playing,
	Won,
	Lost,
}

Enemy_Kind :: enum {
	Chaser,
	Runner,
}

Enemy :: struct {
	pos:    rl.Vector2,
	kind:   Enemy_Kind,
	hp:     int,
	radius: f32,
	speed:  f32,
}

Bullet :: struct {
	pos:  rl.Vector2,
	vel:  rl.Vector2,
	life: f32,
}

Orb :: struct {
	pos:  rl.Vector2,
	life: f32,
	heal: f32,
}

Game :: struct {
	phase:       Phase,
	player_pos:  rl.Vector2,
	hp:          f32,
	hurt_timer:  f32,
	fire_timer:  f32,
	time:        f32,
	spawn_timer: f32,
	kills:       int,
	enemies:     [dynamic]Enemy,
	bullets:     [dynamic]Bullet,
	orbs:        [dynamic]Orb,
}

g: Game

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

in_arena :: proc(p: rl.Vector2) -> bool {
	return p.x >= ARENA_X && p.x <= ARENA_X + ARENA_W && p.y >= ARENA_Y && p.y <= ARENA_Y + ARENA_H
}

clamp_to_arena :: proc(p: rl.Vector2, r: f32) -> rl.Vector2 {
	return {
		clamp(p.x, ARENA_X + r, ARENA_X + ARENA_W - r),
		clamp(p.y, ARENA_Y + r, ARENA_Y + ARENA_H - r),
	}
}

// A random point on the arena's edge (retries so it is not right on top of the player).
spawn_pos :: proc() -> rl.Vector2 {
	p: rl.Vector2
	for _ in 0 ..< 10 {
		side := rl.GetRandomValue(0, 3)
		fx := f32(rl.GetRandomValue(0, ARENA_W))
		fy := f32(rl.GetRandomValue(0, ARENA_H))
		switch side {
		case 0:
			p = {ARENA_X + fx, ARENA_Y}
		case 1:
			p = {ARENA_X + fx, ARENA_Y + ARENA_H}
		case 2:
			p = {ARENA_X, ARENA_Y + fy}
		case:
			p = {ARENA_X + ARENA_W, ARENA_Y + fy}
		}
		if linalg.distance(p, g.player_pos) > 220 {
			break
		}
	}
	return p
}

// ---------------------------------------------------------------------------
// Setup / reset
// ---------------------------------------------------------------------------

reset_game :: proc() {
	clear(&g.enemies)
	clear(&g.bullets)
	clear(&g.orbs)
	g.phase = .Playing
	g.player_pos = {ARENA_X + ARENA_W / 2, ARENA_Y + ARENA_H / 2}
	g.hp = MAX_HP
	g.hurt_timer = 0
	g.fire_timer = 0
	g.time = 0
	g.spawn_timer = 1.0
	g.kills = 0
}

spawn_enemy :: proc() {
	// Runners become more common as the round goes on.
	runner_chance := min(0.15 + g.time * 0.005, 0.5)
	// Everything also gets a little faster over time.
	speed_mult := 1.0 + g.time * 0.004

	e: Enemy
	e.pos = spawn_pos()
	if f32(rl.GetRandomValue(0, 100)) / 100.0 < runner_chance {
		e.kind = .Runner
		e.hp = RUNNER_HP
		e.radius = RUNNER_R
		e.speed = RUNNER_SPEED * speed_mult
	} else {
		e.kind = .Chaser
		e.hp = CHASER_HP
		e.radius = CHASER_R
		e.speed = CHASER_SPEED * speed_mult
	}
	append(&g.enemies, e)
}

// ---------------------------------------------------------------------------
// Update
// ---------------------------------------------------------------------------

update :: proc(dt: f32) {
	g.time += dt
	if g.time >= WIN_TIME {
		g.phase = .Won
		return
	}

	// --- player movement ---
	move: rl.Vector2
	if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP) {move.y -= 1}
	if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN) {move.y += 1}
	if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT) {move.x -= 1}
	if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) {move.x += 1}
	move = linalg.normalize0(move)
	g.player_pos += move * PLAYER_SPEED * dt
	g.player_pos = clamp_to_arena(g.player_pos, PLAYER_R)

	g.hurt_timer = max(g.hurt_timer - dt, 0)

	// --- shooting: every bullet costs HP ---
	g.fire_timer -= dt
	// You may never shoot yourself to death: you need more than SHOT_COST + 1 HP.
	if rl.IsMouseButtonDown(.LEFT) && g.fire_timer <= 0 && g.hp > SHOT_COST + 1 {
		aim := linalg.normalize0(rl.GetMousePosition() - g.player_pos)
		append(
			&g.bullets,
			Bullet{pos = g.player_pos + aim * PLAYER_R, vel = aim * BULLET_SPEED, life = BULLET_LIFE},
		)
		g.hp -= SHOT_COST
		g.fire_timer = FIRE_RATE
	}

	// --- spawning ---
	g.spawn_timer -= dt
	if g.spawn_timer <= 0 {
		spawn_enemy()
		// The gap between spawns shrinks over time, down to a minimum.
		g.spawn_timer = max(0.35, 1.2 - g.time * 0.012)
	}

	// --- enemies chase the player ---
	for &e in g.enemies {
		dir := linalg.normalize0(g.player_pos - e.pos)
		e.pos += dir * e.speed * dt
	}

	// --- bullets: move, expire, hit enemies (loop backwards so removal is safe) ---
	bi := len(g.bullets) - 1
	for bi >= 0 {
		b := &g.bullets[bi]
		b.pos += b.vel * dt
		b.life -= dt
		remove := b.life <= 0 || !in_arena(b.pos)

		if !remove {
			for ei := len(g.enemies) - 1; ei >= 0; ei -= 1 {
				e := &g.enemies[ei]
				if linalg.distance(b.pos, e.pos) < e.radius + BULLET_R {
					e.hp -= 1
					remove = true
					if e.hp <= 0 {
						heal: f32 = e.kind == .Chaser ? CHASER_HEAL : RUNNER_HEAL
						append(&g.orbs, Orb{pos = e.pos, life = ORB_LIFE, heal = heal})
						g.kills += 1
						unordered_remove(&g.enemies, ei)
					}
					break
				}
			}
		}

		if remove {
			unordered_remove(&g.bullets, bi)
		}
		bi -= 1
	}

	// --- enemies touching the player ---
	if g.hurt_timer <= 0 {
		for e in g.enemies {
			if linalg.distance(e.pos, g.player_pos) < e.radius + PLAYER_R {
				g.hp -= e.kind == .Chaser ? CHASER_DAMAGE : RUNNER_DAMAGE
				g.hurt_timer = HURT_COOLDOWN
				break
			}
		}
	}

	// --- orbs: fade out, or get collected ---
	oi := len(g.orbs) - 1
	for oi >= 0 {
		o := &g.orbs[oi]
		o.life -= dt
		if o.life <= 0 {
			unordered_remove(&g.orbs, oi)
		} else if linalg.distance(o.pos, g.player_pos) < PLAYER_R + ORB_R + 6 {
			g.hp = min(g.hp + o.heal, MAX_HP)
			unordered_remove(&g.orbs, oi)
		}
		oi -= 1
	}

	if g.hp <= 0 {
		g.hp = 0
		g.phase = .Lost
	}
}

// ---------------------------------------------------------------------------
// Draw
// ---------------------------------------------------------------------------

draw_centered :: proc(text: cstring, y: i32, size: i32, color: rl.Color) {
	w := rl.MeasureText(text, size)
	rl.DrawText(text, (SCREEN_W - w) / 2, y, size, color)
}

draw :: proc() {
	rl.ClearBackground({18, 18, 24, 255})

	// arena
	rl.DrawRectangle(ARENA_X, ARENA_Y, ARENA_W, ARENA_H, {28, 28, 38, 255})
	rl.DrawRectangleLinesEx(
		{ARENA_X, ARENA_Y, ARENA_W, ARENA_H},
		3,
		g.hurt_timer > 0 ? rl.RED : rl.GRAY,
	)

	// orbs (blink when about to expire)
	for o in g.orbs {
		if o.life < 1.5 && int(o.life * 10) % 2 == 0 {
			continue
		}
		rl.DrawCircleV(o.pos, ORB_R + 3, rl.Fade(rl.GREEN, 0.3))
		rl.DrawCircleV(o.pos, ORB_R, rl.GREEN)
	}

	// enemies
	for e in g.enemies {
		color := e.kind == .Chaser ? rl.MAROON : rl.ORANGE
		rl.DrawCircleV(e.pos, e.radius, color)
	}

	// bullets
	for b in g.bullets {
		rl.DrawCircleV(b.pos, BULLET_R, rl.YELLOW)
	}

	// player (flashes while invulnerable)
	player_color := rl.SKYBLUE
	if g.hurt_timer > 0 && int(g.hurt_timer * 20) % 2 == 0 {
		player_color = rl.WHITE
	}
	rl.DrawCircleV(g.player_pos, PLAYER_R, player_color)

	// aim line
	if g.phase == .Playing {
		rl.DrawLineV(g.player_pos, rl.GetMousePosition(), rl.Fade(rl.WHITE, 0.15))
	}

	// --- HUD ---
	rl.DrawText("HEALTH = AMMO", 40, 14, 18, rl.GRAY)
	rl.DrawRectangle(40, 40, 300, 18, rl.DARKGRAY)
	hp_color := g.hp < 25 ? rl.RED : rl.LIME
	rl.DrawRectangle(40, 40, i32(300 * g.hp / MAX_HP), 18, hp_color)
	rl.DrawText(rl.TextFormat("%d", i32(g.hp)), 350, 40, 20, rl.WHITE)

	if g.phase == .Playing && g.hp <= SHOT_COST + 1 {
		rl.DrawText("TOO LOW TO SHOOT - GRAB AN ORB!", 400, 40, 20, rl.RED)
	}

	time_left := i32(math.ceil(WIN_TIME - g.time))
	rl.DrawText(rl.TextFormat("SURVIVE: %d", time_left), 760, 14, 24, rl.WHITE)
	rl.DrawText(rl.TextFormat("KILLS: %d", i32(g.kills)), 760, 44, 20, rl.LIGHTGRAY)

	// --- end screens ---
	if g.phase != .Playing {
		rl.DrawRectangle(0, 0, SCREEN_W, SCREEN_H, rl.Fade(rl.BLACK, 0.65))
		if g.phase == .Won {
			draw_centered("YOU SURVIVED", 220, 56, rl.LIME)
		} else {
			draw_centered("YOU BLED OUT", 220, 56, rl.RED)
		}
		draw_centered(rl.TextFormat("Kills: %d", i32(g.kills)), 300, 28, rl.WHITE)
		draw_centered("Press R to play again", 350, 24, rl.LIGHTGRAY)
	}
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

main :: proc() {
	rl.InitWindow(SCREEN_W, SCREEN_H, "BLEED ARENA")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	reset_game()

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		if g.phase == .Playing {
			update(dt)
		} else if rl.IsKeyPressed(.R) {
			reset_game()
		}

		rl.BeginDrawing()
		draw()
		rl.EndDrawing()
	}

	delete(g.enemies)
	delete(g.bullets)
	delete(g.orbs)
}

