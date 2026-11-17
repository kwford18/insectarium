# Stick insect behavior prototype

The woodland stick insect starts on the upper branch. On leaving the floor, it takes the branch with food if only one branch is stocked. When both branches have the same food availability, it alternates. Both routes follow the same stem and soil curves. Their stride grids are measured from the same floor rest, so the insect stays in place when it turns uphill. The route clock lives in `StickInsectWalk` and uses a steady walking pace with short ramps into and out of stops. The Flame component maps that clock onto the enclosure geometry, renders the gait, and reports observations through the existing journal API.

The prototype starts with four edible leaves on each of four sprigs. Each branch rest point has a sprig, and two more lie along the climb back from the floor. Hunger advances as the insect explores. At departure from the floor it chooses the first reachable sprig with leaves where it expects to be hungry on arrival. A crown-bound insect can stop at sprigs along the shared stem. It keeps its choice for the climb so the gait stays continuous. It can also feed at either branch rest point. A notch appears partway through the meal. On completion, the leaf disappears and the journal receives one `FoodEaten` observation. The sprigs start fresh on reload. The journal persists completed feedings independently.

Drag a bramble cutting from the bottom tray to a marked stem to replace that sprig's leaves. Any overlap between the cutting preview and the stem marker counts. If two markers overlap the preview, the closest stem receives the cutting. The tray provides as many cuttings as needed for this prototype. A missed drop leaves the sprigs alone. Replanting only changes the sprig's food state, so the journal still records completed meals.

Each sprig's recorded picture is rebuilt when its leaves change appearance. Its geometry is reused across frames and resized with a canvas transform. The decorative enclosure still uses its own recorded pictures. Use the Android emulator on Windows for functional testing. Measure Dart and raster frame times in profile mode on the iPhone when the Mac build is ready.

## Woodland feeding direction

The woodland shrub's visible leaves should have individual state. As the stick insect gets hungry, it should seek reachable foliage and eat from a leaf on the shrub. Visible bite damage can show what's been eaten, and the journal can keep using the existing feeding observation. Leaf simulation belongs to this enclosure and its feeding mechanics. Other enclosures can use the food sources their inhabitants need.

Plant care should happen through the enclosure itself. The cutting prototype gives immediate food. Dragging fertilizer onto the shrub could regrow foliage over time if both interactions feel useful in play.

## Follow-up behavior work

- Let the insect choose when and where to rest or explore, including upper and crown branch destinations
- Extend feeding to more of the shrub, then test how players decide when and where to replant
- Add a turn animation and tune travel and rest timing in the enclosure
- Add a subtle phasmid wiggle while paused, keeping the feet anchored to the surface
- Develop another species with its own feeding or movement rules before extracting behavior shared by both
