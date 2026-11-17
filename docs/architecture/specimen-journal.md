# Shared specimen journal

**Accepted**

## Why change the prototype

The original journal used woodland-specific activity and location enums, a fixed stick insect heading, and a save key for a single specimen. A caterpillar needs to keep the same journal through changes in life stage, enclosure use, and diet. A mantis may record a hunt, while a beetle may spend time beneath bark. These differences belong to the species and its simulation. The journal presents what the player has learned about each individual.

## Data model

| Part | Responsibility |
| --- | --- |
| Species definition | Supplies a stable species ID, display name, supported behaviors, and the species' life stages and allowed transitions |
| Specimen | Has a stable ID, a species ID, and its current life stage. A specimen keeps its identity as it grows or metamorphoses |
| Observation | Records a typed event from the simulation, such as a behavior change, food eaten, a stage change, or an identified morph. Includes the specimen ID, observation time, and stage at the time of the event |
| Journal | Presents live behavior and keeps durable discoveries, feeding records, and recent activity for one specimen |

Start with species definitions in Dart. This gives us type checks and keeps definitions easy to change while the simulation is still small. Store stable IDs in saves so display labels can change independently. Keep the journal independent of the enclosure renderer, so rendering, tapping, and opening the journal never change what the specimen has done.

## What players see

- The profile shows the current life stage, current behavior, and any morphs that have been identified. Live behavior updates on transitions so readers can see what the specimen is doing without requiring per-frame journal updates
- Discoveries reflect evidence. A single feeding records that the specimen ate a food. A preference requires repeated choices among foods offered in the same life stage
- Recent activity starts collapsed and keeps the latest 20 meaningful entries for each specimen. First observations and life-stage changes belong here. Entry rows and timestamps are built when the player expands the log

Persist the life-stage history, morphs, feeding records, and discoveries independently of the activity list. When an entry rolls off, a food discovery or completed stage stays available. Save each journal under a versioned key derived from the specimen ID. Preserve discoveries and activity from the original woodland journal when the new record is absent, keeping the original save as a fallback.

## First implementation check

Adapt the current stick insect to report habitat use through typed observations. Use a second test specimen with a larva, pupa, and adult to prove the same journal keeps its identity and history across stage changes, with stage-specific food observations. This exercises the architecture before we build a second enclosure.
