---
library_name: transformers
license: mit
pipeline_tag: text-to-audio
tags:
- feature-extraction
- audio
- music
- text2music
- custom_code
---

<h1 align="center">ACE-Step 1.5 XL — Turbo (4B DiT)</h1>
<p align="center">
    <a href="https://ace-step.github.io/ace-step-v1.5.github.io/">Project</a> |
    <a href="https://huggingface.co/collections/ACE-Step/ace-step-15">Hugging Face</a> |
    <a href="https://modelscope.cn/collections/ACE-Step/Ace-Step-15-xl">ModelScope</a> |
    <a href="https://huggingface.co/spaces/ACE-Step/Ace-Step-v1.5">Space Demo</a> |
    <a href="https://discord.gg/PeWDxrkdj7">Discord</a> |
    <a href="https://arxiv.org/abs/2602.00744">Tech Report</a>
</p>

## Model Details

This is the **XL (4B) Turbo** variant of ACE-Step 1.5 — a distillation-accelerated model that generates high-quality audio in just 8 steps. Combines the speed of turbo with the quality of the 4B architecture.

### XL Architecture

| Parameter | Value |
|-----------|-------|
| DiT Decoder hidden_size | 2560 |
| DiT Decoder layers | 32 |
| DiT Decoder attention heads | 32 |
| Encoder hidden_size | 2048 |
| Encoder layers | 8 |
| Total params | ~4B |
| Weights size (bf16) | ~18.8 GB |
| Inference steps | 8 (no CFG, distilled) |

### GPU Requirements

| VRAM | Support |
|------|---------|
| ≥12 GB | With CPU offload + INT8 quantization |
| ≥16 GB | With CPU offload |
| ≥20 GB | Without offload (recommended) |
| ≥24 GB | Full quality (XL + 4B LM) |

All LM models (0.6B / 1.7B / 4B) are fully compatible with XL.

### Key Features

- **💰 Commercial-Ready:** Trained on legally compliant datasets. Generated music can be used for commercial purposes.
- **📚 Safe Training Data:** Licensed music, royalty-free/public domain, and synthetic (MIDI-to-Audio) data.
- **⚡ Fast:** 8-step inference — the fastest XL variant.
- **🔮 Higher Quality:** 4B parameters provide richer audio quality than 2B turbo.

## Quick Start

```bash
# Install ACE-Step
git clone https://github.com/ace-step/ACE-Step-1.5.git
cd ACE-Step-1.5
pip install -e .

# Download this model
huggingface-cli download ACE-Step/acestep-v15-xl-turbo --local-dir ./checkpoints/acestep-v15-xl-turbo

# Run with Gradio UI
python acestep --config-path acestep-v15-xl-turbo
```

## Model Zoo

### XL (4B) DiT Models

| DiT Model | CFG | Steps | Quality | Diversity | Tasks | Hugging Face | ModelScope |
|-----------|:---:|:-----:|:-------:|:---------:|-------|--------------| ---------- |
| `acestep-v15-xl-base` | ✅ | 50 | High | High | All (extract, lego, complete) | [Link](https://huggingface.co/ACE-Step/acestep-v15-xl-base) |[Link](https://modelscope.cn/models/ACE-Step/acestep-v15-xl-base) |
| `acestep-v15-xl-sft` | ✅ | 50 | Very High | Medium | Standard | [Link](https://huggingface.co/ACE-Step/acestep-v15-xl-sft) | [Link](https://modelscope.cn/models/ACE-Step/acestep-v15-xl-sft) |
| **`acestep-v15-xl-turbo`** | ❌ | 8 | Very High | Medium | Standard | This repo | [Link](https://modelscope.cn/models/ACE-Step/acestep-v15-xl-turbo) |

### LM Models (all compatible with XL)

| LM Model | Params | Audio Understanding | Composition | Hugging Face | ModelScope |
|----------|:------:|:-------------------:|:-----------:|--------------| ---------- |
| `acestep-5Hz-lm-0.6B` | 0.6B | Medium | Medium | [Link](https://huggingface.co/ACE-Step/acestep-5Hz-lm-0.6B) | [Link](https://modelscope.cn/models/ACE-Step/acestep-5Hz-lm-0.6B) |
| `acestep-5Hz-lm-1.7B` | 1.7B | Medium | Medium | Included in main |  Included in main |
| `acestep-5Hz-lm-4B` | 4B | Strong | Strong | [Link](https://huggingface.co/ACE-Step/acestep-5Hz-lm-4B) | [Link](https://modelscope.cn/models/ACE-Step/acestep-5Hz-lm-4B) |

## Acknowledgements

This project is co-led by ACE Studio and StepFun.

## Citation

```BibTeX
@misc{gong2026acestep,
    title={ACE-Step 1.5: Pushing the Boundaries of Open-Source Music Generation},
    author={Junmin Gong, Yulin Song, Wenxiao Zhao, Sen Wang, Shengyuan Xu, Jing Guo},
    howpublished={\url{https://github.com/ace-step/ACE-Step-1.5}},
    year={2026},
    note={GitHub repository}
}
```
