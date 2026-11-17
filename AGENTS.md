# Insect Sanctuary contributor guidance

## Code and documentation

- Keep files focused on one responsibility. Split simulation rules, rendering, input, and persistence at clear boundaries when their logic grows
- Use comments to explain why code exists, how a non-obvious part works, or what constraint the code preserves
- Keep comments selective. For every code comment and doc comment, omit a period, question mark, or exclamation mark at the end of the comment. Use normal punctuation within the comment
- Prefer descriptive headings and unnumbered lists in comments and documentation. Use numbering only when it makes a required order materially clearer
- Prefer `ColorScheme.fromSeed` for Flutter interface themes and `Color.from` for explicit color channels when appropriate
- Run the full Flutter test suite from the app root after making code changes

## Project decisions

- Consult the user before making architectural decisions. Document agreed decisions with their rationale and relevant tradeoffs
- Design for multiple species and lifecycles, including phasmids, caterpillars, beetles, and mantises
- Include a suggested commit message with each update. Create a commit only when the user explicitly requests it
- Work directly until the user asks to switch to pair programming
