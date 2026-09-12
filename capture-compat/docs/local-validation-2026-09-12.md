# Local cross-application validation

Date: 2026-09-12. These are observations on one Windows 10 Pro 22H2 x64 machine, build 19045.6332, not a universal application compatibility claim.

## Configuration and provenance

- Core implementation, installer, build scripts, and original tests match upstream commit `1a56b5578d86932b43f958a084253ee00081b049`.
- Normal local DLL SHA-256: `CA9B29BC788BF9C1823CA34DF9AA45C5C85EA60554CAA5BFF8FFE4821EF10965`.
- Screenshot helper: `@oai/sky/bin/windows/codex-computer-use.exe`, SHA-256 `BAD605EF7A800D2E2EBE2D9205DB6F9AB73EF193524392F5CAA1FA2E1A0DAE2C`.
- The running legacy helper loaded its local proxy with that hash and the forwarded system DLL. Its executable was not modified.
- The coexisting Swift helper loaded only the system DLL after removal of the experimental proxy. No official Swift screenshot route was established.
- Native GUI tests used the official `sky` Computer Use API through its configured Node REPL, not the browser-only `cua_repl` surface, raw UI automation, COMSOL MCP, MATLAB, or LiveLink.
- Original core/dispatch unit tests, installation tests, and all 8 live WGC checks passed. A renamed probe is not an official-helper integration test.

## Observed matrix

| Application | Operations | Verified observation |
| --- | --- | --- |
| COMSOL 5.2a | Launch, screenshots, model wizard, tree expansion, coordinate and indexed clicks, typing, stationary solve, result evaluation, Save As | New 0D Global Equations model with residual `u-5`, initial value 0; stationary solution evaluated as `5.0000`. Saved a separate MPH through the GUI. |
| Notepad4 | Activate, screenshots and accessibility, coordinate click, mixed-language input, Ctrl+A, replacement, Ctrl+Z, Ctrl+Y | `Computer Use verification 123` plus four Chinese characters was entered; 34 characters selected; replacement became `Replacement verified`; undo restored original text and redo restored replacement. |
| Paint | Launch, screenshots, drag, undo, redo | A diagonal black stroke appeared at the observed canvas coordinates; undo returned the canvas to blank; redo restored the stroke. |
| Windows Calculator | Launch, screenshots, digit/operator clicks, menu, scroll, maximize/restore | `7 x 8 = 56`; scrolling changed the visible conversion categories; screenshot dimensions changed from 388x638 to 1707x920 and back. |
| File Explorer | Activate, screenshot/accessibility, indexed double-click, Back shortcut | Opened the repository's `capture-compat` folder and verified its address/list; after refreshing following a user-input warning, Alt+Left returned to the repository root. No files were deleted or moved through the GUI. |

## Failures, qualifications, and exclusions

- Launching `notepad.exe` reported no targetable window, but a fresh enumeration found the machine's Notepad4 replacement. This is a launch/discovery mismatch, not a clean launch pass for stock Notepad.
- Calculator returned no accessibility tree in the tested observation. Its successful interaction used screenshots and coordinates.
- COMSOL `set_value` timed out during earlier testing. Ordinary clicks and keyboard entry completed the successful workflow. The capture proxy is not a general UIA repair.
- Some immediate accessibility snapshots lagged behind a GUI transition. Re-observation was required before reusing indexes or judging the outcome.
- File Explorer returned multiple screenshot regions, including background content. Do not assume every returned image is a tightly bounded target window; do not publish raw screenshots containing unrelated user data.
- Paint scrolling produced only a small shift and is not the primary scrolling proof; Calculator's visibly changed menu provides that proof.
- A physical-user-input warning blocked one Explorer input. State was refreshed before retry; safety checks were retained.
- Test content remains in the dedicated unsaved Notepad4/Paint windows. Calculator retains 56; Explorer was returned to its original repository folder. Existing user documents were not edited.
- No claim is made for Office, Electron applications, browsers via native input, elevated apps, games, multiple displays, alternate DPI settings, locked/remote desktops, protected content, or every Computer Use method. COMSOL's 0D solver test is not a spatial finite-element accuracy benchmark.

## Difference from upstream

The final local change is documentation only: helper-selection/restart guidance, this test record, and README links. The speculative Swift allowlist and diagnostic activation hooks were withdrawn. The working fix on this machine was installation of the author's original proxy beside the actual legacy screenshot helper, not a new capture implementation.

The earlier remote Swift PR is not equivalent to this validated local tree. Publication remains subject to user approval; a local test record is not approval to update the remote PR.
