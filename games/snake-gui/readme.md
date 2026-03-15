# Snake — Free Pascal / Lazarus

A classic Snake game built with Free Pascal and the Lazarus LCL, developed
as a teaching project for the
[SilverPascalCoder](https://www.youtube.com/channel/UCEDZT_VZ0oz-gt7Mf_hJp2A)
YouTube channel.

The project is deliberately built in stages — each version introduces new
features and better code structure — so it works as both a playable game and
a practical guide to writing clean, maintainable Pascal.

---

## Gameplay

| Key | Action |
|-----|--------|
| Arrow keys / WASD | Change direction |
| Space | Start / Pause / Resume / Restart |
| H | View high score table |
| Escape | Quit |

**Fruit**
- 🍎 **Apple** — always on the board, worth +10 points
- 🍐 **Golden Pear** — 30% spawn chance, worth +25 points, disappears after 20 moves
- Any fruit has a 15% chance of being **rotten** — looks identical but costs points
- Eating rotten fruit reverses your controls for a random number of moves (0–7)

**Scoring** — score can go negative. That is intentional.

---

## How to Build In Lazarus IDE

1. Open Lazarus
2. **File → Open Project** → select `src/snake.lpi`
3. Press **F9** to build and run

The game searches for the `assets/` folder relative to the executable and
walks up two directory levels automatically, so it works from both the IDE
and a shipped binary.

**Requirements:** Free Pascal ≥ 3.2 and Lazarus ≥ 2.2.
No third-party packages — only the standard LCL.

---
## Licence

MIT — do what you like with it.
