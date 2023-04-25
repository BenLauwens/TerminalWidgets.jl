struct Label <: Widget
    w::ElementaryWidgetInternal
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
        w = ElementaryWidgetInternal(; width, background, foreground)
        new(w, str)
    end
end

function redraw(label::Label)
    screen_string(label.str, row(label), col(label);
        style=Style(; background=label.w.background, foreground=label.w.foreground))
    nothing
end
