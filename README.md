# 🐍 Snaketrix v5.3

Terminal-based Snake game written entirely in Bash with cyberpunk vibes!  
Features permanent B-block hazards, matrix rain animations, and fully customizable gameplay.

---

## 🎮 Features

- Classic Snake gameplay in your terminal.
- Permanent **B-block hazards** that act like walls.
- Matrix rain effect during **game-over sequences**.
- Customizable snake:
  - Color (Red, Green, Yellow, Blue, Multi-coloured)
  - Character
- Adjustable B-block frequency (0–50 per item eaten).
- High score saving system.
- Lives system (3 lives per game).

---

## ⚙️ Configuration

You can configure these options during gameplay via the **Options menu**:

| Option            | Description                                                     | Default |
|------------------|-----------------------------------------------------------------|---------|
| Snake Colour      | Choose the color of your snake                                   | Green   |
| Snake Character   | Character representing your snake                                | O       |
| B Block Frequency | Number of permanent B blocks spawned per item eaten             | 20      |
| High Scores File  | Path to save high scores                                         | `/userdata/system/configs/snakescores.txt` |

**Notes:**

- B blocks are **permanent** and will remain on screen until all 3 lives are lost and a new game is started.  
- Snake speed increases slightly as you eat apples.  
- Matrix rain effects are purely aesthetic and can also be triggered via the main menu.

---

## 🧩 Requirements

- Linux or macOS terminal (or Windows WSL)  
- Bash 4.0+  
- `tput` (part of `ncurses`, usually installed by default)  

---

## 🚀 Installation & Running

1. Clone the repository:  
```bash
git clone https://github.com/YOUR_USERNAME/snaketrix.git
cd snaketrix
