# Map UI runtime art

`map_base.png` is the approved paper map with five permanent illustrated roads. The five `icon_*.png` files are separate 256 × 256 transparent destination icons; `storm_wash.png`, `storm_wind.png`, and `storm_eye.png` are separate 512 × 512 transparent moving ink layers. `storm_front_clouds.png` is a separate 1536 × 1024 transparent cloud-and-rain cutout fixed at the storm's starting corner. Live labels, status badges, hit targets, travel confirmation, and End the Day controls are built in Godot.

Full-size sources, generation prompts, and the export script are in `design_previews/map_ui_v1/`. Keep the printed roads aligned with `MapScreen.gd`'s location positions when revising the map. `TravelCalculator.gd` remains the authority for route costs; its graph contains more edges than the five illustrated roads.
