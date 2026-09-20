const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const vm = require("node:vm");

const scriptPath = path.join(__dirname, "..", "42", "media", "web", "expanded-needs.js");
const source = fs.readFileSync(scriptPath, "utf8");

function escapeHtml(value) {
    return String(value == null ? "" : value)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;");
}

function loadRenderer() {
    const context = vm.createContext({
        console,
        esc: escapeHtml,
        window: {}
    });

    vm.runInContext(`${source}\n;globalThis.__test = {
        adaptNaturesCallStats,
        adaptOptionalModStats,
        adaptCustomMoodles,
        adaptPzPulseMoodles,
        adaptPzPulseNeeds,
        buildPlayerStat,
        isValidMoodle,
        normalizePercent,
        renderNeedsExpanded,
        renderMoodleBadge,
        renderPlayerStatRow,
        statBarClass
    };`, context, { filename: scriptPath });

    return { context, api: context.__test };
}

function vanillaNeeds() {
    return [
        { label: "Hunger", value: 0, badHigh: true, icon: "status_hunger" },
        { label: "Thirst", value: 10, badHigh: true, icon: "status_thirst" },
        { label: "Fatigue", value: 20, badHigh: true, icon: "mood_sleepy" },
        { label: "Stamina", value: 25, badHigh: false, icon: "status_difficultybreathing" },
        { label: "Boredom", value: 40, badHigh: true, icon: "mood_bored" },
        { label: "Stress", value: 50, badHigh: true, icon: "mood_stressed" },
        { label: "Panic", value: 60, badHigh: true, icon: "mood_panicked" },
        { label: "Unhappiness", value: 70, badHigh: true, icon: "mood_sad" },
        { label: "Pain", value: 75, badHigh: true, icon: "mood_pained" },
        { label: "Sickness", value: 80, badHigh: true, icon: "mood_nauseous" },
        { label: "Wetness", value: 90, badHigh: true, icon: "status_wet" },
        { label: "Drunkenness", value: 100, badHigh: true, icon: "mood_drunk" }
    ];
}

function count(haystack, needle) {
    return haystack.split(needle).length - 1;
}

function compactHtml(html) {
    return html.replace(/\s+/g, " ");
}

function countLabel(html, label) {
    return count(
        compactHtml(html),
        `class="needs-expanded-label"> ${label} </span>`
    );
}

