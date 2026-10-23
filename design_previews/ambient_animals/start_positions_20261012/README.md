# Current walking animal starts

The walking cat and two dogs start at the user-saved scene positions. The shared controller anchors its route to the editor position, so moving the animal no longer resets it on play. Tindahan's route is 1 m long to keep the dog clear of Mang Nestor; the Palengke routes retain their previous leg lengths and direction. Stationary cats and initial rotations retain the user's edits.

The focused regression reproduces three placement failures [before](before.log) and passes **229 checks, 0 failures** [after](after.log). [Route ground/body clearance](clearance-final.log) passes **2,031 checks, 0 failures**. Body checks include visible solids and NPC bodies; hidden CSG player boundary walls are excluded because these animals are decorative and do not use collision bodies. Player boundary colliders remain unchanged.

All probes run in the imported disposable project with isolated user data. The camera probe holds translation at the saved starts, retains native animated models, lighting, camera volumes and HUD, and uses temporary restored magenta materials only to measure visibility.

Manual keyboard play and standalone Windows builds were not rerun. Known headless shutdown retention warnings remain in the logs.

![Current starts in the gameplay cameras](new_starts.png)

[Camera log](visual-final.log): **12 captures, 0 visibility failures** across all three walkers, High/Performance and VHS off/on. The sheet crops normal gameplay pixels around each animal; full-resolution views and [measurement records](camera_measurements.json) are included.
