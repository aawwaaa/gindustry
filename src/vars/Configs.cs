using Gindustry.IO;
using Gindustry.Utils;
using Godot;

namespace Gindustry;

public partial class Vars {
    public partial class Vars_Configs : Node
    {
        [Signal]
        public delegate void ConfigsLoadedEventHandler();

        private ConfigsGroup configs = new ConfigsGroup();
        private Log.Logger logger = Log.RegisterLogger("Configs");

        private bool configValueChanged = false;
        
        public T Get<T>(string key) => configs.Get<T>(key);
        public T Get<T>(string key, T defaultValue) => configs.Get(key, defaultValue);
        public T Get<T>(ConfigKey<T> key) => configs.Get(key);
        public Variant g(string key) => configs.g(key);
        public Variant g(string key, Variant defaultValue) => configs.g(key, defaultValue);
        
        public void Set(string key, object value) => configs.Set(key, value);
        public void Set<T>(ConfigKey<T> key, T value) => configs.Set(key, value);
        public void s(string key, Variant value) => configs.s(key, value);

        public object this[string key] { get => configs[key]; set => configs[key] = value; }

        public delegate T ConfigDefaultValueProvider<T>();

        public void SetDefault<T>(ConfigKey<T> key, ConfigDefaultValueProvider<T> defaultValueProvider)
        {
            if (configs.Contains(key)) return;
            key[configs] = defaultValueProvider();
            configValueChanged = true;
        }

        public void GeneratePlayerConfigs()
        {
            /*
            SetDefault(Vars.Client.ConfigPlayerToken, () => Utils.GenerateToken());
            SetDefault(Vars.Players.ConfigTokenMappingKey, () => {
                var key = new byte[32];
                using (var rng = System.Security.Cryptography.RandomNumberGenerator.Create())
                    rng.GetBytes(key);
                return key;
            });
            */
        }

        public void LoadConfigs()
        {
            if (!FileAccess.FileExists("user://configs.bin"))
            {
                configs.InitConfigs();
                logger.Warn("No configs found, generating default configs.");
                GeneratePlayerConfigs();
                SaveConfigs();
                return;
            }

            logger.Info("Loading configs");
            var io = new GodotFileIO("user://configs.bin", FileAccess.ModeFlags.Read);
            configs.LoadConfigs(io.Reader());
            io.Close();
            EmitSignal("ConfigsLoaded");
            GeneratePlayerConfigs();
            if (configValueChanged)
                SaveConfigs();
        }

        public void SaveConfigs()
        {
            logger.Info("Saving configs");
            var io = new GodotFileIO("user://configs.bin", FileAccess.ModeFlags.Write);
            configs.SaveConfigs(io.Writer());
            io.Close();
        }
    }
}
