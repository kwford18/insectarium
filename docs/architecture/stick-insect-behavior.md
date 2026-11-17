# Stick insect behavior prototype

The woodland stick insect rests on the upper branch, follows the existing trail to the floor, rests again, and returns uphill. The timed route makes both surfaces observable and preserves planted feet at each stop. The route clock lives in `StickInsectWalk`. The Flame component maps that clock onto the enclosure geometry, renders the gait, and reports observations through the existing journal API.

The player can offer one bramble leaf at the branch rest point. The insect eats it during a branch rest, pausing route progress while it feeds. A completed meal produces one `FoodEaten` observation. Availability and eating progress are session state. The journal persists the completed feeding count independently.

## Follow-up behavior work

- Choose among reachable branch and floor destinations, and let the insect decide when to rest, explore, or approach food
- Add a turn animation and tune travel and rest timing in the enclosure
- Develop another species with its own feeding or movement rules before extracting behavior shared by both
