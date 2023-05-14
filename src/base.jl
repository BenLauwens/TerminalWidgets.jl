abstract type Widget end
abstract type FocusableWidget <: Widget end
abstract type EditableWidget <: FocusableWidget end

abstract type WidgetInternal end

struct TopWidgetInternal <: WidgetInternal
    childs::Vector{Widget}
    signals::Dict{Symbol,Vector{Function}}
    keys::Dict{String,Symbol}
    background::Color
    foreground::Color
    function TopWidgetInternal(; background::Color=COLOR_BLACK,
        foreground::Color=COLOR_GREEN
    )
        new(Vector{Widget}(), Dict{Symbol,Vector{Function}}(), Dict{String,Symbol}(), background, foreground)
    end
end

struct HorizontalContainerWidgetInternal <: WidgetInternal
    parent::Ref{Widget}
    childs::Vector{Widget}
    signals::Dict{Symbol,Vector{Function}}
    keys::Dict{String,Symbol}
    row::Ref{Int}
    col::Ref{Int}
    background::Color
    foreground::Color
    function HorizontalContainerWidgetInternal(; row::Integer=1,
        col::Integer=1,
        background::Color=COLOR_BLACK,
        foreground::Color=COLOR_GREEN
    )
        new(Ref{Widget}(), Vector{Widget}(), Dict{Symbol,Vector{Function}}(), Dict{String,Symbol}(), Ref{Int}(row), Ref{Int}(col), background, foreground)
    end
end

struct VerticalContainerWidgetInternal <: WidgetInternal
    parent::Ref{Widget}
    childs::Vector{Widget}
    signals::Dict{Symbol,Vector{Function}}
    keys::Dict{String,Symbol}
    row::Ref{Int}
    col::Ref{Int}
    background::Color
    foreground::Color
    function VerticalContainerWidgetInternal(; row::Integer=1,
        col::Integer=1,
        background::Color=COLOR_BLACK,
        foreground::Color=COLOR_GREEN
    )
        new(Ref{Widget}(), Vector{Widget}(), Dict{Symbol,Vector{Function}}(), Dict{String,Symbol}(), Ref{Int}(row), Ref{Int}(col), background, foreground)
    end
end

struct ElementaryWidgetInternal <: WidgetInternal
    parent::Ref{Widget}
    signals::Dict{Symbol,Vector{Function}}
    keys::Dict{String,Symbol}
    row::Ref{Int}
    col::Ref{Int}
    height::Int
    width::Int
    background::Color
    foreground::Color
    function ElementaryWidgetInternal(; row::Integer=1,
        col::Integer=1,
        height::Integer=1,
        width::Integer=1,
        background::Color=COLOR_BLACK,
        foreground::Color=COLOR_GREEN
    )
        new(Ref{Widget}(), Dict{Symbol,Vector{Function}}(), Dict{String,Symbol}(), Ref{Int}(row), Ref{Int}(col), height, width, background, foreground)
    end
end

function width(_::TopWidgetInternal)
    screen_size()[2]
end

function height(_::TopWidgetInternal)
    screen_size()[1]
end

function width(wi::ElementaryWidgetInternal)
    wi.width
end

function height(wi::ElementaryWidgetInternal)
    wi.height
end

function width(wi::VerticalContainerWidgetInternal)
    maximum(map(widget::Widget->width(widget.w), wi.childs))
end

function height(wi::VerticalContainerWidgetInternal)
    sum(map(widget::Widget->height(widget.w), wi.childs))
end

function width(wi::HorizontalContainerWidgetInternal)
    sum(map(widget::Widget->width(widget.w), wi.childs))
end

function height(wi::HorizontalContainerWidgetInternal)
    maximum(map(widget::Widget->height(widget.w), wi.childs))
end

function row(widget::Widget)
    widget.w.row[] + row(widget.w.parent[]) - 1
end

function col(widget::Widget)
    widget.w.col[] + col(widget.w.parent[]) - 1
end

function emit(widget::Widget, sig::Symbol, args...)
    handlers = get(widget.w.signals, sig, nothing)
    if handlers === nothing
        return false
    end
    for handler in handlers
        handler(widget, args...)
    end
    true
end

function focus(to::FocusableWidget)
    focus = APP[].focus[]
    APP[].focus[] = to
    redraw(focus)
    redraw(to)
    nothing
end

function has_focus(widget::FocusableWidget)
    APP[].focus[] === widget
end

function Base.size(widget::Widget, dim::Int=0)
    if dim === 1
        height(widget.w)
    elseif dim === 2
        width(widget.w)
    else
        height(widget.w), width(widget.w)
    end
end

function add(parent::Widget, child::Widget, row::Integer=1, col::Integer=1)
    app = APP[]
    if !isassigned(app.focus) && child isa FocusableWidget
        app.focus[] = child
    end
    push!(parent.w.childs, child)
    child.w.row[] = row
    child.w.col[] = col
    child.w.parent[] = parent
    nothing
end

function on(handler::Function, widget::Widget, signal::Symbol; key::String="")
    handlers = get!(widget.w.signals, signal, Vector{Function}())
    push!(handlers, handler)
    if key !== ""
        widget.w.keys[key] = signal
    end
    nothing
end

function redraw(widget::Widget)
    height, width = size(widget)
    screen_box_clear(row(widget), col(widget), height, width)
    for child in widget.w.childs
        redraw(child)
    end
    nothing
end

function inside(widget::Widget, r::Integer, c::Integer)
    height, width = size(widget)
    row(widget) <= r < row(widget) + height &&
        col(widget) <= c < col(widget) + width
end

function handle_mouse(widget::Widget, row::Integer, col::Integer)
    if widget.w isa ElementaryWidgetInternal
        return nothing
    end
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
