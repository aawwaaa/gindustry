using Gindustry.Utils;
using Godot;
using System;
using System.Collections.Generic;
using Gindustry.Content;
using Gindustry.Object;
using Gindustry.IO;
using Gindustry.Game;

namespace Gindustry;

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
                new ("lang", TranslationServer.SetLocale),
                new ("multi-instance-id", Log.SetMultiInstanceId),
            }, new List<CommandLineParser.ActionArg>{
                new ("help", ActionHelp, null, "h"),
                new ("load-save", s => ActionLoadSave(s[0]), s => s.Length != 1? "load-save <name>": "", "l"),
                new ("load-preset", s => ActionLoadPreset(s[0]), s => s.Length != 1? "load-preset <presetId>": "", "p"),
                new ("create-server", s => ActionCreateServer(s[0]), s => s.Length != 1? "create-server <port>": ""),
                new ("test", ActionTest, null),
                new ("multiplayer-test", s => ActionMultiplayerTest(s.Length > 0 ? s[0] : null), null),
            }
        );

        public void ApplyArgsFromCmdline()
        {
            var args = OS.GetCmdlineUserArgs();
            parser.Parse(args);
        }

        public void Restart(string[] args = null)
        {
            _logger.Info("Restarting " + string.Join(" ", args));
            OS.SetRestartOnExit(true, args);
            Exit();
        }

        public static void Exit()
        {
            _logger.Info("Exiting");
            Vars.Tree.Quit();
        }

        public void LoadMultiInstanceId()
        {
            var args = OS.GetCmdlineUserArgs();
            foreach(var arg in args) {
                if (arg.StartsWith("--multi-instance-id=")) {
                    Log.SetMultiInstanceId(arg.Substring("--multi-instance-id=".Length));
                }
            }
        }

        private static void ActionHelp(string[] args)
        {
            _logger.Info(@"
Properties:
    --lang=<locale> Set language of translation
    --multi-instance-id=<id> Set multi instance id for logging
Actions:
    --help Show this message
    --load-save <name> Load save
    --load-preset <presetId> Load preset
    --create-server <port> Create server on specified port
    --test [group] [test] Run tests (all tests, specific group, or specific test)
    --multiplayer-test <presetId> Test multiplayer with preset
");
        }

        private static void ActionLoadSave(string saveName)
        {
            Vars.Saves.LoadSave(saveName);
        }

        private static void ActionLoadPreset(string presetId)
        {
            var preset = Preset.Type.Get<Preset>(presetId);
            if (preset == null)
            {
                _logger.Error($"Unknown preset: {presetId}");
                Exit();
                return;
            }
            Vars.Presets.LoadPreset(preset).Wait();
        }

        private static void ActionCreateServer(string portStr)
        {
            if (!int.TryParse(portStr, out int port) || port < 1 || port > 65535)
            {
                _logger.Error($"Invalid port number: {portStr}. Port must be between 1 and 65535.");
                Exit();
                return;
            }

            try
            {
                _logger.Info($"Creating server on port {port}");
                Vars.Server.CreateServer(port);
                _logger.Info($"Server created successfully on port {port}");
            }
            catch (Exception e)
            {
                _logger.Error($"Failed to create server on port {port}: {e.Message}");
                Exit();
            }
        }

        private static void ActionTest(string[] args)
        {
            try
            {
                if (args.Length == 0)
                {
                    // Run all tests
                    _logger.Info("Running all tests...");
                    int totalTests = 0;
                    int failedTests = 0;
                    
                    foreach (var group in Vars.Tests.groups.Values)
                    {
                        group.RunAll(testResults => 
                        {
                            foreach (var result in testResults.Values)
                            {
                                totalTests++;
                                if (result.failed)
                                    failedTests++;
                            }
                        });
                    }
                    
                    _logger.Info($"Test results: {totalTests - failedTests}/{totalTests} passed, {failedTests} failed");
                }
                else if (args.Length == 1)
                {
                    // Run specific group
                    string groupName = args[0];
                    if (Vars.Tests.groups.ContainsKey(groupName))
                    {
                        _logger.Info($"Running tests in group: {groupName}");
                        var group = Vars.Tests.groups[groupName];
                        int totalTests = 0;
                        int failedTests = 0;
                        
                        group.RunAll(testResults => 
                        {
                            totalTests = testResults.Count;
                            foreach (var result in testResults.Values)
                            {
                                if (result.failed)
                                    failedTests++;
                            }
                        });
                        
                        _logger.Info($"Group {groupName} results: {totalTests - failedTests}/{totalTests} passed, {failedTests} failed");
                    }
                    else
                    {
                        _logger.Error($"Test group not found: {groupName}");
                        Exit();
                    }
                }
                else if (args.Length == 2)
                {
                    // Run specific test in specific group
                    string groupName = args[0];
                    string testName = args[1];
                    if (Vars.Tests.groups.ContainsKey(groupName))
                    {
                        var group = Vars.Tests.groups[groupName];
                        if (group.tests.ContainsKey(testName))
                        {
                            _logger.Info($"Running test: {groupName}.{testName}");
                            var test = group.tests[testName];
                            test.Run(testResult => 
                            {
                                if (testResult.failed)
                                    _logger.Error($"Test {groupName}.{testName} failed");
                                else
                                    _logger.Info($"Test {groupName}.{testName} passed");
                            });
                        }
                        else
                        {
                            _logger.Error($"Test not found: {groupName}.{testName}");
                            Exit();
                        }
                    }
                    else
                    {
                        _logger.Error($"Test group not found: {groupName}");
                        Exit();
                    }
                }
                else
                {
                    _logger.Error("Invalid arguments for test command. Usage: --test [group] [test]");
                    Exit();
                }
            }
            catch (Exception e)
            {
                _logger.Error($"Error running tests: {e.Message}");
                Exit();
            }
        }

        private static async void ActionMultiplayerTest(string presetId)
        {
            if (string.IsNullOrEmpty(presetId))
            {
                _logger.Error("Preset ID is required for multiplayer test");
                Exit();
                return;
            }

            try
            {
                var preset = Preset.Type.Get<Preset>(presetId);
                if (preset == null)
                {
                    _logger.Error($"Unknown preset: {presetId}");
                    Exit();
                    return;
                }

                _logger.Info($"Starting multiplayer test with preset: {presetId}");
                await Vars.Presets.LoadPreset(preset);
                
                // Create server for multiplayer testing
                Vars.Server.CreateServer(1234);
                _logger.Info("Multiplayer test server created on port 1234");
            }
            catch (Exception e)
            {
                _logger.Error($"Error in multiplayer test: {e.Message}");
                Exit();
            }
        }
    }
}
