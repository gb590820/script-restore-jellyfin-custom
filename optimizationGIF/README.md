# GIF Performance Optimization for Jellyfin Avatars

This document describes the current avatar galleries, what they do, and how they work.

Credit: avatar library and base code for the avatar pages were adapted from https://github.com/gb590820/script-restore-jellyfin-custom

## Files

- `web/avatars/index.html` — main entry page linking to available avatar galleries.
- `web/avatars/Steam/gallery-static-frame.html` — active Steam gallery. Main behavior is described below.
- `web/avatars/pop/pop-optimized.html` — active Pop gallery. Works similarly to the Steam gallery.

## What these galleries do (summary)

- They read the list of GIF filenames from a `gallery.html` file (or `pop.html` for the Pop gallery).
- They display a static thumbnail (first-frame capture) for each avatar initially.
- The full animation (GIF) is loaded and displayed only when the user hovers the thumbnail.
- Clicking a thumbnail calls `updateUserImage(...)` to apply the avatar.
- A progress bar and a counter show thumbnail load status.

## How it works (technical)

1. Extract filenames
   - The page performs a `fetch('gallery.html')` (or `pop.html`) and extracts `.gif` URLs by parsing the HTML.

2. Create tiles
   - For each filename the page creates a DOM tile containing:
     - a `canvas` element (or static image) holding the first frame,
     - a hidden `img` element for the animated version,
     - an info overlay and click handler.

3. Lazy loading (IntersectionObserver)
   - Tiles are observed via `IntersectionObserver`. When a tile becomes visible the first image is loaded and drawn to the canvas.

4. Hover animation
   - On `mouseenter` the page sets the animated image source (`animated-image.src = filename`) and displays it when loaded.
   - On `mouseleave` the tile returns to the static view to limit memory/CPU usage.

5. Indicators and monitoring
   - A progress bar at the top shows the percentage of prepared thumbnails.
   - A counter shows `loaded / total` for simple diagnostics.




