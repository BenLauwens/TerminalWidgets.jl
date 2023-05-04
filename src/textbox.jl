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
        v = string2vector(str, height, width)
        text = new(w, v, Ref{Int}(1), Ref{Int}(1))
        on(focus, text, :click)
        on(text, :up; key=KEY_UP) do text::TextBox
            width = size(text, 2) - 2
            move_cursor(text, -width)
            nothing
        end
        on(text, :down; key=KEY_DOWN) do text::TextBox
            width = size(text, 2) - 2
            move_cursor(text, width)
            nothing
        end
        on(text, :left; key=KEY_LEFT) do text::TextBox
            move_cursor(text, -1)
            nothing
        end
        on(text, :right; key=KEY_RIGHT) do text::TextBox
            move_cursor(text, 1)
            nothing
        end
        text
    end
end

function move_cursor(text::TextBox, offset:: Integer)
    height, width = size(text)
    height -= 2
    width -= 2
    index = cursor2index(text.y[], text.x[], width)
    index = findprev(!isequal(' '), text.v, min(max(1, index + offset), width * height))
    if index !== nothing
        text.y[], text.x[] = index2cursor(index, height, width)
        cursor(row(text) + text.y[], col(text) + text.x[])
    end
    nothing
end

function handle_mouse(text::TextBox, row::Integer, col::Integer)
    emit(text, :click, row::Integer, col::Integer)
    nothing
end

function handle_key(text::TextBox, input::String)
    sig = get(text.w.keys, input, :nothing)
    if !emit(text, sig)
        char, offset = if input === " "
            '␣', 1
        elseif input === KEY_ENTER
            '⮐', 1
        elseif input === KEY_BACKSPACE || input === '\b'
            '⌫', 1
        elseif input === KEY_DELETE
            '␡', 2
        elseif length(input) === 1 && !iscntrl(input[begin])
            input[begin], 1
        else
            handle_key(text.w.parent[], input)
            return nothing
        end
        height, width = size(text)
        index = cursor2index(text.y[], text.x[], width - 2)
        insert!(text.v, index, char)
        index = findnext(!isequal(' '), text.v, index + offset)
        if index === nothing
            push!(text.v, '⮐')
            index = length(text.v)
        end
        char = text.v[index]
        text.v[index] = if char === '⮐'
            '⏎'
        elseif char === '␣'
            ' '
        else
            '█'
        end
        str = vector2string(text.v)
        empty!(text.v)
        append!(text.v, string2vector(str, height - 2, width - 2))
        index = if char === '⮐'
            findfirst(isequal('⏎'), text.v)
        elseif char === '␣'
            findfirst(isequal(' '), text.v)
        else
            findfirst(isequal('█'), text.v)
        end
        text.v[index] = char
        text.y[], text.x[] = index2cursor(index, height - 2, width - 2)
        redraw(text)
    end
    nothing
end

function focus(text::TextBox, y::Integer, x::Integer)
    height, width = size(text)
    y -= row(text)
    x -= col(text)
    if 1 <= y < height - 1 && 1 <= x < width - 1
        index = (y - 1) * (width - 2)
        x = findprev(!isequal(' '), text.v[index + 1:index + (width - 2)], x)
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
    style = Style(; bold=has_focus(text), background=text.w.background, foreground=text.w.foreground)
    screen_box(start_r, start_c, height, width; type=BORDER_LIGHT, style)
    height -= 2
    width -= 2
    for y in 1:height
        for x in 1:width
            index = (y - 1) * width + x
            screen_char(text.v[index], start_r + y, start_c + x; style)
        end
    end
    if has_focus(text)
        cursor(start_r + text.y[], start_c + text.x[])
    else
        cursor()
    end
    nothing
end

function value(text::TextBox)
    vector2string(text.v)
end
