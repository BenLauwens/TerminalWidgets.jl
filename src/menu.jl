struct MenuItem <: FocusableWidget
    w::ElementaryWidgetInternal
    str::String
    function MenuItem(handler::Function, str::String;
        width::Integer=length(str),
        background::Color=APP[].w.background,
        foreground::Color=APP[].w.foreground
    )
        w = ElementaryWidgetInternal(; height=1, width, background, foreground)
        menuitem = new(w, str)
        on(menuitem, :click; key="\r") do _::MenuItem
            handler()
        end
        menuitem
    end
end

function redraw(menuitem::MenuItem)
    r = row(menuitem)
    c = col(menuitem)
    screen_string(menuitem.str, r, c;
        style=Style(; bold=has_focus(menuitem), background=menuitem.w.background, foreground=menuitem.w.foreground))
    nothing
end

function handle_mouse(menuitem::MenuItem, _::Integer, _::Integer)
    emit(menuitem, :click)
    nothing
end

struct Menu <: FocusableWidget
    w::VerticalContainerWidgetInternal
    str::String
    visible::Ref{Bool}
    function Menu(str::String;
        background::Color=APP[].w.background,
        foreground::Color=APP[].w.foreground
    )
        w = VerticalContainerWidgetInternal(;background, foreground)
        menu = new(w, str, Ref(false))
        on(menu, :click; key="\r") do menu::Menu
            menu.visible[] = !menu.visible[]
            redraw(APP[])
        end
        menu
    end
end

function add(menu::Menu, menuitem::MenuItem)
    push!(menu.w.childs, menuitem)
    menuitem.w.row[] = row(menu) + length(menu.w.childs) + 1
    menuitem.w.col[] = col(menu) + 1
    menuitem.w.parent[] = menu
    nothing
end

function inside(menu::Menu, r::Integer, c::Integer)
    if menu.visible[]
        row(menu) <= r < row(menu) + height(menu.w) + 3 &&
            col(menu) <= c < col(menu) + width(menu.w) + 2
    else
        row(menu) <= r < row(menu) + 1 &&
            col(menu) <= c < col(menu) + length(menu.str)
    end
end

function handle_mouse(menu::Menu, row::Integer, col::Integer)
    if menu.visible[]
        for menuitem in menu.w.childs
            if inside(menuitem, row, col)
                handle_mouse(menuitem, row, col)
            end
        end
    end
    emit(menu, :click)
    nothing
end

function redraw(menu::Menu)
    r = row(menu)
    c = col(menu)
    screen_string(menu.str, r, c;
        style=Style(; bold=has_focus(menu), background=menu.w.background, foreground=menu.w.foreground))
    if menu.visible[]
        screen_box(r+1, c, height(menu.w)+2, width(menu.w)+2;
        type=BORDER_LIGHT, style=Style(; background=menu.w.background, foreground=menu.w.foreground))
        for menuitem in menu.w.childs
            redraw(menuitem)
        end
    end
    nothing
end
