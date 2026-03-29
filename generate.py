#!/usr/bin/env python3
"""Generate music samples using Foundation-1 (stable-audio fine-tune).

Loads the safetensors model, runs text-to-audio generation,
outputs WAV files ready for stego embedding.
"""

import argparse, os, json

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True, help="Path to model dir")
    parser.add_argument("--prompt", required=True, help="Generation prompt")
    parser.add_argument("--output", default="output/generated.wav")
    parser.add_argument("--duration", type=float, default=19.2, help="Duration in seconds (8 bars @ 100bpm = 19.2s)")
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    os.makedirs(os.path.dirname(args.output), exist_ok=True)

    # Load stable-audio-tools
    import torch
    import torchaudio
    import json, glob
    from stable_audio_tools.models.factory import create_model_from_config
    from stable_audio_tools.models.utils import load_ckpt_state_dict
    from stable_audio_tools.inference.generation import generate_diffusion_cond

    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Device: {device}")

    # Load model from local path
    with open(os.path.join(args.model, "model_config.json")) as f:
        model_config = json.load(f)
    model = create_model_from_config(model_config)
    ckpt = glob.glob(os.path.join(args.model, "*.safetensors"))[0]
    print(f"Loading weights: {ckpt}")
    model.load_state_dict(load_ckpt_state_dict(ckpt))
    model = model.to(device)

    sample_rate = model_config["sample_rate"]
    sample_size = int(args.duration * sample_rate)

    print(f"Generating: {args.prompt}")
    print(f"Duration: {args.duration}s, sample_rate: {sample_rate}")

    conditioning = [{
        "prompt": args.prompt,
        "seconds_start": 0,
        "seconds_total": args.duration,
    }]

    with torch.no_grad():
        output = generate_diffusion_cond(
            model,
            steps=100,
            cfg_scale=7,
            conditioning=conditioning,
            sample_size=sample_size,
            sigma_min=0.3,
            sigma_max=500,
            sampler_type="dpmpp-3m-sde",
            device=device,
            seed=args.seed,
        )

    output = output.squeeze(0).cpu()
    import scipy.io.wavfile as wavfile
    import numpy as np
    audio_np = output.numpy()
    if audio_np.ndim > 1:
        audio_np = audio_np.T
    audio_np = np.clip(audio_np, -1.0, 1.0)
    audio_int16 = (audio_np * 32767).astype(np.int16)
    wavfile.write(args.output, sample_rate, audio_int16)
    print(f"→ {args.output} ({os.path.getsize(args.output) // 1024}KB)")

if __name__ == "__main__":
    main()
