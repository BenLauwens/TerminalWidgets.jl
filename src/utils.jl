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
