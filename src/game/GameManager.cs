using Godot;
using System;
using static CoreClass;

public partial class GameManager: Node
{
    public bool Paused{ get; protected set; }

    // ModulesGame
    public void GameResetModules()
    {
        ModuleGameReset();
        Vars.objects.ModuleGameReset();
    }

    public void GameInitModules()
    {
        ModuleGameInit();
        Vars.objects.ModuleGameInit();
    }

    public void GameReadyModules()
    {
        ModuleGameReady();
        Vars.objects.ModuleGameReady();
    }

    public void GameLoadModules(IReadableStream stream)
    {
        ModuleGameLoad(stream);
        Vars.objects.ModuleGameLoad(stream);
    }

    public void GameSaveModules(IWritableStream stream)
    {
        ModuleGameSave(stream);
        Vars.objects.ModuleGameSave(stream);
    }

    public void ModuleGameReset()
    {
        SetPausedRpc(false);
    }

    public void ModuleGameInit()
    {

    }

    public void ModuleGameReady()
    {

    }

    public void ModuleGameLoad(IReadableStream stream)
    {

    }

    public void ModuleGameSave(IWritableStream stream)
    {

    }
    
    protected void OnStateStateChanged(GameState newState, GameState oldState)
    {
        if (oldState == GameState.LoadingGame && newState == GameState.InGame)
        {
            GameReadyModules();
        }
        if (oldState == GameState.InGame && newState == GameState.ResetingGame)
        {
            GameResetModules();
        }
    }

    public void SetPausedRpc(bool paused)
    {
        Paused = paused;
        Vars.tree.Paused = paused;
    }

    public void InitGame()
    {
        Vars.core.SetState(GameState.LoadingGame);
        GameInitModules();
        Vars.core.SetState(GameState.InGame);
    }

    public void ResetGame()
    {
        Vars.core.SetState(GameState.ResetingGame);

        Vars.core.SetState(GameState.MainMenu);
    }
}
