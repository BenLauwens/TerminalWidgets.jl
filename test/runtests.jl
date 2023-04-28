using TerminalWidgets
using TerminalBase
using REPL

let
    init()
    on(:quit; key="q") do
        exit()
    end
    label = Label("Hello, World"; width=20, align=ALIGN_CENTER)
    add(label, 1, 1)
    button1 = Button("The winner takes it all!"; foreground=COLOR_RED) do
        error("My Mistake!")
    end
    add(button1, 8, 1)
    button2 = Button("The loser gets nothing!") do
        exit()
    end
    add(button2, 12, 10)
    checkbox = CheckBox("Check me!")
    add(checkbox, 3, 20)
    multi = MultiSelect(["A", "B", "C", "D"])
    add(multi, 5, 50)
    radio = RadioGroup(["E", "F", "G", "H"])
    add(radio, 11, 50)
    text = TextBox("Dit is een natuurvoorbeeld van een te splitsen tekst.\nIk weet niet hoe goed dit kan gebeuren met dit programma!\n\n  Hoera"; width=14, height=13)
    add(text, 2, 75)
    on(button1, :next; key=KEY_TAB) do
        focus(button2)
    end
    on(button2, :next; key=KEY_TAB) do
        focus(multi)
    end
    on(multi, :next; key=KEY_TAB) do
        focus(radio)
    end
    on(radio, :next; key=KEY_TAB) do
        focus(text)
    end
    on(text, :next; key=KEY_TAB) do
        focus(checkbox)
    end
    on(checkbox, :next; key=KEY_TAB) do
        focus(button1)
    end
    try
        run()
    catch err
        terminal = TerminalBase.SCREEN[].terminal
        print(terminal, TerminalBase.TerminalCommand("?1000l"))
        print(terminal, TerminalBase.TerminalCommand("?25h"))
        #print(terminal, TerminalBase.TerminalCommand("?1049l"))
        REPL.Terminals.raw!(terminal, false)
        rethrow()
    end
end
