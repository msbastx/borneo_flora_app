"""Ekspor model flora ke format PyTorch Lite (.ptl) untuk Flutter.

PENTING: model server memakai wrapper `FixedLogitScaleModel` yang mengalikan
logit dengan 0.3. Wrapper itu HARUS ikut di-trace, kalau tidak skala hilang
dan semua gambar (termasuk non-flora) mendapat skor near-1.0.
"""
import argparse

import torch
import torch.nn as nn
from torch.utils.mobile_optimizer import optimize_for_mobile
from torchvision import models


class FixedLogitScaleModel(nn.Module):
    """Salinan dari `apps/identifier/services.py` pada portal Django."""

    def __init__(self, model, scale):
        super().__init__()
        self.model = model
        self.scale = scale

    def forward(self, x):
        return self.model(x) * self.scale


def build_model(checkpoint_path: str, num_classes: int, scale: float) -> nn.Module:
    base = models.mobilenet_v3_large(weights=None)
    base.classifier[3] = nn.Linear(base.classifier[3].in_features, num_classes)

    # Checkpoint portal menyimpan kunci dengan prefix "backbone.".
    state = torch.load(checkpoint_path, map_location="cpu", weights_only=False)
    inner = {
        key[len("backbone."):]: value
        for key, value in state.items()
        if key.startswith("backbone.")
    }
    if not inner:
        inner = state
    base.load_state_dict(inner, strict=True)

    model = FixedLogitScaleModel(base, scale)
    model.eval()
    return model


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--checkpoint", required=True)
    parser.add_argument("--output", default="model_flora.ptl")
    parser.add_argument("--num-classes", type=int, default=75)
    parser.add_argument("--scale", type=float, default=0.3)
    parser.add_argument("--input-size", type=int, default=224)
    args = parser.parse_args()

    model = build_model(args.checkpoint, args.num_classes, args.scale)
    dummy = torch.rand(1, 3, args.input_size, args.input_size)

    traced = torch.jit.trace(model, dummy)
    try:
        traced = optimize_for_mobile(traced)
    except RuntimeError as error:
        # PyTorch tanpa XNNPACK tidak bisa menjalankan pass mobile.
        # Hasilnya tetap valid untuk Lite Interpreter.
        print(f"[warn] optimize_for_mobile dilewati: {error}")

    traced._save_for_lite_interpreter(args.output)
    print(f"[ok] {args.output} ditulis (scale={args.scale}, classes={args.num_classes})")


if __name__ == "__main__":
    main()
