using Godot;
using System.Collections.Generic;

public partial class Vars
{
    public partial class Vars_Presets : Node
    {
        private Log.Logger logger = Log.RegisterLogger("Presets_LogSource");

        public class PresetGroup
        {
            public string GroupName { get; set; } = "unnamed";
            public List<Preset> Presets { get; set; } = new List<Preset>();

            public void Add(Preset preset) => Presets.Add(preset);
        }

        private List<PresetGroup> presetGroups = new List<PresetGroup>();
        private Dictionary<string, PresetGroup> presetGroupsMap = new Dictionary<string, PresetGroup>();

        public PresetGroup RegisterPresetGroup(string groupName)
        {
            if (presetGroupsMap.ContainsKey(groupName))
                return presetGroupsMap[groupName];

            var group = new PresetGroup
            {
                GroupName = groupName
            };

            presetGroups.Add(group);
            presetGroupsMap[groupName] = group;
            return group;
        }

        public List<PresetGroup> GetPresetGroups() => presetGroups;

        public async void LoadPreset(Preset preset)
        {
            logger.Info($"Load preset {preset.FullId}");

            Vars.Core.state.SetState(State.PresetConfig);
            preset.PreConfigPreset(new(out var task));
            var result = await task;

            if (!result)
            {
                Vars.Core.state.SetState(State.MainMenu);
                return;
            }

            Vars.Game.StartGameLoad();
            Vars.Game.InitGame();
            Vars.Game.SavePreset = preset;
            preset.PreInitPreset();
            preset.EnablePreset();
            preset.InitPreset();
            preset.ApplyPreset();
            preset.LoadAfterWorldLoad();
            Vars.Game.MakeReadyGame();
            var player = Vars.Client.JoinLocal();
            preset.InitAfterLocalPlayerJoin();
            Vars.Game.EnterGame();
            preset.AfterReady();
        }
    }
}
