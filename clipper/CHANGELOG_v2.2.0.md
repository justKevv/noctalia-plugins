# Changelog v2.2.0

## Release Date
**2026-03-11**

## Bug Fixes

#### Clear All Notes Fix
- Fixed the bug where you click Clear All Notes and reopen the plugin panel but the notes are still there

#### Panel Corners Fix
- Fixed the plugin's panel bottom corners has square corners when the top is rounded

#### Export Notes Fix
- Fixed you can export a Note many times but when deleting you can only delete one so the other notes still stucking inside your `~/Documents/` directory. Now you can still export a note many times, changing the contents and all the notes were exported from that one note will all be deleted

#### Applying Settings
- Settings will now only apply when you click the `Apply` button instead of immediately applying the settings (this is to make use of the apply button)

#### Panel Close Button
- Fixed an issue where clicking the NoteCards panel would close the plugin panel even when the Close Button was enabled. The panel now only closes on background click when the Close Button is disabled. When enabled, use the Close Button or click outside the plugin's panel to close the panel.

## Improvements

#### UI Enhancement
- Panel will now attach to bar instead of being separate
- Decrease abit of panel's width and height for a cleaner look

#### Keybind Changes
- Pressing `Alt+1` will now navigate you back to `All` instead of `Alt+0`, `Alt+2` is `Text` and goes on

#### Clipboard Mouse Wheel Scroll
- You can now use the mouse wheel scroll to navigate left and right between clipboards

#### Note Card and Pinned Item Separator
- Added a separator between Note Card and Pinned Item

#### Panel Close Button
- Moved the Close Button from next to Open Settings to the panel's top right corner

## Breaking Changes
- Might be - please report if there are bugs

## Known Issues
- After adding a clipboard into ToDo plugin you can't check the complete box or remove that clipboard from ToDo

## Upgrade Notes
- Plugin will automatically migrate settings
- No user action required
- Existing pinned items and notecards will be preserved

## To Do 
- Add `Annotation Tool` support for Images clipboards
