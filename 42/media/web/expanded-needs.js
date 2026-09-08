/*
     ██╗███████╗    ██████╗  ██████╗  ██████╗    ██████╗ ███████╗███████╗██╗███╗   ██╗██╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
     ██║██╔════╝    ██╔══██╗██╔═══██╗██╔════╝    ██╔══██╗██╔════╝██╔════╝██║████╗  ██║██║╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
     ██║███████╗    ██║  ██║██║   ██║██║         ██║  ██║█████╗  █████╗  ██║██╔██╗ ██║██║   ██║   ██║██║   ██║██╔██╗ ██║███████╗
██   ██║╚════██║    ██║  ██║██║   ██║██║         ██║  ██║██╔══╝  ██╔══╝  ██║██║╚██╗██║██║   ██║   ██║██║   ██║██║╚██╗██║╚════██║
╚█████╔╝███████║    ██████╔╝╚██████╔╝╚██████╗    ██████╔╝███████╗██║     ██║██║ ╚████║██║   ██║   ██║╚██████╔╝██║ ╚████║███████║
 ╚════╝ ╚══════╝    ╚═════╝  ╚═════╝  ╚═════╝    ╚═════╝ ╚══════╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

*/

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
 * Base normalized numeric stat.
 *
 * @typedef {Object} Stat
 * @property {string} id
 * @property {string} label
 * @property {string} [description]
 * @property {number|string} value
 * @property {number|string} min
 * @property {number|string} max
 * @property {StatSource} source
 */

/**
 * Live numeric state about the current player.
 *
 * @typedef {Stat & Object} PlayerStat
 * @property {boolean} badHigh
 * @property {string} [iconKey]
 * @property {boolean} [visibleByDefault=true]
 */

/*
███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗    ██████╗ ███████╗███████╗██╗███╗   ██╗██╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║    ██╔══██╗██╔════╝██╔════╝██║████╗  ██║██║╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║    ██║  ██║█████╗  █████╗  ██║██╔██╗ ██║██║   ██║   ██║██║   ██║██╔██╗ ██║███████╗
██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║    ██║  ██║██╔══╝  ██╔══╝  ██║██║╚██╗██║██║   ██║   ██║██║   ██║██║╚██╗██║╚════██║
██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║    ██████╔╝███████╗██║     ██║██║ ╚████║██║   ██║   ██║╚██████╔╝██║ ╚████║███████║
╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝    ╚═════╝ ╚══════╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

*/

/*
  ____  _        _     ____        __ _       _ _   _
 / ___|| |_ __ _| |_  |  _ \  ___ / _(_)_ __ (_) |_(_) ___  _ __  ___
 \___ \| __/ _` | __| | | | |/ _ \ |_| | '_ \| | __| |/ _ \| '_ \/ __|
  ___) | || (_| | |_  | |_| |  __/  _| | | | | | |_| | (_) | | | \__ \
 |____/ \__\__,_|\__| |____/ \___|_| |_|_| |_|_|\__|_|\___/|_| |_|___/

*/

const PLAYER_STAT_DEFINITIONS = {
    discomfort: {
        label: "Discomfort",
        description: "Current underlying discomfort level.",

        min: 0,
        max: 100,

        badHigh: true,
        iconKey: "mood_discomfort",
        visibleByDefault: true,

        source: {
            type: "base_game",
            id: "project_zomboid",
            name: "Project Zomboid"
        }
    }
};

/*
 __     __    _ _     _       _   _               _____                 _   _
 \ \   / /_ _| (_) __| | __ _| |_(_) ___  _ __   |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
  \ \ / / _` | | |/ _` |/ _` | __| |/ _ \| '_ \  | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
   \ V / (_| | | | (_| | (_| | |_| | (_) | | | | |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
    \_/ \__,_|_|_|\__,_|\__,_|\__|_|\___/|_| |_| |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/

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
 * Returns true for strings containing at least one non-whitespace character.
 *
 * @param {*} value
 * @returns {boolean}
 */
function isNonEmptyString(value) {
    return typeof value === "string" && value.trim() !== "";
}

/**
 * Validates that a value is a non-null, non-undefined object.
 * 
 * @param {*} value
 * @returns {boolean}
 */
function isValidObject(value) {
    return (
        value !== null && typeof value === "object" && !Array.isArray(value)
    );
}

/**
 * Validates provenance metadata for a normalized PlayerStat.
 *
 * @param {*} source
 * @returns {source is StatSource}
 */
