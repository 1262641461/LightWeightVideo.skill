# -*- coding: utf-8 -*-
"""H3 首帧生视频（MiniMaxH3ImageToVideo）。

用法：python h3_i2v.py "提示词" 输出前缀 首帧图 [宽] [高] [帧数] [步数]
"""
import json
import sys
import time
import uuid

import requests

HOST = "http://127.0.0.1:8188"
prompt = sys.argv[1]
prefix = sys.argv[2]
img = sys.argv[3]
W = int(sys.argv[4]) if len(sys.argv) > 4 else 640
H = int(sys.argv[5]) if len(sys.argv) > 5 else 352
LEN = int(sys.argv[6]) if len(sys.argv) > 6 else 124
STEPS = int(sys.argv[7]) if len(sys.argv) > 7 else 6

wf = {
    "1": {"class_type": "UNETLoader",
          "inputs": {"unet_name": "minimax_h3_ref2va_pruned_fp8_scaled.safetensors", "weight_dtype": "default"}},
    "2": {"class_type": "MiniMaxH3SigmaShift",
          "inputs": {"model": ["1", 0], "shift_video": 12.0, "shift_audio": 3.0}},
    "3": {"class_type": "CLIPLoader",
          "inputs": {"clip_name": "qwen3vl_32b_minimax_h3_nvfp4.safetensors", "type": "minimax"}},
    "4": {"class_type": "VAELoader", "inputs": {"vae_name": "minimax_h3_video_vae.safetensors"}},
    "5": {"class_type": "VAELoader", "inputs": {"vae_name": "minimax_h3_audio_vae.safetensors"}},
    "6": {"class_type": "LoadImage", "inputs": {"image": img}},
    "7": {"class_type": "MiniMaxH3ImageToVideo", "inputs": {
        "clip": ["3", 0], "vae": ["4", 0], "prompt": prompt,
        "width": W, "height": H, "length": LEN,
        "first_frame": ["6", 0]}},
    "8": {"class_type": "RandomNoise", "inputs": {"noise_seed": 7}},
    "9": {"class_type": "BasicGuider", "inputs": {"model": ["2", 0], "conditioning": ["7", 0]}},
    "10": {"class_type": "KSamplerSelect", "inputs": {"sampler_name": "euler"}},
    "11": {"class_type": "BasicScheduler",
           "inputs": {"model": ["2", 0], "scheduler": "simple", "steps": STEPS, "denoise": 1.0}},
    "12": {"class_type": "SamplerCustomAdvanced", "inputs": {
        "noise": ["8", 0], "guider": ["9", 0], "sampler": ["10", 0],
        "sigmas": ["11", 0], "latent_image": ["7", 1]}},
    "13": {"class_type": "VAEDecode", "inputs": {"samples": ["12", 0], "vae": ["4", 0]}},
    "14": {"class_type": "VAEDecodeAudio", "inputs": {"samples": ["12", 0], "vae": ["5", 0]}},
    "15": {"class_type": "CreateVideo", "inputs": {"images": ["13", 0], "fps": 24.0, "audio": ["14", 0]}},
    "16": {"class_type": "SaveVideo", "inputs": {
        "video": ["15", 0], "filename_prefix": prefix, "format": "mp4", "codec": "h264"}},
}

r = requests.post(f"{HOST}/prompt", json={"prompt": wf, "client_id": str(uuid.uuid4())}, timeout=60)
print("submit", r.status_code, r.text[:600], flush=True)
if r.status_code != 200:
    sys.exit(1)
pid = r.json()["prompt_id"]
t0 = time.time()
while time.time() - t0 < 7200:
    h = requests.get(f"{HOST}/history/{pid}", timeout=10).json()
    if pid in h:
        print("DONE %.0fs" % (time.time() - t0))
        print(json.dumps(h[pid].get("outputs", {}), ensure_ascii=False)[:400])
        print("status", h[pid].get("status", {}).get("status_str"))
        break
    time.sleep(10)
else:
    print("TIMEOUT")
