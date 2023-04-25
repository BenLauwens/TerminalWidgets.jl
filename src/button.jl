struct Button <: FocusableWidget
    w::ElementaryWidgetInternal
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
            str = align(str, width - 2, align)
        end
        w = ElementaryWidgetInternal(; height, width, background, foreground)
        w.signals[:click] = _::Button -> handler()
        w.keys["\r"] = :click
        new(w, str)
    end
end

function redraw(button::Button)
    height, width = size(button)
    r = row(button)
    c = col(button)
    screen_box(r, c, height, width;
        type=BORDER_ROUNDED, style=Style(; bold=has_focus(button), background=button.w.background, foreground=button.w.foreground))
    screen_string(button.str, r + 1, c + 1;
        style=Style(; bold=has_focus(button), background=button.w.background, foreground=button.w.foreground))
    nothing
end

function handle_mouse(button::Button, row::Integer, col::Integer)
    emit(button, :click)
    nothing
end
