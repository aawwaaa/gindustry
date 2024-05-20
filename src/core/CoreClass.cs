using Godot;
using System;

public partial class CoreClass: Node
{
    public Log.Logger logger = Log.CreateLogger("core_log_source");

    // GameState
    public enum GameState
    {
        Loading, MainMenu, PresetConfifg, LoadingGame, InGame
    }
    /*
        Available changing:
            <Null> => Loading                        // init
            Loading => MainMenu                      // load finished
            MainMenu => PresetConfig                 // preset selected
            MainMenu => LoadingGame                  // load save/multiplayer load world data 
            PresetConfig => LoadingGame              // new game
            PresetConfig => MainMenu                 // cancel
            LoadingGame => InGame                    // game loaded
            InGame => MainMenu                       // back to main menu
        Auto execute:
            * => MainMenu               : Show main menu
            MainMenu => *               : Hide main menu
            * => Loading/LoadingGame    : Show loading ui
            Loading/LoadingGame => *    : Hide loading ui
            LoadingGame => InGame       : Ready game
            * => InGame                 : Show game ui
            InGame => *                 : Reset game, Hide game ui
    */
    public readonly StateMachine state = new StateMachine();

    public GameState GetState()
    {
        if (state.State == StateMachine.NOT_INITIALZIED) return GameState.Loading;
        return (GameState)state.State;
    }
    public void SetState(GameState newState)
    {
        state.SetState((int)newState);
    }
    public bool IsLoading()
    {
        return GetState() == GameState.Loading || GetState() == GameState.LoadingGame;
    }
    public bool IsInGame()
    {
        return GetState() == GameState.InGame;
    }
    public bool IsInMenu()
    {
        return GetState() == GameState.MainMenu || GetState() == GameState.PresetConfifg;
    }

    public override void _Ready()
    {
        state.Name = "State";
        AddChild(state);

        Log.OnProgressAllFinished += OnLogProgressesAllFinished;
        state.StateChanged += OnStateStateChanged;
    }

    protected void OnLogProgressesAllFinished()
    {
        if (GetState() != GameState.Loading) return;
        SetState(GameState.MainMenu);
    }

    protected void OnStateStateChanged(int newState, int oldState)
    {
        string newStateName = Enum.GetName(typeof(GameState), newState);
        string oldStateName = oldState == StateMachine.NOT_INITIALZIED? "<Null>": Enum.GetName(typeof(GameState), oldState);
        logger.Info(Tr("core_state_changed {src} => {dst}")
                .Fmt("src", oldStateName)
                .Fmt("dst", newStateName));
    }

    public void StartLoad()
    {
        Log.Progress progress = Log.CreateProgress("core_loading", "", 100);
        state.SetState((int)GameState.Loading);
        progress.Finish();
    }
}
