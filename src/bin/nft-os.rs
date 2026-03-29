//! nft-os CLI — Rust native. Tests pipeline, pushes to kant-pastebin, encodes via erdfa.
//!
//! Commands:
//!   test       — verify all endpoints serve
//!   push <file> — upload to kant-pastebin, get erdfa URL
//!   push-self  — push this binary to pastebin
//!   encode <file> — wrap in DA51 CBOR, push
//!   boot       — generate browser bootstrap loader

use std::process::Command;

const BASE: &str = "https://solana.solfunmeme.com";
const PASTE_URL: &str = "https://solana.solfunmeme.com/pastebin/upload";

fn check_url(url: &str) -> (bool, usize) {
    let output = Command::new("curl")
        .args(["-s", "-o", "/dev/null", "-w", "%{http_code} %{size_download}", url])
        .output();
    match output {
        Ok(o) => {
            let s = String::from_utf8_lossy(&o.stdout);
            let parts: Vec<&str> = s.trim().split(' ').collect();
            let code = parts.first().and_then(|c| c.parse::<u16>().ok()).unwrap_or(0);
            let size = parts.get(1).and_then(|s| s.parse::<usize>().ok()).unwrap_or(0);
            (code == 200, size)
        }
        Err(_) => (false, 0),
    }
}

fn push_file(path: &str) -> Option<String> {
    // Use pastebinit (already configured for kant-pastebin)
    let output = Command::new("pastebinit")
        .arg(path)
        .output()
        .ok()?;
    let url = String::from_utf8_lossy(&output.stdout).trim().to_string();
    if url.starts_with("http") { Some(url) } else { None }
}

fn push_bytes(data: &[u8], filename: &str) -> Option<String> {
    // Write to tmp, push via curl multipart
    let tmp = format!("/tmp/nft-os-{}-{}", std::process::id(), filename);
    std::fs::write(&tmp, data).ok()?;
    let url = push_file(&tmp);
    let _ = std::fs::remove_file(&tmp);
    url
}

fn da51_wrap(data: &[u8]) -> Vec<u8> {
    // Minimal DA51 CBOR: tag(55889, bstr(data))
    let mut cbor = vec![0xD9, 0xDA, 0x51]; // tag 55889
    if data.len() < 24 {
        cbor.push(0x40 | data.len() as u8);
    } else if data.len() < 256 {
        cbor.push(0x58);
        cbor.push(data.len() as u8);
    } else {
        cbor.push(0x59);
        cbor.extend_from_slice(&(data.len() as u16).to_be_bytes());
    }
    cbor.extend_from_slice(data);
    cbor
}

fn cmd_test() {
    println!("═══ NFT-OS PIPELINE TEST ═══\n");
    let tests = [
        ("tiles/01.png", "/retro-sync/tiles/01.png"),
        ("tiles/71.png", "/retro-sync/tiles/71.png"),
        ("stego.js", "/retro-sync/pkg/stego.js"),
        ("stego.wasm", "/retro-sync/pkg/stego_bg.wasm"),
        ("os.html", "/retro-sync/os.html"),
        ("viewer", "/retro-sync/index.html"),
        ("proof", "/retro-sync/scratch/foundation1/proof.json"),
        ("ishtar", "/retro-sync/scratch/ishtar_shamash.svg"),
        ("animated", "/retro-sync/scratch/ishtar_shamash_anim.svg"),
        ("breeder", "/retro-sync/scratch/breeder.html"),
    ];

    let mut passed = 0;
    for (name, path) in &tests {
        let url = format!("{}{}", BASE, path);
        let (ok, size) = check_url(&url);
        if ok {
            println!("  ✅ {:<12} {:>8}B  {}", name, size, path);
            passed += 1;
        } else {
            println!("  ❌ {:<12}           {}", name, path);
        }
    }

    println!("\n  {}/{} passed", passed, tests.len());
    if passed == tests.len() {
        println!("\n  ✅ ALL ENDPOINTS SERVING");
    }

    println!("\n  OS:       {}/retro-sync/os.html", BASE);
    println!("  Viewer:   {}/retro-sync/", BASE);
    println!("  Breeder:  {}/retro-sync/scratch/breeder.html", BASE);
}

