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

function loadRenderer(savedBars = null, options = null, savedPins = null, savedOrder = null) {
    let now = 1000;
    let pending = null;
    const context = vm.createContext({
        console,
        esc: escapeHtml,
        window: {},
        Date: { now: () => now },
        o: name => options ? options[name] : undefined,
        setTimeout: (callback, delay) => { pending = { callback, due: now + delay }; return 1; },
        clearTimeout: () => { pending = null; },
        localStorage: {
            getItem: key => {
                const value = key.includes("pins.v1") ? savedPins
                    : key.includes("order.v1") ? savedOrder : savedBars;
                return value === null ? null : JSON.stringify(value);
            },
            setItem: () => {},
            removeItem: () => {}
        }
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
        statBarClass,
        BAR_CHOICES,
        BAR_GROUPS,
        renderBarChoices,
        setBarGroupVisible,
        moveBar,
        resetBarOrder,
        normalizeBarOrder,
        getBarOrder: () => barOrder.slice(),
        tooltipText: id => tooltipTexts.get(id)
    };`, context, { filename: scriptPath });

    return {
        context,
        api: context.__test,
        advance(ms) {
            now += ms;
            if (pending && pending.due <= now) {
                const callback = pending.callback;
                pending = null;
                callback();
            }
        },
        pending: () => pending
    };
}

test("auto-hide waits after a bar returns to zero and flash expires on a timer", () => {
    const renderer = loadRenderer(null, {
        auto_hide_zero: true,
        zero_hide_delay: 5,
        flash_increases: true,
        flash_seconds: 2
    });
    const payload = { needs: vanillaNeeds(), needs_expanded: {} };
    renderer.context.window.PZ_DATA = payload;
    let lastHtml = "";
    renderer.context.updateContent = data => { lastHtml = renderer.api.renderNeedsExpanded(data); };

    let html = renderer.api.renderNeedsExpanded(payload);
    assert.equal(countLabel(html, "Hunger"), 0);
    assert.equal(countLabel(html, "Stamina"), 1);

    payload.needs[0].value = 15;
    html = renderer.api.renderNeedsExpanded(payload);
    assert.equal(countLabel(html, "Hunger"), 1);
    assert.match(html, /needs-expanded-bar-flash/);
    assert.equal(renderer.pending().due, 4200);

    renderer.advance(1000);
    payload.needs[0].value = 16;
    html = renderer.api.renderNeedsExpanded(payload);
    assert.match(html, /needs-expanded-bar-flash/);
    assert.match(html, /--needs-expanded-flash-offset:-1000ms/,
        "panel updates keep the current pulse phase");
    assert.equal(renderer.pending().due, 4200, "later increases do not restart the flash");

    renderer.advance(1000);
    assert.match(renderer.api.renderNeedsExpanded(payload), /needs-expanded-bar-flash/,
        "the flash continues past its requested time to finish the current pulse");
    renderer.advance(1200);
    assert.equal(count(lastHtml, "needs-expanded-bar-flash"), 0);

    payload.needs[0].value = 20;
    html = renderer.api.renderNeedsExpanded(payload);
    assert.equal(count(html, "needs-expanded-bar-flash"), 0);

    payload.needs[0].value = 0;
    html = renderer.api.renderNeedsExpanded(payload);
    assert.equal(countLabel(html, "Hunger"), 1);
    assert.equal(renderer.pending().due, 9200);
    renderer.advance(5000);
    assert.equal(countLabel(lastHtml, "Hunger"), 0);
});

test("auto-hide respects zero-is-bad bars and individual bar choices", () => {
    const { api } = loadRenderer({ hunger: false }, {
        auto_hide_zero: true,
        zero_hide_delay: 5,
        flash_increases: false
    });
    const needs = vanillaNeeds();
    needs[3].value = 0;
    const html = api.renderNeedsExpanded({ needs, needs_expanded: {} });
    assert.equal(countLabel(html, "Hunger"), 0);
    assert.equal(countLabel(html, "Stamina"), 1);
    assert.equal(count(html, "needs-expanded-bar-flash"), 0);
});

test("pins keep zero bars visible and suppress reveal flashes", () => {
    const renderer = loadRenderer(null, {
        auto_hide_zero: true,
        flash_increases: true,
        flash_seconds: 3
    }, { hunger: true });
    const payload = { needs: vanillaNeeds(), needs_expanded: {} };
    let html = renderer.api.renderNeedsExpanded(payload);
    assert.equal(countLabel(html, "Hunger"), 1);
    payload.needs[0].value = 10;
    html = renderer.api.renderNeedsExpanded(payload);
    assert.equal(count(html, "needs-expanded-bar-flash"), 0);
});

test("flash setting has no effect without auto-hide", () => {
    const renderer = loadRenderer(null, { auto_hide_zero: false, flash_increases: true });
    const payload = { needs: vanillaNeeds(), needs_expanded: {} };
    renderer.api.renderNeedsExpanded(payload);
    payload.needs[0].value = 10;
    const html = renderer.api.renderNeedsExpanded(payload);
    assert.equal(count(html, "needs-expanded-bar-flash"), 0);
});

test("auto-hide uses the new flash and hide defaults", () => {
    const renderer = loadRenderer(null, { auto_hide_zero: true });
    const payload = { needs: vanillaNeeds(), needs_expanded: {} };
    renderer.context.window.PZ_DATA = payload;
    renderer.context.updateContent = data => renderer.api.renderNeedsExpanded(data);

    renderer.api.renderNeedsExpanded(payload);
    payload.needs[0].value = 10;
    let html = renderer.api.renderNeedsExpanded(payload);
    assert.match(html, /needs-expanded-bar-flash/);
    assert.equal(renderer.pending().due, 9000);

    payload.needs[0].value = 0;
    html = renderer.api.renderNeedsExpanded(payload);
    assert.equal(countLabel(html, "Hunger"), 1);
    assert.equal(renderer.pending().due, 9000);
    renderer.advance(7000);
    assert.equal(renderer.pending().due, 9000);
    renderer.advance(1000);
    assert.equal(renderer.pending().due, 11000);
});

test("icon controls size only Needs Expanded and validate saved scales", () => {
    const payload = { needs: vanillaNeeds(), needs_expanded: {} };
    const defaults = loadRenderer().api.renderNeedsExpanded(payload);
    assert.match(defaults, /--needs-expanded-moodle-size:56px;--needs-expanded-bar-icon-size:24px/);

    const adjusted = loadRenderer(null, {
        moodle_icon_scale: 3.5,
        bar_icon_scale: 2.25
    }).api.renderNeedsExpanded(payload);
    assert.match(adjusted, /--needs-expanded-moodle-size:49px;--needs-expanded-bar-icon-size:27px/);

    const invalid = loadRenderer(null, {
        moodle_icon_scale: 100,
        bar_icon_scale: "bad"
    }).api.renderNeedsExpanded(payload);
    assert.match(invalid, /--needs-expanded-moodle-size:56px;--needs-expanded-bar-icon-size:24px/);

    const css = fs.readFileSync(path.join(__dirname, "..", "42", "media", "web", "expanded-needs.css"), "utf8");
    assert.doesNotMatch(css, /var\(--(?:moodle-size|need-icon-size)/);
    assert.match(css, /\.needs-expanded-bar\s*\{[^}]*height:\s*calc\(var\(--needs-expanded-bar-icon-size\) \* 0\.5\)/s);
});

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
    const escaped = label.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    return (compactHtml(html).match(new RegExp(`class="needs-expanded-label"[^>]*> ${escaped} </span>`, "g")) || []).length;
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
    assert.match(api.tooltipText("stat:hunger"), /Source: Project Zomboid/);
    assert.match(api.tooltipText("stat:natures_call_bladder"), /Source: Nature's Call/);
});

test("keeps a Nature's Call tooltip visible across stat updates", () => {
    const renderer = loadRenderer();
    const listeners = {};
    const tooltipNodes = [];
    renderer.context.document = {
        body: { appendChild: node => tooltipNodes.push(node) },
        createElement: () => ({ style: {}, hidden: true, textContent: "", offsetWidth: 100, offsetHeight: 50 }),
        addEventListener: (name, handler) => { listeners[name] = handler; },
        querySelector: () => null
    };
    renderer.context.window.innerWidth = 800;
    renderer.context.window.innerHeight = 600;
    renderer.api.renderNeedsExpanded({ needs_expanded: { natures_call: { bladder: 60 } } });
    const target = { closest: () => ({ getAttribute: () => "stat:natures_call_bladder" }) };
    listeners.mouseover({ target, clientX: 40, clientY: 50 });
    assert.equal(tooltipNodes.length, 1);
    assert.equal(tooltipNodes[0].hidden, true, "tooltip waits before opening");
    renderer.api.renderNeedsExpanded({ needs_expanded: { natures_call: { bladder: 60.5 } } });
    renderer.advance(649);
    assert.equal(tooltipNodes[0].hidden, true);
    renderer.advance(1);
    assert.equal(tooltipNodes[0].hidden, false);
    assert.match(tooltipNodes[0].textContent, /60\.5/);
    assert.match(tooltipNodes[0].textContent, /Source: Nature's Call/);

    renderer.api.renderNeedsExpanded({ needs_expanded: { natures_call: { bladder: 61 } } });
    assert.equal(tooltipNodes[0].hidden, false);
    assert.match(tooltipNodes[0].textContent, /61/);
    listeners.mousemove({ target: { closest: () => null }, clientX: 40, clientY: 50 });
    assert.equal(tooltipNodes[0].hidden, true);
});

test("tooltip delay cancels when the pointer leaves before it opens", () => {
    const renderer = loadRenderer();
    const listeners = {};
    const tooltip = { style: {}, hidden: true, textContent: "", offsetWidth: 100, offsetHeight: 50 };
    renderer.context.document = {
        body: { appendChild() {} }, createElement: () => tooltip,
        addEventListener: (name, handler) => { listeners[name] = handler; },
        querySelector: () => null
    };
    renderer.context.window.innerWidth = 800;
    renderer.context.window.innerHeight = 600;
    renderer.api.renderNeedsExpanded({ needs_expanded: { natures_call: { bladder: 60 } } });
    listeners.mouseover({ target: { closest: () => ({ getAttribute: () => "stat:natures_call_bladder" }) }, clientX: 1, clientY: 1 });
    listeners.mousemove({ target: { closest: () => null }, clientX: 1, clientY: 1 });
    renderer.advance(700);
    assert.equal(tooltip.hidden, true);
});

test("bar order validates saved IDs and reorders visible rows", () => {
    const { api } = loadRenderer(null, null, null,
        ["natures_call_bladder", "hunger", "hunger", "unknown", 12]);
    assert.equal(api.getBarOrder()[0], "natures_call_bladder");
    assert.equal(api.getBarOrder()[1], "hunger");
    assert.equal(api.getBarOrder().length, api.BAR_CHOICES.length);
    const payload = { needs: vanillaNeeds(), needs_expanded: { natures_call: { bladder: 60 } } };
    let html = api.renderNeedsExpanded(payload);
    assert.ok(html.indexOf("Bladder") < html.indexOf("Hunger"));
    assert.equal(api.moveBar("hunger", -1), true);
    html = api.renderNeedsExpanded(payload);
    assert.ok(html.indexOf("Hunger") < html.indexOf("Bladder"));
    assert.equal(api.moveBar("unknown", 1), false);
    api.resetBarOrder();
    assert.equal(api.getBarOrder()[0], "hunger");
    assert.equal(api.normalizeBarOrder({ invalid: true }).length, api.BAR_CHOICES.length);
});

test("order view lists every bar and disables moves at the ends", () => {
    const { api, context } = loadRenderer();
    context.window.PZ_MOODLE_ICONS = { status_hunger: "hunger-icon" };
    context.__list = { innerHTML: "" };
    vm.runInContext(`barModal = { querySelector: () => __list };
        barChooserMode = "order"; barAvailability = {};`, context);
    api.renderBarChoices();
    const html = context.__list.innerHTML;
    assert.equal(count(html, 'class="needs-expanded-order-line"'), api.BAR_CHOICES.length);
    assert.match(html, /data-bar-move="-1" data-bar-id="hunger"[^>]* disabled/);
    assert.match(html, /data-bar-move="1" data-bar-id="casualties_euphoria"[^>]* disabled/);
    assert.match(html, /Reset order/);
    assert.match(html, /src="hunger-icon"/);
    assert.equal(count(html, 'class="needs-expanded-choice-icon"'), api.BAR_CHOICES.length);
});

test("renders the agreed new bars once and honors independent saved choices", () => {
    const { api } = loadRenderer({ addiction_alcohol: false, idleness: false });
    const html = api.renderNeedsExpanded({ needs_expanded: {
        vanilla_stats: { nicotine_withdrawal: 0.3, idleness: 0.4, poison: 12 },
        optional_mod_stats: {
            drugtime_stoned: 70, drugtime_hard: 80,
            addiction_alcohol: 50, addiction_nicotine: 40,
            addiction_caffeine: 30, addiction_painkillers: 20,
            addiction_sleeping_pills: 10, addiction_amphetamines: 0,
            caffeine_load: 2, caffeine_load_max: 8,
            casualties_euphoria: 0.64
        }
    }});
    assert.equal(api.BAR_CHOICES.length, 34);
    assert.equal(count(html, 'class="needs-expanded-row"'), 11);
    assert.equal(countLabel(html, "Nicotine Withdrawal"), 1);
    assert.equal(countLabel(html, "Poison"), 1);
    assert.equal(countLabel(html, "Caffeine Level"), 1);
    assert.equal(countLabel(html, "Drug Euphoria"), 1);
    assert.equal(countLabel(html, "Alcohol Addiction"), 0);
    assert.equal(countLabel(html, "Idleness"), 0);
});

test("adds one chooser button to this panel's gear and restores it after a menu rebuild", () => {
    const { api, context } = loadRenderer();
    let button = null;
    let observed = null;
    const gear = {
        querySelector(selector) {
            return selector === ".needs-expanded-choose-button" ? button : null;
        },
        insertBefore(node) { button = node; }
    };
    context.document = {
        querySelector(selector) {
            assert.match(selector, /pz_pulse_expanded__needs_expanded/);
            return { querySelector: () => gear };
        },
        createElement() {
            return { addEventListener() {} };
        }
    };
    context.MutationObserver = class {
        constructor(callback) { observed = callback; }
        observe() {}
    };
    api.renderNeedsExpanded({ needs: vanillaNeeds() });
    assert.equal(button.textContent, "Manage Stat Bars…");
    const first = button;
    api.renderNeedsExpanded({ needs: vanillaNeeds() });
    assert.equal(button, first, "normal renders do not add duplicate buttons");
    button = null;
    observed();
    assert.equal(button.textContent, "Manage Stat Bars…");
    assert.notEqual(button, first, "a rebuilt gear gets a fresh button");
});

test("unavailable mod bars have disabled checkboxes without losing their choice", () => {
    const { api, context } = loadRenderer({ drugtime_stoned: false });
    context.window.PZ_MOODLE_ICONS = { status_hunger: "hunger-icon" };
    context.__list = { innerHTML: "" };
    vm.runInContext(`barModal = { querySelector: () => __list };
        barAvailability = { DrugTime89: false, twbInfirmities: true };`, context);
    api.renderBarChoices();
    const html = context.__list.innerHTML;
    assert.match(html, /data-bar-id="drugtime_stoned" disabled/);
    assert.match(html, /data-bar-id="addiction_alcohol" checked/);
    assert.doesNotMatch(html, /data-bar-id="addiction_alcohol" checked disabled/);
    assert.match(html, /data-bar-group="DrugTime89" disabled/);
    assert.match(html, /data-bar-group="twbInfirmities" checked/);
    assert.match(html, /data-bar-pin="addiction_alcohol"/);
    assert.match(html, /data-bar-pin="drugtime_stoned" disabled/);
    assert.match(html, /src="hunger-icon"/);
    assert.equal(count(html, 'class="needs-expanded-choice-icon"'), api.BAR_CHOICES.length);
});

test("Caffeine Level has a bundled coffee icon and effect tooltip", () => {
    const { api } = loadRenderer();
    const html = api.renderNeedsExpanded({ needs_expanded: {
        optional_mod_stats: { caffeine_load: 1, caffeine_load_max: 4,
            addiction_caffeine: 2 }
    }});
    assert.equal(countLabel(html, "Caffeine Level"), 1);
    assert.match(html, /data:image\/png;base64,/);
    assert.match(api.tooltipText("stat:caffeine_load"), /separate from Infirmities/);
    assert.match(api.tooltipText("stat:addiction_caffeine"), /worsen fatigue during withdrawal/);
});

test("source toggle changes every bar in that source and preserves individual overrides", () => {
    const { api, context } = loadRenderer();
    vm.runInContext(`barAvailability = { twbInfirmities: true, DrugTime89: false };`, context);
    assert.equal(api.setBarGroupVisible("twbInfirmities", false), true);
    assert.equal(api.BAR_GROUPS.find(group => group.id === "twbInfirmities").choices.length, 6);
    assert.equal(api.setBarGroupVisible("DrugTime89", false), false);
    const hidden = api.renderNeedsExpanded({ needs_expanded: {
        optional_mod_stats: { addiction_alcohol: 20, addiction_caffeine: 30 }
    }});
    assert.equal(countLabel(hidden, "Alcohol Addiction"), 0);
    assert.equal(countLabel(hidden, "Caffeine Addiction"), 0);
    vm.runInContext(`barPreferences.addiction_caffeine = true;`, context);
    const partial = api.renderNeedsExpanded({ needs_expanded: {
        optional_mod_stats: { addiction_alcohol: 20, addiction_caffeine: 30 }
    }});
    assert.equal(countLabel(partial, "Alcohol Addiction"), 0);
    assert.equal(countLabel(partial, "Caffeine Addiction"), 1);
});

test("addiction bars use their bundled moodle icons and Poison differs from Sickness", () => {
    const { api, context } = loadRenderer();
    context.window.PZ_MOODLE_ICONS = { mood_dead: "poison-skull", mood_nauseous: "sick-face" };
    const html = api.renderNeedsExpanded({ needs_expanded: {
        vanilla_stats: { poison: 10 },
        optional_mod_stats: {
            addiction_alcohol: 1, addiction_amphetamines: 1,
            addiction_caffeine: 1, addiction_nicotine: 1,
            addiction_painkillers: 1, addiction_sleeping_pills: 1
        }
    }});
    assert.match(html, /src="poison-skull"/);
    assert.doesNotMatch(html, /src="sick-face"/);
    assert.equal(count(html, 'class="needs-expanded-icon"'), 7);
    assert.doesNotMatch(html, /needs-expanded-icon-blank/);
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
    assert.equal(api.statBarClass(highBad), "bad2");
    assert.equal(api.statBarClass(highGood), "bad3");
    assert.equal(api.statBarClass(api.buildPlayerStat("high_bad", 24, {
        label: "High bad", min: 0, max: 120, badHigh: true,
        source: { type: "mod", id: "test", name: "Test" }
    })), "ok");
});

test("vanilla bar colors change at each Build 42 moodle threshold", () => {
    const { api } = loadRenderer();
    const cases = [
        ["hunger", [15, 25, 45, 70]],
        ["thirst", [12, 25, 70, 84]],
        ["fatigue", [60, 70, 80, 90]],
        ["boredom", [25, 50, 75, 90]],
        ["panic", [6, 30, 65, 80]],
        ["unhappiness", [20, 45, 60, 80]],
        ["pain", [10, 20, 50, 75]],
        ["sickness", [25, 50, 75, 90]],
        ["wetness", [15, 40, 70, 90]],
        ["intoxication", [10, 30, 50, 70]]
    ];
    const stat = (id, value, badHigh = true) => api.buildPlayerStat(id, value, {
        label: id, min: 0, max: 100, badHigh,
        source: { type: "base_game", id: "project_zomboid", name: "Project Zomboid" }
    });
    for (const [id, thresholds] of cases) {
        assert.equal(api.statBarClass(stat(id, 0)), "ok", id);
        thresholds.forEach((threshold, index) => {
            assert.equal(api.statBarClass(stat(id, threshold)),
                index === 0 ? "ok" : `bad${index}`, `${id} equality ${threshold}`);
            assert.equal(api.statBarClass(stat(id, threshold + 0.01)),
                `bad${index + 1}`, `${id} above ${threshold}`);
        });
    }
    assert.equal(api.statBarClass(stat("endurance", 75.01, false)), "ok");
    assert.equal(api.statBarClass(stat("endurance", 75, false)), "bad1");
    assert.equal(api.statBarClass(stat("endurance", 50, false)), "bad2");
    assert.equal(api.statBarClass(stat("endurance", 25, false)), "bad3");
    assert.equal(api.statBarClass(stat("endurance", 10, false)), "bad4");
    [20, 40, 60, 80].forEach((threshold, index) => {
        assert.equal(api.statBarClass(stat("discomfort", threshold - 0.01)),
            index === 0 ? "ok" : `bad${index}`);
        assert.equal(api.statBarClass(stat("discomfort", threshold)), `bad${index + 1}`);
    });
});

test("mod bar levels follow their source thresholds and active moodles", () => {
    const { api } = loadRenderer();
    const stat = (id, value, max = 100, badHigh = true) => api.buildPlayerStat(id, value, {
        label: id, min: 0, max, badHigh,
        source: { type: "mod", id: "test", name: "Test" }
    });
    assert.equal(api.statBarClass(stat("natures_call_bladder", 69.99, 120)), "ok");
    assert.equal(api.statBarClass(stat("natures_call_bladder", 70, 120)), "bad1");
    assert.equal(api.statBarClass(stat("natures_call_bladder", 95, 120)), "bad2");
    assert.equal(api.statBarClass(stat("natures_call_bladder", 100, 120)), "bad2");
    assert.equal(api.statBarClass(stat("natures_call_bladder", 100.01, 120)), "bad4");
    assert.equal(api.statBarClass(stat("lifestyle_hygiene_need", 9.99)), "good4");
    assert.equal(api.statBarClass(stat("lifestyle_hygiene_need", 30)), "good1");
    assert.equal(api.statBarClass(stat("lifestyle_hygiene_need", 40)), "ok");
    assert.equal(api.statBarClass(stat("lifestyle_hygiene_need", 60)), "ok");
    assert.equal(api.statBarClass(stat("lifestyle_hygiene_need", 90.01)), "bad4");
    assert.equal(api.statBarClass(stat("lifestyle_embarrassment", 0.14, 1)), "ok");
    assert.equal(api.statBarClass(stat("lifestyle_embarrassment", 0.15, 1)), "bad1");
    assert.equal(api.statBarClass(stat("lifestyle_embarrassment", 0.7, 1)), "bad4");
    assert.equal(api.statBarClass(stat("lifestyle_beauty_need", 9.99)), "bad4");
    assert.equal(api.statBarClass(stat("lifestyle_beauty_need", 90.01)), "good4");
    assert.equal(api.statBarClass(stat("tasab_body_grime", 45)), "bad2");
    assert.equal(api.statBarClass(stat("tasab_body_grime", 75)), "bad3");
    assert.equal(api.statBarClass(stat("tasab_body_grime", 90)), "bad4");
    assert.equal(api.statBarClass(stat("drugtime_stoned", 105, 140)), "good4");
    assert.equal(api.statBarClass(stat("drugtime_hard", 120, 160)), "bad4");
    assert.equal(api.statBarClass(stat("casualties_euphoria", 0.02, 1, false)), "ok");
    assert.equal(api.statBarClass(stat("casualties_euphoria", 0.75, 1, false)), "good4");

    const active = (id, level, valence = "bad", maxLevel = 4) => ({
        id, label: id, level, maxLevel, valence,
        source: { type: "mod", id: "test", name: "Test" }
    });
    const mouth = [active("BrushYourDamnTeeth:BYDT_MouthState", 4)];
    assert.equal(api.statBarClass(stat("bydt_dental_hygiene", 0.9, 1, false), mouth), "ok");
    assert.equal(api.statBarClass(stat("bydt_dental_hygiene", 0.49, 1, false), mouth), "bad1");
    assert.equal(api.statBarClass(stat("bydt_dental_hygiene", 0.29, 1, false), mouth), "bad2");
    assert.equal(api.statBarClass(stat("bydt_dental_hygiene", 0.09, 1, false), mouth), "bad4");
    assert.equal(api.statBarClass(stat("addiction_alcohol", 20),
        [active("twbInfirmities:AddictedToAlcohol", 1)]), "bad1");
    assert.equal(api.statBarClass(stat("addiction_alcohol", 95)), "ok");
    assert.equal(api.statBarClass(stat("stress", 95)), "ok");
    assert.equal(api.statBarClass(stat("stress", 5),
        [active("project_zomboid:mood_stressed", 3)]), "bad3");
    assert.equal(api.statBarClass(stat("natures_call_bladder", 95, 120),
        [active("NC_NaturesCall:NCBladder", 2, "bad", 3)]), "bad2");
    assert.equal(api.statBarClass(stat("endurance", 90, 100, false),
        [active("project_zomboid:status_difficultybreathing", 2)]), "bad2");
    assert.equal(api.statBarClass(stat("hunger", 5),
        [active("project_zomboid:status_hunger", 3, "good")]), "ok");
});

test("rendered bars use active moodle colors and every severity has a style", () => {
    const { api } = loadRenderer();
    const needs = vanillaNeeds();
    needs[3].value = 90;
    const html = api.renderNeedsExpanded({
        needs,
        moodles: [{ label: "Out of Breath", level: 1,
            icon: "status_difficultybreathing", valence: "bad" }]
    });
    assert.match(html, /needs-expanded-fill bad1"\s+style="width:90%"/);

    const css = fs.readFileSync(path.join(__dirname, "..", "42", "media", "web", "expanded-needs.css"), "utf8");
    for (const color of ["ok", "good1", "good2", "good3", "good4",
        "bad1", "bad2", "bad3", "bad4"]) {
        assert.match(css, new RegExp(`\\.needs-expanded-fill\\.${color}\\s*\\{`), color);
    }
    assert.match(css, /\.needs-expanded-fill\.bad2 \{ background: var\(--warn\); \}/);
    assert.match(css, /\.needs-expanded-fill\.bad3 \{[^}]*color-mix\(in srgb, var\(--warn\) 50%, var\(--danger\) 50%\)/);
    assert.match(css, /\.needs-expanded-fill\.bad4 \{ background: var\(--danger\); \}/);
});

test("level-one bad bars soften while moodle badges keep PZ Pulse art", () => {
    const { api, context } = loadRenderer();
    context.window.PZ_MOODLE_ICONS = {
        circle_bad1: "yellow-circle", circle_good: "green-circle",
        mood_stressed: "stress-glyph"
    };
    const moodle = {
        id: "project_zomboid:mood_stressed", label: "Stressed", level: 1,
        maxLevel: 1, valence: "bad", iconKey: "mood_stressed",
        source: { type: "base_game", id: "project_zomboid", name: "Project Zomboid" }
    };
    const stat = api.buildPlayerStat("stress", 20, {
        label: "Stress", min: 0, max: 100, badHigh: true,
        source: moodle.source
    });
    assert.equal(api.statBarClass(stat, [moodle]), "bad1");
    const badge = api.renderMoodleBadge(moodle);
    assert.match(badge, /src="yellow-circle"/);
    assert.doesNotMatch(badge, /src="green-circle"/);
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

    assert.match(compactHtml(html), /needs-expanded-value"[^>]*> 0% <\/span>/);
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
                lifestyle_embarrassment: 0.38,
                lifestyle_comfort_need: 0.72,
                lifestyle_beauty_need: 74,
                tasab_body_grime: "bad",
                bydt_dental_hygiene: 0.82
            }
        }
    });

    assert.equal(countLabel(html, "Hygiene Need"), 1);
    assert.equal(countLabel(html, "Embarrassment"), 1);
    assert.equal(countLabel(html, "Comfort Need"), 1);
    assert.equal(countLabel(html, "Beauty Need"), 1);
    assert.equal(countLabel(html, "Body Grime"), 0);
    assert.equal(countLabel(html, "Dental Hygiene"), 1);
    assert.match(api.tooltipText("stat:lifestyle_hygiene_need"), /Source: Lifestyle: Hobbies/);
    assert.match(api.tooltipText("stat:bydt_dental_hygiene"), /Source: Brush Your Damn Teeth/);
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
    assert.match(api.tooltipText("moodle:TakeABathAndShowerNew:BodyGrime"), /Body Grime/);
    assert.match(api.tooltipText("moodle:TakeABathAndShowerNew:CoolingBody"), /Cooling Body/);
    assert.doesNotMatch(html, /Inactive/);
    assert.doesNotMatch(html, /Malformed/);
    assert.doesNotMatch(html, /Active Moodles/);
    assert.match(html, /<b>3<\/b>/);
    assert.doesNotMatch(html, /needs-expanded-moodle-row/);
    assert.match(api.tooltipText("moodle:TakeABathAndShowerNew:BodyGrime"), /Source: Take A Bath And Shower/);
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
    assert.match(api.tooltipText("stat:unsafe"), /Source: Source "name"/);

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
        moodles: [{ label: "Very Hungry", level: 3, icon: "status_hunger", valence: "bad" }],
        needs_expanded: { vanilla_moodle_descriptions: {
            "status_hunger:bad": "The game says hunger is severe."
        } }
    });

    assert.equal(api.adaptPzPulseMoodles(null).length, 0);
    assert.equal(count(html, "needs-expanded-moodle-badge"), 1);
    assert.match(html, /src="circle"/);
    assert.match(html, /src="glyph"/);
    assert.match(html, /<b>3<\/b>/);
    assert.match(api.tooltipText("moodle:project_zomboid:status_hunger"), /The game says hunger is severe/);
    assert.match(api.tooltipText("moodle:project_zomboid:status_hunger"), /Severe, prolonged starvation/);

    const fed = api.renderNeedsExpanded({
        moodles: [{ label: "Well fed", level: 3, icon: "status_hunger", valence: "good" }]
    });
    assert.match(api.tooltipText("moodle:project_zomboid:status_hunger"), /positive eating state/);
    assert.doesNotMatch(api.tooltipText("moodle:project_zomboid:status_hunger"), /Severe, prolonged starvation/);
});
