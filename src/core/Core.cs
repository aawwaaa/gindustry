using Godot;
using System;
using System.Collections.Generic;

public partial class Vars{
    public enum State
    {
        None = -1,
        Loading = 0,
        MainMenu = 1,
        PresetConfig = 2,
        LoadingGame = 3,
        InGame = 4,
        ResetingGame = 5
    }

    public partial class Vars_Core : Node
    {
        [Signal]
        public delegate void StateChangedEventHandler(int state, int from);
        public delegate void StateChangedGenericEventHandler(State state, State from);

        public event StateChangedGenericEventHandler StateChangedGeneric;

        public readonly StateMachineGeneric<State> state = new(State.None);
        private Log.Logger logger = Log.RegisterLogger("Core");

        public override void _Ready()
        {
            state.StateChanged += (s, f) => EmitSignal(SignalName.StateChanged, (int)s, (int)f);
            state.StateChanged += (s, f) => StateChangedGeneric?.Invoke(s, f);

            Log.AllProgressTrackerFinished += OnAllProgressTrackersFinished;
        }

        public bool IsInGame()
        {
            return state.GetState() == State.InGame;
        }

        public bool IsInMainMenu()
        {
            return state.GetState() == State.MainMenu;
        }

        public bool IsInLoading()
        {
            State currentState = state.GetState();
            return currentState == State.Loading || currentState == State.LoadingGame || currentState == State.ResetingGame;
        }

        public State GetState()
        {
            return state.GetState();
        }

        public void SetState(State v)
        {
            state.SetState(v);
        }

        public void InitConfigs()
        {
            if (!DirAccess.DirExistsAbsolute("user://mods/"))
            {
                DirAccess.MakeDirAbsolute("user://mods/");
            }
            if (!DirAccess.DirExistsAbsolute("user://saves/"))
            {
                DirAccess.MakeDirAbsolute("user://saves/");
            }
        }

        private void OnAllProgressTrackersFinished()
        {
            if (state.GetState() != State.Loading)
                return;
            state.SetState(State.MainMenu);
            Vars.Headless.ApplyArgsFromCmdline();
        }

        public bool IsHeadlessClient()
        {
            return DisplayServer.GetName() == "headless";
        }

        public async void StartLoad()
        {
            state.SetState(State.Loading);
            var progress = Log.RegisterProgressTracker(100, "Loading", logger.source);
            progress.Name = "Searching mods";
            Vars.Mods.SearchModFolder("res://mods/");
            Vars.Mods.SearchModFolder("user://mods/");
            Vars.Mods.LoadEnableConfigs();
            progress.Progress += 5;

            progress.Name = "Checking dependencies";
            var errors = Vars.Mods.CheckErrors();
            if (errors.Count != 0)
            {
                var message = new System.Text.StringBuilder();
                foreach (var source in errors.Keys)
                {
                    message.Append(source + "\n");
                    foreach (var error in errors[source])
                        message.Append("  - " + error + "\n");
                }
                Logger.Error($"Mod dependency error: \n{message.ToString()}");
                foreach (var info in Vars.Mods.ModInfoList.Values)
                {
                    info.Enabled = false;
                }
                await ToSignal(GetTree().CreateTimer(3), "timeout");
                progress.Progress = progress.Total;
                Vars.Mods.DisplayOrder = new List<string>(Vars.Mods.ModInfoList.Keys);
                // Vars.Main.GetWindowNode("Mods").Call("load_mod_list");
                return;
            }

            progress.Name = "Loading configs";
            Vars.Configs.LoadConfigs();
            // Vars.Main.GetWindowNode("Settings").Call("load_tabs");
            progress.Progress += 5;

            progress.Name = "Loading mods";
            await Vars.Mods.LoadModsInit();
            progress.Progress += 10;
            await Vars.Mods.LoadModsContents();
            progress.Progress += 20;
            await Vars.Mods.LoadModsAssets();
            progress.Progress += 20;
            await Vars.Mods.LoadModsPost();
            progress.Progress += 10;
            progress.Name = "Loading saves";
            Vars.Saves.LoadSaves();
            progress.Progress += 20;

            // Vars.Main.LoadUi(progress);

            Vars.Game.ResetGame();
            progress.Finish();
        }
    }
}
