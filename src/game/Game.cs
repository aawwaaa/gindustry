using Godot;
using System;
using System.Collections.Generic;

public partial class Vars
{
    public partial class Vars_Game : Node
    {
        [Signal]
        public delegate void SaveMetaChangedEventHandler(SaveMeta meta);

        [Signal]
        public delegate void PlayerChangedEventHandler(Player player, Player from);

        private Log.Logger logger = Log.RegisterLogger("Game");

        private bool isPaused;

        private Preset savePreset;
        public Preset SavePreset
        {
            get => savePreset;
            set
            {
                if (savePreset != null)
                    savePreset.DisablePreset();
                savePreset = value;
            }
        }

        private SaveMeta saveMeta;
        public SaveMeta SaveMeta
        {
            get => saveMeta;
            set
            {
                saveMeta = value;
                EmitSignal(SignalName.SaveMetaChanged, value);
            }
        }

        public ConfigsGroup SaveConfigs { get; set; } = new ConfigsGroup();

        private Player player;
        public Player Player
        {
            get => player;
            set
            {
                var old = player ?? null;
                player = value;
                EmitSignal(SignalName.PlayerChanged, value, old);
            }
        }

        public SaveDataLayer SaveDataLayer { get; set; }
        public readonly Dictionary<string, SaveDataComponent> saveDataComponents = new Dictionary<string, SaveDataComponent>();

        [Rpc(MultiplayerApi.RpcMode.Authority, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable, CallLocal = false)]
        public void SetPaused(bool v)
        {
            if (Vars.Client.PostToServer(this, nameof(SetPaused), v)) return;
            if (!Vars.Server.IsCallerHasPermission(Multiplayer, "Game/SetPaused"))
                return;
            // Sync(nameof(SetPausedRpc), v);
            SetPausedRpc(v);
        }

        public void SetPausedRpc(bool v)
        {
            isPaused = v;
            GetTree().Paused = v;
            PhysicsServer3D.SetActive(!v);
        }

        private void OnStateStateChanged(Vars.State state, Vars.State from)
        {
            if (from == Vars.State.InGame && state != Vars.State.InGame)
                ResetGame();
            if (from == Vars.State.LoadingGame && state != Vars.State.InGame)
                ResetGame();
        }

        public bool IsPaused()
        {
            return isPaused;
        }

        public override void _Ready()
        {
            Vars.Core.state.StateChanged += OnStateStateChanged;
        }

        public void ResetGame()
        {
            if (SaveDataLayer is not null)
            {
                logger.Info("Saving game");
                SaveDataLayer.SaveAll();
                SaveDataLayer.QueueFree();
                SaveDataLayer = null;
            }
            logger.Info("Resetting game");
            SetPausedRpc(false);
            Vars.Client.Reset();
            
            if (savePreset != null)
            {
                savePreset.DisablePreset();
                savePreset.ResetPreset();
            }

            foreach(var component in saveDataComponents.Values)
            {
                component.DisposeData();
                component.QueueFree();
            }
            saveDataComponents.Clear();

            Vars.Objects.Reset();

            savePreset = null;
            player = null;

            // Vars.Players.Reset();
            Vars.Server.Reset();
            SaveDataLayer = null;
        }

        public void ResetToMenu()
        {
            Vars.Core.state.SetState(Vars.State.MainMenu);
        }

        public void StartGameLoad()
        {
            logger.Info(Tr("Game_LoadStarted"));
            if (Vars.Core.state.GetState() != Vars.State.LoadingGame)
                Vars.Core.state.SetState(Vars.State.LoadingGame);
        }

        public void InitGame()
        {
            saveMeta = new SaveMeta();
            SaveDataLayer = new MemorySaveDataLayer();
            saveMeta.ApplyCurrentMods();
            InitSaveDataComponents();
            SaveConfigs = new ConfigsGroup();
            Vars.Objects.InitObjectTypesMapping();
        }

        public void ReadyGame()
        {
            logger.Info(Tr("Game_Ready"));
            Vars.Objects.ObjectReady();
        }

        public void EnterGame()
        {
            logger.Info(Tr("Game_Enter"));
            Vars.Core.state.SetState(Vars.State.InGame);
        }

        public void InitSaveDataComponents()
        {
            foreach(var pair in SaveDataComponent.SaveDataComponentInitList)
            {
                if (saveDataComponents.ContainsKey(pair.Key))
                    continue;
                var component = pair.Value();
                component.Name = pair.Key;
                AddChild(component);
                saveDataComponents[pair.Key] = component;
                component.InitData();
            }
        }

        public void HandleLoadError(Exception err)
        {
            ResetGame();
            var msg = $"Load error: {err}";
            logger.Error(msg);
            // Vars.UI.MessagePanel.AddMessage(msg);
        }

        public void LoadGameMeta(Reader r)
        {
            StartGameLoad();
            saveMeta = new SaveMeta();
            saveMeta.LoadFrom(r);
            r.A(r => {
                SaveConfigs = new ConfigsGroup();
                SaveConfigs.LoadFrom(r);
                Vars.Objects.LoadObjectTypesMapping(r);

                SetPausedRpc(r.Z());

                savePreset = Preset.Type.Get<Preset>(r.S());
                if (savePreset == null)
                    throw new Exception($"Preset {r.S()} not found");
                savePreset.LoadPresetData(r);
                var size = r.U16();
                for(int i = 0; i < size; i++)
                {
                    var id = r.S();
                    if (!SaveDataComponent.SaveDataComponentInitList.ContainsKey(id))
                        throw new Exception($"SaveDataComponent {id} not found");
                    var func = SaveDataComponent.SaveDataComponentInitList[id];
                    var component = func();
                    component.Name = id;
                    AddChild(component);
                    component.LoadData(r);
                    saveDataComponents[id] = component;
                }
                savePreset.EnablePreset();
                savePreset.ApplyPreset();

                // Vars.Players.LoadData(r);

                savePreset.LoadAfterWorldLoad();
            });
        }

        public void MakeReadyGame()
        {
            ReadyGame();
        }

        public void SaveGameMeta(Writer w, bool toClient = false)
        {
            saveMeta.SaveTo(w);
            w.A(w => {
                SaveConfigs.SaveConfigs(w);
                Vars.Objects.SaveObjectTypesMapping(w);

                w.Z(IsPaused());

                w.S(savePreset.FullId);
                savePreset.SavePresetData(w);

                w.U16((ushort)saveDataComponents.Count);
                foreach(var pair in saveDataComponents)
                {
                    w.S(pair.Key);
                    if (toClient)
                        pair.Value.SaveDataClient(w);
                    else
                        pair.Value.SaveData(w);
                }

                // if (toClient)
                //     Vars.Players.SaveDataEmpty(w);
                // else
                //     Vars.Players.SaveData(w);
            });
        }
    }
}
