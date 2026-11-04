// PLAYERS_QML must point to services/Players.qml with the shell patches applied.
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { test } = require('node:test');
const vm = require('node:vm');

const source = readFileSync(process.env.PLAYERS_QML
    || '/etc/xdg/quickshell/caelestia/services/Players.qml', 'utf8');
const signature = 'function maybeToastNowPlaying(): void {';
const start = source.indexOf(signature);
assert.notEqual(start, -1, 'Missing now-playing handler');
const bodyStart = start + signature.length;
const body = source.slice(bodyStart, source.indexOf('\n    }', bodyStart));

function player(url) {
    return { metadata: url === undefined ? {} : { 'xesam:url': url },
        identity: 'Firefox', trackTitle: 'Track', trackArtist: 'Artist',
        lengthSupported: true, length: 180 };
}

function harness(active) {
    const toasts = [];
    let artCalls = 0;
    const context = vm.createContext({
        active, GlobalConfig: { utilities: { toasts: { nowPlaying: true } } },
        lastNowPlayingKey: '', lastNowPlayingAt: 0, nowPlayingRepeatFallback: 600000,
        nowPlayingToastTimeout: 1750,
        hiResArt: {}, artRevision: 0,
        getIdentity: p => p.identity,
        getArtUrl() { artCalls++; return ''; },
        Tr: { tr: x => x, trCtx: () => ({ arg: () => ({ arg: () => 'Artist - Track' }) }) },
        Toaster: { toast: (...args) => toasts.push(args) }, Toast: { Info: 0 },
    });
    context.root = context;
    const notify = vm.runInContext(`() => {${body}}`, context);
    const icon = payload => {
        const signature = 'function getToastIcon(icon: string): string {';
        const start = source.indexOf(signature);
        assert.notEqual(start, -1, 'Missing toast icon resolver');
        const bodyStart = start + signature.length;
        const body = source.slice(bodyStart, source.indexOf('\n    }', bodyStart));
        return vm.runInContext(`icon => {${body}}`, context)(payload);
    };
    return { context, toasts, notify, icon, artCalls: () => artCalls };
}

test('scrolling Shorts never toasts or starts cover lookup', () => {
    const h = harness(null);
    for (const host of ['youtube.com', 'www.youtube.com', 'm.youtube.com']) {
        for (const id of ['abcdefghijk', 'lmnopqrstuv']) {
            h.context.active = player(`https://${host}/shorts/${id}?feature=share`);
            h.context.active.trackTitle = id;
            h.notify();
        }
    }
    assert.equal(h.toasts.length, 0);
    assert.equal(h.artCalls(), 0);
    assert.equal(h.context.lastNowPlayingKey, '');
});

test('music and ordinary videos keep their toast, including short tracks', () => {
    for (const url of ['https://music.yandex.ru/', 'https://music.youtube.com/watch?v=abcdefghijk',
        'https://www.youtube.com/watch?v=abcdefghijk', 'file:///music/song.flac',
        'https://example.org/shorts/abcdefghijk', 'https://youtube.com.evil.test/shorts/id', undefined]) {
        const h = harness(player(url));
        h.context.active.length = 15;
        h.notify();
        h.notify();
        assert.equal(h.toasts.length, 1, `Expected one toast for ${url}`);
    }
});

test('music resumes after Shorts without losing duplicate suppression', () => {
    const h = harness(player('https://music.yandex.ru/'));
    h.notify();
    h.context.active = player('https://www.youtube.com/shorts/abcdefghijk');
    h.notify();
    h.context.active = player('https://music.yandex.ru/');
    h.notify();
    assert.equal(h.toasts.length, 1);
    h.context.active.trackTitle = 'Next song';
    h.notify();
    assert.equal(h.toasts.length, 2);
});

test('disabled toasts and absent players stay silent', () => {
    const h = harness(null);
    h.notify();
    h.context.active = player('https://music.yandex.ru/');
    h.context.GlobalConfig.utilities.toasts.nowPlaying = false;
    h.notify();
    assert.equal(h.toasts.length, 0);
});

test('pending high-resolution art never delays a toast and upgrades it in place', () => {
    const h = harness(player('https://music.yandex.ru/'));
    const low = 'file:///tmp/firefox-mpris/cover.png';
    h.context.getArtUrl = () => low;
    h.context.hiResArt['Artist|Track'] = null;
    // No artwork polling timer exists in this harness: waiting would throw.
    h.notify();
    assert.equal(h.toasts.length, 1);
    const payload = h.toasts[0][2];
    assert.equal(h.icon(payload), low);
    h.context.active.trackTitle = 'Next track';
    h.context.hiResArt['Artist|Next track'] = 'https://example.org/other.jpg';
    assert.equal(h.icon(payload), low, 'A different track must not replace the cover');
    h.context.hiResArt['Artist|Track'] = 'https://example.org/600x600.jpg';
    h.context.artRevision++;
    assert.equal(h.icon(payload), 'https://example.org/600x600.jpg');
    assert.equal(h.toasts.length, 1, 'Cover updates must not create new toasts');
});

test('failed cover lookups keep the original image or music icon', () => {
    const h = harness(player('https://music.yandex.ru/'));
    h.notify();
    const payload = h.toasts[0][2];
    assert.equal(h.icon(payload), 'music_note');
    h.context.hiResArt['Artist|Track'] = '';
    assert.equal(h.icon(payload), 'music_note');
    for (const icon of ['keyboard', 'music_note', 'https://example.org/cover.jpg'])
        assert.equal(h.icon(icon), icon, 'Other toasts keep their icons');
});
