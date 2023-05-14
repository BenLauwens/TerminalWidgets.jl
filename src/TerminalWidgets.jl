module TerminalWidgets

using Unicode
using TerminalBase

export KEY_UP, KEY_DOWN, KEY_RIGHT, KEY_LEFT, KEY_PGUP, KEY_PGDN, KEY_ENTER, KEY_BACKSPACE, KEY_DELETE, KEY_INSERT
export KEY_ESCAPE, KEY_TAB, KEY_SHIFT_TAB, KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10
export ALIGN_LEFT, ALIGN_RIGHT, ALIGN_CENTER
export COLOR_BLACK, COLOR_RED, COLOR_GREEN, COLOR_YELLOW, COLOR_BLUE, COLOR_MAGENTA, COLOR_CYAN, COLOR_WHITE
export COLOR_BRIGHT_BLACK, COLOR_BRIGHT_RED, COLOR_BRIGHT_GREEN, COLOR_BRIGHT_YELLOW, COLOR_BRIGHT_BLUE, COLOR_BRIGHT_MAGENTA, COLOR_BRIGHT_CYAN, COLOR_BRIGHT_WHITE
export BORDER_LIGHT, BORDER_ROUNDED, BORDER_HEAVY, BORDER_DOUBLE, BORDER_NONE
export Style, Color, Color256, ColorRGB
export Widget, Label, Button, CheckBox, MultiSelect, RadioGroup, TextBox, Menu, MenuItem
export init, run, add, on, focus

include("utils.jl")
include("base.jl")
include("label.jl")
include("button.jl")
include("checkbox.jl")
include("radiogroup.jl")
include("textbox.jl")
include("menu.jl")
include("app.jl")

end
