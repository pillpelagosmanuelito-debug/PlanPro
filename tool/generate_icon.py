#!/usr/bin/env python3
"""Genera el icono de Project Management Simulator por codigo.

El icono se genera en lugar de incluirse como binario para que quede
versionado como fuente: cualquiera puede leer por que se ve asi y cambiarlo
sin abrir un editor grafico.

Motivo del diseno: un diagrama de Gantt de tres barras escalonadas sobre azul
marino, con la barra critica en ambar y un hito en rombo. Es el simbolo que
un estudiante de gestion de proyectos reconoce de inmediato, y dice
"cronograma con una ruta critica", que es exactamente de lo que trata la app.

Uso:
    python3 tool/generate_icon.py
    python3 tool/generate_icon.py --out android_icons

Requiere Pillow:
    pip install Pillow
"""

from __future__ import annotations

import argparse
import os

try:
    from PIL import Image, ImageDraw
except ImportError:  # pragma: no cover
    raise SystemExit(
        "Falta Pillow. Instalalo con: pip install Pillow"
    )

NAVY_DARK = (16, 42, 69)
NAVY = (20, 56, 92)
AMBER = (217, 128, 50)
CREAM = (240, 244, 248)
SLATE = (120, 148, 176)

# Densidades de Android para mipmap.
DENSITIES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

MASTER = 1024
# El contenido se dibuja en una capa aparte y se reduce antes de componerlo,
# de modo que siempre quede un margen de seguridad y nada toque el borde.
CONTENT_SCALE = 0.82


def rounded(draw: "ImageDraw.ImageDraw", box, radius, fill) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def build_master() -> "Image.Image":
    base = Image.new("RGBA", (MASTER, MASTER), NAVY)
    bg = ImageDraw.Draw(base)

    # Fondo con un degradado sobrio hecho por bandas: da profundidad sin
    # depender de filtros.
    for i in range(MASTER):
        t = i / MASTER
        color = (
            int(NAVY_DARK[0] + (NAVY[0] - NAVY_DARK[0]) * t),
            int(NAVY_DARK[1] + (NAVY[1] - NAVY_DARK[1]) * t),
            int(NAVY_DARK[2] + (NAVY[2] - NAVY_DARK[2]) * t),
        )
        bg.line([(0, i), (MASTER, i)], fill=color)

    layer = Image.new("RGBA", (MASTER, MASTER), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    bar_h = 116
    radius = bar_h // 2

    # Tres barras escalonadas. Cada una empieza donde termina la anterior:
    # asi el escalonado se lee como secuencia y no como solapamiento.
    bars = [
        (150, 200, 560, CREAM),
        (330, 200 + bar_h + 46, 760, AMBER),   # la critica
        (510, 200 + 2 * (bar_h + 46), 880, CREAM),
    ]
    # Las barras se traslapan en el tiempo a proposito: asi es como se ve un
    # cronograma con fases traslapadas, que es justo lo que el simulador
    # modela. No se dibujan flechas de dependencia porque a 48 pixeles serian
    # ruido, y un icono tiene que leerse en el tamanio en que se usa.
    for x0, y, x1, color in bars:
        rounded(d, (x0, y, x1, y + bar_h), radius=radius, fill=color)

    # Eje de tiempo con hitos.
    axis_y = bars[-1][1] + bar_h + 120
    d.line([(150, axis_y), (880, axis_y)], fill=SLATE, width=12)
    for x in (150, 333, 516, 699):
        d.line([(x, axis_y - 20), (x, axis_y + 20)], fill=SLATE, width=9)

    # Hito de cierre: rombo ambar al final del eje.
    cx, cy, r = 880, axis_y, 58
    d.polygon(
        [(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)],
        fill=AMBER,
    )

    # Centrado real: se recorta al contenido dibujado y se escala para dejar
    # un margen de seguridad uniforme. Asi el icono no depende de que las
    # coordenadas de arriba esten perfectamente equilibradas a mano.
    box = layer.getbbox()
    content = layer.crop(box)
    target = int(MASTER * CONTENT_SCALE)
    ratio = min(target / content.width, target / content.height)
    scaled = content.resize(
        (max(1, int(content.width * ratio)), max(1, int(content.height * ratio))),
        Image.LANCZOS,
    )
    base.alpha_composite(
        scaled,
        ((MASTER - scaled.width) // 2, (MASTER - scaled.height) // 2),
    )
    return base


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out",
        default="android_icons",
        help="Carpeta destino de los mipmap (por defecto: android_icons)",
    )
    args = parser.parse_args()

    master = build_master()

    os.makedirs(args.out, exist_ok=True)
    master.save(os.path.join(args.out, "ic_launcher_master.png"))

    for folder, size in DENSITIES.items():
        target = os.path.join(args.out, folder)
        os.makedirs(target, exist_ok=True)
        icon = master.resize((size, size), Image.LANCZOS)
        icon.save(os.path.join(target, "ic_launcher.png"))
        icon.save(os.path.join(target, "ic_launcher_round.png"))
        print(f"  {folder}/ic_launcher.png  ({size}x{size})")

    print(f"\nIcono generado en {args.out}/")
    print("Se copia a android/app/src/main/res/ con tool/prepare_android.sh")


if __name__ == "__main__":
    main()
