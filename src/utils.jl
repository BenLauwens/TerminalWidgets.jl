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

function string2vector(str::String, height::Integer, width::Integer)
    v = Vector{Char}()
    col = 1
    for phrase in eachsplit(str, '\n')
        for word in eachsplit(phrase, ' ')
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
            push!(v, word..., '␣')
            col += len + 1

        end
        v[end] = '⮐'
        push!(v, ' '^(width - col + 1)...)
        col = 1
    end
    if length(v) < height * width
        push!(v, ' '^(height * width)...)
    end
    v
end

function vector2string(v::Vector{Char})
    v = replace(filter(!isequal(' '), v), '⮐' => '\n', '␣' => ' ')
    join(v)
end

function string2matrix(str::String, height::Integer, width::Integer)
    mat = fill(' ', width + 1, height)
    row = 1
    col = 1
    str = rstrip(str) * ' '
    for (index, char) in enumerate(str)
        if char === '\n'
            char = '⏎'
        end
        if col === width + 1
            if char !== ' '
                col = 1
                row += 1
            end
        end
        sp = findnext(isequal(' '), str, index + 1)
        if char !== ' ' && col + sp - index > width + 2
            if col !== 1
                row += 1
                col = 1
            end
        end
        if row > height
            break
        end
        mat[col, row] = char
        if char === '⏎'
            col = 1
            row += 1
        else
            col += 1
        end
    end
    mat
end
