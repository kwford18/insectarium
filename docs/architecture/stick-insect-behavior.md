# Stick insect behavior prototype

The woodland stick insect rests on the upper branch, follows the existing trail to the floor, rests again, and returns uphill. The timed route makes both surfaces observable and preserves planted feet at each stop. The route clock lives in `StickInsectWalk`. The Flame component maps that clock onto the enclosure geometry, renders the gait, and reports observations through the existing journal API.

The temporary **Offer leaf** button exists to test feeding and its journal record. It places one bramble leaf at the branch rest point. The insect eats it during a branch rest, pausing route progress while it feeds. A completed meal produces one `FoodEaten` observation. Availability and eating progress are session state. The journal persists the completed feeding count independently.

## Woodland feeding direction

The woodland shrub's visible leaves should have individual state. As the stick insect gets hungry, it should seek reachable foliage and eat from a leaf on the shrub. Visible bite damage can show what's been eaten, and the journal can keep using the existing feeding observation. Leaf simulation belongs to this enclosure and its feeding mechanics. Other enclosures can use the food sources their inhabitants need.

Plant care should happen through the enclosure itself. Two ideas to try are dragging fresh cuttings onto stems for immediate food and dragging fertilizer onto the shrub to regrow foliage over time. They could serve different purposes if both feel good in play. The corner button can go once there is a way to replenish the shrub in the enclosure.

## Follow-up behavior work

- Choose among reachable branch and floor destinations, and let the insect decide when to rest, explore, or approach food
- Prototype hunger-driven feeding on one reachable sprig and show the effect of eating on its leaves, then extend that to the shrub
- Add a turn animation and tune travel and rest timing in the enclosure
- Develop another species with its own feeding or movement rules before extracting behavior shared by both
