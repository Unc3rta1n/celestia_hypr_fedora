// Run against the installed picker or PICKER_QML=/path/to/patched/Picker.qml.
// Exercise its JavaScript handlers while controlling asynchronous frame delivery.
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { test } = require('node:test');
const vm = require('node:vm');

const source = readFileSync(process.env.PICKER_QML
    || '/etc/xdg/quickshell/caelestia/modules/areapicker/Picker.qml', 'utf8');

function handler(signature, indent = 4) {
    const start = source.indexOf(signature);
    assert.notEqual(start, -1, `Missing handler: ${signature}`);
    const body = source.indexOf('{', start) + 1;
    return source.slice(body, source.indexOf(`\n${' '.repeat(indent)}}`, body));
}

function picker(freeze = false) {
    const saves = [];
    const context = vm.createContext({
        capturePending: false, savePending: false, captureRect: undefined, selecting: false,
        rsx: 10, rsy: 20, sw: 200, sh: 100,
        sx: 10, sy: 20, ex: 210, ey: 120, ssx: 10, ssy: 20,
        clients: [{ lastIpcObject: { at: [0, 0], size: [1920, 1080] } }],
        screen: { x: 0, y: 0 }, pressed: false, onClient: false,
        loader: { freeze, closing: false, clipboardOnly: true },
        screencopy: { active: freeze, visible: true },
        overlay: { visible: true }, border: { visible: true },
        closeAnim: { running: false, start() { context.loader.closing = true; } },
        Qt: { rect: (...values) => values, resolvedUrl: value => value,
            BlankCursor: 0, CrossCursor: 1,
            styleHints: { startDragDistance: 10 } },
        Quickshell: { processId: 1, execDetached() {} },
        Tr: { tr: value => value },
        CUtils: { saveItem: (...args) => saves.push(args) },
        console: { warn() {} },
    });
    context.root = context;
    context.save = vm.runInContext(`() => {${handler('function save(): void {')}}`, context);
    context.checkClientRects = vm.runInContext(
        `(x, y) => {${handler('function checkClientRects(x: real, y: real): void {')}}`, context);
    const release = () => vm.runInContext(`(() => {${handler('onReleased: {')}})()`, context);
    const cursor = () => vm.runInContext(source.match(/^\s+cursorShape: (.+)$/m)[1], context);
    const frame = () => {
        context.hasContent = true;
        vm.runInContext(`(() => {${handler('onHasContentChanged: {', 12)}})()`, context);
    };
    const press = (x, y) => {
        context.pressed = true;
        context.event = { x, y };
        vm.runInContext(`(() => {${handler('onPressed: event => {')}})()`, context);
    };
    const move = (x, y) => {
        context.event = { x, y };
        vm.runInContext(`(() => {${handler('onPositionChanged: event => {')}})()`, context);
        context.rsx = Math.min(context.sx, context.ex);
        context.rsy = Math.min(context.sy, context.ey);
        context.sw = Math.abs(context.sx - context.ex);
        context.sh = Math.abs(context.sy - context.ey);
    };
    return { context, saves, release, frame, press, move, cursor };
}

test('hover over a window after release preserves the selected crop', () => {
    const { context, saves, release, frame } = picker();
    release();
    context.checkClientRects(30, 40);
    frame();
    assert.deepEqual(Array.from(saves[0][2]), [10, 20, 200, 100]);
    assert.equal(context.sx, 10);
    assert.equal(context.ex, 210);
});

test('duplicate frames and releases cannot save twice before completion', () => {
    const { saves, release, frame } = picker();
    release();
    frame();
    release();
    frame();
    assert.equal(saves.length, 1);
});

test('frozen captures also save only once', () => {
    const { saves, release } = picker(true);
    release();
    release();
    assert.equal(saves.length, 1);
    assert.deepEqual(Array.from(saves[0][2]), [10, 20, 200, 100]);
});

test('save failure permits retry and restores the selection overlay', () => {
    const { context, saves, release, frame } = picker();
    release();
    frame();
    saves[0][4]();
    assert.equal(context.screencopy.active, false);
    assert.equal(context.overlay.visible, true);
    release();
    frame();
    assert.equal(saves.length, 2);
});

test('Escape during capture prevents a late frame from saving', () => {
    const { context, saves, release, frame } = picker();
    release();
    context.loader.closing = true;
    frame();
    assert.equal(saves.length, 0);
});

test('empty selection does not start a capture', () => {
    const { context, saves, release, frame } = picker();
    context.sw = 0;
    release();
    assert.equal(context.screencopy.active, false);
    frame();
    assert.equal(saves.length, 0);
});

test('window click with subpixel motion saves the window instead of ignoring the click', () => {
    const { context, saves, press, move, release } = picker(true);
    press(100, 60);
    move(101.75, 60.875);
    context.pressed = false;
    release();
    move(1000, 700);
    assert.equal(saves.length, 1);
    assert.deepEqual(Array.from(saves[0][2]), [10, 20, 200, 100]);
});

test('window click with several pixels of motion does not save a tiny fragment', () => {
    const { context, saves, press, move, release } = picker(true);
    press(100, 60);
    move(106.9296875, 62.5546875);
    context.pressed = false;
    release();
    assert.deepEqual(Array.from(saves[0][2]), [10, 20, 200, 100]);
});

test('drag crossing the threshold selects an area and can return near its starting point', () => {
    const { context, saves, press, move, release } = picker(true);
    press(100, 60);
    move(120, 80);
    move(103, 62);
    context.pressed = false;
    release();
    assert.deepEqual(Array.from(saves[0][2]), [100, 60, 3, 2]);
});

test('a new press resets the previous drag decision', () => {
    const { context, saves, press, move, release } = picker(true);
    press(100, 60);
    move(120, 80);
    context.pressed = false;
    release();
    saves[0][4]();
    press(110, 70);
    move(111, 70.5);
    context.pressed = false;
    release();
    assert.equal(saves.length, 2);
    assert.deepEqual(Array.from(saves[1][2]), [100, 60, 20, 20]);
});

test('frozen picker hides the cursor until its screen frame is ready', () => {
    const { context, cursor } = picker(true);
    assert.equal(cursor(), context.Qt.BlankCursor);
    context.screencopy.item = { hasContent: false };
    assert.equal(cursor(), context.Qt.BlankCursor);
    context.screencopy.item.hasContent = true;
    assert.equal(cursor(), context.Qt.CrossCursor);
});

test('live capture hides the cursor and restores it when a save fails', () => {
    const { context, cursor, release, frame, saves } = picker();
    assert.equal(cursor(), context.Qt.CrossCursor);
    release();
    assert.equal(cursor(), context.Qt.BlankCursor);
    frame();
    assert.equal(cursor(), context.Qt.BlankCursor);
    saves[0][4]();
    assert.equal(cursor(), context.Qt.CrossCursor);
});
