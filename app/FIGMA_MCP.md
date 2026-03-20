# Figma ↔ Cursor (authenticated MCP)

## Your file

| | |
|---|---|
| **File** | [Hanti riyo (Copy)](https://www.figma.com/design/1pH0qfybRFvvBbWUCcN5Lm/Hanti-riyo--Copy-) |
| **File key** | `1pH0qfybRFvvBbWUCcN5Lm` |

## Important: `node-id=0-1` is not a screen

`node-id=0-1` → node **`0:1`** = **Page 1** (the whole canvas). It has **no single layout** to implement; it only lists all frames.

To pull **exact** specs into Cursor:

1. Open the file in **Figma Desktop** (logged in).
2. **Select one frame** (e.g. **Explore / Search**).
3. In Cursor, ask to implement that screen — the agent calls **`get_design_context`** on that node.

If nothing is selected, MCP may respond with *“You need to select a layer first”*. **Selection + auth** is required for some calls.

## MCP tools (project server: `plugin-figma-figma`)

| Tool | Use |
|------|-----|
| **`get_design_context`** | Code + screenshot + tokens for the **selected** (or specified) node — primary for build. |
| **`get_metadata`** | XML tree of structure (node ids, names, sizes) — good for finding ids without selecting. |

### URL → MCP parameters

Figma URLs use hyphens (`node-id=21-3653`). MCP / API use a colon: **`nodeId`: `"21:3653"`**.

## Useful frame IDs (from file metadata)

| Node | Name |
|------|------|
| `21:3653` | Explore / Search |
| `21:3735` | (related empty / explore states — verify in file) |
| `24:3484` | Search / Result - Filter |
| `24:3583` | Search / Empty |
| `24:3566` | Search / Result |
| `2:5`, `9:251` | Welcome / set3-1 |
| `6:264` | Login / FAQ |

Re-run **`get_metadata`** on `0:1` if the file structure changes.

## Implementation rule

MCP output is **React + Tailwind reference**. This app is **Flutter** — convert to:

- `AppColors` / `figma_tokens.dart` for color, blur, radii, shadows  
- `GoogleFonts.raleway` / theme where Figma says Raleway  
- Existing widgets (`EstateCard`, `SearchScreen`, etc.)

## Token source in repo

Shared numbers for **Explore / Search** live in:

`lib/core/theme/figma_tokens.dart`

Update that file when you change the Figma file and re-fetch specs.
