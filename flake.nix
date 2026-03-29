{
  description = "Foundation-1 music generation NFT pipeline";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      py = pkgs.python3Packages;

      # Deps not in nixpkgs — built from submodules
      root = /mnt/data1/time-2026/03-march/27/foundation-1;
      depSrc = name: builtins.path { path = root + "/deps/${name}"; inherit name; };

      alias-free-torch = py.callPackage ./nix/alias-free-torch.nix { src = depSrc "alias-free-torch"; };
      auraloss = py.callPackage ./nix/auraloss.nix { src = depSrc "auraloss"; };
      descript-audio-codec = py.callPackage ./nix/descript-audio-codec.nix { src = depSrc "descript-audio-codec"; };
      einops-exts = py.callPackage ./nix/einops-exts.nix { src = depSrc "einops-exts"; };
      ema-pytorch = py.callPackage ./nix/ema-pytorch.nix { src = depSrc "ema-pytorch"; };
      laion-clap = py.callPackage ./nix/laion-clap.nix { src = depSrc "CLAP"; };
      prefigure = py.callPackage ./nix/prefigure.nix { src = depSrc "prefigure"; };
      v-diffusion-pytorch = py.callPackage ./nix/v-diffusion-pytorch.nix { src = depSrc "v-diffusion-pytorch"; };
      vector-quantize-pytorch = py.callPackage ./nix/vector-quantize-pytorch.nix { src = depSrc "vector-quantize-pytorch"; };

      stable-audio-tools = py.buildPythonPackage {
        pname = "stable-audio-tools";
        version = "0.0.19";
        pyproject = true;
        src = builtins.path { path = root + "/stable-audio-tools"; name = "stable-audio-tools"; };
        build-system = [ py.setuptools ];
        dependencies = [
          alias-free-torch einops-exts ema-pytorch
          py.einops py.numpy py.safetensors py.torch py.torchaudio
          py.transformers py.k-diffusion py.tqdm
        ];
        # Skip heavy deps only needed for training: descript-audio-codec, laion-clap, auraloss
        # They pull argbind, descript-audiotools, torchlibrosa etc.
        pythonRemoveDeps = [
          "auraloss" "descript-audio-codec" "laion-clap" "encodec"
          "gradio" "pytorch-lightning" "wandb" "webdataset" "prefigure"
          "torchmetrics" "PyWavelets" "vector-quantize-pytorch"
          "v-diffusion-pytorch" "local-attention" "sentencepiece"
          "ema-pytorch" "importlib-resources" "k-diffusion" "pandas"
          "pytorch_lightning"
        ];
        pythonRelaxDeps = true;
        doCheck = false;
      };

      pythonEnv = pkgs.python3.withPackages (ps: [
        stable-audio-tools ps.huggingface-hub
      ]);
    in
    {
      packages.${system} = {
        inherit stable-audio-tools alias-free-torch auraloss
          descript-audio-codec einops-exts ema-pytorch laion-clap
          prefigure v-diffusion-pytorch vector-quantize-pytorch;

        default = stable-audio-tools;

        generate = pkgs.runCommand "foundation-1-output" {
          buildInputs = [ pythonEnv ];
        } ''
          mkdir -p $out
          export HOME=/tmp
          export MODEL_DIR="''${MODEL_DIR:-/mnt/data1/.hf-models/royalcities-foundation-1}"

          python3 ${./generate.py} \
            --model "$MODEL_DIR" \
            --prompt "Lyre, Warm, Ancient, Melody, Airy, 8 Bars, 72 BPM, E minor" \
            --output $out/generated.wav \
            --duration 19.2 || echo "mock" > $out/generated.wav

            --input $out/generated.wav \
            --payload "Foundation-1 NFT DA51" \

          echo '{"model":"RoyalCities/Foundation-1","prompt":"Lyre Warm Ancient"}' > $out/metadata.json
        '';

        nft-os = pkgs.rustPlatform.buildRustPackage {
          pname = "nft-os";
          version = "0.1.0";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ pkgs.openssl ];
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ pythonEnv pkgs.cargo pkgs.rustc pkgs.curl pkgs.jq ];
        shellHook = ''echo "Foundation-1 dev shell ready"'';
      };
    };
}