function isValidStatSource(source) {
    if (!isValidObject(source)) {
        return false;
    }

    if (
        source.type !== "base_game" &&
        source.type !== "mod"
    ) {
        return false;
    }

    if (
        !isNonEmptyString(source.id)
    ) {
        return false;
    }

    if (
        !isNonEmptyString(source.name)
    ) {
        return false;
    }

    return true;
}

/**
 * Validates the complete Stat base object.
 * 
 * @param {*} stat
 * @returns {boolean}
 */
function isValidStat(stat) {
    if (!isValidObject(stat)) {
        return false;
    }

    if (
        !isNonEmptyString(stat.id) ||
        !isNonEmptyString(stat.label) ||
        !isFiniteNumbers(stat.value, stat.min, stat.max)
    ) {
        return false;
    }

    const min = Number(stat.min);
    const max = Number(stat.max);

    if (max <= min) {
        return false;
    }

    if (
        !isValidStatSource(stat.source)
    ) {
        return false;
    }

    // Optional fields must still satisfy their documented type when supplied.
    if (
        stat.description !== undefined &&
        !isNonEmptyString(stat.description)
    ) {
        return false;
    }

    return true;
}

/**
 * Validates the complete normalized PlayerStat contract.
 *
 * Values outside [min, max] are still valid because presentation code clamps
 * them during normalization. The range itself must be valid.
 *
 * @param {*} stat
 * @returns {boolean}
 */
function isValidPlayerStat(stat) {
    if (!isValidStat(stat)) {
        return false;
    }

    if (typeof stat.badHigh !== "boolean") {
        return false;
    }

    // Optional fields must still satisfy their documented type when supplied.
    if (
        stat.iconKey !== undefined &&
        !isNonEmptyString(stat.iconKey)
    ) {
        return false;
    }

    if (
        stat.visibleByDefault !== undefined &&
        typeof stat.visibleByDefault !== "boolean"
    ) {
        return false;
    }

    return true;
}

/*
  ____        _ _     _             _____                 _   _
 | __ ) _   _(_) | __| | ___ _ __  |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
 |  _ \| | | | | |/ _` |/ _ \ '__| | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
 | |_) | |_| | | | (_| |  __/ |    |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
 |____/ \__,_|_|_|\__,_|\___|_|    |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/

*/

/**
 * Combines a live numeric value with a static PlayerStat definition.
 *
 * @param {string} id
 * @param {*} value
 * @param {*} definition
 * @returns {PlayerStat|null}
 */
function buildPlayerStat(id, value, definition) {
    if (!isNonEmptyString(id)) {
        return null;
    }

    if (!isFiniteNumber(value)) {
        return null;
    }

    if (
        !isValidObject(definition)
    ) {
        return null;
    }

    const stat = {
        ...definition,
        id,
        value
    };

    return isValidPlayerStat(stat)
        ? stat
        : null;
}

/**
 * Builds normalized PlayerStats from a keyed live-value payload.
 *
 * Values without a matching definition are ignored.
 *
 * @param {*} values
 * @param {*} definitions
 * @returns {PlayerStat[]}
 */
function buildPlayerStats(values, definitions) {
    if (
        !isValidObject(values)
    ) {
        return [];
    }

    if (
        !isValidObject(definitions)
    ) {
        return [];
    }

    const stats = [];

    for (const [id, definition] of Object.entries(definitions)) {
        const value = values[id];

        if (value === undefined) {
            continue;
        }

        const stat = buildPlayerStat(
            id,
            value,
            definition
        );

        if (stat !== null) {
            stats.push(stat);
        }
    }
    return stats;
}

/*
  __  __       _   _       _____                 _   _
 |  \/  | __ _| |_| |__   |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
 | |\/| |/ _` | __| '_ \  | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
 | |  | | (_| | |_| | | | |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
 |_|  |_|\__,_|\__|_| |_| |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/

*/

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
 * Converts a normalized Stat into a numeric percentage from 0 to 100.
 *
 * The raw value is clamped before normalization. A zero-width or reversed
 * range is invalid because it cannot be normalized meaningfully.
 *
 * @param {Stat} stat
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

