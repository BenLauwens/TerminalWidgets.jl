struct CheckBox <: EditableWidget
    w::ElementaryWidgetInternal
    v::Ref{Bool}
    str::String
    function CheckBox(str::String="", v::Bool=false;
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
        w.signals[:click] = toggle
        w.keys["\r"] = :click
        new(w, Ref{Bool}(v), str)
    end
end

function toggle(checkbox::CheckBox)
    checkbox.v[] = !checkbox.v[]
    focus(checkbox)
    nothing
end

function redraw(checkbox::CheckBox)
    screen_string((checkbox.v[] ? '✓' : '⬚') * checkbox.str, row(checkbox), col(checkbox);
        style=Style(; bold=has_focus(checkbox), background=checkbox.w.background, foreground=checkbox.w.foreground)
    )
    nothing
end

function handle_mouse(checkbox::CheckBox, row::Integer, col::Integer)
    emit(checkbox, :click)
    nothing
end

function value(checkbox::CheckBox)
    checkbox.v[]
end

struct MultiSelect <: EditableWidget
    w::VerticalContainerWidgetInternal
    function MultiSelect(options::Vector{String}, values::Vector{Bool}=fill(false,size(options));
        width::Integer=1,
        background::Color=APP[].w.background,
        foreground::Color=APP[].w.foreground
    )
        rows = length(options)
        w = VerticalContainerWidgetInternal(; background, foreground)
        multi = new(w)
        for (row, (str, val)) in enumerate(zip(options, values))
            checkbox = CheckBox(str, val ;width, background, foreground)
            add(multi, checkbox, row, 3)
        end
        for (index, prev) in enumerate(multi.w.childs)
            next = multi.w.childs[mod(index, rows) + 1]
            on(prev, :next; key=KEY_DOWN) do
                focus(next)
            end
            on(next, :prev; key=KEY_UP) do
                focus(prev)
            end
        end
        multi
    end
end

function Base.size(multi::MultiSelect, dim::Int=0)
    if dim === 1
        height(multi.w)
    elseif dim === 2
        width(multi.w) + 2
    else
        height(multi.w), width(multi.w) + 2
    end
end

function redraw(multi::MultiSelect)
    height, width = size(multi)
    r = row(multi)
    c = col(multi)
    screen_box_clear(r, c, height, width)
    screen_string("↑ ",r, c;
        style=Style(; background=multi.w.background, foreground=multi.w.foreground))
    screen_string("↓ ", r + length(multi.w.childs) - 1, c;
        style=Style(; background=multi.w.background, foreground=multi.w.foreground))
    for child in multi.w.childs
        redraw(child)
    end
    nothing
end

function focus(multi::MultiSelect)
    focus(multi.w.childs[1])
    nothing
end

function value(multi::MultiSelect)
    map(value, multi.w.childs)
end
