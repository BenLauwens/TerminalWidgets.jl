struct TextBox <: EditableWidget
    w::ElementaryWidgetInternal
    v::Vector{Char}
    x::Ref{Int}
    y::Ref{Int}
    function TextBox(str::String;
        height::Integer=1,
        width::Integer=length(str),
        background::Color=APP[].w.background,
        foreground::Color=APP[].w.foreground
    )
        w = ElementaryWidgetInternal(; width=width+2, height=height+2, background, foreground)
        w.signals[:click] = focus
        v = string2vector(str, height, width)
        new(w, v, Ref{Int}(1), Ref{Int}(1))
    end
end

function handle_mouse(text::TextBox, row::Integer, col::Integer)
    emit(text, :click, row::Integer, col::Integer)
    nothing
end

function handle_key(text::TextBox, input::String)
    sig = get(text.w.keys, input, :nothing)
    if !emit(text, sig)
        char = input[begin]
        if char === ' '
            char = '␣'
        elseif char === '\r'
            char = '⮐'
        end
        if length(input) === 1 && !iscntrl(char)
            height, width = size(text)
            height -= 2
            width -= 2
            index = (text.y[] - 1) * width + text.x[]
            insert!(text.v, index, char)
            index += 1
            char = text.v[index]
            if char === '⮐'
                text.v[index] = '⏎'
            elseif char === '␣'
                text.v[index] = ' '
            else
                text.v[index] = '█'
            end
            str = vector2string(text.v)
            empty!(text.v)
            append!(text.v, string2vector(str, height, width))
            if char === '⮐'
                index = findfirst(isequal('⏎'), text.v)
            elseif char === '␣'
                index = findfirst(isequal(' '), text.v)
            else
                index = findfirst(isequal('█'), text.v)
            end
            text.v[index] = char
            y, x = divrem(index - 1, width)
            text.y[] = y + 1
            text.x[] = x + 1
            if text.x[] > width
                if text.y[] < height
                    text.x[] = 1
                    text.y[] += 1
                else
                    text.x[] -= 1
                end
            end
            redraw(text)
        elseif text !== APP[]
            handle_key(text.w.parent[], input)
        end
    end
    nothing
end

function focus(text::TextBox, y::Integer, x::Integer)
    height, width = size(text)
    y -= row(text)
    x -= col(text)
    if 1 <= y < height - 1 && 1 <= x < width - 1
        index = (y - 1) * (width - 2)
        x = findprev(!isequal(' '), text.v[index + 1:index + (width-2)], x)
        if x !== nothing
            text.y[] = y
            text.x[] = x
        else
            index = findlast(!isequal(' '), text.v)
            y, x = divrem(index - 1, width - 2)
            text.y[] = y + 1
            text.x[] = x + 1
        end
    end
    focus(text)
    nothing
end

function redraw(text::TextBox)
    height, width = size(text)
    start_r = row(text)
    start_c = col(text)
    screen_box(start_r, start_c, height, width;
        type=BORDER_LIGHT, style=Style(; bold=has_focus(text), background=text.w.background, foreground=text.w.foreground))
    height -= 2
    width -= 2
    for y in 1:height
        for x in 1:width
            index = (y - 1) * width + x
            screen_char(text.v[index], start_r + y, start_c + x;
                style=Style(; bold=has_focus(text), background=text.w.background, foreground=text.w.foreground))
        end
    end
    if has_focus(text)
        cursor(start_r + text.y[], start_c + text.x[])
    else
        cursor()
    end
    nothing
end
