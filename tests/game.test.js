const assert = require("assert");
const game = require("../docs/game.js");

function memoryStorage(seed = {}) {
  const data = { ...seed };
  return {
    getItem(key) {
      return Object.prototype.hasOwnProperty.call(data, key) ? data[key] : null;
    },
    setItem(key, value) {
      data[key] = String(value);
    },
  };
}

function testFormulas() {
  assert.strictEqual(game.hazardSpeed(0), 300);
  assert.strictEqual(game.hazardSpeed(10), 520);
  assert.strictEqual(game.spawnInterval(0), 1.12);
  assert.ok(Math.abs(game.spawnInterval(10) - 0.84) < 1e-9);
  assert.strictEqual(game.spawnInterval(100), 0.42);
  assert.strictEqual(game.scoreFromElapsed(1.99), 19);
}

function testCollision() {
  assert.strictEqual(
    game.circleHitsDiamond(360, 1048, 30, 360, 1048, 30),
    true
  );
  assert.strictEqual(
    game.circleHitsDiamond(360, 1048, 30, 360, 900, 30),
    false
  );
  assert.strictEqual(
    game.circleHitsDiamond(180, 1048, 30, 360, 1048, 30),
    false
  );
}

function testSteeringAndHint() {
  const state = game.createState(memoryStorage());
  assert.strictEqual(state.playerLane, 1);
  game.steer(state, -1);
  assert.strictEqual(state.playerLane, 0);
  assert.strictEqual(state.hintHiding, true);
  game.steer(state, -1);
  assert.strictEqual(state.playerLane, 0);
  game.steer(state, 1);
  game.steer(state, 1);
  game.steer(state, 1);
  assert.strictEqual(state.playerLane, 2);
}

function testTapDeadZone() {
  const state = game.createState(memoryStorage());
  assert.strictEqual(game.handleTap(state, 10, 10, 720, 1280), false);
  assert.strictEqual(state.playerLane, 1);
  assert.strictEqual(game.handleTap(state, 100, 400, 720, 1280), true);
  assert.strictEqual(state.playerLane, 0);
  assert.strictEqual(game.handleTap(state, 500, 400, 720, 1280), true);
  assert.strictEqual(state.playerLane, 1);
}

function testSpawnKeepsOpenLane() {
  const randoms = [0.9, 0.1, 0.1];
  let i = 0;
  const random = () => randoms[i++] ?? 0.5;
  const picked = game.pickBlockedLanes(1, 1, random);
  assert.ok(!picked.blocked.includes(picked.openLane));
  assert.strictEqual(picked.blocked.length, 1);
  assert.ok(Math.abs(picked.openLane - 1) <= 1);
}

function testBestScore() {
  const storage = memoryStorage();
  assert.strictEqual(game.loadBest(storage), 0);
  const next = game.recordScore(storage, 0, 42);
  assert.strictEqual(next, 42);
  assert.strictEqual(game.loadBest(storage), 42);
  assert.strictEqual(game.recordScore(storage, 42, 10), 42);
}

function testDeathAndRamp() {
  const storage = memoryStorage();
  const state = game.createState(storage);
  const random = () => 0.99;
  game.updateWorld(state, 2.0, random, storage);
  assert.ok(state.hazards.length >= 1);
  assert.ok(state.score >= 19);
  state.hazards[0].x = state.playerX;
  state.hazards[0].y = game.PLAYER_Y;
  const result = game.updateWorld(state, 0.016, random, storage);
  assert.strictEqual(result.died, true);
  assert.strictEqual(state.playing, false);
  assert.strictEqual(game.loadBest(storage), state.score);
}

function testPauseBlocksSteer() {
  const state = game.createState(memoryStorage());
  state.paused = true;
  assert.strictEqual(game.canSteer(state), false);
  assert.strictEqual(game.steer(state, 1), false);
}

testFormulas();
testCollision();
testSteeringAndHint();
testTapDeadZone();
testSpawnKeepsOpenLane();
testBestScore();
testDeathAndRamp();
testPauseBlocksSteer();
console.log("ok");
