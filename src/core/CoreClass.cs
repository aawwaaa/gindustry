using Godot;
using System;

public partial class CoreClass: Node
{
    public Log.Logger logger = Log.CreateLogger("core-log-source");

    // GameState
    public enum GameState
    {
        Loading, MainMenu, PresetConfifg, LoadingGame, InGame, ResetingGame
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
            * => MainMenu               : Show main menu TODO
            MainMenu => *               : Hide main menu TODO
            * => Loading/LoadingGame    : Show loading ui TODO
            Loading/LoadingGame => *    : Hide loading ui TODO
            LoadingGame => InGame       : Ready game DOING
            * => InGame                 : Show game ui TODO
            InGame => *                 : Reset game DOING, Hide game ui TODO
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
        return GetState() == GameState.Loading || GetState() == GameState.LoadingGame || GetState() == GameState.ResetingGame;
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

        Log.ProgressAllFinished += OnLogProgressesAllFinished;
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
        logger.Info(Tr("core-state-changed {src} => {dst}")
                .Fmt("src", Tr("core-state-" + oldStateName))
                .Fmt("dst", Tr("core-state-" + newStateName)));
    }

    public void StartLoad()
    {
        Log.Progress progress = Log.CreateProgress("core-loading", "", 100);
        state.SetState((int)GameState.Loading);
        progress.Finish();
    }
}
