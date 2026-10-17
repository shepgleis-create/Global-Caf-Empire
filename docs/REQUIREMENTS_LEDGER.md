# GLOBAL CAFÉ EMPIRE — ENGINEERING LEDGER
Updated 2026-10-17. This ledger is an audit of running code, not a list of promises. Reference images are not shipped assets.

## 2026-10-17 — Verified native-engine development increment

- **3D city environment**: Regional ground treatments; pedestrian plazas, waterfront piers, avenue cycling lanes, pedestrian crossings, civic planting, distinctive skyline height rules and physical leased-store awnings. This is geometric Godot 3D, not generated pictures. Full unique hand-authored cities and photorealism are not achieved.
- **3D headquarters**: Enlarged camera scale for portrait rendering. Executive board meeting table and chairs, Product beverage tasting bench, IT server racks, Finance research monitors; different workstation counts per department. Scene assets remain stylized procedural geometry and need substantial art passes.
- **Financials**: Company/Finance panel draws cumulative revenue, expenses, retained earnings, assets, liabilities, contributed equity, inventory, equipment and cash from the balanced journal; invariants checked for 30 simulated weeks.
- **Actual governance actions**: Quarterly board meeting (13-week cooldown) can approve a Growth campaign, employee training, or cash preservation. Spending is posted once to the journal; awareness/service changes feed the weekly demand function. Decisions and history persist through saves.
- **Mobile and performance**: Godot world is instantiated only while World tab is active; tapping 3D lots uses correct stretched viewport coordinate mapping.
- **Tests**: core_gameplay_test, finance_hq_test, board_meeting_test and map_touch_test run headlessly using Godot 4.4.1; CI gates actual Godot unedited scene capture on test success.
- **Known limitations**: not validated in physical iPhone Safari; cities still share a procedural block grammar rather than fully independent street grids; advanced board governance, hiring, finance drilldowns and player-configurable setup remain unfinished. Existing save structure is preserved with optional new board fields defaulted by .get().
- **Delivery**: tracked on the independent GitHub repo and Git-linked Vercel project. Vercel READY alone does not certify actual mobile hardware performance.

## Evidence gates
- **TESTED** means Godot 4.4.1 executed the relevant test with passing assertions.
- **WEB LIVE** means Vercel returned READY and a browser loaded the native WebGL game.
- **SOURCE PRESENT** means Godot code exists but has not passed its full gameplay acceptance case.
- **NOT YET IMPLEMENTED** does not mean a visual mockup or a static button exists.

| ID | System | Actual state | Evidence and next constraint |
|---|---|---|---|
| M0-01 | Dedicated Godot engine/repository | TESTED, WEB LIVE | Native project.godot, Main.tscn, reproducible WebAssembly GitHub-to-Vercel build |
| M0-02 | Actual 3D city presentation | TESTED early renderer | CityWorld3D.gd + Xvfb actual Godot frame captures; art quality below reference standard |
| M0-03 | Main menu/company identity | SOURCE PRESENT | Working seeded default founder, Continue from local storage; full customizable founder wizard not yet built |
| M0-04 | Property leasing | TESTED | Lease deposit, ownership in parcel data, cash journal |
| M0-05 | Staffing and equipment | TESTED | Expenses/assets posted, staff and capacity restrictions |
| M0-06 | Ingredient stock + per-unit cost | TESTED | Quantity, capitalized stock purchase, depletion, COGS journaling |
| M0-07 | Weekly customer demand and capacity | TESTED | Price elasticity, staffing, machine throughput, stock ceiling, financial report |
| M0-08 | Currency & journal | TESTED first-store scope | Balanced integer-cent postings, bank cash reconciliation; full consolidated financial statements pending |
| M0-09 | Local save and resume | TESTED first-store scope | JSON save load, same stores and company cash; atomic backup/migrations not yet built |
| M0-10 | 64 markets | TESTED data registry | City IDs/costs/styles and 16 commercial parcels each; unique hand-authored detailed city geometry NOT completed |
| M0-11 | True Godot browser export | WEB LIVE | Vercel GitHub build, WebGL 2.0 Chromium smoke. Actual iPhone Safari device test pending |
| M0-12 | Real 3D headquarters | TESTED renderer | Separate World3D subviewport with animated staff, office furniture, Product/Technology/Executive/Finance profile |
| M1-01 | Product research | SOURCE PRESENT | Research payment adds future demand benefit; full recipe R&D lab / pilot model pending |
| M1-02 | Retail technology development | SOURCE PRESENT | Capital outflow, new POS tech boosts demand & throughput in following weeks; app penetration model pending |
| M1-03 | Executive delegation | SOURCE PRESENT | Hiring cost, recurring salary, bounded reorder policy; sophisticated executive autonomy/role traits pending |
| M1-04 | Map touch parcel interaction | SOURCE PRESENT | Mouse/touch events and lease dialog implemented; real mobile iPhone gesture testing pending |
| M1-05 | Responsive mobile visuals | IN PROGRESS | UI compression and overlay interception corrected; some long-store views still need manual device QA |
| M2-01 | 13+ distinct physical cities | IN PROGRESS | 64 market archetypes exist; city-specific terrain, landmark variety and physical animations immature |
| M2-02 | Autonomous competitors | NOT YET IMPLEMENTED | CompetitionAI same-domain economy not built |
| M3 | Real IPO, stocks, full financial statements, M&A | NOT YET IMPLEMENTED | Full ledger and governance roadmap |
| M4 | Farms, roasting, wholesale, franchise, property | NOT YET IMPLEMENTED | Full simulation extension |
| M5 | Politics, founder lifestyle, sports, art, legacy | NOT YET IMPLEMENTED | Optional original endgame |
| M6 | Localization, accessibility, device/perf QA, app-store exports | NOT YET IMPLEMENTED | iOS/Android native devices not tested |

## Immediate next development gates
1. Deepen 3D cities with original modeled façades, street furniture, animated real traffic, distinct roads and neighborhoods per city. Do not extract or copy Coffee Inc 2 assets.
2. Fully implement a touch-validated floor designer; represent placed furniture in persistent operational state.
3. Add actual AI café companies using the same operating/ledger rules as the player. World lots require competitor ownership and business closures.
4. Increase player setup and first-year depth, from 15 minute startup to resilient 52-week play.
5. Add signed integer-cent financial statements and ledger-backed branch drilldowns.
6. Run reproducible scenario seeds, 10-year balance sweeps, native iPhone Safari profile and stress-test.
7. Save compatible migrations when any existing state schema changes; never silently overwrite an old save.

## Reference-to-implementation mapping
Ten supplied screenshots show: Executive board meeting + C-suite staffing; technology division Mobile Pay and Loyalty with transaction trends; Products division with an isometric office and beverage reporting; Paris airport and city map; travel route/atlas selection; company offices/employee distribution; statement summary plus balance-sheet equality; geographic store counts and portfolio drill-down; and large interconnected parcel map with varying commercial architecture.

Requirements derived for this ORIGINAL game: a 3D floor with executives and board governance, product/IT capacity and real research effects, finance drilldowns and graphs from the journal, a physical atlas linking travel markets, 64+ diverse worlds with upgradeable real estate and original building kits, fluent mobile navigation and true company-to-personal money separation. These are long-term scope statements, not a claim of completed parity.

## Publishing policy
Screenshots in captures/ are generated only by the Godot executable in GitHub Actions. They are unedited engine captures. The older HTML demo is deprecated as a foundation; only the native Godot repository is the authoritative source. Do not claim commercial-quality iPhone visuals before physical-device validation.
