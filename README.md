# mini-jam

# BLEED ARENA

**ARENA, but every shot costs you health, and kills drop health orbs you have to go collect.**

A top-down survival shooter made with Odin + Raylib (`vendor:raylib`) for the
CSCI 4160U Mini Game Jam (SQ2).

## Build and run (one command)

Requires the [Odin compiler](https://odin-lang.org) (Raylib ships with it as `vendor:raylib`).

```
odin run .
```

## How to play

| input | action |
|---|---|
| W A S D / arrow keys | move |
| hold left mouse button | shoot toward the cursor |
| R | restart (after winning or losing) |

Survive for 60 seconds to win. You lose if your health reaches 0.

- **Every bullet costs 2 HP.** You cannot shoot if you are too low, so you can never shoot yourself to death.
- **Killed enemies drop a green orb** that restores health. Orbs fade after 5 seconds.
- **Chasers** (red, slow, 2 hits) drop bigger orbs. **Runners** (orange, fast, 1 hit) drop smaller ones.
- Missing is expensive. Landing every shot makes you gain health.

## Files

- `main.odin`: the whole game. Tuning constants are at the top.
- `ATTRIBUTION.md`: asset credits (none used).