fn cmd_push(path: &str) {
    println!("Pushing {}...", path);
    match push_file(path) {
        Some(url) => println!("✅ {}", url),
        None => println!("❌ push failed"),
    }
}

fn cmd_encode_push(path: &str) {
    println!("Encoding {} as DA51 CBOR...", path);
    let data = match std::fs::read(path) {
        Ok(d) => d,
        Err(e) => { println!("❌ read: {}", e); return; }
    };
    let cbor = da51_wrap(&data);
    println!("  DA51: {} bytes (payload {})", cbor.len(), data.len());

    let filename = std::path::Path::new(path)
        .file_name().unwrap_or_default()
        .to_string_lossy();
    match push_bytes(&cbor, &format!("{}.cbor", filename)) {
        Some(url) => {
            println!("✅ {}", url);
            println!("\n  Load in browser REPL:");
            println!("  eval fetch(\"{}\").then(r=>r.arrayBuffer()).then(b=>console.log(\"DA51:\",b.byteLength,\"bytes\"))", url);
        }
        None => println!("❌ push failed"),
    }
}

fn cmd_push_self() {
    let self_path = std::env::current_exe().unwrap_or_default();
    println!("Pushing self: {:?} ({} bytes)", self_path, 
        std::fs::metadata(&self_path).map(|m| m.len()).unwrap_or(0));
    
    // Push the source, not the binary (browser can't run ELF)
    let src = file!();
    let src_path = format!("src/bin/{}", src);
    if std::path::Path::new(&src_path).exists() {
        cmd_push(&src_path);
    } else {
        // Push a JS bootstrap that loads the test suite
        let loader = format!(r#"// NFT-OS CLI bootstrap — load in browser REPL
// eval fetch("THIS_URL").then(r=>r.text()).then(eval)
async function testAll() {{
  const base = "{}";
  const tests = ["tiles/01.png","pkg/stego.js","os.html","scratch/foundation1/proof.json"];
  let ok = 0;
  for (const t of tests) {{
    const r = await fetch(base+"/retro-sync/"+t);
    if (r.ok) {{ ok++; print("✅ "+t,"ok"); }} else {{ print("❌ "+t,"err"); }}
  }}
  print(ok+"/"+tests.length+" passed", ok===tests.length?"ok":"err");
}}
testAll();
"#, BASE);
        match push_bytes(loader.as_bytes(), "nft-os-bootstrap.js") {
            Some(url) => {
                println!("✅ {}", url);
                println!("\n  Load in NFT-OS browser REPL:");
                println!("  eval fetch(\"{}\").then(r=>r.text()).then(eval)", url);
            }
            None => println!("❌ push failed"),
        }
    }
}

fn cmd_boot() {
    println!("NFT-OS Boot URLs:\n");
    println!("  Full OS:    {}/retro-sync/os.html", BASE);
    println!("  Viewer:     {}/retro-sync/", BASE);
    println!("  Breeder:    {}/retro-sync/scratch/breeder.html", BASE);
    println!("  Proof:      {}/retro-sync/scratch/foundation1/", BASE);
    println!("\n  Browser REPL quick-start:");
    println!("    1. Open {}/retro-sync/os.html", BASE);
    println!("    2. Type: load-local");
    println!("    3. Type: decode");
    println!("    4. Type: play wav");
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let cmd = args.get(1).map(|s| s.as_str()).unwrap_or("test");

    match cmd {
        "test" => cmd_test(),
        "push" => {
            let path = args.get(2).map(|s| s.as_str()).unwrap_or("");
            if path.is_empty() { println!("Usage: nft-os push <file>"); }
            else { cmd_push(path); }
        }
        "encode" => {
            let path = args.get(2).map(|s| s.as_str()).unwrap_or("");
            if path.is_empty() { println!("Usage: nft-os encode <file>"); }
            else { cmd_encode_push(path); }
        }
        "push-self" => cmd_push_self(),
        "boot" => cmd_boot(),
        _ => {
            println!("nft-os — NFT-OS pipeline CLI\n");
            println!("Commands:");
            println!("  test         — verify all endpoints");
            println!("  push <file>  — upload to kant-pastebin");
            println!("  encode <file>— DA51 CBOR wrap + push");
            println!("  push-self    — push JS bootstrap to pastebin");
            println!("  boot         — show boot URLs");
        }
    }
}
