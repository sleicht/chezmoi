# OmniWM test migration

Base: the original `private_dot_config/aerospace/aerospace.toml.tmpl`, not the
Hyprspace starter bindings. Target: OmniWM v0.6.8, settings schema 3.

## Try it

1. Install: `brew install --cask barutsrb/tap/omniwm`.
2. Unlock the vault yourself with `rbw unlock`, then preview and deploy with
   `mise run d` and `mise run a`.
3. Quit Hyprspace/AeroSpace and SwipeAeroSpace before opening OmniWM. Stop
   SketchyBar with `brew services stop sketchybar` during this trial: its workspace
   integration still uses Aerospace. OmniWM supplies its own workspace bar.
4. Open OmniWM, grant Accessibility permission, and keep macOS “Displays have
   separate Spaces” enabled. Leave launch at login off until the trial passes.
5. Check workspaces 0–7, app placement, floating, focus, moving and fullscreen.
   Workspace 7 uses the secondary display; the others use the main display.
   Select exact displays in OmniWM Settings if these roles differ from the
   Aerospace monitor-name assignments. Review any resulting settings edits before
   copying them into the chezmoi source.

Aerospace stays installed for rollback, with its source config retained and
`start-at-login` disabled. This branch does not automatically launch OmniWM.

## Bindings and differences

- Ctrl+arrows: focus; Ctrl+Alt+arrows: move. The original Right/Down movement
  swap is deliberately preserved.
- Ctrl+Shift+Up/Down: previous/next workspace. The duplicate Left/Right aliases
  are omitted because OmniWM stores one binding per action.
- Ctrl+0–7: select a workspace; Ctrl+Shift+0–7: move to it. These use workspace
  slots so the first slot correctly addresses workspace **0**.
- Ctrl+Alt+Shift+Up/Down: move to previous/next workspace. Left/Right moves to
  the physical neighbouring monitor, rather than Aerospace’s wrapped monitor order.
- Ctrl+Q: close; Ctrl+F: fullscreen; Ctrl+Alt+F: float; Ctrl+Alt+O: flip split;
  Alt+Tab: previous workspace. Ctrl+F11’s duplicate fullscreen binding is omitted.
- Ctrl+Alt+Plus/Minus (the Equal/Minus keys): grow/shrink width; add Shift for
  height. These replace Aerospace’s modal resize bindings; sizes are OmniWM’s
  increments, not Aerospace’s 50 pixels.
- Ctrl+Alt+Space opens OmniWM’s command palette. Ctrl+Enter launching Ghostty,
  service mode, accordion, HUD notifications and moving a whole workspace to the
  next monitor have no binding in this first trial. Config changes live-reload.
- Dwindle replaces tiled/accordion layouts. All 22 explicit app assignments are
  retained; a less-specific title rule supplies the default floating behaviour.
  OmniWM app assignments are initial placement defaults, not Aerospace’s startup
  sweep of already-open windows. Verify follow-focus behaviour when moving.
- Inner gaps are 3; outer gaps are 5. Borders are disabled to avoid increasing
  effective gaps. The DELL-specific top gap of 20 and Spark’s exact width of 1400
  are not translated. OmniWM’s own bar reserves additional layout space.
- Clipboard history, quake terminal and hidden-bar functionality are disabled.
  Unused actions are explicitly unassigned because the schema requires all 188.

## Verify and roll back

Run `bash scripts/verify-configs.sh --phase 21` and `mise run test`.
Static checks cover parsing, action uniqueness, shortcuts, app rules and workspace
assignments. A live OmniWM session is still required to validate window behaviour.

To roll back the live trial, quit OmniWM, open AeroSpace, and restart SketchyBar
with `brew services start sketchybar`. Re-enable SwipeAeroSpace if used. To roll back
the source, unapply `feature/dotfiles-omniwm-test` in GitButler, then preview/apply
chezmoi manually. Keep `feature/dotfiles-review-fixes` applied.

Schema reference: [OmniWM settings](https://omniwm.app/config/settings-reference/).
The complete settings skeleton derives from upstream’s
[v0.6.4 compatibility fixture](https://github.com/BarutSRB/OmniWM/blob/v0.6.8/Tests/OmniWMTests/Fixtures/Settings/v0.6.4-custom.toml),
updated to schema 3 and the v0.6.8 assignable action catalogue.
