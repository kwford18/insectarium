# Stick insect behavior prototype

The woodland stick insect rests on the upper branch, follows the existing trail to the floor, rests again, and returns uphill. The timed route makes both surfaces observable and preserves planted feet at each stop. The route clock lives in `StickInsectWalk`. The Flame component maps that clock onto the enclosure geometry, renders the gait, and reports observations through the existing journal API.

The prototype starts with four edible leaves on each of two sprigs. One is at the upper branch rest point. The other is a brief stop on the climb back from the floor. Hunger advances as the insect explores. A hungry insect can feed at either stop if leaves remain there. It pauses to feed, then one leaf disappears from that sprig and the journal receives one `FoodEaten` observation. The sprigs start fresh on reload. The journal persists completed feedings independently.

Each sprig's recorded picture is rebuilt when one of its leaves is eaten. Its geometry is reused across frames and resized with a canvas transform. The decorative enclosure still uses its own recorded pictures. Use the Android emulator on Windows for functional testing. Measure Dart and raster frame times in profile mode on the iPhone when the Mac build is ready.

## Woodland feeding direction

The woodland shrub's visible leaves should have individual state. As the stick insect gets hungry, it should seek reachable foliage and eat from a leaf on the shrub. Visible bite damage can show what's been eaten, and the journal can keep using the existing feeding observation. Leaf simulation belongs to this enclosure and its feeding mechanics. Other enclosures can use the food sources their inhabitants need.

Plant care should happen through the enclosure itself. Two ideas to try are dragging fresh cuttings onto stems for immediate food and dragging fertilizer onto the shrub to regrow foliage over time. They could serve different purposes if both feel good in play.

## Follow-up behavior work

- Choose among reachable branch and floor destinations, and let the insect decide when to rest, explore, or approach food
- Extend feeding to more of the shrub, with individually selectable leaves, visible bites, and a way to replenish food during play
- Add a turn animation and tune travel and rest timing in the enclosure
- Develop another species with its own feeding or movement rules before extracting behavior shared by both
