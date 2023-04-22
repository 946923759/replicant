![F.M. RepliCant](https://github.com/946923759/replicant/blob/main/FM%20RepliCant%20Logo.png?raw=true)

This is a VN engine designed to handle simpler types of VNs. It is currently used for Guns Girl Z: Fire Moth DLC.

## Features
- Resize window on the fly, supports any resolutions close to 16:9
- No FPS limit. Animations are as smooth as your display can handle.
- Supports mouse, keyboard, game controller, and touchscreen
- Supports multiple languages.
- Gallery screen, automatically unlocks images displayed in cutscenes.
- Sound Test screen.

## Features for developers
- Choice branching, show/remove choices, set/get variable (beta).
- Automatic portrait positioning.
- Load portrait database from GGZ or GFL
- Load music internally or externally
- Scripts have multilanguage support built in to the syntax.
- Script syntax is simple and easy to write.


## Project Structure
Backgrounds: Dumped game backgrounds, matches game structure

Portraits: Dumped game portraits, matches game structure

Ext: Dumped game files that are required

stepmania-compat: Wrappers that make nodes slightly closer to how Actors work in StepMania

## Syntax
Unfortunately syntax is not standard yet, but check out syntax.md.


# Compilation Instructions
Download Godot Engine v3.5 (NOT the Mono one). Download the zip for this project, extract, open the project.godot in Godot Engine. Go to Project -> Export and select export type.

Only Windows (Win32 not UWP), Linux, and Android is being targeted currently. Web export is fully functional

# License

This engine is CC-BY-NC-SA, no commercial use, feel free to modify it and do whatever you want besides that.
