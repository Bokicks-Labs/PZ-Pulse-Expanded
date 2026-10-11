# Workshop images

These are the five current in-game captures used by
[`workshop-description.md`](../workshop-description.md). The Markdown links in
that document render these local originals in the repository.

## Add them to the Workshop description

Steam descriptions need hosted image URLs; repository-relative paths will not
work there. On the PZ Pulse Expanded Workshop item, use **Add/edit images &
videos** to upload the five PNG files in this folder. For each uploaded image,
copy its direct image URL and replace the matching named URL in `workshop.txt`:

| Workshop section | File | URL placeholder |
|---|---|---|
| Needs Expanded dashboard | `main-dashboard.png` | `SCREENSHOT_MAIN_DASHBOARD_URL` |
| Manage Stat Bars | `manage-stat-bars.png` | `SCREENSHOT_MANAGE_STAT_BARS_URL` |
| Optional mod data | `optional-mod-data.png` | `SCREENSHOT_OPTIONAL_MOD_DATA_URL` |
| Tooltip detail | `tooltip-detail.png` | `SCREENSHOT_TOOLTIP_DETAIL_URL` |
| Display controls | `display-controls.png` | `SCREENSHOT_DISPLAY_CONTROLS_URL` |
| Auto-hide and reveal flash | GIF to be captured | `GIF_AUTO_HIDE_FLASH_URL` |

Keep the GIF in this folder too once it is ready. Replace each placeholder
inside its `[img]...[/img]` tag with the corresponding direct image URL before
submitting `workshop.txt` to Steam.
