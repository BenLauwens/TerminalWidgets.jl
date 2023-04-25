struct RadioButton <: EditableWidget
    w::ElementaryWidgetInternal
    v::Ref{Bool}
    str::String
    function RadioButton(str::String="", v::Bool=false;
        width::Integer=length(str) + 2,
        background::Color=APP[].w.background,
        foreground::Color=APP[].w.foreground
    )
        str = ' ' * str
        if width < length(str) + 2
            width = length(str) + 2
        elseif width > length(str) + 2
            str = align_string(str, width - 1, ALIGN_LEFT)
        end
        w = ElementaryWidgetInternal(; width, background, foreground)
        w.signals[:click] = select
        w.keys["\r"] = :click
        new(w, Ref{Bool}(v), str)
    end
end

function redraw(radiobutton::RadioButton)
    screen_string((radiobutton.v[] ? '◉' : '◌') * radiobutton.str, row(radiobutton), col(radiobutton);
        style=Style(; bold=has_focus(radiobutton), background=radiobutton.w.background, foreground=radiobutton.w.foreground)
    )
    nothing
end

function select(radiobutton::RadioButton)
    for button in radiobutton.w.parent[].w.childs
        button.v[] = false
    end
    radiobutton.v[] = true
    focus(radiobutton)
    nothing
end

function handle_mouse(radiobutton::RadioButton, row::Integer, col::Integer)
    emit(radiobutton, :click)
    nothing
end

function value(radiobutton::RadioButton)
    radiobutton.v[]
end

struct RadioGroup <: EditableWidget
    w::VerticalContainerWidgetInternal
    function RadioGroup(options::Vector{String}, v::Integer=1;
        width::Integer=1,
        background::Color=APP[].w.background,
        foreground::Color=APP[].w.foreground
    )
        rows = length(options)
        w = VerticalContainerWidgetInternal(; background, foreground)
        radiogroup = new(w)
        for (row, str) in enumerate(options)
            radiobutton = RadioButton(str, row===v; width, background, foreground)
            add(radiogroup, radiobutton, row, 3)
        end
        for (index, prev) in enumerate(radiogroup.w.childs)
            next = radiogroup.w.childs[mod(index, rows) + 1]
            on(prev, :next; key=KEY_DOWN) do
                focus(next)
            end
            on(next, :prev; key=KEY_UP) do
                focus(prev)
            end
        end
        radiogroup
    end
end

function Base.size(radiogroup::RadioGroup, dim::Int=0)
    if dim === 1
        height(radiogroup.w)
    elseif dim === 2
        width(radiogroup.w) + 2
    else
        height(radiogroup.w), width(radiogroup.w) + 2
    end
end

function redraw(radiogroup::RadioGroup)
    height, width = size(radiogroup)
    r = row(radiogroup)
    c = col(radiogroup)
    screen_box_clear(r, c, height, width)
    screen_string("↑ ", r, c;
        style=Style(; background=radiogroup.w.background, foreground=radiogroup.w.foreground))
    screen_string("↓ ", r + length(radiogroup.w.childs) - 1, c;
        style=Style(; background=radiogroup.w.background, foreground=radiogroup.w.foreground))
    for child in radiogroup.w.childs
        redraw(child)
    end
    nothing
end

function focus(radiogroup::RadioGroup)
    APP[].focus[] = radiogroup.w.childs[value(radiogroup)]
end

function value(radiogroup::RadioGroup)
    for (index, child) in enumerate(radiogroup.w.childs)
        if value(child)
            return index
        end
    end
    0
end
