TEMPLATE = app
CONFIG += console c++11
CONFIG -= app_bundle
CONFIG -= qt

SOURCES +=

DISTFILES += \
    src/main.asm \
    src/timer/timer.asm \
    src/input/mouse/mouse_cursor.inc \
    src/input/mouse/mouse.asm \
    src/text/font.inc \
    src/text/text.asm \
    src/useful.asm \
    src/graphics/palette.inc \
    src/graphics/vga.asm \
    src/graphics/draw_routines.asm \
    src/file/file.asm \
    src/cmd_line/cmd_line.asm \
    src/file/manif_parser.asm \
    src/editor/editor.asm

