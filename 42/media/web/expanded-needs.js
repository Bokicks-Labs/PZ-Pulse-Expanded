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

function isFiniteNumbers(...nums) {
    for (let num of nums) {
        if (!isFiniteNumber(num)) {
            return false;
        }
    }
    return true;
}

function clamp(value, min, max, round, precision = 0) {

    if (!isFiniteNumbers(value, min, max)) {
        return null;
    }

    // Convert to nums
    let _value = Number(value);
    let _min = Number(min);
    let _max = Number(max);

    if (_max < _min) {
        return null;
    }

    let clamped = Math.max(_min, Math.min(_max, _value));
    let rounded = round ? Number(clamped.toFixed(precision)) : clamped;

    return rounded;
}

function normalizePercent(stat) {
    if (stat === null || stat === undefined) {
        return null;
    }

    if (!isFiniteNumbers(stat.value, stat.min, stat.max)) {
        return null;
    }

    let value = Number(stat.value);
    let min = Number(stat.min);
    let max = Number(stat.max);

    if (max <= min) {
        return null;
    }

    value = clamp(value, min, max, false);

    if (value === null) {
        return null;
    }

    let percent = (value - min) / (max - min) * 100;

    return percent;
}

function formatStatValue(stat) {
    const percent = normalizePercent(stat);

    if (percent === null) {
        return null;
    }

    return `${percent.toFixed(0)}%`;
}

function statBarClass(stat) {
    const percent = normalizePercent(stat);

    if (percent === null) {
        return null;
    }

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
        typeof iconUri === "string" && iconUri !== ""
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