/*
  _____                          _      ___     ____                _           _               _   _      _
 |  ___|__  _ __ _ __ ___   __ _| |_   ( _ )   |  _ \ ___ _ __   __| | ___ _ __(_)_ __   __ _  | | | | ___| |_ __   ___ _ __ ___
 | |_ / _ \| '__| '_ ` _ \ / _` | __|  / _ \/\ | |_) / _ \ '_ \ / _` |/ _ \ '__| | '_ \ / _` | | |_| |/ _ \ | '_ \ / _ \ '__/ __|
 |  _| (_) | |  | | | | | | (_| | |_  | (_>  < |  _ <  __/ | | | (_| |  __/ |  | | | | | (_| | |  _  |  __/ | |_) |  __/ |  \__ \
 |_|  \___/|_|  |_| |_| |_|\__,_|\__|  \___/\/ |_| \_\___|_| |_|\__,_|\___|_|  |_|_| |_|\__, | |_| |_|\___|_| .__/ \___|_|  |___/
                                                                                        |___/               |_|
*/

/**
 * Formats a PlayerStat's normalized value for the Needs Expanded row.
 *
 * Formatting is intentionally separate from normalization. The bar keeps full
 * percentage precision while the visible text currently rounds to a whole
 * percentage.
 *
 * @param {Stat} stat
 * @param {"raw"|"percentage"} format
 * @returns {string|null}
 */
function formatStatValue(stat, format) {
    if (!isValidStat(stat)) {
        return null;
    }

    switch (format) {
        case "raw":
            if (!isFiniteNumbers(stat.value)) {
                return null;
            }

            return String(Number(stat.value));

        case "percentage":
            const percent = normalizePercent(stat);
            return percent === null ? null : `${percent.toFixed(0)}%`;

        default:
            return null;
    }

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
 * Builds player-facing tooltip text for a normalized PlayerStat.
 *
 * Tooltip content includes the stat label, optional description, normalized
 * display value, and provenance.
 *
 * @param {*} stat
 * @returns {string|null}
 */
function formatStatTooltip(stat) {
    if (!isValidPlayerStat(stat)) {
        return null;
    }

    const formattedValue = formatStatValue(stat, "raw");

    if (formattedValue === null) {
        return null;
    }

    const lines = [
        stat.label
    ];

    if (
        typeof stat.description === "string" &&
        stat.description.trim() !== ""
    ) {
        lines.push(
            "",
            stat.description.trim()
        );
    }

    lines.push(
        "",
        `Value: ${formattedValue}`,
        `Source: ${stat.source.name}`
    );

    return lines.join("\n");
}

/*
  ____                _
 |  _ \ ___ _ __   __| | ___ _ __ ___ _ __ ___
 | |_) / _ \ '_ \ / _` |/ _ \ '__/ _ \ '__/ __|
 |  _ <  __/ | | | (_| |  __/ | |  __/ |  \__ \
 |_| \_\___|_| |_|\__,_|\___|_|  \___|_|  |___/

*/

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
function renderPlayerStatRow(stat) {
    if (!isValidPlayerStat(stat)) {
        return null;
    }

    const percent = normalizePercent(stat);
    const formattedValue = formatStatValue(stat, "percentage");
    const barClass = statBarClass(stat);

    if (
        percent === null ||
        formattedValue === null ||
        barClass === null
    ) {
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

    const tooltip = formatStatTooltip(stat);

    if (tooltip === null) {
        return null;
    }

    return `
    <div
        class="needs-expanded-row"
        title="${esc(tooltip)}"
    >
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

/**
 * Renders the Needs Expanded panel from the complete PZ Pulse payload.
 *
 * PZ Pulse places this extension's collector result at d.needs_expanded.
 * Missing or unusable extension data returns an empty body so PZ Pulse can
 * display its standard "No data" state.
 *
 * @param {*} d
 * @returns {string}
 */
function renderNeedsExpanded(d) {
    if (!isValidObject(d)) {
        return "";
    }

    const values = d.needs_expanded;

    if (!isValidObject(values)) {
        return "";
    }

    const stats = buildPlayerStats(
        values,
        PLAYER_STAT_DEFINITIONS
    );

    if (stats.length === 0) {
        return "";
    }

    const rows = [];

    for (const stat of stats) {
        const row = renderPlayerStatRow(stat);

        if (row !== null) {
            rows.push(row);
        }
    }

    if (rows.length === 0) {
        return "";
    }

    return `
        <div class="needs-expanded">
            <div class="needs-expanded-rows">
                ${rows.join("")}
            </div>
        </div>
    `;
}
