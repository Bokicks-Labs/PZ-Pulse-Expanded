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

    // TODO: Need a way to send useful error messages to the console for debugging
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

function needsExpandedBarClass(value) {

}

function needsExpandedRow(label, value, iconKey) {
    var moodleMap = window.PZ_MOODLE_ICONS || {};
    var iconURI = iconKey && moodleMap[iconKey] ? moodleMap[iconKey] : null;
    return `<div><span></span></div>`;
}
