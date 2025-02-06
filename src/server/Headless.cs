using Godot;
using System;
using System.Collections.Generic;

/*
    输入：["--a", "abc", "--b", "--c=123", "--d=\"123", "456\"", "-efg"]
    支持：
        -<short1><short2...>(无参数)
        --name [args...](支持assert参数数量)
        --key=value
        --key="value value..."
*/

public partial class Vars{
    public partial class Vars_Headless : Node
    {
        public bool HeadlessClient
        {
            get { return Vars.Core.IsHeadlessClient(); }
        }

        private static Log.Logger _logger = Log.RegisterLogger("Headless");

        public static CommandLineParser parser = new CommandLineParser(
            new List<CommandLineParser.PropertyArg>{
                new ("lang", lang => TranslationServer.SetLocale(lang)),
            }, new List<CommandLineParser.ActionArg>{
                new ("help", ActionHelp, null, "h"),
                new ("load-save", s => ActionLoadSave(s[0]), s => s.Length != 1? "load-save <name>": "", "l"),
                new ("load-preset", s => ActionLoadPreset(s[0]), s => s.Length != 1? "load-preset <presetId>": "", "p"),
                new ("multiplayer-test", s => ActionMultiplayerTest(s[0]), s => s.Length != 1? "multiplayer-test <presetId>": ""),
            }
        );

        public void ApplyArgsFromCmdline()
        {
        }

        public void Restart(string[] args = null)
        {
            _logger.Info("Restarting " + string.Join(" ", args));
            OS.SetRestartOnExit(true, args);
            Exit();
        }

        public void Exit()
        {
            _logger.Info("Exiting");
            Vars.Tree.Quit();
        }

        private static void ActionHelp(string[] args)
        {
            _logger.Info(@"
Properties:
    --lang=<locale> Set language of translation
Actions:
    --help Show this message
    --load-save <name> Load save
    --load-preset <presetId> Load preset
    --multiplayer-test <presetId> Test multiplayer
");
        }

        private static void ActionLoadSave(string saveName)
        {
            Vars.Saves.LoadSave(saveName);
        }

        private static void ActionLoadPreset(string presetId)
        {
            var preset = Vars.Types.GetType(Preset.TYPE, presetId) as Preset;
            if (preset == null)
            {
                _logger.Error($"Unknown preset: {presetId}");
                Exit();
                return;
            }
            Vars.Presets.LoadPreset(preset);
        }

        private static async void ActionMultiplayerTest(string presetId)
        {
            await Vars.Headless.ToSignal(Vars.Tree.CreateTimer(GD.RandRange(0, 0.4f)), "timeout");

            FileAccess file;
            int runId;
            if (FileAccess.FileExists("user://runid"))
            {
                file = FileAccess.Open("user://runid", FileAccess.ModeFlags.Read);
                string s = file.GetAsText();
                file.Close();
                runId = int.Parse(s);
            }
            else
                runId = 0;

            file = FileAccess.Open("user://runid", FileAccess.ModeFlags.Write);
            file.StoreString((runId + 1).ToString());
            file.Close();

            _logger.Info("Runid " + runId);

            if (runId % 2 == 0)
            {
                var preset = Vars.Types.GetType(Preset.TYPE, presetId) as Preset;
                await Vars.Presets.LoadPreset(preset);
                Vars.Server.CreateServer(1234);
            }
            else
            {
                Vars.Tree.CreateTimer(0.1f).Timeout += () =>
                {
                    Vars.Client.ConfigPlayerToken.V = Utils.GenerateToken();
                    Vars.Client.ConnectTo("localhost", 1234);
                };
            }
        }
    }
}
