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
            index = cursor2index(text.y[], text.x[], width)
            move_cursor(text, index - width)
            nothing
        end
        on(text, :down; key=KEY_DOWN) do text::TextBox
            width = size(text, 2) - 2
            index = cursor2index(text.y[], text.x[], width)
            move_cursor(text, index + width)
            nothing
        end
        on(text, :left; key=KEY_LEFT) do text::TextBox
            width = size(text, 2) - 2
            index = cursor2index(text.y[], text.x[], width)
            move_cursor(text, index - 1)
            nothing
        end
        on(text, :right; key=KEY_RIGHT) do text::TextBox
            width = size(text, 2) - 2
            index = cursor2index(text.y[], text.x[], width)
            move_cursor(text, index + 1)
            nothing
        end
        on(text, :keypress) do text::TextBox, input::String
            char, offset = if input === " "
                '␣', false
            elseif input === KEY_ENTER
                '⮐', false
            elseif input === KEY_BACKSPACE || input === '\b'
                '⌫', false
            elseif input === KEY_DELETE
                '␡', true
            elseif iscntrl(input[begin])
                return nothing
            else
                input[begin], false
            end
            width = size(text, 2)
            index = cursor2index(text.y[], text.x[], width - 2)
            insert!(text.v, index, char)
            process_insert(text, index, offset)
            redraw(text)
            nothing
        end
        text
    end
end

function move_cursor(text::TextBox, index:: Integer)
    height, width = size(text)
    height -= 2
    width -= 2
    index = findprev(!isequal(' '), text.v, min(max(1, index), width * height))
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
    if !emit(text, sig) && !emit(text, :keypress, input)
        handle_key(text.w.parent[], input)
    end
    nothing
end

function process_insert(text::TextBox, index::Integer, offset::Bool)
    index = if offset
        index = findnext(!isequal(' '), text.v, index+2)
        if index === nothing
            push!(text.v, '⮐')
            length(text.v)
        else
            index
        end
    else
        index + 1
    end
    height, width = size(text)
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
