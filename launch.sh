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

for c in 1 2 3 4 5 6 7; do
	[ -w "/sys/devices/system/cpu/cpu${c}/online" ] && echo 1 > "/sys/devices/system/cpu/cpu${c}/online" 2>/dev/null
done

if [ -n "$PLATFORM" ] && [ -f "$PAK_DIR/cores/$PLATFORM/${EMU_EXE}_libretro.so" ]; then
	CORE_SO="$PAK_DIR/cores/$PLATFORM/${EMU_EXE}_libretro.so"
else
	CORE_SO="$PAK_DIR/${EMU_EXE}_libretro.so"
fi

minarch.elf "$CORE_SO" "$ROM" > "$LOGS_PATH/$EMU_TAG.txt" 2>&1
