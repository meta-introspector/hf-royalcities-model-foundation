#!/usr/bin/env node
// nft-os-cli.js — Test the full pipeline, runs in Node.js AND browser REPL.
// Push content to browser via erdfa/pastebin URLs.
// Push itself: the CLI is its own payload.

const IS_BROWSER = typeof window !== 'undefined';
const BASE = IS_BROWSER ? '' : 'https://solana.solfunmeme.com';

// ── Portable fetch ──
async function get(url) {
  if (IS_BROWSER) return fetch(url).then(r => r.ok ? r.text() : null);
  const https = require('https');
  const http = require('http');
  const mod = url.startsWith('https') ? https : http;
  return new Promise((resolve) => {
    mod.get(url, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => resolve(res.statusCode === 200 ? data : null));
    }).on('error', () => resolve(null));
  });
}

async function getBytes(url) {
  if (IS_BROWSER) return fetch(url).then(r => r.ok ? r.arrayBuffer() : null);
  const https = require('https');
  return new Promise((resolve) => {
    https.get(url, (res) => {
      const chunks = [];
      res.on('data', c => chunks.push(c));
      res.on('end', () => resolve(res.statusCode === 200 ? Buffer.concat(chunks) : null));
    }).on('error', () => resolve(null));
  });
}

// ── Print (works in both envs) ──
function log(msg) {
  if (IS_BROWSER && typeof print === 'function') print(msg, 'data');
  else console.log(msg);
}
function ok(msg) {
  if (IS_BROWSER && typeof print === 'function') print(msg, 'ok');
  else console.log('✅ ' + msg);
}
function err(msg) {
  if (IS_BROWSER && typeof print === 'function') print(msg, 'err');
  else console.log('❌ ' + msg);
}

// ── Tests ──
async function testTilesServe() {
  log('TEST: tiles serve...');
  let passed = 0;
  for (const i of [1, 37, 71]) {
    const pad = String(i).padStart(2, '0');
    const url = `${BASE}/retro-sync/tiles/${pad}.png`;
    const data = await getBytes(url);
    if (data && data.byteLength > 1000) passed++;
    else err(`  tile ${i}: failed`);
  }
  if (passed === 3) ok(`tiles: ${passed}/3 serve OK`);
  else err(`tiles: ${passed}/3`);
  return passed === 3;
}

async function testWasmServe() {
  log('TEST: WASM serves...');
  const js = await get(`${BASE}/retro-sync/pkg/stego.js`);
  const wasm = await getBytes(`${BASE}/retro-sync/pkg/stego_bg.wasm`);
  if (js && wasm) { ok(`WASM: stego.js (${js.length}B) + stego_bg.wasm (${wasm.byteLength}B)`); return true; }
  err('WASM: not serving'); return false;
}

async function testOsServe() {
  log('TEST: OS page serves...');
  const html = await get(`${BASE}/retro-sync/os.html`);
  if (html && html.includes('NFT-OS')) { ok(`os.html: ${html.length}B`); return true; }
  err('os.html: not serving'); return false;
}

async function testProofServe() {
  log('TEST: proof serves...');
  const proof = await get(`${BASE}/retro-sync/scratch/foundation1/proof.json`);
  if (proof) {
    const p = JSON.parse(proof);
    ok(`proof: ${p.spot_checks.length} spot-checks, model=${p.model}`);
    return true;
  }
  err('proof: not serving'); return false;
}

async function testSvgServe() {
  log('TEST: SVG art serves...');
  const svg = await get(`${BASE}/retro-sync/scratch/ishtar_shamash.svg`);
  if (svg && svg.includes('<svg')) { ok(`ishtar_shamash.svg: ${svg.length}B`); return true; }
  err('SVG: not serving'); return false;
}

async function testAnimServe() {
  log('TEST: animated SVG serves...');
  const svg = await get(`${BASE}/retro-sync/scratch/ishtar_shamash_anim.svg`);
  if (svg && svg.includes('animate')) { ok(`animated: ${svg.length}B`); return true; }
  err('animated SVG: not serving'); return false;
}

// ── Push to pastebin ──
async function pushToPastebin(content, filename) {
  if (IS_BROWSER) {
    log('Push: use pastebinit from CLI');
    return null;
  }
  const { execSync } = require('child_process');
  const fs = require('fs');
  const tmp = `/tmp/nft-os-push-${Date.now()}.txt`;
  fs.writeFileSync(tmp, content);
  try {
    const url = execSync(`pastebinit ${tmp}`, { encoding: 'utf8' }).trim();
    ok(`Pushed to: ${url}`);
    return url;
  } catch(e) {
    err('pastebinit failed');
    return null;
  }
}

// ── Push self ──
async function pushSelf() {
  if (IS_BROWSER) { err('Push self from CLI only'); return; }
  const fs = require('fs');
  const self = fs.readFileSync(__filename, 'utf8');
  log(`Pushing self (${self.length}B)...`);
  const url = await pushToPastebin(self, 'nft-os-cli.js');
  if (url) {
    ok(`Self pushed. Load in browser REPL:`);
    log(`  eval fetch("${url}").then(r=>r.text()).then(eval)`);
  }
}

// ── Generate browser loader ──
function browserLoader(cliUrl) {
  return `// Load NFT-OS CLI in browser REPL
fetch("${cliUrl}").then(r=>r.text()).then(code=>{
  const fn = new Function('print','window',code+'\\nreturn{testAll,pushSelf};');
  window.cli = fn(print,window);
  print("CLI loaded. Run: cli.testAll()","ok");
});`;
}

// ── Main ──
async function testAll() {
  log('═══ NFT-OS FULL PIPELINE TEST ═══\n');
  
  let passed = 0, total = 6;
  if (await testTilesServe()) passed++;
  if (await testWasmServe()) passed++;
  if (await testOsServe()) passed++;
  if (await testProofServe()) passed++;
  if (await testSvgServe()) passed++;
  if (await testAnimServe()) passed++;
  
  log('');
  if (passed === total) ok(`ALL TESTS PASSED: ${passed}/${total}`);
  else err(`${passed}/${total} passed`);
  
  log('\nEndpoints:');
  log(`  OS:       ${BASE}/retro-sync/os.html`);
  log(`  Tiles:    ${BASE}/retro-sync/tiles/`);
  log(`  Viewer:   ${BASE}/retro-sync/`);
  log(`  Proof:    ${BASE}/retro-sync/scratch/foundation1/`);
  log(`  Ishtar:   ${BASE}/retro-sync/scratch/ishtar_shamash.svg`);
  log(`  Animated: ${BASE}/retro-sync/scratch/ishtar_shamash_anim.svg`);
  log(`  Breeder:  ${BASE}/retro-sync/scratch/breeder.html`);
  
  return passed === total;
}

// ── CLI entry ──
if (!IS_BROWSER) {
  const cmd = process.argv[2] || 'test';
  (async () => {
    switch(cmd) {
      case 'test': await testAll(); break;
      case 'push-self': await pushSelf(); break;
      case 'push': {
        const file = process.argv[3];
        if (!file) { err('Usage: nft-os-cli.js push <file>'); break; }
        const fs = require('fs');
        const content = fs.readFileSync(file, 'utf8');
        await pushToPastebin(content, file);
        break;
      }
      default: log('Commands: test, push-self, push <file>');
    }
  })();
}

// Export for browser REPL
if (IS_BROWSER) { window.nftOsCli = { testAll, pushSelf }; }
