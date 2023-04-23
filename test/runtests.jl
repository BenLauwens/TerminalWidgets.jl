using TerminalWidgets

let
    app = App()
    on(app, :quit, app::App->exit(); key="q")
    label = Label("Hello, World"; background=BLUE, foreground=WHITE, width=20, align=ALIGN_CENTER)
    add(app, label, 5, 5)
    button1 = Button("The winner takes it all!", button::Button->error("My mistake!"); background=BLACK, foreground=RED)
    add(app, button1, 8, 10)
    button2 = Button("The loser gets nothing!", button::Button->exit())
    on(button1, :next, button::Button->change_focus(button, button2); key=KEY_TAB)
    on(button2, :next, button::Button->change_focus(button, button1); key=KEY_TAB)
    add(app, button2, 12, 10)
    try
        run(app)
    catch err
        print(stdout, "\e[?1049l")
        rethrow()
    end
end
