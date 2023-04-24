module TerminalWidgets

using TerminalBase

export KEY_UP, KEY_DOWN, KEY_RIGHT, KEY_LEFT, KEY_PGUP, KEY_PGDN, KEY_ENTER, KEY_BACKSPACE, KEY_DELETE, KEY_INSERT
export KEY_ESCAPE, KEY_TAB, KEY_SHIFT_TAB, KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10
export ALIGN_LEFT, ALIGN_RIGHT, ALIGN_CENTER
export BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE
export BRIGHT_BLACK, BRIGHT_RED, BRIGHT_GREEN, BRIGHT_YELLOW, BRIGHT_BLUE, BRIGHT_MAGENTA, BRIGHT_CYAN, BRIGHT_WHITE
export LIGHT, ROUNDED, HEAVY, DOUBLE
export Style, Color, Color256, ColorRGB
export Widget, Label, Button, CheckBox
export init, run, add, on, focus

abstract type Widget end
abstract type FocusableWidget <: Widget end
abstract type EditableWidget <: FocusableWidget end

struct BaseWidget
    parent::Ref{Widget}
    childs::Vector{Widget}
    signals::Dict{Symbol, Function}
    keys::Dict{String, Symbol}
    row::Ref{Int}
    col::Ref{Int}
    height::Int
    width::Int
    background::Color
    foreground::Color
    function BaseWidget(; row::Integer=1,
        col::Integer=1,
        height::Integer=1,
        width::Integer=1,
        background::Color=BLACK, 
        foreground::Color=GREEN
    )
        new(Ref{Widget}(), Vector{Widget}(), Dict{Symbol, Function}(), Dict{String, Symbol}(), Ref{Int}(row), Ref{Int}(col), height, width, background, foreground)
    end
end

function emit(widget::Widget, sig::Symbol)
    handler = get(widget.w.signals, sig, nothing)
    if handler === nothing
        return false
    end
    handler(widget)
    true
end

function focus(to::FocusableWidget)
    APP[].focus[] = to
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
        background::Color=APP[].w.background,
        foreground::Color=APP[].w.foreground
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
    screen_string(label.str, label.w.row[], label.w.col[];
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
    function Button(handler::Function, str::String;
        height::Integer=3,
        width::Integer=length(str),
        align::Align=ALIGN_CENTER,
        background::Color=APP[].w.background, 
        foreground::Color=APP[].w.foreground
    )
        if width < length(str) + 1
            width = length(str) + 2
        elseif width > length(str) + 2
            str = align(str, width-2, align)
        end
        w = BaseWidget(;height, width, background, foreground)
        w.signals[:click] = _::Button -> handler()
        w.keys["\r"] = :click
        new(w, str)
    end
end

function redraw(button::Button)
    screen_box(button.w.row[], button.w.col[], button.w.height, button.w.width;
        type=BORDER_ROUNDED, style=Style(;bold=has_focus(button), background=button.w.background, foreground=button.w.foreground))
    screen_string(button.str, button.w.row[]+1, button.w.col[]+1;
        style=Style(;bold=has_focus(button), background=button.w.background, foreground=button.w.foreground))
    nothing
end

function handle_mouse(button::Button, row::Integer, col::Integer)
    emit(button, :click)
    nothing
end

struct CheckBox <: EditableWidget
    w::BaseWidget
    v::Ref{Bool}
    str::String
    function CheckBox(str::String="", v::Bool=false;
        width::Integer=length(str)+2,
        background::Color=APP[].w.background, 
        foreground::Color=APP[].w.foreground
    )
        str = ' ' * str
        if width < length(str) + 2
            width = length(str) + 2
        elseif width > length(str) + 2
            str = align(str, width-1, ALIGN_LEFT)
        end
        w = BaseWidget(;width, background, foreground)
        w.signals[:click] = toggle
        w.keys["\r"] = :click
        new(w, Ref{Bool}(v), str)
    end
end

function toggle(checkbox::CheckBox)
    checkbox.v[] = ! checkbox.v[]
end

function redraw(checkbox::CheckBox)
    screen_string((checkbox.v[] ? '✓' : '⬚') * checkbox.str, checkbox.w.row[], checkbox.w.col[]; 
        style=Style(;bold=has_focus(checkbox), background=checkbox.w.background, foreground=checkbox.w.foreground)
    )
    nothing
end

function handle_mouse(checkbox::CheckBox, row::Integer, col::Integer)
    emit(checkbox, :click)
    nothing
end

struct App <: Widget
    w::BaseWidget
    focus::Ref{FocusableWidget}
    function App(w::BaseWidget)
        new(w, Ref{FocusableWidget}())
    end
end

const APP = Ref{App}()

function init(; char::Char=' ', background::Color=BLACK, foreground::Color=GREEN)
    screen_init(; char, background, foreground)
    height, width = screen_size()
    w = BaseWidget(;height, width, background, foreground)
    APP[] = App(w)
    nothing
end

function has_focus(widget::FocusableWidget)
    APP[].focus[] === widget
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
    app = APP[]
    if !isassigned(app.focus) && child isa FocusableWidget
        app.focus[] = child
    end
    push!(parent.w.childs, child)
    child.w.row[] = row + parent.w.row[] - 1
    child.w.col[] = col + parent.w.col[] - 1
    child.w.parent[] = parent
    nothing
end

function add(child::Widget, row::Integer, col::Integer)
    add(APP[], child, row, col)
end

function on(handler::Function, widget::Widget, signal::Symbol; key::String="")
    widget.w.signals[signal] = _::Widget -> handler()
    if key !== ""
        widget.w.keys[key] = signal
    end
    nothing
end

function on(handler::Function, signal::Symbol; key::String="")
    on(handler, APP[], signal; key)
end

function redraw(widget::Widget)
    screen_box_clear(widget.w.row[], widget.w.col[], widget.w.height, widget.w.width)
    for child in widget.w.childs
        redraw(child)
    end
    nothing
end

function inside(widget::Widget, row, col)
    widget.w.row[] <= row < widget.w.row[] + widget.w.height &&
    widget.w.col[] <= col < widget.w.col[] + widget.w.width
end

function handle_mouse(widget::Widget, row::Integer, col::Integer)
    for child in widget.w.childs
        if inside(child, row, col)
            handle_mouse(child, row, col)
        end
    end
    nothing
end

function handle_key(widget::Widget, input::String)
    sig = get(widget.w.keys, input, :nothing)
    if !emit(widget, sig) && widget !== APP[]
        handle_key(widget.w.parent[], input)
    end
    nothing
end

function Base.run()
    app = APP[]
    while true
        redraw(app)
        screen_refresh()
        input = screen_input()
        if startswith(input, "\e[M ")
            mouse = transcode(UInt8, input[5:6])
            row = Int(mouse[2]) - 32
            col = Int(mouse[1]) - 32
            handle_mouse(app, row, col)
        else
            handle_key(app.focus[], input)
        end
    end
end

end
