using Gindustry;
using Godot;
using System;

namespace builtin.ui;

public partial class MainUi : Control
{
    Loading loading;
    MainMenu mainMenu;

    Control layers;
    Tests tests;
    public override void _Ready()
    {
        Vars.MainUi = this;
        loading = GetNode<Loading>("%Loading");
        mainMenu = GetNode<MainMenu>("%MainMenu");
        layers = GetNode<Control>("%Layers");
        Vars.Core.StateChangedGeneric += StateChanged;
        LoadMainMenuButtons();
    }

    public void StateChanged(Vars.State state, Vars.State from)
    {
        loading.Visible = state == Vars.State.Loading || state == Vars.State.LoadingGame;
        mainMenu.Visible = state == Vars.State.MainMenu;
    }

    public void LoadUi(Log.ProgressTracker progress)
    {
        progress.Name = "Loading ui";
        var quitButton = mainMenu.AddButton("MainMenu_Quit", () => Vars.Core.Exit("MainMenu"));
        quitButton.SizeFlagsVertical = SizeFlags.Expand | SizeFlags.ShrinkEnd;
        if (Vars.Core.IsEditorEnvironment())
        {
            tests = GD.Load<PackedScene>("uid://17j7hp4jnmun" /* tests.tscn */).Instantiate<Tests>();
            layers.AddChild(tests);
            tests.Visible = false;
            tests.LoadUi();
        }
        progress.Progress += 10;
    }

    private void LoadMainMenuButtons()
    {
        mainMenu.AddButton("MainMenu_NewGame", () => mainMenu.ShowContent("MainMenu_NewGame"));
        mainMenu.AddButton("MainMenu_LoadGame", () => mainMenu.ShowContent("MainMenu_LoadGame"));
        mainMenu.AddButton("MainMenu_Mods", () => mainMenu.ShowContent("MainMenu_Mods"));
        mainMenu.AddButton("MainMenu_Configs", () => mainMenu.ShowContent("MainMenu_Configs"));
        if (Vars.Core.IsEditorEnvironment())
        {
            mainMenu.AddButton("MainMenu_Tests", () => tests.Visible = true);
        }
    }
}
