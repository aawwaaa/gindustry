using Godot;
using System;

public partial class GameManager: Node
{
    // ModulesGame
    public void GameResetModules()
    {
        Vars.objects.ModuleGameReset();
    }

    public void GameInitModules()
    {
        Vars.objects.ModuleGameInit();
    }

    public void GameReadyModules()
    {
        Vars.objects.ModuleGameReady();
    }

    public void GameLoadModules(IReadableStream stream)
    {
        Vars.objects.ModuleGameLoad(stream);
    }

    public void GameSaveModules(IWritableStream stream)
    {
        Vars.objects.ModuleGameSave(stream);
    }

}
