# Architecture atlas

The overview and twelve focused diagrams together document the complete implementation.
Each view is rendered at its natural layout size with 2x pixel density. Light and dark
renders use matching high-contrast palettes for text, edges, nodes, and backgrounds.
Repeated boundary nodes keep the same names across views; there are no cross-page wires.
Solid arrows represent imports, calls, data flow, or control flow as labeled; dotted
arrows indicate configuration, type relationships, or review caveats. These diagrams
describe implementation behavior, not verified EMVA standards compliance.

| View | Mermaid | Light PNG | Dark PNG |
| --- | --- | --- | --- |
| Overview | [Source](../../ARCHITECTURE.mmd) | [Light](../../ARCHITECTURE.png) | [Dark](../../ARCHITECTURE.dark.png) |
| Repository, build, and execution | [Source](01-build.mmd) | [Light](01-build.light.png) | [Dark](01-build.dark.png) |
| Exact module import graph: importer to imported module | [Source](02-modules.mmd) | [Light](02-modules.light.png) | [Dark](02-modules.dark.png) |
| All explicit data structures and instances | [Source](03-types.mmd) | [Light](03-types.light.png) | [Dark](03-types.dark.png) |
| Basic.lean: every FloatConv function; full-range BT.601 / JFIF formulas | [Source](04-color.mmd) | [Light](04-color.light.png) | [Dark](04-color.dark.png) |
| Image.lean: every Image function | [Source](05-images.mmd) | [Light](05-images.light.png) | [Dark](05-images.dark.png) |
| EMVA1288.lean: analysis orchestration and parameter characterization | [Source](06-analysis.mmd) | [Light](06-analysis.light.png) | [Dark](06-analysis.dark.png) |
| EMVA1288.lean: complete low-level statistics paths | [Source](07-statistics.mmd) | [Light](07-statistics.light.png) | [Dark](07-statistics.dark.png) |
| EMVA1288.lean: spatial non-uniformity | [Source](08-spatial.mmd) | [Light](08-spatial.light.png) | [Dark](08-spatial.dark.png) |
| EMVA1288.SensorParams: all seven derived metric functions | [Source](09-metrics.mmd) | [Light](09-metrics.light.png) | [Dark](09-metrics.dark.png) |
| EMVA1288.formatReport: string formatting and output boundary | [Source](10-output.mmd) | [Light](10-output.light.png) | [Dark](10-output.dark.png) |
| Main.lean: all declarations, elaboration-time examples, and runtime behavior | [Source](11-demo.mmd) | [Light](11-demo.light.png) | [Dark](11-demo.dark.png) |
| Code-review boundaries and limitations: current behavior, not proposed features | [Source](12-review.mmd) | [Light](12-review.light.png) | [Dark](12-review.dark.png) |

## Rendering again

Requires Node.js, Mermaid CLI (`@mermaid-js/mermaid-cli`), and a Chromium browser.
From this directory, run:

```powershell
./render.ps1 -MermaidCli mmdc -BrowserPath 'C:/Program Files/Google/Chrome/Application/chrome.exe'
```

Rendering configuration is stored in `light.json` and `dark.json`. No Lean code is
modified by this workflow. The demo prints examples; it does not validate the analysis
pipeline with assertions. See the review diagram for implementation limitations.
