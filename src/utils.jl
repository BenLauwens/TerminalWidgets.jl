struct Align
    v::Symbol
end

const ALIGN_LEFT = Align(:left)
const ALIGN_RIGHT = Align(:right)
const ALIGN_CENTER = Align(:center)

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

function cursor2index(y::Integer, x::Integer, width::Integer)
    (y - 1) * width + x
end

function index2cursor(index::Integer, height::Integer, width::Integer)
    y, x = divrem(index - 1, width)
    y = y + 1
    x = x + 1
    if x > width
        if y < height
            x = 1
            y += 1
        else
            x -= 1
        end
    end
    y, x
end

function word2vector(word::SubString{String}, v::Vector, width::Integer, col::Integer, spacekey::Char='␣')
    word = collect(word)
    if col === width
        push!(v, ' ')
        col = 1
    end
    len = length(word)
    if len > width - 1
        if col !== 1
            push!(v, ' '^(width - col + 1)...)
        end
        while len > width - 1
            push!(v, word[1:width-1]..., ' ')
            word = word[width:end]
            len = length(word)
        end
        col = 1
    elseif col + len > width
        push!(v, ' '^(width - col + 1)...)
        col = 1
    end
    push!(v, word..., spacekey)
    col += len + 1
end

function phrase2vector(phrase::SubString{String}, v::Vector, width::Integer, enterkey::Char='⮐')
    col = 1
    for word in eachsplit(phrase, ' ')
        if ' ' in word
            special, word = split(word, ' ')
            col = word2vector(special, v, width, col, ' ')
        end
        col = word2vector(word, v, width, col)
    end
    v[end] = enterkey
    push!(v, ' '^(width - col + 1)...)
end

function string2vector(str::String, height::Integer, width::Integer)
    v = Vector{Char}()
    for phrase in eachsplit(str, '\n')
        if '⏎' ∈ phrase
            special, phrase = split(phrase, '⏎')
            phrase2vector(special, v, width, '⏎')
        end
        phrase2vector(phrase, v, width)
    end
    if length(v) < height * width
        push!(v, ' '^(height * width - length(v))...)
    end
    v
end

function vector2string(v::Vector{Char})
    v = replace(filter(!isequal(' '), v), '⮐' => '\n', '␣' => ' ')
    index = findfirst(isequal('⌫'), v)
    if index !== nothing
        if index === 1
            deleteat!(v, index)
        else
            deleteat!(v, index-1:index)
        end
    end
    join(v)
end
