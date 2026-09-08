/**
 * Browser-side normalized model contracts.
 *
 * These typedefs are documentation/editor hints only; they do not add runtime
 * type checking. Keep them in sync with docs/pulse/data-model.md.
 *
 * @typedef {"base_game"|"mod"} StatSourceType
 */

/**
 * Identifies where a normalized player stat originated.
 *
 * @typedef {Object} StatSource
 * @property {StatSourceType} type - Provenance category.
 * @property {string} id - Stable source identifier. For mods, prefer the mod ID.
 * @property {string} name - Player-facing source name used by tooltips.
 */

/**
 * Normalized live numeric state about the current player.
 *
 * Numeric fields may be finite numbers or non-empty numeric strings because
 * values cross a serialized PZ Pulse boundary before reaching this renderer.
 *
 * @typedef {Object} PlayerStat
 * @property {string} id - Stable machine-readable stat identifier.
 * @property {string} label - Non-empty player-facing label.
 * @property {string} [description] - Optional tooltip description.
 * @property {number|string} value - Current raw value.
 * @property {number|string} min - Minimum raw value.
 * @property {number|string} max - Maximum raw value. Must be greater than min for normalization.
 * @property {boolean} badHigh - True when larger normalized values are worse.
 * @property {string} [iconKey] - Optional icon lookup key.
 * @property {boolean} [visibleByDefault=true] - Intended initial visibility.
 * @property {StatSource} source - Required provenance metadata.
 */

/**
 * Returns true only for finite numbers or non-empty numeric strings.
 *
 * This intentionally rejects JavaScript values that Number(...) would
 * otherwise coerce into misleading numeric data, such as booleans, arrays,
 * objects, null, and empty strings.
 *
 * @param {*} value
 * @returns {boolean}
 */
function isFiniteNumber(value) {
    if (typeof value === "number") {
        return Number.isFinite(value);
    }

    if (typeof value === "string") {
        if (value.trim() === "") {
            return false;
        }

        const num = Number(value);

        return Number.isFinite(num);
    }

    return false;
}

/**
 * Returns true when every supplied value satisfies isFiniteNumber().
 *
 * @param {...*} nums
 * @returns {boolean}
 */
function isFiniteNumbers(...nums) {
    for (let num of nums) {
        if (!isFiniteNumber(num)) {
            return false;
        }
    }
    return true;
}

/**
 * Clamps a numeric value to an inclusive range.
 *
 * Rounding is optional because normalization should preserve source precision,
 * while display formatting may intentionally round later.
 *
 * @param {number|string} value
 * @param {number|string} min
 * @param {number|string} max
 * @param {boolean} round
 * @param {number} [precision=0]
 * @returns {number|null}
 */
function clamp(value, min, max, round, precision = 0) {

    if (!isFiniteNumbers(value, min, max)) {
        return null;
    }

    const _value = Number(value);
    const _min = Number(min);
    const _max = Number(max);

    if (_max < _min) {
        return null;
    }

    const clamped = Math.max(_min, Math.min(_max, _value));
    const rounded = round ? Number(clamped.toFixed(precision)) : clamped;

    return rounded;
}

/**
 * Converts a normalized PlayerStat into a numeric percentage from 0 to 100.
 *
 * The raw value is clamped before normalization. A zero-width or reversed
 * range is invalid because it cannot be normalized meaningfully.
 *
 * @param {PlayerStat} stat
 * @returns {number|null}
 */
function normalizePercent(stat) {
    if (stat === null || stat === undefined) {
        return null;
    }

    // Validate the raw fields before Number(...) conversion so missing or
    // coercible non-numeric values cannot silently become valid zeroes.
    if (!isFiniteNumbers(stat.value, stat.min, stat.max)) {
        return null;
    }

    const value = Number(stat.value);
    const min = Number(stat.min);
    const max = Number(stat.max);

    if (max <= min) {
        return null;
    }

    const clampedValue = clamp(value, min, max, false);

    if (clampedValue === null) {
        return null;
    }

    return ((clampedValue - min) / (max - min)) * 100;
}

/**
 * Formats a PlayerStat's normalized value for the Needs Expanded row.
 *
 * Formatting is intentionally separate from normalization. The bar keeps full
 * percentage precision while the visible text currently rounds to a whole
 * percentage.
 *
 * @param {PlayerStat} stat
 * @returns {string|null}
 */
function formatStatValue(stat) {
    const percent = normalizePercent(stat);

    if (percent === null) {
        return null;
    }

    return `${percent.toFixed(0)}%`;
}

/**
 * Returns the semantic color state for a PlayerStat bar.
 *
 * These thresholds mirror the current PZ Pulse Needs+ presentation and are
 * dashboard styling thresholds, not Project Zomboid Moodle thresholds.
 *
 * @param {PlayerStat} stat
 * @returns {"ok"|"warn"|"danger"|null}
 */
function statBarClass(stat) {
    const percent = normalizePercent(stat);

    if (percent === null) {
        return null;
    }

    // Strict boolean validation prevents values such as the string "false"
    // from being treated as truthy and silently reversing bar semantics.
    if (typeof stat.badHigh !== "boolean") {
        return null;
    }

    if (stat.badHigh) {
        if (percent >= 75) {
            return "danger";
        }

        if (percent >= 50) {
            return "warn";
        }

        return "ok";
    }

    if (percent <= 25) {
        return "danger";
    }

    if (percent < 50) {
        return "warn";
    }

    return "ok";
}

/**
 * Renders one normalized PlayerStat as a Needs Expanded body row.
 *
 * Returns null when required row data is invalid. Panel-level code decides
 * whether to skip an invalid item or return an empty body so PZ Pulse shows
 * its standard "No data" state.
 *
 * @param {PlayerStat} stat
 * @returns {string|null}
 */
function renderStatRow(stat) {
    if (stat === null || stat === undefined) {
        return null;
    }

    const percent = normalizePercent(stat);
    const formattedValue = formatStatValue(stat);
    const barClass = statBarClass(stat);

    if (
        percent === null ||
        formattedValue === null ||
        barClass === null
    ) {
        return null;
    }

    if (typeof stat.label !== "string" || stat.label.trim() === "") {
        return null;
    }

    // PZ_MOODLE_ICONS is a useful PZ Pulse browser global, but it is not part
    // of the documented stable extension API. Missing upstream icon data must
    // degrade to an empty spacer instead of breaking the row.
    const iconMap =
        window.PZ_MOODLE_ICONS &&
        typeof window.PZ_MOODLE_ICONS === "object"
            ? window.PZ_MOODLE_ICONS
            : {};

    const iconKey =
        typeof stat.iconKey === "string" &&
        stat.iconKey.trim() !== ""
            ? stat.iconKey
            : null;

    const iconUri = iconKey ? iconMap[iconKey] : null;

    const iconHtml =
        typeof iconUri === "string" && iconUri.trim() !== ""
            ? `<img class="needs-expanded-icon" src="${esc(iconUri)}" alt="">`
            : `<span class="needs-expanded-icon needs-expanded-icon-blank"></span>`;

    return `
        <div class="needs-expanded-row">
            ${iconHtml}

            <span class="needs-expanded-label">
                ${esc(stat.label)}
            </span>

            <span class="needs-expanded-bar">
                <span
                    class="needs-expanded-fill ${barClass}"
                    style="width:${percent}%"
                ></span>
            </span>

            <span class="needs-expanded-value">
                ${esc(formattedValue)}
            </span>
        </div>
    `;
}
