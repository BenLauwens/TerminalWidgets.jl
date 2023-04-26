struct App <: Widget
    w::TopWidgetInternal
    focus::Ref{FocusableWidget}
    x::Ref{Int}
    y::Ref{Int}
    function App(w::TopWidgetInternal)
        new(w, Ref{FocusableWidget}(), Ref{Int}(0), Ref{Int}(0))
    end
end

function row(app::App)
    1
end

function col(app::App)
   1
end

const APP = Ref{App}()

function cursor(y::Integer=0, x::Integer=0)
    app = APP[]
    app.y[] = y
    app.x[] = x
    nothing
end

function add(child::Widget, row::Integer, col::Integer)
    add(APP[], child, row, col)
end

function on(handler::Function, signal::Symbol; key::String="")
    on(handler, APP[], signal; key)
end

function init(; char::Char=' ', background::Color=COLOR_BLACK, foreground::Color=COLOR_GREEN)
    screen_init(; char, background, foreground)
    w = TopWidgetInternal(; background, foreground)
    APP[] = App(w)
    nothing
end

function Base.run()
    app = APP[]
    redraw(app)
    while true
        screen_refresh(app.y[], app.x[])
        input = screen_input()
        if startswith(input, "\e[M ")
            mouse = transcode(UInt8, input[5:6])
            row = Int(mouse[2]) - 32
            col = Int(mouse[1]) - 32
            handle_mouse(app, row, col)
        else
            handle_key(app.focus[], input)
        end
    end
end
