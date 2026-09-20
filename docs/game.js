/**
 * Faithful HTML5 port of Lane Dodge (Godot 4 day-1 loop).
 * Mirrors scripts/main.gd, player.gd, hazard.gd, and game_state.gd.
 */
(function (root, factory) {
  const api = factory();
  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
  root.LaneDodge = api;
})(typeof globalThis !== "undefined" ? globalThis : this, function () {
  const WIDTH = 720;
  const HEIGHT = 1280;
  const PLAYER_Y = 1048;
  const SPAWN_Y = -56;
  const LANE_CENTERS = [180, 360, 540];
  const HINT_AUTO_HIDE_SEC = 2.5;
  const HINT_FADE_SEC = 0.4;
  const PLAYER_RADIUS = 30;
  const HAZARD_HALF = 30;
  const HAZARD_DESPAWN_Y = 1400;
  const SLIDE_SPEED = 16;
  const BEST_KEY = "lane_dodge_best_score";
  const PLAYER_POLY = [
    [-30, -20],
    [-20, -30],
    [20, -30],
    [30, -20],
    [30, 20],
    [20, 30],
    [-20, 30],
    [-30, 20],
  ];
  const PLAYER_SHINE = [
    [-16, -18],
    [-8, -24],
    [10, -24],
    [16, -16],
    [6, -8],
    [-12, -8],
  ];
  const HAZARD_SHADOW = [
    [0, -40],
    [40, 0],
    [0, 40],
    [-40, 0],
  ];
  const HAZARD_BODY = [
    [0, -34],
    [34, 0],
    [0, 34],
    [-34, 0],
  ];

  function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }

  function lerp(a, b, t) {
    return a + (b - a) * t;
  }

  function hazardSpeed(elapsed) {
    return 300 + elapsed * 22;
  }

  function spawnInterval(elapsed) {
    return Math.max(0.42, 1.12 - elapsed * 0.028);
  }

  function scoreFromElapsed(elapsed) {
    return Math.floor(elapsed * 10);
  }

  function circleHitsDiamond(cx, cy, radius, hx, hy, half) {
    const px = cx - hx;
    const py = cy - hy;
    const manhattan = Math.abs(px) + Math.abs(py);
    if (manhattan <= half) {
      return true;
    }
    const scale = half / manhattan;
    const qx = px * scale;
    const qy = py * scale;
    const dx = px - qx;
    const dy = py - qy;
    return dx * dx + dy * dy <= radius * radius;
  }

  function shuffle(list, random) {
    const copy = list.slice();
    for (let i = copy.length - 1; i > 0; i -= 1) {
      const j = Math.floor(random() * (i + 1));
      const tmp = copy[i];
      copy[i] = copy[j];
      copy[j] = tmp;
    }
    return copy;
  }

  function pickBlockedLanes(elapsed, guaranteedOpenLane, random) {
    let count = 1;
    if (elapsed > 7 && random() < Math.min(0.72, 0.28 + elapsed * 0.02)) {
      count = 2;
    }

    let openLane = guaranteedOpenLane;
    if (random() < 0.6) {
      const step = random() < 0.5 ? -1 : 1;
      openLane = clamp(openLane + step, 0, 2);
    }

    const blocked = [];
    for (let lane = 0; lane < 3; lane += 1) {
      if (lane !== openLane) {
        blocked.push(lane);
      }
    }

    if (count === 1) {
      return { blocked: [shuffle(blocked, random)[0]], openLane };
    }
    return { blocked, openLane };
  }

  function loadBest(storage) {
    const raw = storage.getItem(BEST_KEY);
    const value = parseInt(raw, 10);
    return Number.isFinite(value) ? value : 0;
  }

  function recordScore(storage, best, score) {
    if (score > best) {
      storage.setItem(BEST_KEY, String(score));
      return score;
    }
    return best;
  }

  function createState(storage) {
    return {
      score: 0,
      elapsed: 0,
      spawnTimer: -0.8,
      playing: true,
      paused: false,
      settingsOpen: false,
      guaranteedOpenLane: 1,
      hintHiding: false,
      hintVisible: true,
      hintAlpha: 1,
      playerLane: 1,
      playerX: LANE_CENTERS[1],
      playerTargetX: LANE_CENTERS[1],
      playerAlive: true,
      hazards: [],
      bestScore: loadBest(storage),
    };
  }

  function canSteer(state) {
    return state.playing && !state.paused && !state.settingsOpen;
  }

  function steer(state, direction) {
    if (!canSteer(state) || !state.playerAlive) {
      return false;
    }
    const previous = state.playerLane;
    if (direction < 0) {
      state.playerLane = Math.max(state.playerLane - 1, 0);
    } else {
      state.playerLane = Math.min(state.playerLane + 1, 2);
    }
    state.playerTargetX = LANE_CENTERS[state.playerLane];
    if (state.playerLane !== previous) {
      dismissHint(state);
      return true;
    }
    return false;
  }

  function dismissHint(state) {
    if (state.hintHiding || !state.hintVisible) {
      return;
    }
    state.hintHiding = true;
  }

  function handleTap(state, x, y, viewW, viewH) {
    if (!canSteer(state)) {
      return false;
    }
    if (y < viewH * 0.12) {
      return false;
    }
    return steer(state, x < viewW * 0.5 ? -1 : 1);
  }

  function spawnWave(state, random) {
    const picked = pickBlockedLanes(state.elapsed, state.guaranteedOpenLane, random);
    state.guaranteedOpenLane = picked.openLane;
    const speed = hazardSpeed(state.elapsed);
    for (const lane of picked.blocked) {
      state.hazards.push({
        x: LANE_CENTERS[lane],
        y: SPAWN_Y,
        speed,
      });
    }
  }

  function killPlayer(state, storage) {
    if (!state.playing) {
      return;
    }
    state.playing = false;
    state.playerAlive = false;
    state.hintVisible = false;
    state.hintAlpha = 0;
    state.bestScore = recordScore(storage, state.bestScore, state.score);
  }

  function updateWorld(state, dt, random, storage) {
    if (!state.playing || state.paused) {
      return { died: false };
    }

    state.elapsed += dt;
    state.score = scoreFromElapsed(state.elapsed);

    if (!state.hintHiding && state.elapsed >= HINT_AUTO_HIDE_SEC) {
      dismissHint(state);
    }
    if (state.hintHiding && state.hintVisible) {
      state.hintAlpha = Math.max(0, state.hintAlpha - dt / HINT_FADE_SEC);
      if (state.hintAlpha <= 0) {
        state.hintVisible = false;
        state.hintAlpha = 0;
      }
    }

    const interval = spawnInterval(state.elapsed);
    state.spawnTimer += dt;
    if (state.spawnTimer >= interval) {
      state.spawnTimer = 0;
      spawnWave(state, random);
    }

    state.playerX = lerp(
      state.playerX,
      state.playerTargetX,
      Math.min(1, SLIDE_SPEED * dt)
    );

    for (const hazard of state.hazards) {
      hazard.y += hazard.speed * dt;
    }
    state.hazards = state.hazards.filter((hazard) => hazard.y <= HAZARD_DESPAWN_Y);

    for (const hazard of state.hazards) {
      if (
        circleHitsDiamond(
          state.playerX,
          PLAYER_Y,
          PLAYER_RADIUS,
          hazard.x,
          hazard.y,
          HAZARD_HALF
        )
      ) {
        killPlayer(state, storage);
        return { died: true };
      }
    }

    return { died: false };
  }

  function drawPolygon(ctx, x, y, points, fill) {
    ctx.beginPath();
    ctx.moveTo(x + points[0][0], y + points[0][1]);
    for (let i = 1; i < points.length; i += 1) {
      ctx.lineTo(x + points[i][0], y + points[i][1]);
    }
    ctx.closePath();
    ctx.fillStyle = fill;
    ctx.fill();
  }

  function drawWorld(ctx, state) {
    ctx.fillStyle = "#0b1220";
    ctx.fillRect(0, 0, WIDTH, HEIGHT);

    ctx.fillStyle = "#172238";
    ctx.fillRect(90, 0, 180, HEIGHT);
    ctx.fillStyle = "#1c2b45";
    ctx.fillRect(270, 0, 180, HEIGHT);
    ctx.fillStyle = "#172238";
    ctx.fillRect(450, 0, 180, HEIGHT);

    ctx.fillStyle = "rgba(51, 82, 115, 0.55)";
    ctx.fillRect(268, 0, 4, HEIGHT);
    ctx.fillRect(448, 0, 4, HEIGHT);
    ctx.fillStyle = "rgba(41, 66, 97, 0.7)";
    ctx.fillRect(88, 0, 4, HEIGHT);
    ctx.fillRect(628, 0, 4, HEIGHT);

    for (const hazard of state.hazards) {
      drawPolygon(ctx, hazard.x, hazard.y, HAZARD_SHADOW, "#8c1424");
      drawPolygon(ctx, hazard.x, hazard.y, HAZARD_BODY, "#ed384d");
    }

    drawPolygon(ctx, state.playerX, PLAYER_Y, PLAYER_POLY, "#3df0f2");
    drawPolygon(ctx, state.playerX, PLAYER_Y, PLAYER_SHINE, "rgba(178, 255, 255, 0.28)");
  }

  function bind(dom) {
    const storage = dom.storage || localStorage;
    const random = dom.random || Math.random;
    const canvas = dom.canvas;
    const ctx = canvas.getContext("2d");
    canvas.width = WIDTH;
    canvas.height = HEIGHT;

    let state = createState(storage);
    let raf = 0;
    let lastTs = 0;

    const els = {
      score: dom.score,
      best: dom.best,
      hint: dom.hint,
      pauseOverlay: dom.pauseOverlay,
      gameOverOverlay: dom.gameOverOverlay,
      settingsOverlay: dom.settingsOverlay,
      finalScore: dom.finalScore,
      finalBest: dom.finalBest,
    };

    function syncHud() {
      els.score.textContent = "Score  " + state.score;
      els.best.textContent = "Best  " + state.bestScore;
      els.hint.style.opacity = String(state.hintAlpha);
      els.hint.classList.toggle("hidden", !state.hintVisible);
      els.pauseOverlay.classList.toggle("visible", state.paused && !state.settingsOpen);
      els.settingsOverlay.classList.toggle("visible", state.settingsOpen);
      els.gameOverOverlay.classList.toggle("visible", !state.playing);
      if (!state.playing) {
        els.finalScore.textContent = "Score  " + state.score;
        els.finalBest.textContent = "Best  " + state.bestScore;
      }
    }

    function restart() {
      state = createState(storage);
      syncHud();
    }

    function togglePause() {
      if (!state.playing || state.settingsOpen) {
        return;
      }
      if (state.paused) {
        resume();
      } else {
        state.paused = true;
        syncHud();
      }
    }

    function resume() {
      if (!state.playing) {
        return;
      }
      state.paused = false;
      state.settingsOpen = false;
      syncHud();
    }

    function openSettings() {
      if (!state.playing) {
        return;
      }
      state.settingsOpen = true;
      state.paused = true;
      syncHud();
    }

    function closeSettings() {
      state.settingsOpen = false;
      syncHud();
    }

    function onPointer(event) {
      if (!canSteer(state)) {
        return;
      }
      const rect = canvas.getBoundingClientRect();
      const x = ((event.clientX - rect.left) / rect.width) * WIDTH;
      const y = ((event.clientY - rect.top) / rect.height) * HEIGHT;
      handleTap(state, x, y, WIDTH, HEIGHT);
    }

    function onKey(event) {
      if (event.repeat) {
        return;
      }
      if (event.code === "Escape" || event.code === "KeyP") {
        event.preventDefault();
        if (state.settingsOpen) {
          closeSettings();
        } else {
          togglePause();
        }
        return;
      }
      if (!canSteer(state)) {
        return;
      }
      if (event.code === "ArrowLeft" || event.code === "KeyA") {
        event.preventDefault();
        steer(state, -1);
      } else if (event.code === "ArrowRight" || event.code === "KeyD") {
        event.preventDefault();
        steer(state, 1);
      }
    }

    function frame(ts) {
      if (!lastTs) {
        lastTs = ts;
      }
      const dt = Math.min(0.05, (ts - lastTs) / 1000);
      lastTs = ts;
      updateWorld(state, dt, random, storage);
      drawWorld(ctx, state);
      syncHud();
      raf = requestAnimationFrame(frame);
    }

    canvas.addEventListener("pointerdown", onPointer);
    window.addEventListener("keydown", onKey);
    syncHud();
    raf = requestAnimationFrame(frame);

    return {
      restart,
      togglePause,
      resume,
      openSettings,
      closeSettings,
      getState() {
        return state;
      },
      destroy() {
        cancelAnimationFrame(raf);
        canvas.removeEventListener("pointerdown", onPointer);
        window.removeEventListener("keydown", onKey);
      },
    };
  }

  function boot(documentRef) {
    const doc = documentRef || document;
    const game = bind({
      canvas: doc.getElementById("game"),
      score: doc.getElementById("score"),
      best: doc.getElementById("best"),
      hint: doc.getElementById("hint"),
      pauseOverlay: doc.getElementById("pause-overlay"),
      gameOverOverlay: doc.getElementById("game-over-overlay"),
      settingsOverlay: doc.getElementById("settings-overlay"),
      finalScore: doc.getElementById("final-score"),
      finalBest: doc.getElementById("final-best"),
    });
    doc.getElementById("pause-btn").addEventListener("click", (event) => {
      event.stopPropagation();
      game.togglePause();
    });
    doc.getElementById("resume-btn").addEventListener("click", () => game.resume());
    doc.getElementById("settings-btn").addEventListener("click", () => game.openSettings());
    doc.getElementById("settings-back-btn").addEventListener("click", () => game.closeSettings());
    doc.getElementById("restart-btn").addEventListener("click", () => game.restart());
    return game;
  }

  return {
    WIDTH,
    HEIGHT,
    PLAYER_Y,
    SPAWN_Y,
    LANE_CENTERS,
    PLAYER_RADIUS,
    HAZARD_HALF,
    BEST_KEY,
    hazardSpeed,
    spawnInterval,
    scoreFromElapsed,
    circleHitsDiamond,
    pickBlockedLanes,
    loadBest,
    recordScore,
    createState,
    canSteer,
    steer,
    handleTap,
    updateWorld,
    bind,
    boot,
  };
});
