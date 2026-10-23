
(async () => {
    "use strict";

    /* ── config (Safe for users to edit) ────────────────────────── */

    const CONFIG = {
        NAME: "NAs Store",
        VERSION: "v4.10.6",
        THEME: "#b12222",             // dark red theme
        SUCCESS: "#3BA55C",
        WARN: "#faa61a",
        ERR: "#f04747",
        HIDE_ACTIVITY: false,
        MAX_LOG_ITEMS: 60
    };

    /* ── internal system limits (DO NOT EDIT) ─────────────────── */

    const SYS = Object.freeze({
        MAX_TIME: 25 * 60 * 1000,
        HEARTBEAT_GRACE: 90 * 1000,
        MAX_TASK_FAILURES: 5,
        MAX_RETRIES: 3,
        IS_DESKTOP: typeof window.DiscordNative !== 'undefined'
    });

    const RUNTIME = {
        running: true,
        cleanups: new Set(),
        autoEnroll: true,
        autoClaim: false,
        playSound: false,
        randomDelay: false
    };

    /* ── PASSWORD GATE ───────────────────────────────────────────── */
    // كلمة السر الثابتة NAs
    const PASSWORD = "NAs";

    // دالة التحقق من كلمة السر قبل تشغيل أي شيء
    function checkPassword() {
        if (window._orion_authorized) return true;
        
        const input = prompt(
            `🔐 ${CONFIG.NAME}\nجميع الحقوق محفوظة لـ NAs Store\n\nأدخل كلمة السر للمتابعة:`,
            ""
        );
        
        if (input === PASSWORD) {
            window._orion_authorized = true;
            return true;
        }
        
        if (input === null) {
            console.warn(`[${CONFIG.NAME}] تم إلغاء المصادقة.`);
        } else {
            alert("❌ كلمة سر خاطئة! الرجاء المحاولة مرة أخرى.");
            // نعيد المحاولة بشكل متكرر
            return checkPassword();
        }
        return false;
    }

    // التحقق أولاً
    if (!checkPassword()) {
        console.warn(`[${CONFIG.NAME}] غير مصرح بالدخول.`);
        return;
    }

    /* ── audio cue ───────────────────────────────────────────────── */
    const Sound = {
        _ctx: null,
        play(type) {
            if (!RUNTIME.playSound) return;
            try {
                const Ctx = window.AudioContext || window.webkitAudioContext;
                if (!Ctx) return;
                if (!this._ctx || this._ctx.state === 'closed') this._ctx = new Ctx();
                const ctx = this._ctx;
                const o = ctx.createOscillator();
                const g = ctx.createGain();
                o.connect(g); g.connect(ctx.destination);
                o.type = 'sine';
                const t0 = ctx.currentTime;
                if (type === 'done') {
                    o.frequency.setValueAtTime(523.25, t0);
                    o.frequency.setValueAtTime(659.25, t0 + 0.12);
                    o.frequency.setValueAtTime(783.99, t0 + 0.24);
                    g.gain.setValueAtTime(0.55, t0);
                    g.gain.exponentialRampToValueAtTime(0.001, t0 + 0.55);
                    o.start(t0); o.stop(t0 + 0.6);
                } else {
                    o.frequency.value = 880;
                    g.gain.setValueAtTime(0.45, t0);
                    g.gain.exponentialRampToValueAtTime(0.001, t0 + 0.18);
                    o.start(t0); o.stop(t0 + 0.2);
                }
            } catch (_) { }
        }
    };

    /* ── OAuth consent gate ────────────────────────────────────── */
    const Consent = {
        _granted: new Set(),
        TIMEOUT: 60000,
        SCOPES: ['identify', 'applications.commands', 'applications.entitlements'],
        ask(appId, appName) {
            if (this._granted.has(appId)) return Promise.resolve(true);
            return new Promise(resolve => {
                const ov = document.createElement('div');
                ov.id = 'orion-consent';
                ov.style.cssText = 'position:fixed;inset:0;z-index:1002;display:flex;align-items:center;justify-content:center;background:rgba(0,0,0,.8);font-family:var(--font-primary);';
                ov.innerHTML = `<div style="width:420px;max-width:92vw;background:#141215;border:1px solid #a12b2b;border-radius:var(--radius-lg);box-shadow:var(--shadow-button-overlay);color:#ece6e6;overflow:hidden;">
                    <div style="padding:14px 16px;background:#1f1616;border-bottom:1px solid #a12b2b;font-weight:700;color:#e6d5d5;">Authorize application?</div>
                    <div style="padding:16px;font-size:13px;line-height:1.5;">
                        <div>To complete this achievement quest, Orion needs to OAuth-authorize this app on your Discord account:</div>
                        <div id="oc-app" style="font-weight:700;color:#e6d5d5;margin:6px 0;"></div>
                        <div style="color:#b27a7a;">Scopes requested:</div>
                        <ul id="oc-scopes" style="margin:4px 0 10px;padding-left:18px;color:#b27a7a;"></ul>
                        <div style="color:#d4934b;">The app's backend receives a real authorization code. Orion revokes the grant immediately after the quest is marked complete. Discord enforcement against quest automation can affect the whole account.</div>
                        <label style="display:flex;gap:8px;align-items:center;margin-top:12px;font-size:12px;color:#b27a7a;">
                            <input type="checkbox" id="oc-remember" class="native-cb"> Don't ask again for this app this session</label>
                    </div>
                    <div style="display:flex;gap:10px;padding:12px 16px;border-top:1px solid #291d1d;">
                        <button id="oc-no" class="quest-pick-btn deselect" style="flex:1;background:#221a1a;border:1px solid #3d2a2a;color:#b27a7a;">Cancel</button>
                        <button id="oc-yes" class="quest-pick-btn start" style="flex:1;background:#b12222;border:1px solid #b12222;color:#fff;">Authorize</button>
                    </div></div>`;
                document.body.appendChild(ov);
                ov.querySelector('#oc-app').textContent = appName ? `${appName} (${appId})` : `App ${appId}`;
                const ul = ov.querySelector('#oc-scopes');
                this.SCOPES.forEach(s => { const li = document.createElement('li'); li.textContent = s; ul.appendChild(li); });
                let done = false;
                const finish = v => {
                    if (done) return; done = true;
                    clearTimeout(timer); document.removeEventListener('keydown', onKey);
                    if (v && ov.querySelector('#oc-remember').checked) this._granted.add(appId);
                    ov.remove(); resolve(v);
                };
                const onKey = e => { if (e.key === 'Escape') finish(false); };
                ov.querySelector('#oc-yes').addEventListener('click', () => finish(true));
                ov.querySelector('#oc-no').addEventListener('click', () => finish(false));
                ov.addEventListener('mousedown', e => { if (e.target === ov) finish(false); });
                document.addEventListener('keydown', onKey);
                const timer = setTimeout(() => finish(false), this.TIMEOUT);
            });
        }
    };

    const ICONS = Object.freeze({
        OPT: `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M10.56 1.1c-.46.05-.7.53-.64.98.18 1.16-.19 2.2-.98 2.53-.8.33-1.79-.15-2.49-1.1-.27-.36-.78-.52-1.14-.24-.77.59-1.45 1.27-2.04 2.04-.28.36-.12.87.24 1.14.96.7 1.43 1.7 1.1 2.49-.33.8-1.37 1.16-2.53.98-.45-.07-.93.18-.99.64a11.1 11.1 0 0 0 0 2.88c.06.46.54.7.99.64 1.16-.18 2.2.19 2.53.98.33.8-.14 1.79-1.1 2.49-.36.27-.52.78-.24 1.14.59.77 1.27 1.45 2.04 2.04.36.28.87.12 1.14-.24.7-.95 1.7-1.43 2.49-1.1.8.33 1.16 1.37.98 2.53-.07.45.18.93.64.99a11.1 11.1 0 0 0 2.88 0c.46-.06.7-.54.64-.99-.18-1.16.19-2.2.98-2.53.8-.33 1.79.14 2.49 1.1.27.36.78.52 1.14.24.77-.59 1.45-1.27 2.04-2.04.28-.36.12-.87-.24-1.14-.96-.7-1.43-1.7-1.1-2.49.33-.8 1.37-1.16 2.53-.98.45.07.93-.18.99-.64a11.1 11.1 0 0 0 0-2.88c-.06-.46-.54-.7-.99-.64-1.16.18-2.2-.19-2.53-.98-.33-.8.14-1.79 1.1-2.49.36-.27.52-.78.24-1.14a11.07 11.07 0 0 0-2.04-2.04c-.36-.28-.87-.12-1.14.24-.7.96-1.7 1.43-2.49 1.1-.8-.33-1.16-1.37-.98-2.53.07-.45-.18-.93-.64-.99a11.1 11.1 0 0 0-2.88 0ZM16 12a4 4 0 1 1-8 0 4 4 0 0 1 8 0Z"/></svg>`,
        BOLT: `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M11 21h-1l1-7H7.5c-.58 0-.57-.32-.29-.62L14.5 3h1l-1 7h3.5c.58 0 .57.32.29.62L11 21z"/></svg>`,
        VIDEO: `<svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M10 16.5l6-4.5-6-4.5v9zM12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z"/></svg>`,
        GAME: `<svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M21 6H3c-1.1 0-2 .9-2 2v8c0 1.1.9 2 2 2h18c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2zm-10 7H8v3H6v-3H3v-2h3V8h2v3h3v2zm4.5 2c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zm4-3c-.83 0-1.5-.67-1.5-1.5S18.67 9 19.5 9s1.5.67 1.5 1.5-.67 1.5-1.5 1.5z"/></svg>`,
        STREAM: `<svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M17 10.5V7c0-.55-.45-1-1-1H4c-.55 0-1 .45-1 1v10c0 .55.45 1 1 1h12c.55 0 1-.45 1-1v-3.5l4 4v-11l-4 4z"/></svg>`,
        ACTIVITY: `<svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 14.5c-2.49 0-4.5-2.01-4.5-4.5S9.51 7.5 12 7.5s4.5 2.01 4.5 4.5-2.01 4.5-4.5 4.5zm0-5.5c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1z"/></svg>`,
        CHECK: `<svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>`,
        CLOCK: `<svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z"/><path d="M12.5 7H11v6l5.25 3.15.75-1.23-4.5-2.67z"/></svg>`,
        STOP: `<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M6 6h12v12H6z"/></svg>`
    });

    const CONST = Object.freeze({
        ID: "1412491570820812933",
        EVT: Object.freeze({
            HEARTBEAT: "QUESTS_SEND_HEARTBEAT_SUCCESS",
            GAME: "RUNNING_GAMES_CHANGE",
            RPC: "LOCAL_ACTIVITY_UPDATE"
        })
    });

    if (window.orionLock) {
        const existingUI = document.getElementById('orion-ui');
        if (existingUI) existingUI.style.display = 'flex';
        return console.warn(`[${CONFIG.NAME}] Already running.`);
    }
    window.orionLock = true;

    const sleep = ms => new Promise(r => setTimeout(r, ms));
    const rnd = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

    const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

    const notExpired = q => { const e = new Date(q.config?.expiresAt ?? 0).getTime(); return Number.isNaN(e) || e > Date.now(); };

    const sealedFor = questId => {
        try { return Mods.QuestStore?.getQuest?.(questId)?.trafficMetadataSealed ?? null; }
        catch (_) { return null; }
    };

    const enrollmentBlockedUntil = () => {
        try {
            const raw = Mods.QuestStore?.questEnrollmentBlockedUntil;
            if (!raw) return null;
            const when = raw instanceof Date ? raw : new Date(raw);
            return Number.isNaN(when.getTime()) || when.getTime() <= Date.now() ? null : when;
        } catch (_) { return null; }
    };

    const buildStreamKey = () => {
        try {
            const ownerId = Mods.UserStore?.getCurrentUser?.()?.id;
            if (!ownerId) return null;
            // Check if user is ACTUALLY in a voice channel via VoiceStateStore
            if (Mods.VoiceStateStore) {
                const vs = Mods.VoiceStateStore.getVoiceStateForUser?.(ownerId);
                if (vs?.channelId) {
                    const ch = Mods.ChanStore?.getChannel?.(vs.channelId);
                    if (ch?.type === 1 || ch?.type === 3) {
                        // DM/GroupDM call
                        return `call:${vs.channelId}:${ownerId}`;
                    }
                    if (ch?.guild_id) {
                        return `guild:${ch.guild_id}:${vs.channelId}:${ownerId}`;
                    }
                }
            }
            // Fallback: check SelectedChannelStore for current voice channel
            if (Mods.SelectedChanStore) {
                const vcId = Mods.SelectedChanStore.getVoiceChannelId?.();
                if (vcId) {
                    const ch = Mods.ChanStore?.getChannel?.(vcId);
                    if (ch?.type === 1 || ch?.type === 3) return `call:${vcId}:${ownerId}`;
                    if (ch?.guild_id) return `guild:${ch.guild_id}:${vcId}:${ownerId}`;
                }
            }
            return null;
        } catch (e) {
            Logger.log(`[Task] Stream key lookup error: ${e.message}`, 'debug');
            return null;
        }
    };

    const ErrorHandler = {
        RETRYABLE: new Set([429, 500, 502, 503, 504, 408]),
        CLIENT_ERRORS: new Set([400, 403, 404, 409, 410]),
        classify(error) {
            const status = error?.status ?? error?.statusCode;
            return {
                isRetryable: this.RETRYABLE.has(status),
                isClientError: this.CLIENT_ERRORS.has(status),
                status,
                message: error?.message ?? error?.body?.message ?? `HTTP ${status ?? 'UNKNOWN'}`
            };
        },
        isSkippableQuest(error) {
            const status = error?.status;
            return status === 404 || status === 403 || status === 410;
        }
    };

    /* ── UI + logger ──────────────────────────────────────────── */
    const Logger = {
        root: null, tasks: new Map(), tickerId: null, _hotkey: null,

        init() {
            const oldUI = document.getElementById('orion-ui'); if (oldUI) oldUI.remove();
            const oldStyle = document.getElementById('orion-styles'); if (oldStyle) oldStyle.remove();

            const style = document.createElement('style');
            style.id = 'orion-styles';
            style.innerHTML = `
                @keyframes slideIn { from { transform: translateY(-20px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
                @keyframes fadeOut { from { opacity: 1; transform: scale(1); } to { opacity: 0; transform: scale(0.95); margin: 0; padding: 0; height: 0; border: none; } }

                #orion-ui {
                    position: fixed; top: 32px; left: auto; right: 20px; width: 380px;
                    max-height: 53vh;
                    background: #141215; color: #ece6e6;
                    border: 1px solid #a12b2b; border-radius: var(--radius-lg);
                    box-shadow: 0 20px 50px #000000cc; z-index: 1001;
                    font-family: var(--font-primary);
                    overflow: hidden; animation: slideIn 0.3s ease; 
                    display: flex; flex-direction: column; box-sizing: border-box;
                    user-select: none;-webkit-app-region: no-drag;
                }

                #orion-head { padding: 12px 16px; background: #1f1616; flex: 0 0 auto; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #a12b2b; cursor: grab; }
                #orion-head.dragging { cursor: grabbing; background: #2a1a1a; }
                #orion-title { font-weight: 700; font-size: 15px; color: #e6d5d5; display: flex; align-items: center; gap: 8px; }
                #orion-title svg { color: #b12222; }
                .dev-credit { font-size: 12px; margin-left: -4px; padding-top: 2px; font-weight: 500; color: #b27a7a; }

                #orion-controls { display: flex; gap: 10px; align-items: center; }
                .ctrl-btn { cursor: pointer; transition: 0.2s; display: flex; align-items: center; }
                .ctrl-hide, .ctrl-opts { font-size: 11px; font-weight: 600; color: #b27a7a; }
                .ctrl-hide:hover, .ctrl-opts:hover { color: #e6d5d5; }
                .ctrl-stop { font-size: 11px; font-weight: 700; gap: 4px; padding: 3px 8px 3px 6px; border-radius: var(--radius-sm); background: transparent; border: 1px solid #b12222; color: #b12222; }
                .ctrl-stop:hover { background: #b12222; color: #fff; }

                #orion-logs { padding: 10px 14px; background: #0f0e10; flex: 0 0 auto; font-family: 'Consolas', 'Monaco', monospace; font-size: 11px; height: 110px; overflow-y: auto; border-top: 1px solid #291d1d; scroll-behavior: smooth; }
                .log-item { margin-bottom: 6px; display: flex; gap: 8px; line-height: 1.4; padding-bottom: 4px; }
                .log-ts { opacity: 0.5; min-width: 50px; font-size: 10px; color: #8a6a6a; }
                .c-info { color: #b27a7a; opacity: .8; } .c-success { color: #3BA55C; } .c-err { color: #f04747; } .c-warn { color: #faa61a; } .c-debug { color: #6a5a5a; }

                #orion-body { flex: 1 1 auto; padding: 12px; min-height: 0; overflow-y: auto; display: flex; flex-direction: column; }
                #orion-picker-form { display: flex; flex-direction: column; min-height: 0; }

                #orion-ui ::-webkit-scrollbar { width: 4px; height: 4px; }
                #orion-ui ::-webkit-scrollbar-track { background: transparent; }
                #orion-ui ::-webkit-scrollbar-thumb { background: #3d2a2a; border-radius: 4px; }

                .task-card { 
                    --state-color: #b12222;
                    --icon-bg-opacity: 20%;
                    --icon-color: var(--state-color);
                    display: flex; gap: 12px; padding: 10px 12px; margin-bottom: 8px; align-items: center;
                    background: #1a1719; 
                    border-radius: var(--radius-sm); border: 1px solid #291d1d; 
                    border-left: 4px solid var(--state-color);
                    box-shadow: var(--shadow-low); transition: 0.3s; flex-shrink: 0;
                }
                .task-card.removing { animation: fadeOut 0.4s forwards; }
                .task-card.done { --state-color: #3BA55C; --icon-bg-opacity: 100%; --icon-color: #fff; }
                .task-card.failed { --state-color: #f04747; }
                .task-card.pending { --state-color: #faa61a; }

                .task-icon { position: relative; width: 40px; height: 40px; border-radius: 50%; flex: 0 0 auto; background-color: color-mix(in srgb, var(--state-color) var(--icon-bg-opacity), transparent); display: flex; align-items: center; justify-content: center; }
                .task-card.running .task-icon::before { content: ''; position: absolute; inset: 0; border-radius: 50%; z-index: 1; background: conic-gradient(#b12222 0% var(--p, 0%), #291d1d var(--p, 0%) 100%); -webkit-mask-image: radial-gradient(circle at center, transparent 16px, black 17px); mask-image: radial-gradient(circle at center, transparent 16px, black 17px); }
                .task-icon-inner { z-index: 2; color: var(--icon-color); display: flex; transition: filter 0.2s, opacity 0.2s; }
                .task-card.running:hover .task-icon-inner { filter: blur(2px); opacity: 0.3; }
                .task-icon-overlay { position: absolute; inset: 0; z-index: 3; display: flex; align-items: center; justify-content: center; font-size: 11px; font-weight: 800; color: #ece6e6; opacity: 0; transition: opacity 0.2s; pointer-events: none; }
                .task-card.running:hover .task-icon-overlay { opacity: 1; }

                .task-info { flex: 1 1 auto; min-width: 0; display: flex; flex-direction: column; gap: 2px; justify-content: center; }
                .task-status { font-size: 10px; font-weight: 800; color: var(--state-color); text-transform: uppercase; letter-spacing: 0.5px; }
                .task-name { font-size: 13px; font-weight: 700; color: #e6d5d5; letter-spacing: 0.2px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; line-height: 1.2; }
                .task-meta { font-size: 11px; font-weight: 700; color: #b27a7a; display: flex; justify-content: space-between; }
                .task-actions { flex: 0 0 auto; display: flex; align-items: center; margin-left: 4px; }

                .claim-btn, .goto-btn { padding: 6px 10px; border: none; border-radius: var(--radius-sm); font-size: 11px; font-weight: 700; cursor: pointer; transition: 0.2s; text-transform: uppercase; letter-spacing: 0.2px; white-space: nowrap; font-family: inherit; color: #fff; }
                .claim-btn { background: #b12222; }
                .claim-btn:hover:not(:disabled) { background: #c93333; }
                .claim-btn:disabled { opacity: 0.5; cursor: not-allowed; }
                .claim-btn.failed { background: #2a1a1a; color: #b27a7a; }
                .goto-btn { background: #2a1a1a; border: 1px solid #b12222; color: #b12222; }
                .goto-btn:hover:not(:disabled) { background: #3d2a2a; }

                .picker-section-title { font-size: 11px; font-weight: 700; color: #b27a7a; margin-bottom: 8px; text-transform: uppercase; letter-spacing: 0.5px; flex-shrink: 0; }
                .reward-filters { display: flex; gap: 6px; margin-bottom: 12px; flex-wrap: wrap; flex-shrink: 0; }

                .reward-filter, .type-filter { background-color: transparent; border: 2px solid; padding: 4px 10px; border-radius: 24px; font-size: 10px; font-weight: 600; cursor: pointer; transition: 0.2s; color: #b27a7a; font-family: inherit; }
                .reward-filter:hover, .type-filter:hover { background-color: color-mix(in srgb, currentColor 25%, transparent); }
                .reward-filter.off, .type-filter.off { background: transparent; color: #5a4a4a; opacity: 0.4; }

                .picker-quest-list { display: flex; flex-direction: column; gap: 8px; flex: 1 1 auto; min-height: 50px; overflow-y: auto; padding-right: 4px; }

                .quest-pick { display: flex; gap: 12px; padding: 10px; background: #1a1719; border-radius: var(--radius-sm); border: 1px solid #291d1d; border-left-width: 4px; cursor: pointer; transition: 0.2s; align-items: center; user-select: none; flex-shrink: 0; }
                .quest-pick:hover { filter: brightness(1.15); }
                .quest-pick.hidden { display: none !important; }

                .native-cb { appearance: none; width: 20px; height: 20px; margin: 0; flex-shrink: 0; border: 1px solid #3d2a2a; border-radius: var(--radius-xs); background: transparent; cursor: pointer; transition: 0.15s; display: grid; place-content: center; }
                .native-cb::before {
                    content: ''; width: 12px; height: 12px; opacity: 0; transition: 0.1s;
                    background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='white' stroke-width='3' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpolyline points='20 6 9 17 4 12'%3E%3C/polyline%3E%3C/svg%3E");
                    background-size: contain; background-repeat: no-repeat; background-position: center;
                }
                .native-cb:checked { background: #b12222; border-color: #b12222; }
                .native-cb:checked::before { opacity: 1; }

                .picker-options { display: flex; flex-direction: column; gap: 6px; flex-shrink: 0; }
                .orion-option { display: flex; justify-content: space-between; align-items: center; background: #1a1719; padding: 8px 12px; border-radius: var(--radius-sm); border: 1px solid #291d1d; }
                .orion-option-label { font-size: 13px; font-weight: 500; color: #ece6e6; }

                .native-toggle { appearance: none; width: 40px; height: 20px; margin: 0; flex-shrink: 0; background: #1a1719; border-radius: 12px; cursor: pointer; position: relative; transition: 0.2s; border: 1px solid #291d1d; }
                .native-toggle::after { content: ''; position: absolute; top: 2px; left: 2px; width: 14px; height: 14px; background: #b27a7a; border-radius: 50%; box-shadow: var(--shadow-low); transition: 0.2s; }
                .native-toggle:checked { background: #b12222; border-color: #b12222; }
                .native-toggle:checked::after { background: #fff; transform: translateX(20px); }

                .picker-actions { display: flex; gap: 10px; padding-top: 12px; flex-shrink: 0; }
                .quest-pick-btn { flex: 1; padding: 10px; border: 1px solid; border-radius: var(--radius-sm, 8px); font-size: 13px; font-weight: 700; cursor: pointer; transition: 0.2s; display: flex; align-items: center; justify-content: center; gap: 6px; font-family: inherit; color: #fff;}
                .quest-pick-btn.start { background-color: #b12222; border-color: #b12222; }
                .quest-pick-btn.start:hover:not(:disabled) { background: #c93333; border-color: #c93333; }
                .quest-pick-btn.deselect { background-color: #1a1719; border-color: #291d1d; color: #b27a7a; }
                .quest-pick-btn.deselect:hover:not(:disabled) { background: #2a1a1a; }
                .quest-pick-btn:disabled { opacity: 0.5; cursor: not-allowed; }
            `;
            document.head.appendChild(style);

            this.root = document.createElement('div');
            this.root.id = 'orion-ui';
            this.root.innerHTML = `
                <div id="orion-head">
                    <span id="orion-title">${ICONS.BOLT} ${CONFIG.NAME}
                        <span class="dev-credit">by NAs Team</span>
                        <span style="opacity:0.6; font-size:10px; margin-left:4px; padding-top: 3px; font-weight:500; color:#8a6a6a;">${CONFIG.VERSION}</span>
                    </span>
                    <div id="orion-controls">
                        <span class="ctrl-btn ctrl-stop" id="orion-stop" title="Stop script">${ICONS.STOP} STOP</span>
                        <span class="ctrl-btn ctrl-hide" id="orion-close" title="Shift + .">HIDE</span>
                        <span class="ctrl-btn ctrl-opts" id="orion-opts" title="Options">${ICONS.OPT}</span>
                    </div>
                </div>
                <div id="orion-body"><div style="text-align:center; padding:30px; color:#b27a7a; font-size:12px; font-weight:500;">جاري تهيئة النظام...</div></div>
                <div id="orion-logs"></div>
            `;
            document.body.appendChild(this.root);

            const head = document.getElementById('orion-head');
            let collapsed = false;
            head.addEventListener('dblclick', e => {
                if (e.target.closest('.ctrl-btn')) return;
                collapsed = !collapsed;
                this.root.style.height = collapsed ? '50px' : '';
            });

            head.addEventListener('mousedown', e => {
                if (e.target.closest('.ctrl-btn')) return;
                head.classList.add('dragging');
                const startX = e.clientX, startY = e.clientY;
                const rect = this.root.getBoundingClientRect();
                const initialLeft = rect.left, initialTop = rect.top;
                this.root.style.left = `${initialLeft}px`;
                this.root.style.top = `${initialTop}px`;
                this.root.style.right = 'auto';
                e.preventDefault();
                const onMouseMove = ev => {
                    this.root.style.left = `${Math.max(0, Math.min(initialLeft + (ev.clientX - startX), window.innerWidth - this.root.offsetWidth))}px`;
                    this.root.style.top = `${Math.max(0, Math.min(initialTop + (ev.clientY - startY), window.innerHeight - 50))}px`;
                };
                const onMouseUp = () => {
                    head.classList.remove('dragging');
                    document.removeEventListener('mousemove', onMouseMove);
                    document.removeEventListener('mouseup', onMouseUp);
                };
                document.addEventListener('mousemove', onMouseMove);
                document.addEventListener('mouseup', onMouseUp);
            });

            document.getElementById('orion-body').addEventListener('click', async (e) => {
                if (e.target.classList.contains('goto-btn')) {
                    if (Mods.Router) Mods.Router.transitionTo('/quest-home');
                    return;
                }
                if (e.target.classList.contains('claim-btn')) {
                    const btn = e.target;
                    if (btn.disabled) return;
                    const questId = btn.getAttribute('data-id');
                    const taskData = this.tasks.get(questId);
                    if (!taskData) return;
                    btn.innerText = "WAITING...";
                    btn.disabled = true;
                    btn.style.opacity = "0.5";
                    this.updateTask(questId, { ...taskData, claimState: 'WAITING' });
                    try {
                        const claimRes = await Tasks.claimReward(questId);
                        if (claimRes?.body?.claimed_at) {
                            btn.innerText = "CLAIMED!";
                            this.log(`[Claim] Reward for "${taskData.name}" claimed successfully!`, 'success');
                            this.updateTask(questId, { ...taskData, status: "CLAIMED", claimable: false, claimState: null });
                            setTimeout(() => this.removeTask(questId), 2000);
                        } else {
                            this.log(`[Claim] Reward for "${taskData.name}" wasn't confirmed. Claim it from Discord's Quests page.`, 'warn');
                            this.updateTask(questId, { ...taskData, claimState: 'FAILED' });
                        }
                    } catch (err) {
                        this.log(`[Claim] Action required for "${taskData.name}". Check Discord UI for captcha.`, 'warn');
                        this.updateTask(questId, { ...taskData, claimState: 'FAILED' });
                    }
                }
            });

            document.getElementById('orion-close').onclick = () => this.toggle();
            document.getElementById('orion-stop').onclick = () => this.shutdown();

            this._hotkey = e => (e.key === '>' || (e.shiftKey && e.key === '.')) && this.toggle();
            document.addEventListener('keydown', this._hotkey);

            document.getElementById('orion-opts').addEventListener('click', () => {
                const panel = document.getElementById('orion-options-panel');
                if (!panel) return;
                const open = panel.style.display === 'none';
                panel.style.display = open ? '' : 'none';
                const list = document.getElementById('orion-quest-list');
                if (list) list.style.display = open ? 'none' : '';
                const actions = document.querySelector('#orion-picker-form .picker-actions');
                if (actions) actions.style.display = open ? 'none' : '';
            });

            this.startTicker();
        },

        toggle() {
            if (!this.root?.parentElement) return;
            this.root.style.display = this.root.style.display === 'none' ? 'flex' : 'none';
        },

        shutdown() {
            if (!RUNTIME.running) return;
            RUNTIME.running = false;
            this.log("[System] Stopping script & cleaning up...", "warn");
            if (this.tickerId) clearInterval(this.tickerId);
            if (this._hotkey) { document.removeEventListener('keydown', this._hotkey); this._hotkey = null; }
            for (const cleanupFn of RUNTIME.cleanups) {
                try { cleanupFn(); } catch (e) { this.log(`[Cleanup] ${e.message}`, 'debug'); }
            }
            RUNTIME.cleanups.clear();
            Patcher.clean();
            window.orionLock = false;
            const styles = document.getElementById('orion-styles');
            const root = this.root;
            setTimeout(() => {
                if (styles?.parentElement) styles.remove();
                if (root?.parentElement) root.remove();
            }, 1000);
        },

        _getPct(t) {
            if (t.done) return 100;
            if (t.pending || t.failed || !t.max) return 0;
            return Math.min(100, (t.cur / t.max) * 100);
        },

        SERVER_DRIVEN: ["GAME", "STREAM"],

        startTicker() {
            if (this.tickerId) clearInterval(this.tickerId);
            this.tickerId = setInterval(() => {
                if (!RUNTIME.running) return clearInterval(this.tickerId);
                for (const [id, task] of this.tasks.entries()) {
                    if (task.status !== "RUNNING" || task.type === "ACHIEVEMENT") continue;
                    let cur;
                    if (this.SERVER_DRIVEN.includes(task.type)) {
                        if (task.serverAt == null) continue;
                        cur = Math.min(task.serverCur + (Date.now() - task.serverAt) / 1000, task.max);
                    } else {
                        cur = Math.min(task.cur + 1, task.max);
                    }
                    this.updateTask(id, { cur });
                }
            }, 1000);
        },

        updateTask(id, data) {
            const oldData = this.tasks.get(id);
            const isPending = data.status === "PENDING" || data.status === "QUEUE";
            const isDone = data.status === "COMPLETED" || data.status === "CLAIMED";
            const isFailed = data.status === "FAILED";
            const newData = { ...oldData, ...data, done: isDone, pending: isPending, failed: isFailed };
            this.tasks.set(id, newData);
            if (oldData && oldData.status === newData.status && oldData.removing === newData.removing &&
                oldData.claimable === newData.claimable && oldData.claimState === newData.claimState &&
                oldData.actionRequired === newData.actionRequired) {
                const card = document.getElementById(`orion-task-${esc(id)}`);
                if (card) {
                    const pct = this._getPct(newData);
                    const iconContainer = card.querySelector('.task-icon');
                    if (iconContainer) iconContainer.style.setProperty('--p', `${pct}%`);
                    const overlay = card.querySelector('.task-icon-overlay');
                    if (overlay) overlay.textContent = `${Math.floor(pct)}%`;
                    const progressText = card.querySelector('.progress-text');
                    if (progressText) {
                        const unit = newData.type === 'ACHIEVEMENT' ? '' : 's';
                        progressText.textContent = `${Math.min(Math.floor(newData.cur), newData.max)} / ${newData.max}${unit}`;
                    }
                    return;
                }
            }
            this.render();
        },

        removeTask(id) {
            if (this.tasks.has(id)) {
                this.tasks.get(id).removing = true;
                this.render();
                setTimeout(() => { this.tasks.delete(id); this.render(); }, 500);
            }
        },

        log(msg, type = 'info') {
            const colors = { info: "#b27a7a", success: "#3BA55C", warn: "#faa61a", err: "#f04747", debug: "#6a5a5a" };
            console.log(`%c[${CONFIG.NAME}] %c${msg}`, `color: ${CONFIG.THEME}; font-weight: bold;`, `color: ${colors[type] || colors.info}`);
            try {
                const box = document.getElementById('orion-logs');
                if (box && type !== 'debug') {
                    const el = document.createElement('div'); el.className = `log-item c-${type}`;
                    el.innerHTML = `<span class="log-ts">${new Date().toLocaleTimeString().split(' ')[0]}</span> <span>${esc(msg)}</span>`;
                    box.appendChild(el); box.scrollTop = box.scrollHeight;
                    while (box.children.length > CONFIG.MAX_LOG_ITEMS) box.firstChild.remove();
                }
            } catch (e) { console.debug('[Logger] DOM error:', e.message); }
        },

        render() {
            if (document.getElementById('orion-picker-form')) return;
            const body = document.getElementById('orion-body');
            if (!body) return;
            if (!this.tasks.size) return body.innerHTML = `<div style="text-align:center; padding:30px; color:#b27a7a; font-size:13px;">في انتظار المهام...</div>`;
            const sorted = [...this.tasks.entries()].sort((a, b) => {
                const ta = a[1], tb = b[1];
                if (ta.done !== tb.done) return ta.done ? 1 : -1;
                if (ta.failed !== tb.failed) return ta.failed ? 1 : -1;
                if (ta.pending !== tb.pending) return ta.pending ? 1 : -1;
                if (!ta.done && !ta.pending && !tb.done && !tb.pending) {
                    const pctA = ta.max ? ta.cur / ta.max : 0;
                    const pctB = tb.max ? tb.cur / tb.max : 0;
                    return pctB - pctA;
                }
                return 0;
            });
            body.innerHTML = sorted.map(([id, t]) => {
                const pct = t.pending || t.failed ? 0 : Math.min(100, (t.cur / t.max) * 100).toFixed(1);
                const icon =
                    t.done ? ICONS.CHECK :
                    t.failed ? ICONS.STOP :
                    t.pending ? ICONS.CLOCK :
                    t.type === 'VIDEO' ? ICONS.VIDEO :
                    t.type === 'ACHIEVEMENT' ? ICONS.ACTIVITY :
                    t.type?.includes('GAME') ? ICONS.GAME :
                    t.type?.includes('STREAM') ? ICONS.STREAM :
                    ICONS.BOLT;
                let statusText = t.status === 'CLAIMED' ? 'CLAIMED' : t.done ? 'COMPLETED' : t.status;
                let progressLabel = t.pending ? 'In Queue' : t.failed ? 'Aborted' : 'Progress';
                const unit = t.type === 'ACHIEVEMENT' ? '' : 's';
                let actionBtn = '';
                if (t.claimable) {
                    if (t.claimState === 'WAITING') actionBtn = `<button class="claim-btn" disabled>WAITING...</button>`;
                    else if (t.claimState === 'FAILED') actionBtn = `<button class="claim-btn failed" disabled>ACTION REQUIRED</button>`;
                    else actionBtn = `<button class="claim-btn" data-id="${esc(id)}">CLAIM REWARD</button>`;
                } else if (t.actionRequired === 'ENROLL') {
                    statusText = 'ACTION REQUIRED'; progressLabel = 'Accept quest in Discord';
                    actionBtn = `<button class="goto-btn">GO TO QUESTS</button>`;
                } else if (t.type === 'ACHIEVEMENT' && t.status === 'RUNNING') {
                    statusText = 'ACTION REQUIRED'; progressLabel = 'Please, complete manually';
                    actionBtn = `<button class="goto-btn">GO TO QUESTS</button>`;
                }
                const stateClass = t.done ? 'done' : t.failed ? 'failed' : t.pending ? 'pending' : 'running';
                const removingClass = t.removing ? 'removing' : '';
                let taskMetaHtml = '';
                if (!t.done) {
                    taskMetaHtml = `
                    <div class="task-meta">
                        <span>${progressLabel}</span>
                        ${actionBtn ? '' : `<span class="progress-text">${Math.min(Math.floor(t.cur), t.max)} / ${t.max}${unit}</span>`}
                    </div>`;
                }
                return `
                <div id="orion-task-${esc(id)}" class="task-card ${stateClass} ${removingClass}">
                    <div class="task-icon" style="--p: ${pct}%">
                        <div class="task-icon-inner">${icon}</div>
                        ${stateClass === 'running' ? `<div class="task-icon-overlay">${Math.floor(pct)}%</div>` : ''}
                    </div>
                    <div class="task-info">
                        <div class="task-status">${statusText}</div>
                        <div class="task-name" title="${esc(t.name)}">${esc(t.name)}</div>
                        ${taskMetaHtml}
                    </div>
                    ${actionBtn ? `<div class="task-actions">${actionBtn}</div>` : ''}
                </div>`;
            }).join('');
        },

        showQuestPicker(quests) {
            return new Promise((resolve) => {
                const body = document.getElementById('orion-body');
                const logs = document.getElementById('orion-logs');
                const closePicker = (data) => {
                    if (logs) logs.style.display = 'block';
                    if (body) { body.classList.remove('picker-mode'); body.innerHTML = ''; }
                    resolve(data);
                };
                if (!body) return closePicker({ selectedQuests: new Set(), autoEnroll: false, autoClaim: false, playSound: false });
                if (logs) logs.style.display = 'none';
                const items = [];
                const rewardTypes = new Map();
                const questTypes = new Set();
                const REWARD_META = { 1: { label: "IN-GAME", color: "#d4934b" }, 3: { label: "AVATAR DECORATION", color: "#a358f2" }, 4: { label: "ORBS", color: "#b12222" } };
                const REWARD_FALLBACK = { label: "OTHER", color: "#b27a7a" };
                quests.forEach(q => {
                    const cfg = q.config?.taskConfig ?? q.config?.taskConfigV2;
                    if (!cfg?.tasks) return;
                    const typeData = Tasks.detectType(cfg, q.config?.application?.id);
                    if (!typeData) return;
                    if (!SYS.IS_DESKTOP && (typeData.type === 'GAME' || typeData.type === 'STREAM')) return;
                    const rw = q.config?.rewardsConfig?.rewards?.[0];
                    const rewardType = rw?.type ?? 0;
                    const rewardText = rw?.messages?.name ?? "Unknown Reward";
                    const meta = REWARD_META[rewardType] ?? REWARD_FALLBACK;
                    const displayType = typeData.type === 'WATCH_VIDEO' ? 'VIDEO' : typeData.type;
                    questTypes.add(displayType);
                    if (!rewardTypes.has(rewardType)) {
                        rewardTypes.set(rewardType, { label: meta.label, count: 0, type: rewardType, color: meta.color });
                    }
                    rewardTypes.get(rewardType).count++;
                    items.push({
                        id: q.id,
                        name: q.config?.messages?.questName ?? "Unknown Quest",
                        type: displayType,
                        rewardType,
                        rewardText,
                        color: meta.color
                    });
                });
                if (!items.length) return closePicker({ selectedQuests: new Set(), autoEnroll: false, autoClaim: false, playSound: false });

                const buildCard = (q) => `
                    <label class="quest-pick" data-rt="${q.rewardType}" data-qt="${q.type}" style="border-left-color: ${q.color};">
                        <input type="checkbox" name="quests" value="${q.id}" class="native-cb" checked>
                        <div class="task-info">
                            <div class="task-name" title="${esc(q.name)}">${esc(q.name)}</div>
                            <div class="task-meta" style="justify-content: flex-start; gap: 8px;">
                                <span style="text-transform: uppercase; color: #b27a7a;">${esc(q.type)}</span>
                                <span style="color: ${q.color};">${esc(q.rewardText)}</span>
                            </div>
                        </div>
                    </label>`;

                const buildToggle = (name, label, isChecked) => `
                    <div class="orion-option">
                        <span class="orion-option-label">${label}</span>
                        <input type="checkbox" name="${name}" class="native-toggle" ${isChecked ? 'checked' : ''}>
                    </div>`;

                body.innerHTML = `
                    <form id="orion-picker-form">
                        <div id="orion-options-panel" style="display:none;">
                            ${rewardTypes.size > 1 ? `
                                <div class="picker-section-title">Filter By Reward</div>
                                <div class="reward-filters">
                                    ${[...rewardTypes.values()].map(rt => `<button type="button" class="reward-filter" data-rt="${rt.type}" style="color: ${rt.color}; border-color: ${rt.color};">${rt.label} (${rt.count})</button>`).join('')}
                                </div>
                            ` : ''}
                            ${questTypes.size > 1 ? `
                                <div class="picker-section-title">Filter By Type</div>
                                <div class="reward-filters">
                                    ${[...questTypes].map(t => `<button type="button" class="type-filter" data-qt="${t}">${t}</button>`).join('')}
                                </div>
                            ` : ''}
                            <div class="picker-section-title">Options</div>
                            <div class="picker-options">
                                ${buildToggle('autoEnroll', 'Auto-enroll in quests', RUNTIME.autoEnroll)}
                                ${buildToggle('autoClaim', 'Auto-claim rewards', RUNTIME.autoClaim)}
                                ${buildToggle('playSound', 'Sound on completion', RUNTIME.playSound)}
                                ${buildToggle('randomDelay', 'Random 1-30min delay between cycles', RUNTIME.randomDelay)}
                            </div>
                        </div>
                        <div id="orion-quest-list" class="picker-quest-list">${items.map(buildCard).join('')}
                            <div id="orion-no-quests" style="display: none; margin: auto; text-align: center; color: #b27a7a; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px;">
                                No quests available
                            </div>
                        </div>
                        <div class="picker-actions">
                            <button type="button" class="quest-pick-btn deselect" id="select-all-btn">DESELECT ALL</button>
                            <button type="submit" class="quest-pick-btn start" id="start-btn">${ICONS.BOLT} <span id="start-btn-text">START (${items.length})</span></button>
                        </div>
                    </form>`;

                const form = document.getElementById('orion-picker-form');
                const selectAllBtn = document.getElementById('select-all-btn');
                const startBtn = document.getElementById('start-btn');
                const getVisibleCheckboxes = () => Array.from(form.querySelectorAll('.quest-pick input[type="checkbox"]'))
                    .filter(cb => !cb.closest('.quest-pick').classList.contains('hidden'));
                const syncUI = () => {
                    const visibleCbs = getVisibleCheckboxes();
                    const totalChecked = visibleCbs.filter(cb => cb.checked).length;
                    const startBtnText = document.getElementById('start-btn-text');
                    if (startBtnText) startBtnText.textContent = `START (${totalChecked})`;
                    startBtn.disabled = totalChecked === 0;
                    if (visibleCbs.length === 0) {
                        selectAllBtn.disabled = true;
                        selectAllBtn.textContent = 'SELECT ALL';
                    } else {
                        selectAllBtn.disabled = false;
                        selectAllBtn.textContent = visibleCbs.every(cb => cb.checked) ? 'DESELECT ALL' : 'SELECT ALL';
                    }
                    const noQuestsMsg = document.getElementById('orion-no-quests');
                    if (noQuestsMsg) {
                        noQuestsMsg.style.display = visibleCbs.length === 0 ? 'block' : 'none';
                    }
                };
                form.addEventListener('change', (e) => { if (e.target.name === 'quests') syncUI(); });
                const activeRewards = new Set([...rewardTypes.keys()].map(String));
                const activeTypes = new Set([...questTypes]);
                const applyFilters = () => {
                    form.querySelectorAll('.quest-pick').forEach(el => {
                        const rt = el.getAttribute('data-rt');
                        const qt = el.getAttribute('data-qt');
                        el.classList.toggle('hidden', !(activeRewards.has(rt) && activeTypes.has(qt)));
                    });
                    syncUI();
                };
                const FILTER_KINDS = [
                    { cls: 'reward-filter', attr: 'data-rt', set: activeRewards },
                    { cls: 'type-filter', attr: 'data-qt', set: activeTypes }
                ];
                form.addEventListener('click', (e) => {
                    const kind = FILTER_KINDS.find(k => e.target.classList.contains(k.cls));
                    if (kind) {
                        e.preventDefault();
                        const value = e.target.getAttribute(kind.attr);
                        e.target.classList.toggle('off');
                        if (e.target.classList.contains('off')) kind.set.delete(value);
                        else kind.set.add(value);
                        applyFilters();
                        return;
                    }
                    if (e.target.id === 'select-all-btn') {
                        e.preventDefault();
                        const visibleCbs = getVisibleCheckboxes();
                        if (visibleCbs.length === 0) return;
                        const shouldCheck = !visibleCbs.every(cb => cb.checked);
                        visibleCbs.forEach(cb => { cb.checked = shouldCheck; });
                        syncUI();
                    }
                });
                form.addEventListener('submit', (e) => {
                    e.preventDefault();
                    const selected = getVisibleCheckboxes().filter(cb => cb.checked);
                    if (selected.length === 0) return;
                    const data = new FormData(form);
                    closePicker({
                        selectedQuests: new Set(selected.map(cb => cb.value)),
                        autoEnroll: data.has('autoEnroll'),
                        autoClaim: data.has('autoClaim'),
                        playSound: data.has('playSound'),
                        randomDelay: data.has('randomDelay')
                    });
                });
                body.classList.add('picker-mode');
                syncUI();
            });
        }
    };

    /* ── request queue ──────────────────────────────────────────── */
    const Traffic = {
        queue: [], processing: false,
        async enqueue(url, body) {
            if (!RUNTIME.running) return Promise.reject(new Error("Stopped"));
            return new Promise((resolve, reject) => {
                this.queue.push({ url, body, resolve, reject, attempts: 0 });
                this.process();
            });
        },
        async process() {
            if (this.processing || this.queue.length === 0) return;
            this.processing = true;
            while (this.queue.length > 0) {
                if (!RUNTIME.running) {
                    this.queue.forEach(req => req.reject(new Error("Shutdown")));
                    this.queue = [];
                    this.processing = false;
                    return;
                }
                const req = this.queue.shift();
                try {
                    const res = await Mods.API.post({ url: req.url, body: req.body });
                    req.resolve(res);
                } catch (e) {
                    const err = ErrorHandler.classify(e);
                    if (err.isRetryable && req.attempts < SYS.MAX_RETRIES) {
                        req.attempts++;
                        const delay = (e.body?.retry_after ?? Math.pow(2, req.attempts)) * 1000;
                        const isGlobal = e.body?.global === true;
                        Logger.log(`[Network] Retry ${req.attempts}/${SYS.MAX_RETRIES} in ${(delay / 1000).toFixed(1)}s (HTTP ${err.status})`, 'warn');
                        const retryJitter = rnd(200, 800);
                        if (isGlobal) {
                            this.queue.unshift(req);
                            await sleep(delay + retryJitter);
                        } else {
                            setTimeout(() => {
                                if (RUNTIME.running) {
                                    this.queue.push(req);
                                    this.process();
                                } else {
                                    req.reject(new Error('Shutdown'));
                                }
                            }, delay + retryJitter);
                        }
                    } else if (err.isClientError) {
                        Logger.log(`[Network] HTTP ${err.status}: ${req.url}`, 'debug');
                        req.reject(e);
                    } else {
                        Logger.log(`[Network] Request to ${req.url} failed: ${err.message}`, 'err');
                        req.reject(e);
                    }
                }
                await sleep(rnd(1200, 1800));
            }
            this.processing = false;
        }
    };

    /* ── store patching ─────────────────────────────────────────── */
    let Mods = {};

    const Patcher = {
        games: [], real: {}, active: false,
        savedShowCurrentGame: null,
        _unhide: null,
        PATCHED: ['getRunningGames', 'getGameForPID', 'getVisibleGame', 'getVisibleRunningGames',
                  'getRunningDiscordApplicationIds', 'getCandidateGames'],
        init(Store) {
            if (!Store) return;
            this.real = {};
            for (const name of this.PATCHED) {
                if (typeof Store[name] === 'function') this.real[name] = Store[name];
            }
            const absent = this.PATCHED.filter(n => !this.real[n]);
            if (absent.length) Logger.log(`[Patcher] Store lacks ${absent.join(', ')}, not patching those.`, 'debug');
        },
        toggle(on) {
            const S = Mods.RunStore;
            const real = this.real;
            if (on && !this.active) {
                S.getRunningGames = () => [...real.getRunningGames.call(S), ...this.games];
                S.getGameForPID = (pid) => this.games.find(g => g.pid === pid) || real.getGameForPID.call(S, pid);
                if (real.getVisibleGame) S.getVisibleGame = () => this.games[0] ?? real.getVisibleGame.call(S);
                if (real.getVisibleRunningGames) S.getVisibleRunningGames = () => [...real.getVisibleRunningGames.call(S), ...this.games];
                if (real.getCandidateGames) S.getCandidateGames = () => [...real.getCandidateGames.call(S), ...this.games];
                if (real.getRunningDiscordApplicationIds) {
                    S.getRunningDiscordApplicationIds = () => {
                        const ids = real.getRunningDiscordApplicationIds.call(S);
                        const ours = this.games.map(g => String(g.id));
                        return ids instanceof Set ? new Set([...ids, ...ours]) : [...(ids ?? []), ...ours];
                    };
                }
                this.active = true;
            } else if (!on && this.active) {
                for (const [name, fn] of Object.entries(real)) S[name] = fn;
                this.active = false;
            }
        },
        syncPresenceSuppression() {
            const setting = Mods.ShowCurrentGame;
            const shouldSuppress = CONFIG.HIDE_ACTIVITY && this.games.length > 0;
            if (!setting) {
                if (shouldSuppress) Logger.log('[Patcher] status.showCurrentGame not found, cannot hide activity.', 'warn');
                return;
            }
            if (shouldSuppress && this.savedShowCurrentGame === null) {
                try {
                    this.savedShowCurrentGame = setting.getSetting() !== false;
                    if (this.savedShowCurrentGame) {
                        Promise.resolve(setting.updateSetting(false)).catch(e =>
                            Logger.log(`[Patcher] Could not turn showCurrentGame off, activity stays visible: ${e.message}`, 'warn'));
                        this._unhide = () => { try { setting.updateSetting(true); } catch (_) { } };
                        window.addEventListener('pagehide', this._unhide);
                        Logger.log('[Patcher] Your "Display current activity as a status message" setting is off while quests run. STOP puts it back. If Discord is closed or reloaded before then, re-enable it in Discord settings.', 'warn');
                    }
                } catch (e) {
                    this.savedShowCurrentGame = null;
                    Logger.log(`[Patcher] showCurrentGame read failed, cannot hide activity: ${e.message}`, 'warn');
                }
            } else if (!shouldSuppress && this.savedShowCurrentGame !== null) {
                const restore = this.savedShowCurrentGame;
                this.savedShowCurrentGame = null;
                if (this._unhide) { window.removeEventListener('pagehide', this._unhide); this._unhide = null; }
                if (restore) {
                    try {
                        Promise.resolve(setting.updateSetting(true)).catch(e =>
                            Logger.log(`[Patcher] Failed to restore showCurrentGame. Re-enable "Display current activity as a status message" in Discord settings: ${e.message}`, 'err'));
                    } catch (e) {
                        Logger.log(`[Patcher] Failed to restore showCurrentGame. Re-enable "Display current activity as a status message" in Discord settings: ${e.message}`, 'err');
                    }
                }
            }
        },
        add(g) {
            if (this.games.some(x => x.pid === g.pid)) return;
            this.games.push(g);
            this.toggle(true);
            this.syncPresenceSuppression();
            this.dispatch([g], []);
            this.rpc(g);
        },
        remove(g) {
            const before = this.games.length;
            this.games = this.games.filter(x => x.pid !== g.pid);
            if (this.games.length === before) return;
            this.dispatch([], [g]);
            this.syncPresenceSuppression();
            if (!this.games.length) {
                this.toggle(false);
                this.rpc(null);
            } else {
                this.rpc(this.games[0]);
            }
        },
        dispatch(added, removed) {
            Mods.Dispatcher?.dispatch({
                type: CONST.EVT.GAME,
                added,
                removed,
                games: Mods.RunStore.getRunningGames()
            });
        },
        rpc(g) {
            if (CONFIG.HIDE_ACTIVITY && g) return;
            try {
                Mods.Dispatcher?.dispatch({
                    type: CONST.EVT.RPC,
                    socketId: null,
                    pid: g ? g.pid : 9999,
                    activity: g ? {
                        application_id: g.id,
                        name: g.name,
                        type: 0,
                        details: null,
                        state: null,
                        timestamps: { start: g.start },
                        icon: g.icon,
                        assets: null
                    } : null
                });
            } catch (e) {
                Logger.log(`[RPC Cleanup] ${e.message}`, 'debug');
            }
        },
        clean() {
            this.games = [];
            this.toggle(false);
            this.syncPresenceSuppression();
            this.rpc(null);
        }
    };

    /* ── task handlers ──────────────────────────────────────────── */
    const Tasks = {
        skipped: new Set(),
        failed: new Set(),
        _streamReal: undefined,
        _streamSpoofs: 0,

        readProgress(userStatus, key) {
            const p = userStatus?.progress;
            const entry = p instanceof Map ? p.get(key) : p?.[key];
            return entry?.value ?? userStatus?.streamProgressSeconds ?? 0;
        },

        sanitize(name) { return name.replace(/[^a-zA-Z0-9 ]/g, "").trim().replace(/\s+/g, " "); },

        appIdFor(cfg, keyName, legacyAppId) {
            return cfg?.tasks?.[keyName]?.applications?.[0]?.id ?? legacyAppId ?? null;
        },

        detectType(cfg, applicationId) {
            const taskKeys = Object.keys(cfg.tasks);
            const typeMap = [
                { match: k => k === "ACHIEVEMENT_IN_ACTIVITY", type: "ACHIEVEMENT" },
                { match: k => k === "PLAY_ACTIVITY", type: "ACTIVITY" },
                { match: k => k.startsWith("STREAM"), type: "STREAM" },
                { match: k => k.includes("VIDEO"), type: "WATCH_VIDEO" },
                { match: k => k.startsWith("PLAY"), type: "GAME" },
                { match: k => k.includes("ACTIVITY"), type: "ACTIVITY" }
            ];
            for (const { match, type } of typeMap) {
                const keyName = taskKeys.find(match);
                if (keyName) {
                    return {
                        type, keyName,
                        target: cfg.tasks[keyName]?.target ?? 0,
                        appId: this.appIdFor(cfg, keyName, applicationId)
                    };
                }
            }
            if (applicationId) {
                return {
                    type: "GAME", keyName: "PLAY_ON_DESKTOP",
                    target: cfg.tasks[taskKeys[0]]?.target ?? 0,
                    appId: applicationId
                };
            }
            return null;
        },

        async fetchGameData(appId, appName) {
            try {
                const res = await Mods.API.get({ url: `/applications/public?application_ids=${appId}` });
                const appData = res?.body?.[0];
                const exeEntry = appData?.executables?.find(x => x.os === "win32");
                const rawExe = exeEntry ? exeEntry.name.replace(">", "") : `${this.sanitize(appName)}.exe`;
                const cleanName = this.sanitize(appData?.name || appName);
                return {
                    name: appData?.name || appName,
                    icon: appData?.icon,
                    exeName: rawExe,
                    cmdLine: `C:\\Program Files\\${cleanName}\\${rawExe}`,
                    exePath: `c:/program files/${cleanName.toLowerCase()}/${rawExe}`,
                    id: appId
                };
            } catch (e) {
                Logger.log(`[FetchGame] Fallback for ${appName}: ${e?.message ?? e}`, 'debug');
                const cleanName = this.sanitize(appName);
                const safeExe = `${cleanName.replace(/\s+/g, "")}.exe`;
                return {
                    name: appName, exeName: safeExe,
                    cmdLine: `C:\\Program Files\\${cleanName}\\${safeExe}`,
                    exePath: `c:/program files/${cleanName.toLowerCase()}/${safeExe}`,
                    id: appId
                };
            }
        },

        async claimReward(questId) {
            return await Mods.API.post({
                url: `/quests/${questId}/claim-reward`,
                body: { platform: 0, location: 11, is_targeted: false, metadata_sealed: null, traffic_metadata_sealed: sealedFor(questId) }
            });
        },

        failTask(q, t, reason) {
            const currentProgress = Logger.tasks.get(q.id)?.cur ?? 0;
            Logger.updateTask(q.id, { name: t.name, type: t.type, cur: currentProgress, max: t.target, status: "FAILED" });
            Logger.log(`[Task] Aborted "${t.name}": ${reason}`, 'err');
            Tasks.skipped.add(q.id);
            Tasks.failed.add(q.id);
            setTimeout(() => Logger.removeTask(q.id), 2000);
        },

        async VIDEO(q, t, s) {
            let cur = s?.progress?.[t.keyName]?.value ?? s?.progress?.[t.type]?.value ?? 0;
            let failCount = 0;
            Logger.updateTask(q.id, { name: t.name, type: "VIDEO", cur, max: t.target, status: "RUNNING" });
            const startTime = Date.now();
            let calls = 0;
            while (cur < t.target && RUNTIME.running) {
                const delayMs = rnd(7000, 9500);
                await sleep(delayMs);
                const elapsedSec = (delayMs / 1000) + (Math.random() * 0.02 - 0.01);
                cur += elapsedSec;
                const payloadTs = Number(Math.min(t.target, cur).toFixed(6));
                try {
                    const r = await Traffic.enqueue(`/quests/${q.id}/video-progress`, { timestamp: payloadTs });
                    calls++;
                    const serverVal = r?.body?.progress?.[t.keyName]?.value ?? r?.body?.progress?.WATCH_VIDEO?.value;
                    if (serverVal > cur) cur = Math.min(t.target, serverVal);
                    if (r?.body?.completed_at) break;
                    failCount = 0;
                } catch (e) {
                    failCount++;
                    const err = ErrorHandler.classify(e);
                    if (err.isClientError) {
                        Logger.log(`[Task] Video quest unavailable (HTTP ${err.status}). Skipping.`, 'warn');
                        return Tasks.failTask(q, t, `Client Error ${err.status}`);
                    }
                    if (failCount >= SYS.MAX_TASK_FAILURES) {
                        return Tasks.failTask(q, t, 'Too many network failures');
                    }
                    Logger.log(`[Task] VIDEO progress failed (${failCount}/${SYS.MAX_TASK_FAILURES}): ${err.message}`, 'debug');
                }
                Logger.updateTask(q.id, { name: t.name, type: "VIDEO", cur, max: t.target, status: "RUNNING" });
                if (Date.now() - startTime > SYS.MAX_TIME) {
                    return Tasks.failTask(q, t, 'Timeout exceeded');
                }
            }
            if (RUNTIME.running) {
                Logger.log(`[Task] VIDEO "${t.name}" done in ${calls} API calls`, 'debug');
                Tasks.finish(q, t);
            }
        },

        GAME(q, t, s) { return Tasks.generic(q, t, "GAME", "PLAY_ON_DESKTOP", s); },
        STREAM(q, t, s) { return Tasks.generic(q, t, "STREAM", "STREAM_ON_DESKTOP", s); },

        async generic(q, t, type, fallbackKey, s) {
            if (!RUNTIME.running) return;
            const key = t.keyName || fallbackKey;
            const gameData = await this.fetchGameData(t.appId, t.name);
            if (!RUNTIME.running) return;
            return new Promise(resolve => {
                const pid = rnd(2500, 12500) * 4;
                const game = {
                    id: gameData.id, name: gameData.name, icon: gameData.icon,
                    pid, pidPath: [pid], processName: gameData.name, start: Date.now(),
                    exeName: gameData.exeName, exePath: gameData.exePath, cmdLine: gameData.cmdLine,
                    executables: [{ os: 'win32', name: gameData.exeName, is_launcher: false }],
                    windowHandle: 0, fullscreenType: 0, overlay: true, sandboxed: false,
                    hidden: false, isLauncher: false
                };
                let cleanupHook;
                let cleaned = false;
                let safetyTimer;
                let watchdogTimer;
                let beats = 0;
                if (type === "STREAM") {
                    if (Mods.StreamStore) {
                        if (Tasks._streamSpoofs === 0) Tasks._streamReal = Mods.StreamStore.getStreamerActiveStreamMetadata;
                        Tasks._streamSpoofs++;
                        Mods.StreamStore.getStreamerActiveStreamMetadata = () => ({ id: gameData.id, pid, sourceName: gameData.name });
                    }
                    cleanupHook = () => {
                        if (Mods.StreamStore && Tasks._streamSpoofs > 0 && --Tasks._streamSpoofs === 0) {
                            Mods.StreamStore.getStreamerActiveStreamMetadata = Tasks._streamReal;
                        }
                    };
                } else {
                    Patcher.add(game);
                    cleanupHook = () => Patcher.remove(game);
                }
                const seeded = Tasks.readProgress(s, key);
                Logger.updateTask(q.id, { name: t.name, type, cur: seeded, max: t.target, status: "RUNNING" });
                Logger.log(`[Task] Started ${type}: ${gameData.name}`, 'info');
                const finish = () => {
                    if (cleaned) return;
                    cleaned = true;
                    clearTimeout(safetyTimer);
                    clearTimeout(watchdogTimer);
                    try { cleanupHook(); } catch (e) { Logger.log(`[Task] Cleanup: ${e.message}`, 'debug'); }
                    try { Mods.Dispatcher?.unsubscribe(CONST.EVT.HEARTBEAT, check); } catch (e) {
                        Logger.log(`[Dispatcher] Unsubscribe failed: ${e.message}`, 'debug');
                    }
                    RUNTIME.cleanups.delete(abort);
                };
                const abort = () => { finish(); resolve(); };
                safetyTimer = setTimeout(() => {
                    if (RUNTIME.running) Tasks.failTask(q, t, 'Timeout exceeded (25m)');
                    finish();
                    resolve();
                }, SYS.MAX_TIME);
                const armWatchdog = () => {
                    clearTimeout(watchdogTimer);
                    watchdogTimer = setTimeout(() => {
                        if (cleaned || !RUNTIME.running) return;
                        Logger.log(beats === 0
                            ? `[Task] Discord never reported progress for "${t.name}". It is not accepting the injected process on this client, so there is nothing to wait for.`
                            : `[Task] Discord stopped reporting progress for "${t.name}" after ${beats} update(s). Giving up instead of idling.`, 'err');
                        Tasks.failTask(q, t, 'No heartbeat from Discord');
                        finish();
                        resolve();
                    }, SYS.HEARTBEAT_GRACE);
                };
                armWatchdog();
                const check = (d) => {
                    if (!RUNTIME.running) { finish(); resolve(); return; }
                    if (d?.questId !== q.id) return;
                    beats++;
                    armWatchdog();
                    const prog = Tasks.readProgress(d.userStatus, key);
                    Logger.updateTask(q.id, {
                        name: t.name, type, cur: prog, max: t.target, status: "RUNNING",
                        serverCur: prog, serverAt: Date.now()
                    });
                    if (prog >= t.target) {
                        finish();
                        Tasks.finish(q, t);
                        resolve();
                    }
                };
                Mods.Dispatcher?.subscribe(CONST.EVT.HEARTBEAT, check);
                RUNTIME.cleanups.add(abort);
            });
        },

        _relayUrl: 'http://127.0.0.1:43210',
        _relayProbe: null,
        _relayProbeAt: 0,
        RELAY_PROBE_TTL: 60000,

        _probeRelay() {
            if (this._relayProbe && Date.now() - this._relayProbeAt < this.RELAY_PROBE_TTL) return this._relayProbe;
            this._relayProbeAt = Date.now();
            return this._relayProbe = (async () => {
                try {
                    const r = await Promise.race([
                        fetch(`${this._relayUrl}/health`, { method: 'GET', redirect: 'error' }),
                        new Promise((_, reject) => setTimeout(() => reject(new Error('probe timeout')), 800))
                    ]);
                    if (!RUNTIME.running) return false;
                    if (r.ok) Logger.log('[Bypass] Orion Relay detected on 127.0.0.1:43210.', 'info');
                    return r.ok;
                } catch (_) {
                    return false;
                }
            })();
        },

        async _bypassPost(url, headers, jsonBody) {
            const relayAvailable = await this._probeRelay();
            if (!RUNTIME.running) throw new Error('Shutdown');
            if (relayAvailable) {
                let r;
                try {
                    r = await fetch(`${this._relayUrl}/proxy`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ url, headers, body: jsonBody }),
                        redirect: 'error'
                    });
                    if (!RUNTIME.running) throw new Error('Shutdown');
                } catch (e) {
                    if (!RUNTIME.running) throw e;
                    this._relayProbe = null;
                    Logger.log(`[Bypass] Relay stopped responding, trying other transports: ${e?.message ?? e}`, 'debug');
                }
                if (r) {
                    if (!r.ok) {
                        const body = await r.text();
                        if (!RUNTIME.running) throw new Error('Shutdown');
                        throw { status: r.status, body };
                    }
                    const result = await r.json();
                    if (!RUNTIME.running) throw new Error('Shutdown');
                    if (!result.ok) throw { status: result.status, body: result.body };
                    return result;
                }
            }
            try {
                const helper = window.VencordNative?.pluginHelpers?.OrionQuests;
                if (helper) {
                    const u = new URL(url);
                    const appId = u.hostname.split('.')[0];
                    const questId = headers['X-Discord-Quest-ID'];
                    const referrer = headers['Referer'];
                    if (u.pathname.endsWith('/acf/authorize')) {
                        const { code } = JSON.parse(jsonBody);
                        const r = await helper.discordsaysAuthorize({ appId, questId, authCode: code, referrer });
                        if (!RUNTIME.running) throw new Error('Shutdown');
                        if (!r.ok) throw { status: r.status, body: r.body };
                        return { ok: true, status: r.status, body: r.body };
                    }
                    if (u.pathname.endsWith('/acf/quest/progress')) {
                        const { progress } = JSON.parse(jsonBody);
                        const token = headers['X-Auth-Token'];
                        const r = await helper.discordsaysProgress({ appId, questId, token, target: progress, referrer });
                        if (!RUNTIME.running) throw new Error('Shutdown');
                        if (!r.ok) throw { status: r.status, body: r.body };
                        return { ok: true, status: r.status, body: r.body };
                    }
                }
            } catch (e) {
                if (!RUNTIME.running) throw e;
                if (e?.status) throw e;
                Logger.log(`[Bypass] VencordNative path errored: ${e?.message ?? e}`, 'debug');
            }
            const dn = window.DiscordNative;
            if (dn) {
                const probes = [
                    () => dn.http?.makeRequest,
                    () => dn.app?.makeRequest,
                ];
                for (const probe of probes) {
                    if (!RUNTIME.running) throw new Error('Shutdown');
                    try {
                        const fn = probe();
                        if (typeof fn === 'function') {
                            const r = await fn.call(dn, { method: 'POST', url, headers, body: jsonBody });
                            if (!RUNTIME.running) throw new Error('Shutdown');
                            if (r && (r.status || r.statusCode)) {
                                const status = r.status ?? r.statusCode;
                                return { ok: status >= 200 && status < 300, status, body: r.body ?? r.responseText ?? '' };
                            }
                        }
                    } catch (e) {
                        if (!RUNTIME.running) throw e;
                    }
                }
            }
            if (!RUNTIME.running) throw new Error('Shutdown');
            const res = await fetch(url, { method: 'POST', headers, body: jsonBody, redirect: 'error' });
            if (!RUNTIME.running) throw new Error('Shutdown');
            const body = await res.text();
            if (!RUNTIME.running) throw new Error('Shutdown');
            if (!res.ok) throw { status: res.status, body };
            return { ok: true, status: res.status, body };
        },

        async bypassAchievement(q, t) {
            const appId = t.appId || q.config?.application?.id;
            let reason = null;
            if (!appId) {
                reason = 'this quest carries no application id, so there is nothing to authorize against';
                return { ok: false, reason };
            }
            if (!/^\d+$/.test(String(appId))) {
                reason = `the quest's application id ("${appId}") is not numeric, so it was refused before any request went out`;
                Logger.log(`[Bypass] Refusing non-numeric appId "${appId}".`, 'warn');
                return { ok: false, reason };
            }
            let preGrantIds;
            try {
                const before = await Mods.API.get({ url: '/oauth2/tokens' });
                if (!RUNTIME.running) return { ok: false, reason };
                preGrantIds = new Set((before?.body || []).filter(tk => tk.application?.id === appId).map(tk => tk.id));
            } catch (e) {
                if (!RUNTIME.running) return { ok: false, reason };
                Logger.log(`[Bypass] Couldn't snapshot existing grants; aborting so we never leave an un-revocable authorization: ${e?.message}`, 'warn');
                return { ok: false, reason };
            }
            try {
                let appName = null;
                try {
                    const a = await Mods.API.get({ url: `/applications/public?application_ids=${appId}` });
                    if (!RUNTIME.running) return { ok: false, reason };
                    appName = a?.body?.[0]?.name ?? null;
                } catch (_) {
                    if (!RUNTIME.running) return { ok: false, reason };
                }
                const consented = await Consent.ask(appId, appName);
                if (!RUNTIME.running) return { ok: false, reason };
                if (!consented) {
                    Logger.log(`[Bypass] Consent declined for "${t.name}". Not authorizing the app.`, 'warn');
                    return { ok: false, reason };
                }
                Logger.log(`[Bypass] Trying Discord Says auth flow for "${t.name}"...`, 'info');
                const authRes = await Mods.API.post({
                    url: '/oauth2/authorize',
                    query: {
                        response_type: 'code',
                        client_id: appId,
                        scope: 'identify applications.commands applications.entitlements'
                    },
                    body: {
                        permissions: '0',
                        authorize: true,
                        integration_type: 1,
                        location_context: { guild_id: '10000', channel_id: '10000', channel_type: 10000 }
                    }
                });
                if (!RUNTIME.running) return { ok: false, reason };
                const location = authRes?.body?.location;
                if (!location) throw new Error('no location in /oauth2/authorize response');
                const authCode = new URL(location).searchParams.get('code');
                if (!authCode) throw new Error('no code in authorize location');
                const ticketRes = await Mods.API.post({ url: `/applications/${appId}/proxy-tickets`, body: {} });
                if (!RUNTIME.running) return { ok: false, reason };
                const proxyTicket = ticketRes?.body?.ticket;
                if (!proxyTicket) throw new Error('no proxy ticket');
                const referrer = `https://${appId}.discordsays.com/?instance_id=example-cl-instance&platform=desktop&discord_proxy_ticket=${encodeURIComponent(proxyTicket)}`;
                const dsAuthRes = await Tasks._bypassPost(
                    `https://${appId}.discordsays.com/.proxy/acf/authorize`,
                    { 'Content-Type': 'application/json', 'X-Auth-Token': '', 'X-Discord-Quest-ID': q.id, 'Referer': referrer },
                    JSON.stringify({ code: authCode })
                );
                if (!RUNTIME.running) return { ok: false, reason };
                let dsToken;
                try { dsToken = JSON.parse(dsAuthRes.body)?.token; }
                catch { throw new Error('discordsays returned non-JSON: ' + String(dsAuthRes.body).slice(0, 120)); }
                if (!dsToken) throw new Error('no discordsays token');
                await Tasks._bypassPost(
                    `https://${appId}.discordsays.com/.proxy/acf/quest/progress`,
                    { 'Content-Type': 'application/json', 'X-Auth-Token': dsToken, 'X-Discord-Quest-ID': q.id, 'Referer': referrer },
                    JSON.stringify({ progress: t.target })
                );
                if (!RUNTIME.running) return { ok: false, reason };
                Logger.log(`[Bypass] Success. "${t.name}" completed via Discord Says.`, 'success');
                return { ok: true, reason: null };
            } catch (e) {
                if (!RUNTIME.running) return { ok: false, reason };
                if (e instanceof TypeError && /failed to fetch|networkerror/i.test(e.message)) {
                    Logger.log(`[Bypass] Discord's CSP blocks the script from reaching discordsays.com. Use the Vencord plugin port for the auto-bypass, since a userscript cannot bypass CSP. Skipping "${t.name}".`, 'warn');
                    return { ok: false, reason };
                }
                const code = e?.body?.code;
                if (code === 50165) {
                    reason = 'the activity is age-gated or delisted, so Discord refuses the proxy ticket on this account';
                    Logger.log(`[Bypass] "${t.name}" can't be launched (age-gated or delisted). Discord blocks the proxy ticket, so there is nothing we can do.`, 'warn');
                    return { ok: false, reason };
                }
                const parts = [];
                if (e?.status) parts.push(`HTTP ${e.status}`);
                if (code) parts.push(`code ${code}`);
                if (e?.body?.message) parts.push(e.body.message);
                else if (e?.message) parts.push(e.message);
                else if (typeof e === 'string') parts.push(e);
                else if (e) { try { parts.push(JSON.stringify(e).slice(0, 200)); } catch { parts.push(String(e)); } }
                reason = `the Discord Says bypass failed (${parts.join(', ') || 'unknown error'})`;
                Logger.log(`[Bypass] Failed: ${parts.join(', ') || 'unknown'}`, 'warn');
                return { ok: false, reason };
            } finally {
                if (preGrantIds) {
                    try {
                        const after = await Mods.API.get({ url: '/oauth2/tokens' });
                        const ours = (after?.body || []).filter(tk => tk.application?.id === appId && !preGrantIds.has(tk.id));
                        for (const g of ours) await Mods.API.del({ url: `/oauth2/tokens/${g.id}` });
                    } catch (e) {
                        Logger.log(`[Bypass] Deauthorize cleanup non-fatal: ${e?.message}`, 'debug');
                    }
                }
            }
        },

        async ACHIEVEMENT(q, t) {
            Logger.updateTask(q.id, { name: t.name, type: "ACHIEVEMENT", cur: 0, max: t.target, status: "RUNNING" });
            const appId = String(t.appId || q.config?.application?.id || '');
            const key = buildStreamKey();

            // Build ordered list of heartbeat payloads to try:
            // 1. Without stream_key (works for some quests without voice requirement)
            // 2. With stream_key if user is actually in voice channel
            const payloads = [{ application_id: appId, terminal: false }];
            if (key) payloads.push({ stream_key: key, application_id: appId, terminal: false });

            let heartbeatSucceeded = false;
            for (const beat of payloads) {
                if (!RUNTIME.running) return;
                const hasKey = !!beat.stream_key;
                Logger.log(`[Achievement] Trying heartbeat ${hasKey ? 'with stream_key' : 'without stream_key'} for "${t.name}"...`, 'info');
                let cur = 0;
                let failCount = 0;
                let hardFail = false;
                while (cur < t.target && RUNTIME.running) {
                    try {
                        const r = await Traffic.enqueue(`/quests/${q.id}/heartbeat`, beat);
                        if (!RUNTIME.running) return;
                        const prog = r?.body?.progress?.[t.keyName]?.value
                            ?? r?.body?.progress?.ACHIEVEMENT_IN_ACTIVITY?.value
                            ?? null;
                        if (typeof prog === 'number') cur = prog;
                        Logger.updateTask(q.id, { name: t.name, type: "ACHIEVEMENT", cur, max: t.target, status: "RUNNING" });
                        failCount = 0;
                        if (cur >= t.target || r?.body?.completed_at) {
                            try { await Traffic.enqueue(`/quests/${q.id}/heartbeat`, { ...beat, terminal: true }); } catch (_) { }
                            heartbeatSucceeded = true;
                            break;
                        }
                    } catch (e) {
                        if (!RUNTIME.running) return;
                        failCount++;
                        const err = ErrorHandler.classify(e);
                        if (err.isClientError) {
                            Logger.log(`[Achievement] Heartbeat rejected (HTTP ${err.status})${hasKey ? ' with stream_key' : ''}. Trying next approach.`, 'warn');
                            hardFail = true;
                            break;
                        }
                        if (failCount >= SYS.MAX_TASK_FAILURES) {
                            Logger.log(`[Achievement] Too many failures${hasKey ? ' with stream_key' : ''}. Trying next approach.`, 'warn');
                            hardFail = true;
                            break;
                        }
                        await sleep(rnd(3000, 5000));
                        continue;
                    }
                    await sleep(rnd(19000, 22000));
                }
                if (heartbeatSucceeded) break;
                if (!hardFail && cur >= t.target) { heartbeatSucceeded = true; break; }
            }

            if (heartbeatSucceeded && RUNTIME.running) return Tasks.finish(q, t);
            if (!RUNTIME.running) return;

            // Fallback: discordsays bypass (requires Vencord relay or desktop client)
            const bypass = await Tasks.bypassAchievement(q, t);
            if (!RUNTIME.running) return;
            if (bypass.ok) return Tasks.finish(q, t);

            // If running in browser (not Vencord/desktop), provide a clear explanation
            const isBrowser = !SYS.IS_DESKTOP && !window.VencordNative;
            if (isBrowser) {
                Logger.log(`[Achievement] "${t.name}" needs Vencord or the desktop app for auto-completion. The browser's CSP blocks direct discordsays.com requests. Install the Orion Relay Vencord plugin or run Discord as the desktop app.`, 'warn');
            } else {
                Logger.log(`[Achievement] "${t.name}": no auto-completion path worked. ${bypass.reason ?? 'Heartbeat rejected and bypass blocked.'}`, 'warn');
            }
            return Tasks.failTask(q, t, bypass.reason ?? 'no auto-completion path worked');
        },

        async ACTIVITY(q, t) {
            const key = buildStreamKey();
            if (!key) {
                return Tasks.failTask(q, t, 'No voice channel found');
            }
            const beat = { stream_key: key, application_id: String(t.appId || ''), terminal: false };
            let cur = 0;
            let failCount = 0;
            let stalledBeats = 0;
            Logger.updateTask(q.id, { name: t.name, type: "ACTIVITY", cur, max: t.target, status: "RUNNING" });
            const startTime = Date.now();
            while (cur < t.target && RUNTIME.running) {
                try {
                    const r = await Traffic.enqueue(`/quests/${q.id}/heartbeat`, beat);
                    const reported = r?.body?.progress?.[t.keyName]?.value ?? r?.body?.progress?.PLAY_ACTIVITY?.value;
                    if (typeof reported === 'number') { cur = reported; stalledBeats = 0; }
                    else if (++stalledBeats >= SYS.MAX_TASK_FAILURES) return Tasks.failTask(q, t, 'Discord credited no progress');
                    Logger.updateTask(q.id, { name: t.name, type: "ACTIVITY", cur, max: t.target, status: "RUNNING" });
                    failCount = 0;
                    if (cur >= t.target) {
                        try { await Traffic.enqueue(`/quests/${q.id}/heartbeat`, { ...beat, terminal: true }); }
                        catch (e) { Logger.log(`[ACTIVITY] Final heartbeat failed: ${e?.message}`, 'debug'); }
                        break;
                    }
                } catch (e) {
                    failCount++;
                    const err = ErrorHandler.classify(e);
                    if (err.isClientError) {
                        Logger.log(`[Task] Activity quest unavailable (HTTP ${err.status}). Skipping.`, 'warn');
                        return Tasks.failTask(q, t, `Client Error ${err.status}`);
                    }
                    if (failCount >= SYS.MAX_TASK_FAILURES) {
                        return Tasks.failTask(q, t, 'Too many network failures');
                    }
                    Logger.log(`[Task] ACTIVITY heartbeat failed (${failCount}/${SYS.MAX_TASK_FAILURES}): ${err.message}`, 'debug');
                }
                if (Date.now() - startTime > SYS.MAX_TIME) {
                    return Tasks.failTask(q, t, 'Timeout exceeded');
                }
                await sleep(rnd(19000, 22000));
            }
            if (RUNTIME.running && cur >= t.target) Tasks.finish(q, t);
        },

        async finish(q, t) {
            Logger.updateTask(q.id, { name: t.name, type: t.type, cur: t.target, max: t.target, status: "COMPLETED" });
            Logger.log(`[Task] Completed "${t.name}"!`, 'success');
            Sound.play('tick');
            try {
                if (typeof Notification !== 'undefined') {
                    if (Notification.permission === 'default') { try { await Notification.requestPermission(); } catch (_) { } }
                    if (Notification.permission === 'granted') {
                        new Notification(`${CONFIG.NAME}: Quest Completed`, { body: t.name, icon: "https://cdn.discordapp.com/emojis/1120042457007792168.webp", tag: `orion-${q.id}` });
                    }
                }
            } catch (e) { Logger.log(`[Notification] ${e.message}`, 'debug'); }
            if (RUNTIME.autoClaim) {
                try {
                    await sleep(rnd(2500, 6000));
                    if (!RUNTIME.running) return;
                    const claimRes = await this.claimReward(q.id);
                    if (claimRes?.body?.claimed_at) {
                        Logger.log(`[Claim] Reward for "${t.name}" claimed automatically!`, 'success');
                        Logger.updateTask(q.id, { name: t.name, type: t.type, cur: t.target, max: t.target, status: "CLAIMED" });
                        setTimeout(() => Logger.removeTask(q.id), 2000);
                        return;
                    }
                } catch (e) {
                    const needsCaptcha = e?.body?.captcha_key || e?.body?.captcha_sitekey;
                    if (needsCaptcha) {
                        Logger.log(`[Claim] Captcha required for "${t.name}". Use UI button.`, 'warn');
                    } else {
                        Logger.log(`[Claim] Auto-claim failed for "${t.name}": ${e?.body?.message ?? e?.message}`, 'err');
                    }
                }
            }
            Logger.updateTask(q.id, { name: t.name, type: t.type, cur: t.target, max: t.target, status: "COMPLETED", claimable: true, questId: q.id });
        }
    };

    /* ── webpack module extraction ─────────────────────────────── */
    function findShowCurrentGameSetting(moduleCache) {
        if (!moduleCache) return undefined;
        let actions, delay, BoolValue;
        for (const m of Object.values(moduleCache)) {
            try {
                const exp = m?.exports;
                if (!exp || typeof exp !== 'object') continue;
                for (const key of Object.keys(exp)) {
                    const p = exp[key];
                    if (!p) continue;
                    if (!BoolValue && typeof p.create === 'function'
                        && String(p.typeName ?? '').includes('Bool')) BoolValue = p;
                    if (!actions && typeof p.updateAsync === 'function'
                        && (p.ProtoClass?.typeName?.endsWith('.PreloadedUserSettings') || p.type === 1)) {
                        actions = p;
                        delay = exp.UserSettingsDelay?.INFREQUENT_USER_ACTION ?? 0;
                    }
                }
                if (actions && BoolValue) break;
            } catch { }
        }
        if (!actions) return undefined;
        if (!BoolValue) Logger.log('[Patcher] BoolValue proto type not found. Hiding activity will only work if the setting already exists.', 'debug');
        return {
            getSetting: () => actions.getCurrentValue?.()?.status?.showCurrentGame?.value,
            updateSetting: value => actions.updateAsync('status', settings => {
                if (settings.showCurrentGame && typeof settings.showCurrentGame.value === 'boolean') {
                    settings.showCurrentGame.value = value;
                } else if (BoolValue) {
                    settings.showCurrentGame = BoolValue.create({ value });
                } else {
                    throw new Error('BoolValue proto type not found');
                }
            }, delay)
        };
    }

    function loadModules() {
        try {
            if (typeof window.Vencord !== 'undefined' && window.Vencord.Webpack) {
                Logger.log('[System] Vencord detected. Using Vencord Webpack API...', 'info');
                const W = window.Vencord.Webpack;
                let routerModule;
                try {
                    const m = W.findByCode('transitionTo -');
                    if (m) {
                        for (const prop of [m, m.default, ...Object.values(m)]) {
                            if (typeof prop === 'function' && prop.toString().includes('transitionTo -')) {
                                routerModule = { transitionTo: prop };
                                break;
                            }
                        }
                    }
                } catch (e) { }
                Mods = {
                    QuestStore: W.findStore('QuestStore') || W.findStore('QuestsStore'),
                    RunStore: W.findStore('RunningGameStore'),
                    StreamStore: W.findStore('ApplicationStreamingStore'),
                    ChanStore: W.findStore('ChannelStore'),
                    GuildChanStore: W.findStore('GuildChannelStore'),
                    UserStore: W.findStore('UserStore'),
                    VoiceStateStore: W.findStore('VoiceStateStore'),
                    SelectedChanStore: W.findStore('SelectedChannelStore'),
                    Dispatcher: W.Common?.FluxDispatcher || W.findByProps('dispatch', 'subscribe', 'flushWaitQueue'),
                    API: W.Common?.RestAPI || W.findByProps('get', 'post', 'del'),
                    Router: routerModule,
                    ShowCurrentGame: findShowCurrentGameSetting(W.cache || W.wreq?.c)
                };
                const required = ['QuestStore', 'API', 'Dispatcher', 'RunStore'];
                const missing = required.filter(k => !Mods[k]);
                if (missing.length === 0) {
                    const optional = ['StreamStore', 'ChanStore', 'GuildChanStore', 'Router', 'VoiceStateStore', 'SelectedChanStore'];
                    optional.forEach(k => { if (!Mods[k]) Logger.log(`[System] Optional module '${k}' not found. Features may be limited.`, 'warn'); });
                    Patcher.init(Mods.RunStore);
                    return true;
                }
                Logger.log(`[System] Vencord extraction missed: ${missing.join(', ')}. Falling back to native...`, 'warn');
            }
            if (typeof webpackChunkdiscord_app === 'undefined') {
                throw new Error("Webpack chunk not found - is this running inside Discord?");
            }
            let req;
            webpackChunkdiscord_app.push([[Symbol()], {}, (r) => {
                const cur = Object.keys(req?.c || {}).length;
                const incoming = Object.keys(r?.c || {}).length;
                if (incoming > cur) req = r;
            }]);
            webpackChunkdiscord_app.pop();
            if (!req?.c) throw new Error("Module registry not available - Discord build incompatible (see issue #20)");
            const modules = Object.values(req.c);
            function findStore(storeName) {
                for (const m of modules) {
                    try {
                        const exp = m?.exports;
                        if (!exp || typeof exp !== 'object') continue;
                        for (const key of Object.keys(exp)) {
                            const prop = exp[key];
                            if (prop && typeof prop === 'object'
                                && prop.__proto__?.constructor?.displayName === storeName) {
                                return prop;
                            }
                        }
                    } catch { }
                }
                return undefined;
            }
            function findDispatcher() {
                for (const m of modules) {
                    try {
                        const exp = m?.exports;
                        if (!exp || typeof exp !== 'object') continue;
                        for (const key of Object.keys(exp)) {
                            const prop = exp[key];
                            if (prop && prop._subscriptions
                                && typeof prop.subscribe === 'function'
                                && typeof prop.dispatch === 'function'
                                && typeof prop.__proto__?.flushWaitQueue === 'function') {
                                return prop;
                            }
                        }
                    } catch { }
                }
                return undefined;
            }
            function findAPI() {
                for (const m of modules) {
                    try {
                        const exp = m?.exports;
                        if (!exp || typeof exp !== 'object') continue;
                        for (const key of Object.keys(exp)) {
                            const prop = exp[key];
                            if (prop && typeof prop.get === 'function'
                                && typeof prop.post === 'function'
                                && typeof prop.del === 'function'
                                && !prop._dispatcher) {
                                return prop;
                            }
                        }
                    } catch { }
                }
                return undefined;
            }
            function findRouter() {
                for (const m of modules) {
                    try {
                        const exp = m?.exports;
                        if (!exp) continue;
                        for (const prop of [exp, exp.default, ...Object.values(exp)]) {
                            if (typeof prop === 'function' && prop.toString().includes('transitionTo -')) {
                                return { transitionTo: prop };
                            }
                        }
                    } catch { }
                }
                return undefined;
            }
            Mods = {
                QuestStore: findStore('QuestStore'),
                RunStore: findStore('RunningGameStore'),
                StreamStore: findStore('ApplicationStreamingStore'),
                ChanStore: findStore('ChannelStore'),
                GuildChanStore: findStore('GuildChannelStore'),
                UserStore: findStore('UserStore'),
                VoiceStateStore: findStore('VoiceStateStore'),
                SelectedChanStore: findStore('SelectedChannelStore'),
                Dispatcher: findDispatcher(),
                API: findAPI(),
                Router: findRouter(),
                ShowCurrentGame: findShowCurrentGameSetting(req.c)
            };
            const required = ['QuestStore', 'API', 'Dispatcher', 'RunStore'];
            const missing = required.filter(k => !Mods[k]);
            if (missing.length > 0) throw new Error(`Core modules not found: ${missing.join(', ')}`);
            const optional = ['StreamStore', 'ChanStore', 'GuildChanStore', 'Router', 'VoiceStateStore', 'SelectedChanStore'];
            optional.forEach(k => { if (!Mods[k]) Logger.log(`[System] Optional module '${k}' not found. Features may be limited.`, 'warn'); });
            Patcher.init(Mods.RunStore);
            return true;
        } catch (e) {
            Logger.log(`[System] Module loading error: ${e.message ?? e}`, 'err');
            console.error(e);
            return false;
        }
    }

    /* ── main loop ─────────────────────────────────────────────── */
    async function runConcurrent(tasks, limit) {
        const executing = new Set();
        for (const task of tasks) {
            if (!RUNTIME.running) break;
            const p = task().finally(() => executing.delete(p));
            executing.add(p);
            await sleep(rnd(1500, 4000));
            if (executing.size >= limit) {
                await Promise.race(executing);
            }
        }
        return Promise.allSettled(executing);
    }

    async function main() {
        Logger.init();
        if (!loadModules()) return Logger.log('[System] Failed to load Discord modules. Aborting.', 'err');

        const getQuests = () => {
            const q = Mods.QuestStore.quests;
            return q instanceof Map ? [...q.values()] : Object.values(q);
        };

        let quests = getQuests().filter(q =>
            !q.userStatus?.completedAt
            && notExpired(q)
            && q.id !== CONST.ID
            && !Tasks.skipped.has(q.id)
        );

        if (!quests.length) {
            Logger.log('[System] All available quests are completed!', 'success');
            return Logger.shutdown();
        }

        const pickerResult = await Logger.showQuestPicker(quests);
        if (!RUNTIME.running) return;

        RUNTIME.autoEnroll = pickerResult.autoEnroll;
        RUNTIME.autoClaim = pickerResult.autoClaim;
        RUNTIME.playSound = pickerResult.playSound;
        RUNTIME.randomDelay = pickerResult.randomDelay;

        if (pickerResult.selectedQuests.size === 0) {
            Logger.log('[System] No quests selected. Shutting down.', 'info');
            return Logger.shutdown();
        }

        let loopCount = 1;

        while (RUNTIME.running) {
            try {
                Logger.log(`[Cycle] Starting loop #${loopCount}...`, 'info');

                const blockedUntil = enrollmentBlockedUntil();
                if (blockedUntil) {
                    Logger.log(`[System] Discord has blocked quest enrollment on this account until ${blockedUntil.toLocaleString()}. Stopping instead of retrying.`, 'err');
                    break;
                }

                quests = getQuests();

                const active = quests.filter(q =>
                    pickerResult.selectedQuests.has(q.id)
                    && !q.userStatus?.completedAt
                    && notExpired(q)
                    && q.id !== CONST.ID
                    && !Tasks.skipped.has(q.id)
                );

                if (!active.length) {
                    const failedCount = [...pickerResult.selectedQuests].filter(id => Tasks.failed.has(id)).length;
                    if (failedCount > 0) {
                        const doneCount = [...pickerResult.selectedQuests].filter(id => !Tasks.failed.has(id)).length;
                        Logger.log(`[System] Done. ${doneCount} quest(s) completed, ${failedCount} quest(s) could not be auto-completed (see warnings above).`, failedCount > 0 ? 'warn' : 'success');
                    } else {
                        Logger.log('[System] All available quests are completed!', 'success');
                    }
                    Sound.play('done');
                    break;
                }

                const queues = { video: [], game: [] };

                active.forEach(q => {
                    try {
                        const cfg = q.config?.taskConfig ?? q.config?.taskConfigV2;
                        if (!cfg?.tasks || typeof cfg.tasks !== 'object') {
                            Logger.log(`[Quest] ${q.id} has invalid task config. Skipping.`, 'warn');
                            return;
                        }
                        const typeData = Tasks.detectType(cfg, q.config?.application?.id);
                        if (!typeData) {
                            Logger.log(`[Quest] Unknown task type: ${q.config?.messages?.questName ?? q.id}`, 'warn');
                            return;
                        }
                        if (!SYS.IS_DESKTOP && (typeData.type === 'GAME' || typeData.type === 'STREAM')) {
                            Logger.log(`[Quest] "${q.config?.messages?.questName}" requires desktop app. Skipping.`, 'warn');
                            return;
                        }
                        const { type, keyName, target, appId } = typeData;
                        if (target <= 0) {
                            Logger.log(`[Quest] Invalid target (${target}) for ${q.id}. Skipping.`, 'warn');
                            return;
                        }
                        if ((type === 'GAME' || type === 'STREAM') && !appId) {
                            Logger.log(`[Quest] "${q.config?.messages?.questName ?? q.id}" has no application id in its config, so the game cannot be spoofed. Skipping.`, 'warn');
                            Tasks.skipped.add(q.id);
                            return;
                        }
                        const tInfo = {
                            id: q.id,
                            appId: appId ?? 0,
                            name: q.config?.messages?.questName ?? "Unknown Quest",
                            target,
                            type,
                            keyName
                        };
                        if (!q.userStatus?.enrolledAt && !RUNTIME.autoEnroll) {
                            Logger.updateTask(tInfo.id, {
                                name: tInfo.name, type: tInfo.type, cur: 0, max: tInfo.target,
                                status: "PENDING", actionRequired: 'ENROLL'
                            });
                            return;
                        }
                        if (Logger.tasks.has(q.id) && Logger.tasks.get(q.id).status === "RUNNING") return;
                        Logger.updateTask(tInfo.id, {
                            name: tInfo.name, type: tInfo.type, cur: 0, max: tInfo.target,
                            status: "QUEUE", actionRequired: null
                        });
                        const taskFunc = async () => {
                            if (!q.userStatus?.enrolledAt) {
                                Logger.log(`[Enroll] Accepting quest: ${tInfo.name}`, 'info');
                                try {
                                    await Traffic.enqueue(`/quests/${q.id}/enroll`, {
                                        location: 11,
                                        is_targeted: false,
                                        metadata_sealed: null,
                                        traffic_metadata_sealed: sealedFor(q.id)
                                    });
                                    await sleep(rnd(800, 1500));
                                } catch (e) {
                                    const err = ErrorHandler.classify(e);
                                    if (ErrorHandler.isSkippableQuest(e)) {
                                        Tasks.skipped.add(q.id);
                                        Logger.log(`[Enroll] ${tInfo.name} unavailable (${err.status}). Skipping.`, 'warn');
                                    } else {
                                        Logger.log(`[Enroll] Failed for ${tInfo.name}: ${err.message}`, 'err');
                                    }
                                    return Tasks.failTask(q, tInfo, `Enrollment failed`);
                                }
                            }
                            if (type === "WATCH_VIDEO") return Tasks.VIDEO(q, tInfo, q.userStatus);
                            if (type === "ACHIEVEMENT") return Tasks.ACHIEVEMENT(q, tInfo);
                            const runner = type === "STREAM" ? Tasks.STREAM : (type === "ACTIVITY" ? Tasks.ACTIVITY : Tasks.GAME);
                            return runner(q, tInfo, q.userStatus);
                        };
                        if (type === "WATCH_VIDEO") queues.video.push(taskFunc);
                        else queues.game.push(taskFunc);
                    } catch (e) {
                        Logger.log(`[Quest] Error processing ${q.id}: ${e.message}`, 'err');
                    }
                });

                const totalTasks = queues.video.length + queues.game.length;

                if (totalTasks > 0) {
                    Logger.log(`[Cycle] Processing: ${queues.video.length} videos, ${queues.game.length} games.`, 'info');
                    const pGames = runConcurrent(queues.game, 1);
                    const pVideos = runConcurrent(queues.video, 2);
                    await Promise.all([pGames, pVideos]);
                } else {
                    if (active.length === 0) { Logger.log('[System] All available quests are completed!', 'success'); break; }
                    else await sleep(rnd(4000, 6000));
                }

                if (!RUNTIME.running) break;

                if (RUNTIME.randomDelay) {
                    const delayMs = rnd(60000, 1800000);
                    Logger.log(`[Cycle] Loop #${loopCount} complete. Random delay: ${Math.round(delayMs / 60000)}m before rescan.`, 'info');
                    await sleep(delayMs);
                } else {
                    Logger.log(`[Cycle] Loop #${loopCount} complete. Waiting before rescan...`, 'info');
                    await sleep(rnd(2500, 4500));
                }
                loopCount++;

            } catch (cycleError) {
                Logger.log(`[Cycle] Error in loop #${loopCount}: ${cycleError?.message ?? cycleError}`, 'err');
                console.error(cycleError);
                await sleep(3000);
                loopCount++;
            }
        }

        const hasUnclaimed = [...Logger.tasks.values()].some(t => t.claimable && !t.removing);
        if (hasUnclaimed) {
            Logger.log('[System] Quest cycle finished. Claim your rewards above, then click STOP.', 'info');
            return;
        }

        Logger.shutdown();
    }

    main().catch(e => {
        const msg = e?.message ?? e?.toString?.() ?? "Unknown fatal error";
        console.error('[Orion Fatal]', e);
        try { Logger.log(`[System] FATAL: ${msg}`, 'err'); } catch (_) { }
        Logger.shutdown();
        setTimeout(() => { window.orionLock = false; }, 1500);
    });
})();