test("renders all vanilla Needs+ rows, Discomfort, and Nature's Call exactly once in order", () => {
    const { api } = loadRenderer();
    const payload = {
        needs: vanillaNeeds(),
        needs_expanded: {
            discomfort: 27.42,
            natures_call: { bladder: 60, bowel: 0 }
        }
    };
    const before = JSON.stringify(payload);
    const html = api.renderNeedsExpanded(payload);

    assert.equal(count(html, 'class="needs-expanded-row"'), 15);
    for (const label of [
        "Hunger", "Thirst", "Fatigue", "Stamina", "Boredom", "Stress",
        "Panic", "Unhappiness", "Pain", "Sickness", "Wetness",
        "Drunkenness", "Discomfort", "Bladder", "Bowel"
    ]) {
        assert.equal(countLabel(html, label), 1, label);
    }
    assert.ok(html.indexOf("Hunger") < html.indexOf("Discomfort"));
    assert.ok(html.indexOf("Discomfort") < html.indexOf("Bladder"));
    assert.equal(JSON.stringify(payload), before, "shared payload was mutated");
    assert.match(html, /Source: Project Zomboid/);
    assert.match(html, /Source: Nature's Call/);
});

test("normalizes source ranges and applies direction-aware semantic colors", () => {
    const { api } = loadRenderer();
    const highBad = api.buildPlayerStat("high_bad", 60, {
        label: "High bad", min: 0, max: 120, badHigh: true,
        source: { type: "mod", id: "test", name: "Test" }
    });
    const highGood = api.buildPlayerStat("high_good", 25, {
        label: "High good", min: 0, max: 100, badHigh: false,
        source: { type: "base_game", id: "test", name: "Test" }
    });

    assert.equal(api.normalizePercent(highBad), 50);
    assert.equal(api.statBarClass(highBad), "warn");
    assert.equal(api.statBarClass(highGood), "danger");
});

test("keeps valid zeroes and skips malformed individual source values", () => {
    const { api } = loadRenderer();
    const needs = vanillaNeeds();
    needs[1].value = null;
    needs[2].value = "";
    needs[4].badHigh = "true";

    const html = api.renderNeedsExpanded({
        needs,
        needs_expanded: {
            discomfort: 0,
            natures_call: { bladder: 0, bowel: "bad" }
        }
    });

    assert.match(compactHtml(html), /needs-expanded-value"> 0% <\/span>/);
    assert.equal(countLabel(html, "Hunger"), 1);
    assert.equal(countLabel(html, "Discomfort"), 1);
    assert.equal(countLabel(html, "Bladder"), 1);
    assert.equal(countLabel(html, "Thirst"), 0);
    assert.equal(countLabel(html, "Fatigue"), 0);
    assert.equal(countLabel(html, "Boredom"), 0);
    assert.equal(countLabel(html, "Bowel"), 0);
});

test("handles Nature's Call absent, uninitialized, and present independently", () => {
    const { api } = loadRenderer();
    const base = { needs: vanillaNeeds(), needs_expanded: { discomfort: 10 } };

    assert.equal(countLabel(api.renderNeedsExpanded(base), "Bladder"), 0);
    assert.equal(countLabel(api.renderNeedsExpanded(base), "Bowel"), 0);

    const uninitialized = api.renderNeedsExpanded({
        ...base,
        needs_expanded: { discomfort: 10, natures_call: {} }
    });
    assert.equal(countLabel(uninitialized, "Bladder"), 0);
    assert.equal(countLabel(uninitialized, "Bowel"), 0);

    const present = api.renderNeedsExpanded({
        ...base,
        needs_expanded: { discomfort: 10, natures_call: { bladder: 0 } }
    });
    assert.equal(countLabel(present, "Bladder"), 1);
});

test("renders optional mod stats independently and omits missing or malformed values", () => {
    const { api } = loadRenderer();
    const html = api.renderNeedsExpanded({
        needs_expanded: {
            optional_mod_stats: {
                lifestyle_hygiene_need: 67,
                tasab_body_grime: "bad",
                bydt_dental_hygiene: 0.82
            }
        }
    });

    assert.equal(countLabel(html, "Hygiene Need"), 1);
    assert.equal(countLabel(html, "Body Grime"), 0);
    assert.equal(countLabel(html, "Dental Hygiene"), 1);
    assert.match(html, /Source: Lifestyle: Hobbies/);
    assert.match(html, /Source: Brush Your Damn Teeth/);
});

test("renders only active valid modded moodles with level and provenance", () => {
    const { api } = loadRenderer();
    const source = { type: "mod", id: "TakeABathAndShowerNew", name: "Take A Bath And Shower" };
    const moodles = [
        {
            id: "TakeABathAndShowerNew:BodyGrime",
            label: "Body Grime",
            description: "Time to wash.",
            level: 3,
            maxLevel: 4,
            valence: "bad",
            iconKey: "tasab/BodyGrime",
            source
        },
        {
            id: "TakeABathAndShowerNew:CoolingBody",
            label: "Cooling Body",
            level: 2,
            maxLevel: 4,
            valence: "good",
            iconKey: "tasab/CoolingBody",
            source
        },
        {
            id: "inactive",
            label: "Inactive",
            level: 0,
            maxLevel: 4,
            valence: "bad",
            source
        },
        {
            id: "malformed",
            label: "Malformed",
            level: 2,
            maxLevel: 4,
            valence: "neutral",
            source
        }
    ];

    const before = JSON.stringify(moodles);
    const html = api.renderNeedsExpanded({
        needs_expanded: { custom_moodles: moodles }
    });

    assert.equal(api.adaptCustomMoodles(moodles).length, 2);
    assert.equal(count(html, "needs-expanded-moodle-badge"), 2);
    assert.match(html, /Body Grime/);
    assert.match(html, /Cooling Body/);
    assert.doesNotMatch(html, /Inactive/);
    assert.doesNotMatch(html, /Malformed/);
    assert.doesNotMatch(html, /Active Moodles/);
    assert.match(html, /<b>3<\/b>/);
    assert.doesNotMatch(html, /needs-expanded-moodle-row/);
    assert.match(html, /Source: Take A Bath And Shower/);
    assert.equal(JSON.stringify(moodles), before, "moodle payload was mutated");
});

test("keeps stat and moodle nullability independent", () => {
    const { api } = loadRenderer();
    const moodleOnly = api.renderNeedsExpanded({
        needs_expanded: {
            custom_moodles: [{
                id: "DrugTime89:Stoned",
                label: "Stoned",
                level: 1,
                maxLevel: 3,
                valence: "good",
                iconKey: "drugtime/DT_Stoned_1",
                source: { type: "mod", id: "DrugTime89", name: "DrugTime 89" }
            }]
        }
    });

    assert.notEqual(moodleOnly, "");
    assert.equal(count(moodleOnly, "needs-expanded-moodle-badge"), 1);
    assert.match(moodleOnly, /Stoned/);
    assert.equal(api.renderNeedsExpanded({
        needs_expanded: { custom_moodles: [{}], optional_mod_stats: {} }
    }), "");
});

test("uses icon spacers when globals or keys are missing and escapes HTML", () => {
    const { api, context } = loadRenderer();
    const stat = api.buildPlayerStat("unsafe", 50, {
        label: '<Unsafe & "label">',
        description: 'A "quoted" description.',
        min: 0,
        max: 100,
        badHigh: true,
        iconKey: "unsafe_icon",
        source: { type: "mod", id: "unsafe", name: 'Source "name"' }
    });

    const withoutMap = api.renderPlayerStatRow(stat);
    assert.match(withoutMap, /needs-expanded-icon-blank/);
    assert.doesNotMatch(withoutMap, /<Unsafe/);
    assert.match(withoutMap, /&lt;Unsafe &amp; &quot;label&quot;&gt;/);
    assert.match(withoutMap, /Source: Source &quot;name&quot;/);

    context.window.PZ_MOODLE_ICONS = { unsafe_icon: 'icon" onerror="bad' };
    const withMap = api.renderPlayerStatRow(stat);
    assert.match(withMap, /src="icon&quot; onerror=&quot;bad"/);
    assert.doesNotMatch(withMap, /src="icon" onerror=/);
});

test("renders an icon for every built-in stat bar", () => {
    const { api, context } = loadRenderer();
    const baseIconKeys = [
        "status_hunger", "status_thirst", "mood_sleepy",
        "status_difficultybreathing", "mood_bored", "mood_stressed",
        "mood_panicked", "mood_sad", "mood_pained", "mood_nauseous",
        "status_wet", "mood_drunk", "mood_discomfort"
    ];
    context.window.PZ_MOODLE_ICONS = Object.fromEntries(
        baseIconKeys.map((key) => [key, `data:${key}`])
    );

    const html = api.renderNeedsExpanded({
        needs: vanillaNeeds(),
        needs_expanded: {
            discomfort: 20,
            natures_call: { bladder: 40, bowel: 50 },
            optional_mod_stats: {
                lifestyle_hygiene_need: 60,
                tasab_body_grime: 70,
                bydt_dental_hygiene: 0.8
            }
        }
    });

    assert.equal(count(html, 'class="needs-expanded-row"'), 18);
    assert.equal(count(html, 'class="needs-expanded-icon"'), 18);
    assert.doesNotMatch(html, /needs-expanded-icon-blank/);
    assert.match(html, /data:image\/png;base64/);
});

test("returns an empty body only when no usable source rows remain", () => {
    const { api } = loadRenderer();
    assert.equal(api.renderNeedsExpanded(null), "");
    assert.equal(api.renderNeedsExpanded({}), "");
    assert.notEqual(api.renderNeedsExpanded({ needs: vanillaNeeds() }), "");
    assert.notEqual(api.renderNeedsExpanded({ needs_expanded: { discomfort: 12 } }), "");
});

test("renders PZ Pulse vanilla moodles through the same icon badge layout", () => {
    const { api, context } = loadRenderer();
    context.window.PZ_MOODLE_ICONS = {
        status_hunger: "glyph",
        circle_bad3: "circle"
    };

    const html = api.renderNeedsExpanded({
        moodles: [{ label: "Very Hungry", level: 3, icon: "status_hunger", valence: "bad" }]
    });

    assert.equal(api.adaptPzPulseMoodles(null).length, 0);
    assert.equal(count(html, "needs-expanded-moodle-badge"), 1);
    assert.match(html, /src="circle"/);
    assert.match(html, /src="glyph"/);
    assert.match(html, /<b>3<\/b>/);
});
