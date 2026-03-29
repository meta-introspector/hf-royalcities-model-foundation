{ pkgs ? import <nixpkgs> { config.allowUnfree = true; } }:

let
  py = pkgs.python3Packages;

  fetchPypi = name: version: hash: py.buildPythonPackage {
    pname = name;
    inherit version;
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/source/${builtins.substring 0 1 name}/${name}/${name}-${version}.tar.gz";
      sha256 = hash;
    };
    doCheck = false;
  };

  fetchGH = owner: repo: rev: hash: pkgs.fetchFromGitHub {
    inherit owner repo rev hash;
  };

  alias-free-torch = py.buildPythonPackage {
    pname = "alias-free-torch";
    version = "0.0.6";
    src = fetchGH "junjun3518" "alias-free-torch" "v0.0.6" "";
    dependencies = [ py.torch ];
    doCheck = false;
  };

  auraloss = py.buildPythonPackage {
    pname = "auraloss";
    version = "0.4.0";
    src = fetchGH "csteinmetz1" "auraloss" "v0.4.0" "";
    dependencies = [ py.torch ];
    doCheck = false;
  };

  descript-audio-codec = py.buildPythonPackage {
    pname = "descript-audio-codec";
    version = "1.0.0";
    src = fetchGH "descriptinc" "descript-audio-codec" "1.0.0" "";
    dependencies = [ py.torch py.torchaudio py.einops ];
    doCheck = false;
  };

  einops-exts = py.buildPythonPackage {
    pname = "einops-exts";
    version = "0.0.4";
    src = fetchGH "lucidrains" "einops-exts" "0.0.4" "";
    dependencies = [ py.einops ];
    doCheck = false;
  };

  ema-pytorch = py.buildPythonPackage {
    pname = "ema-pytorch";
    version = "0.2.3";
    src = fetchGH "lucidrains" "ema-pytorch" "0.2.3" "";
    dependencies = [ py.torch ];
    doCheck = false;
  };

  laion-clap = py.buildPythonPackage {
    pname = "laion-clap";
    version = "1.1.4";
    src = fetchGH "LAION-AI" "CLAP" "v1.1.4" "";
    dependencies = [ py.torch py.transformers ];
    doCheck = false;
  };

  prefigure = py.buildPythonPackage {
    pname = "prefigure";
    version = "0.0.9";
    src = fetchGH "zqevans" "prefigure" "v0.0.9" "";
    doCheck = false;
  };

  v-diffusion-pytorch = py.buildPythonPackage {
    pname = "v-diffusion-pytorch";
    version = "0.0.2";
    src = fetchGH "crowsonkb" "v-diffusion-pytorch" "v0.0.2" "";
    dependencies = [ py.torch ];
    doCheck = false;
  };

  vector-quantize-pytorch = py.buildPythonPackage {
    pname = "vector-quantize-pytorch";
    version = "1.14.41";
    src = fetchGH "lucidrains" "vector-quantize-pytorch" "1.14.41" "";
    dependencies = [ py.torch py.einops ];
    doCheck = false;
  };

in
py.buildPythonPackage {
  pname = "stable-audio-tools";
  version = "0.0.19";
  src = ./stable-audio-tools;
  build-system = [ py.setuptools ];

  dependencies = [
    alias-free-torch
    auraloss
    descript-audio-codec
    py.einops
    einops-exts
    ema-pytorch
    py.encodec
    py.gradio
    py.huggingface-hub
    py.k-diffusion
    laion-clap
    py.local-attention
    py.pandas
    prefigure
    py.pytorch-lightning
    py.pywavelets
    py.safetensors
    py.sentencepiece
    py.torch
    py.torchaudio
    py.torchmetrics
    py.tqdm
    py.transformers
    v-diffusion-pytorch
    vector-quantize-pytorch
    py.wandb
    py.webdataset
  ];

  doCheck = false;
  pythonImportsCheck = [ "stable_audio_tools" ];
}
