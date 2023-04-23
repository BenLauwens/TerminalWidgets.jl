module TerminalWidgets

using TerminalBase

export KEY_UP, KEY_DOWN, KEY_RIGHT, KEY_LEFT, KEY_PGUP, KEY_PGDN, KEY_ENTER, KEY_BACKSPACE, KEY_DELETE, KEY_INSERT
export KEY_ESCAPE, KEY_TAB, KEY_SHIFT_TAB, KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10
export ALIGN_LEFT, ALIGN_RIGHT, ALIGN_CENTER
export BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE
export BRIGHT_BLACK, BRIGHT_RED, BRIGHT_GREEN, BRIGHT_YELLOW, BRIGHT_BLUE, BRIGHT_MAGENTA, BRIGHT_CYAN, BRIGHT_WHITE
export LIGHT, ROUNDED, HEAVY, DOUBLE
export Style, Color, Color256, ColorRGB
export App, Label, Button
export run, add, on, change_focus

abstract type Widget end
abstract type FocusableWidget <: Widget end
abstract type EditableWidget <: FocusableWidget end

mutable struct BaseWidget
    parent::Union{Widget, Nothing}
    childs::Vector{Widget}
    signals::Dict{Symbol, Function}
    keys::Dict{String, Symbol}
    focus::Union{FocusableWidget, Nothing}
    row::Int
    col::Int
    height::Int
    width::Int
    background::Color
    foreground::Color
    function BaseWidget(;row::Integer=1,
        col::Integer=1,
        height::Integer=1,
        width::Integer=1,
        background::Color=BLACK,
        foreground::Color=GREEN
    )
        new(nothing, Vector{Widget}(), Dict{Symbol, Function}(), Dict{String, Symbol}(), nothing, row, col, height, width, background, foreground)
    end
end

function signal(widget::Widget, sig::Symbol)
    handler = get(widget.w.signals, sig, widget::Widget->false)
    handler(widget)
end

function change_focus(from::FocusableWidget, to::FocusableWidget)
    parent = from.w.parent
    while parent.w.parent !== nothing
        parent.w.focus = nothing
        parent = parent.w.parent
    end
    child = to
    parent = to.w.parent
    while parent.w.parent !== nothing
        parent.w.focus = child
        child = parent
        parent = child.w.parent
    end
    parent.w.focus = child
    redraw(from, false)
    redraw(to, true)
    true
end

struct Align
    v::Symbol
end

const ALIGN_LEFT = Align(:left)
const ALIGN_RIGHT = Align(:right)
const ALIGN_CENTER = Align(:center)

struct Label <: Widget
    w::BaseWidget
    str::String
    function Label(str::String;
        width::Integer=length(str),
        align::Align=ALIGN_LEFT,
        background::Color=BLACK,
        foreground::Color=GREEN
    )
        if width < length(str)
            width = length(str)
        elseif width > length(str)
            str = align_string(str, width, align)
        end
        w = BaseWidget(;width, background, foreground)
        new(w, str)
    end
end

function redraw(label::Label)
    screen_string(label.str, label.w.row, label.w.col;
        style=Style(;background=label.w.background, foreground=label.w.foreground))
    nothing
end

function align_string(str::String, width::Integer, align::Align)
    if align === ALIGN_RIGHT
        lpad(str, width)
    elseif align === ALIGN_CENTER
        diff = width - length(str)
        left = width - div(diff, 2)
        rpad(lpad(str, left), width)
    else
        rpad(str, width)
    end
end

struct Button <: FocusableWidget
    w::BaseWidget
    str::String
    function Button(str::String, handler::Function;
        height::Integer=3,
        width::Integer=length(str),
        align::Align=ALIGN_CENTER,
        background::Color=BLACK,
        foreground::Color=GREEN
    )
        if width < length(str) + 1
            width = length(str) + 2
        elseif width > length(str) + 2
            str = align(str, width-2, align)
        end
        w = BaseWidget(;height, width, background, foreground)
        w.signals[:click] = handler
        w.keys["\r"] = :click
        new(w, str)
    end
end

function redraw(button::Button, focus::Bool)
    screen_box(button.w.row, button.w.col, button.w.height, button.w.width;
        type=BORDER_ROUNDED, style=Style(;bold=focus, background=button.w.background, foreground=button.w.foreground))
    screen_string(button.str, button.w.row+1, button.w.col+1;
        style=Style(;bold=focus, background=button.w.background, foreground=button.w.foreground))
end

function handle_mouse(button::Button, row::Integer, col::Integer)
    signal(button, :click)
end

struct App <: FocusableWidget
    w::BaseWidget
    function App(; char::Char=' ', background::Color=BLACK, foreground::Color=GREEN)
        screen_init(;char, background, foreground)
        height, width = screen_size()
        w = BaseWidget(;height, width, background, foreground)
        new(w)
    end
end

function Base.size(widget::Widget, dim::Int=0)
    if dim === 1
        widget.w.height
    elseif dim === 2
        widget.w.width
    else
        widget.w.height, widget.w.width
    end
end

function add(parent::Widget, child::Widget, row::Integer, col::Integer)
    push!(parent.w.childs, child)
    child.w.row = row + parent.w.row - 1
    child.w.col = col + parent.w.col - 1
    child.w.parent = parent
    if parent.w.focus === nothing && child isa FocusableWidget
        parent.w.focus = child
    end
    nothing
end

function on(widget::Widget, signal::Symbol, handler::Function; key::String="")
    widget.w.signals[signal] = handler
    if key !== ""
        widget.w.keys[key] = signal
    end
    nothing
end

function redraw(widget::Widget)
    screen_box_clear(widget.w.row, widget.w.col, widget.w.height, widget.w.width)
    for child in widget.w.childs
        if child isa FocusableWidget
            redraw(child, child === widget.w.focus)
        else
            redraw(child)
        end
    end
    nothing
end

function inside(widget::Widget, row, col)
    widget.w.row <= row < widget.w.row + widget.w.height &&
    widget.w.col <= col < widget.w.col + widget.w.width
end

function handle_mouse(widget::FocusableWidget, row::Integer, col::Integer)
    focus = widget.w.focus
    for child in widget.w.childs
        if child isa FocusableWidget
            if inside(child, row, col)
                widget.w.focus = child
                redraw(child, true)
                handle_mouse(child, row, col)
            elseif child === focus
                redraw(child, false)
            end
        end
    end
    nothing
end

function handle_key(widget::FocusableWidget, input::String)
    if widget.w.focus !== nothing && handle_key(widget.w.focus, input)
        return true
    end
    sig = get(widget.w.keys, input, :nothing)
    signal(widget, sig)
end

function Base.run(app::App)
    redraw(app)
    while true
        screen_refresh()
        input = screen_input()
        if startswith(input, "\e[M ")
            mouse = transcode(UInt8, input[5:6])
            row = Int(mouse[2]) - 32
            col = Int(mouse[1]) - 32
            handle_mouse(app, row, col)
        else
            handle_key(app, input)
        end
    end
end

end
