function fmt(value) {
    // Convert to num
    let num = Number(value);

    if (!Number.isFinite(num)) {
        return null;
    }
    
    // Clamp to 0-100 and round to nearest integer
    num = Math.max(0, Math.min(100, num));
    return `${num.toFixed(0)}%`;
}

function needsExpandedBarClass(value) {
    
}

function needsExpandedRow(label, value, iconKey) {
    var moodleMap = window.PZ_MOODLE_ICONS || {};
    var iconURI = iconKey && moodleMap[iconKey] ? moodleMap[iconKey] : null;
    return `<div><span></span></div>`;
}
