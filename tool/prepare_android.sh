#!/usr/bin/env bash
#
# Genera la carpeta android/ y aplica la configuracion propia del proyecto.
#
# La carpeta android/ NO se versiona a proposito: son cientos de archivos que
# Flutter regenera de forma determinista y que solo aportan ruido a los
# diffs. Este script la reconstruye y vuelve a aplicar lo unico que si es
# nuestro: identificador del paquete, nombre visible e icono.
#
# Uso:
#   bash tool/prepare_android.sh
#
# Despues:
#   flutter build apk --release

set -euo pipefail

APP_ID="pe.edu.simulador.project_management_simulator"
APP_NAME="PM Simulator"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> Proyecto: $ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: no se encontro 'flutter' en el PATH." >&2
  echo "Instala Flutter 3.24+ y vuelve a intentar." >&2
  exit 1
fi

# --- Respaldo de lo que no debe perderse -----------------------------------
BACKUP="$(mktemp -d)"
PROTECTED=(
  "pubspec.yaml"
  "analysis_options.yaml"
  "README.md"
  ".gitignore"
)
for f in "${PROTECTED[@]}"; do
  [ -f "$f" ] && cp "$f" "$BACKUP/$(basename "$f")"
done
[ -d lib ] && cp -r lib "$BACKUP/lib"
[ -d test ] && cp -r test "$BACKUP/test"

restore() {
  for f in "${PROTECTED[@]}"; do
    [ -f "$BACKUP/$(basename "$f")" ] && cp "$BACKUP/$(basename "$f")" "$f"
  done
  [ -d "$BACKUP/lib" ] && rm -rf lib && cp -r "$BACKUP/lib" lib
  [ -d "$BACKUP/test" ] && rm -rf test && cp -r "$BACKUP/test" test
  rm -rf "$BACKUP"
}
trap restore EXIT

# --- Generacion de la plataforma -------------------------------------------
echo "==> Generando android/ ..."
flutter create --platforms=android --org "pe.edu.simulador" \
  --project-name project_management_simulator --overwrite . >/dev/null

echo "==> Restaurando fuentes del proyecto ..."
restore
trap - EXIT

# --- Identificador de aplicacion -------------------------------------------
GRADLE="android/app/build.gradle"
GRADLE_KTS="android/app/build.gradle.kts"
if [ -f "$GRADLE_KTS" ]; then
  GRADLE="$GRADLE_KTS"
fi

if [ -f "$GRADLE" ]; then
  echo "==> Fijando applicationId en $(basename "$GRADLE") ..."
  python3 - "$GRADLE" "$APP_ID" <<'PY'
import re, sys
path, app_id = sys.argv[1], sys.argv[2]
src = open(path, encoding="utf-8").read()
src = re.sub(r'applicationId\s*=\s*"[^"]*"', f'applicationId = "{app_id}"', src)
src = re.sub(r'applicationId\s+"[^"]*"', f'applicationId "{app_id}"', src)
src = re.sub(r'namespace\s*=\s*"[^"]*"', f'namespace = "{app_id}"', src)
src = re.sub(r'namespace\s+"[^"]*"', f'namespace "{app_id}"', src)
open(path, "w", encoding="utf-8").write(src)
PY
fi

# --- Nombre visible ---------------------------------------------------------
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
  echo "==> Fijando el nombre visible ..."
  python3 - "$MANIFEST" "$APP_NAME" <<'PY'
import re, sys
path, name = sys.argv[1], sys.argv[2]
src = open(path, encoding="utf-8").read()
src = re.sub(r'android:label="[^"]*"', f'android:label="{name}"', src, count=1)
open(path, "w", encoding="utf-8").write(src)
PY
fi

# --- Icono ------------------------------------------------------------------
if [ ! -d android_icons ]; then
  echo "==> Generando iconos ..."
  python3 tool/generate_icon.py >/dev/null || {
    echo "AVISO: no se pudo generar el icono (falta Pillow). Se usa el de Flutter." >&2
  }
fi

if [ -d android_icons ]; then
  echo "==> Instalando iconos ..."
  for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
    SRC="android_icons/mipmap-$density"
    DEST="android/app/src/main/res/mipmap-$density"
    if [ -d "$SRC" ]; then
      mkdir -p "$DEST"
      cp "$SRC/ic_launcher.png" "$DEST/ic_launcher.png"
      [ -f "$SRC/ic_launcher_round.png" ] && \
        cp "$SRC/ic_launcher_round.png" "$DEST/ic_launcher_round.png"
    fi
  done
fi

echo ""
echo "Listo. Ahora puedes construir el APK:"
echo "    flutter build apk --release"
echo ""
echo "El APK queda en build/app/outputs/flutter-apk/app-release.apk"
