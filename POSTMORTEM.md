BLEED ARENA Postmortem

Game

BLEED ARENA

One-Sentence Pitch

ARENA, but every shot costs health, and killing enemies creates temporary health orbs that the player must collect to keep fighting.

What I Changed From ARENA

The original ARENA gameplay focuses on moving around the arena, shooting enemies, and surviving.

BLEED ARENA changes the main resource loop. The player’s health is also their ammunition resource. Every shot costs 2 HP, so shooting has a direct survival cost. When an enemy dies, it drops a health orb that restores some HP. The orb disappears after five seconds, which forces the player to decide when it is safe to move toward it.

I also added two enemy types:

* Chasers have more health and deal more damage.
* Runners have less health but move faster.

The difficulty increases during a run. Runner frequency increases over time, enemy speed increases, and the time between enemy spawns decreases.

The player wins by surviving for 60 seconds and loses if their health reaches zero.

Where the LLM Sped Me Up

[ADD YOUR REAL EXAMPLES HERE]

For each example, include the session or commit where it happened.

Example format:

During Session [X], I used [tool/model] to help with [feature]. The useful part was [specific result]. This reduced the amount of time I spent on [specific task]. I still had to [what you personally checked or changed].

Where the LLM Did Not Help

[ADD YOUR REAL EXAMPLES HERE]

Describe a specific problem rather than saying that the LLM was generally unreliable.

For example:

The LLM struggled with [specific Odin problem]. The suggested implementation produced [actual error or incorrect behaviour]. I tried [attempt]. I eventually fixed it by [actual solution].

LLM-Introduced Bug

[ADD YOUR REAL BUG HERE]

Before

[What the game did incorrectly.]

Cause

[What the generated code did wrong.]

Fix

[What you changed.]

Verification

[How you proved that the fix worked. For example, a printed value, repeated test, debug output, or before/after recording.]

Pitch vs. Delivered Game

Original Pitch

[INSERT YOUR ACTUAL WEDNESDAY PITCH]

Delivered Game

The delivered game became BLEED ARENA. The final version focuses on health management as the central gameplay mechanic.

[EXPLAIN WHAT CHANGED FROM THE ORIGINAL PITCH AND WHY.]

Showcase Feedback

[INSERT THE ACTUAL FEEDBACK YOU RECEIVED ON SEPTEMBER 28.]

I used the feedback by [specific change, if applicable].

Pipeline Improvements

For the next jam, I would improve my workflow by:

1. Breaking each gameplay mechanic into a smaller task before asking for implementation help.
2. Testing each generated change immediately instead of combining several changes before testing.
3. Keeping a short record of bugs and fixes during each session.
4. Using Git commits after each working feature so changes can be traced to specific sessions.
5. Testing the complete game repeatedly before the final submission, including winning, losing, restarting, and playing for several minutes.

Final Reflection

The most important design change from ARENA was making health serve two purposes. It controls survival while also controlling how much the player can shoot. This makes every shot part of the resource-management decision.

The health orbs then connect the two systems. Killing enemies gives the player a way to recover health, but the orbs expire and require the player to move toward them. This means the player cannot simply stay in one safe position and shoot continuously.