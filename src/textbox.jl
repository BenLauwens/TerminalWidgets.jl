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
        text = new(w, v, Ref{Int}(1), Ref{Int}(1))
        on(text, :up; key=KEY_UP) do
            index = cursor2index(text.y[], text.x[], width)
            index = findprev(!isequal(' '), text.v, index - width)
            if index !== nothing  && index >= 1
                text.y[], text.x[] = index2cursor(index, height, width)
                redraw(text)
            end
        end
        on(text, :down; key=KEY_DOWN) do
            index = cursor2index(text.y[], text.x[], width)
            index = findprev(!isequal(' '), text.v, index + width)
            if index !== nothing  && index <= width * height
                text.y[], text.x[] = index2cursor(index, height, width)
                redraw(text)
            end
        end
        on(text, :left; key=KEY_LEFT) do
            index = cursor2index(text.y[], text.x[], width)
            index = findprev(!isequal(' '), text.v, index - 1)
            if index !== nothing && index >= 1
                text.y[], text.x[] = index2cursor(index, height, width)
                redraw(text)
            end
        end
        on(text, :right; key=KEY_RIGHT) do
            index = cursor2index(text.y[], text.x[], width)
            index = findnext(!isequal(' '), text.v, index + 1)
            if index !== nothing && index <= width * height
                text.y[], text.x[] = index2cursor(index, height, width)
                redraw(text)
            end
        end
        text
    end
end

function handle_mouse(text::TextBox, row::Integer, col::Integer)
    emit(text, :click, row::Integer, col::Integer)
    nothing
end

function handle_key(text::TextBox, input::String)
    sig = get(text.w.keys, input, :nothing)
    if !emit(text, sig)
        if length(input) === 1
            normal_key(text, input[begin])
        elseif text !== APP[]
            handle_key(text.w.parent[], input)
        end
    end
    nothing
end

function normal_key(text::TextBox, char::Char)
    if char === ' '
        char = '␣'
    elseif char === '\r'
        char = '⮐'
    elseif char === '\x7f'
        char = '⌫'
    elseif iscntrl(char)
        return
    end
    width = size(text, 2) - 2
    index = cursor2index(text.y[], text.x[], width)
    insert!(text.v, index, char)
    process(text, index + 1)
    redraw(text)
    nothing
end

function process(text::TextBox, index::Integer)
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
