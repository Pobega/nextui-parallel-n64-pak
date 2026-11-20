#!/bin/sh

EMU_EXE=parallel_n64
PAK_DIR="$(cd "$(dirname "$0")" && pwd)"
EMU_TAG=$(basename "$PAK_DIR" .pak)
ROM="$1"

mkdir -p "$BIOS_PATH/$EMU_TAG"
mkdir -p "$SAVES_PATH/$EMU_TAG"
mkdir -p "$CHEATS_PATH/$EMU_TAG"
HOME="$USERDATA_PATH"
cd "$HOME" || exit 1

echo 1 >/sys/devices/system/cpu/cpu1/online 2>/dev/null
echo 1 >/sys/devices/system/cpu/cpu2/online 2>/dev/null
echo 1 >/sys/devices/system/cpu/cpu3/online 2>/dev/null

if [ -n "$PLATFORM" ] && [ -f "$PAK_DIR/cores/$PLATFORM/${EMU_EXE}_libretro.so" ]; then
	CORE_SO="$PAK_DIR/cores/$PLATFORM/${EMU_EXE}_libretro.so"
else
	CORE_SO="$PAK_DIR/${EMU_EXE}_libretro.so"
fi

if [ -n "$PLATFORM" ] && [ -f "$PAK_DIR/bin/$PLATFORM/minarch.elf" ]; then
	MINARCH="$PAK_DIR/bin/$PLATFORM/minarch.elf"
elif [ -f "$PAK_DIR/minarch.elf" ]; then
	MINARCH="$PAK_DIR/minarch.elf"
else
	MINARCH="minarch.elf"
fi

"$MINARCH" "$CORE_SO" "$ROM" > "$LOGS_PATH/$EMU_TAG.txt" 2>&1
