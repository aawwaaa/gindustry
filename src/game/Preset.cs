using Godot;
using System.Threading.Tasks;

[GDScriptAdapterTarget("GA_Preset")]
[GlobalClass]
public partial class Preset : ResourceType
{
    // Resource type of Preset
    public new static readonly ResourceTypeType Type = new() { Id = "preset" };

    public static void __Resource__StaticInit()
    {
        Vars.Types.RegisterType(Type);
    }

    public override ResourceTypeType _GetType() => Preset.Type;

    // Show description in new_game menu
    // Call when be selected in new_game menu
    public virtual void _ShowDescription(ScrollContainer node)
    {
        // Implement your logic here
    }

    // Call when clicked "confirm" in new_game menu
    // It will be await to wait for user input
    // When returns true, it will continue load preset
    // When returns false, it will back to new_game menu
    public virtual void _PreConfigPreset(CoroutineBridgeResult<bool> c)
    {
        c.Finish(true);
    }
    public void PreConfigPreset(CoroutineBridgeResult<bool> c) => _PreConfigPreset(c);

    // Call when preset is loaded to create a new game, before _EnablePreset
    // Check and assign default value of preset's data
    public virtual void _PreInitPreset()
    {
        // Implement your logic here
    }
    public void PreInitPreset() => _PreInitPreset();

    // Call when preset is loaded to create a new game, after _EnablePreset
    // Do world operations in this method
    public virtual void _InitPreset()
    {
        // Implement your logic here
    }
    public void InitPreset() => _InitPreset();

    // Call when preset is loaded to create a new game, after JoinLocal
    // Vars.game.player is available when in a client
    public virtual void _InitAfterLocalPlayerJoin()
    {
        // Implement your logic here
    }
    public void InitAfterLocalPlayerJoin() => _InitAfterLocalPlayerJoin();

    // Call when world is ready, after _ApplyPreset
    public virtual void _LoadAfterWorldLoad()
    {
        // Implement your logic here
    }
    public void LoadAfterWorldLoad() => _LoadAfterWorldLoad();

    // Call when game ready
    public virtual void _AfterReady()
    {
        // Implement your logic here
    }
    public void AfterReady() => _AfterReady();

    // Call when preset is enabled, after _InitPreset(if runned), before _LoadAfterWorldLoad
    public virtual void _ApplyPreset()
    {
        // Implement your logic here
    }
    public void ApplyPreset() => _ApplyPreset();

    // Call when game reset
    // Reset datas of preset in this method
    // Free objects in this method
    public virtual void _ResetPreset()
    {
        // Implement your logic here
    }
    public void ResetPreset() => _ResetPreset();

    // Get the translation name of preset, will be as argument to `tr`
    public virtual string _GetTrName() => Tr(FullId);
    public string Name => _GetTrName();

    // Call when preset is loaded, after _LoadPresetData
    // Datas of preset is ready
    // Enable preset in this method
    public virtual void _EnablePreset()
    {
        // Implement your logic here
    }
    public void EnablePreset() => _EnablePreset();

    // Call when game reset, before _ResetPreset
    // Disable preset in this method
    public virtual void _DisablePreset()
    {
        // Implement your logic here
    }
    public void DisablePreset() => _DisablePreset();

    // Call when game load
    // Load preset data in this method
    public virtual void _LoadPresetData(Reader r)
    {
    }
    public void LoadPresetData(Reader r) => _LoadPresetData(r);

    // Call when game save
    // Save preset data in this method
    public virtual void _SavePresetData(Writer w)
    {
    }
    public void SavePresetData(Writer w) => _SavePresetData(w);

    /*
    pre_config -> true -> enable -> init -> load -> ...
               -> false -> back_to_menu
    load_preset_data -> enable -> load -> ...
    ... -> save_preset_data -> ... -> disable_preset
    */
}
