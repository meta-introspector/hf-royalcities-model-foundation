.PHONY: dev download generate stego nft pipeline

MODEL_DIR  ?= models/foundation-1
MODEL_REPO ?= RoyalCities/Foundation-1
VENV       ?= /mnt/data1/time-2026/03-march/05/ubuntu-pytorch-test/venv
NIX        := nix --extra-experimental-features 'nix-command flakes'
RUN        := $(NIX) develop --command

dev:
	$(NIX) develop

download:
	@mkdir -p $(MODEL_DIR)
	source ~/.agentrc && huggingface-cli download $(MODEL_REPO) --local-dir $(MODEL_DIR)
	@ls -lh $(MODEL_DIR)/*.safetensors $(MODEL_DIR)/*.json 2>/dev/null

generate:
	$(RUN) python generate.py \
		--model $(MODEL_DIR) \
		--prompt "Lyre, Warm, Ancient, Melody, Airy, 8 Bars, 72 BPM, E minor" \
		--output output/generated.wav

stego: generate
	$(RUN) python stego_audio.py \
		--input output/generated.wav \
		--payload "Hurrian Hymn h.6 Foundation-1 NFT" \
		--output output/stego.wav

nft: stego
	$(RUN) python nft_series.py \
		--audio output/stego.wav \
		--project project.toml \
		--output output/tiles/

pipeline: download generate stego nft
	@echo "=== Foundation-1 NFT pipeline complete ==="
