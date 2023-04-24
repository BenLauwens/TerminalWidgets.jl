using TerminalWidgets

let
    init()
    on(:quit; key="q") do
        exit()
    end
    label = Label("Hello, World"; width=20, align=ALIGN_CENTER)
    add(label, 5, 5)
    button1 = Button("The winner takes it all!"; foreground=RED) do
        error("My Mistake!")
    end
    add(button1, 8, 10)
    button2 = Button("The loser gets nothing!") do
        exit()  
    end 
    add(button2, 12, 10)
    checkbox = CheckBox("Check me!")
    add(checkbox, 3, 20)
    on(button1, :next; key=KEY_TAB) do
        focus(button2)
    end
    on(button2, :next; key=KEY_TAB) do
        focus(checkbox)
    end
    on(checkbox, :next; key=KEY_TAB) do
        focus(button1)
    end
    try
        run()
    catch err
        print(stdout, "\e[?1049l")
        rethrow()
    end
end
