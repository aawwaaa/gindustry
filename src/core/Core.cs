using Gindustry.Object;
using Gindustry.Utils;
using Godot;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Gindustry;

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
            Vars.Headless.CallDeferred("ApplyArgsFromCmdline");
        }

        public bool IsHeadlessClient()
        {
            return DisplayServer.GetName() == "headless";
        }
        public bool IsEditorEnvironment()
        {
            return OS.HasFeature("editor");
        }

        public async Task StartLoad()
        {
            Headless.LoadMultiInstanceId();
            state.SetState(State.Loading);
            // 如果在编辑器环境下，等待5秒以便调试器附加
            if (IsEditorEnvironment())
            {
                Logger.Info("Editor environment detected, waiting up to 1 seconds for debugger to attach...");
                for (int i = 0; i < 10; i++)
                {
                    if (System.Diagnostics.Debugger.IsAttached)
                    {
                        Logger.Info("Debugger attached, continuing immediately.");
                        break;
                    }
                    await ToSignal(GetTree().CreateTimer(0.1f), "timeout");
                }
            }
            var progress = Log.RegisterProgressTracker(100, "Loading", logger.source);
            progress.Name = "Loading GA";
            GA.Instance.LoadStatics();
            progress.Progress += 1;

            progress.Name = "Searching mods";
            Mods.SearchModFolder("res://mods/");
            Mods.SearchModFolder("user://mods/");
            Mods.LoadEnableConfigs();
            progress.Progress += 4;

            progress.Name = "Checking dependencies";
            var errors = Mods.CheckErrors();
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
                foreach (var info in Mods.ModInfoList.Values)
                {
                    info.Enabled = false;
                }
                await ToSignal(GetTree().CreateTimer(3), "timeout");
                progress.Progress = progress.Total;
                Mods.DisplayOrder = [.. Mods.ModInfoList.Keys];
                // Main.GetWindowNode("Mods").Call("load_mod_list");
                return;
            }

            progress.Name = "Loading configs";
            Configs.LoadConfigs();
            // Main.GetWindowNode("Settings").Call("load_tabs");
            progress.Progress += 5;

            progress.Name = "Loading mods";
            await Mods.LoadModsInit();
            progress.Progress += 10;
            await Mods.LoadModsContents();
            progress.Progress += 20;
            await Mods.LoadModsAssets();
            progress.Progress += 20;
            await Mods.LoadModsPost();
            progress.Progress += 10;
            progress.Name = "Loading saves";
            Saves.LoadSaves();
            progress.Progress += 15;

            if (IsEditorEnvironment()) 
            {
                progress.Name = "Discovering tests";
                await Tests.DiscoverTestsDir("res://test");
            }
            progress.Progress += 5;

            MainUi.LoadUi(progress); // 10

            Game.ResetGame();
            progress.Finish();
        }

        public void Exit(string reason = "")
        {
            if (reason != "")
                logger.Info("Exit: " + reason);
            GetTree().Quit();
        }
    }
}
