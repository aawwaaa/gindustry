using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

public partial class Vars
{
    public partial class Vars_Mods : Node
    {
        private static readonly Log.Logger Logger = Log.RegisterLogger("Mods");

        public Dictionary<string, ModInfo> ModInfoList { get; private set; } = new Dictionary<string, ModInfo>();
        public Dictionary<string, Mod> ModInstList { get; private set; } = new Dictionary<string, Mod>();

        public Mod CurrentLoadingMod { get; private set; }

        public void SearchModFolder(string path)
        {
            var dirAccess = DirAccess.Open(path);
            if (dirAccess == null)
            {
                Logger.Error($"Mod search failed: Dir access error: {path}");
                return;
            }

            var progress = Log.RegisterProgressTracker(5, $"Search mods: {path}", Logger.source);
            int count = 0;

            dirAccess.ListDirBegin();
            string dirName = dirAccess.GetNext();
            while (dirName != "")
            {
                dirName = System.IO.Path.Combine(path, dirName);
                if (dirAccess.CurrentIsDir())
                {
                    var info = ModInfo.LoadFromFolder(dirName);
                    count += FoundMod(info, dirName);
                }
                else
                {
                    var info = ModInfo.LoadFromFile(dirName);
                    count += FoundMod(info, dirName);
                }
                dirName = dirAccess.GetNext();
            }
            dirAccess.ListDirEnd();

            Logger.Info($"Mod search success, found {count} mods in {path}");
            progress.Finish();
        }

        private int FoundMod(ModInfo info, string path)
        {
            if (info == null)
            {
                Logger.Warn($"Mod load failed: Invalid ModInfo: {path}");
                return 0;
            }
            ModInfoList[info.Id] = info;
            return 1;
        }

        public void InitConfigs()
        {
            if (!DirAccess.DirExistsAbsolute("user://mod-configs/"))
            {
                DirAccess.MakeDirAbsolute("user://mod-configs/");
            }
        }

        public void LoadEnableConfigs()
        {
            if (!Godot.FileAccess.FileExists("user://mod-enable-config.bin"))
            {
                foreach (var info in ModInfoList.Values)
                    info.Enabled = true;
                Logger.Warn("Mod enable config file not found, using defaults");
                SaveEnableConfigs();
                return;
            }

            Logger.Info("Loading mod enable configs...");
            var progress = Log.RegisterProgressTracker(5, "Load mod enable configs", Logger.source);
            var access = Godot.FileAccess.Open("user://mod-enable-config.bin", Godot.FileAccess.ModeFlags.Read);

            var founded = new List<string>();
            while (!access.EofReached())
            {
                var modName = access.GetPascalString();
                var enabled = access.Get8() != 0;
                if (ModInfoList.ContainsKey(modName))
                    ModInfoList[modName].Enabled = enabled;
                founded.Add(modName);
            }

            bool hasForeign = false;
            foreach (var info in ModInfoList.Values)
            {
                if (founded.Contains(info.Id))
                    continue;
                info.Enabled = true;
                Logger.Info($"Mod not found in enable configs, using defaults: {info.RefString}");
                hasForeign = true;
            }

            access.Close();
            if (hasForeign)
                SaveEnableConfigs();
            progress.Finish();
        }

        public void SaveEnableConfigs()
        {
            Logger.Info(Tr("Mods_SaveEnableConfigs"));
            var access = FileAccess.Open("user://mod-enable-config.bin", FileAccess.ModeFlags.Write);
            foreach (var info in ModInfoList.Values)
            {
                access.StorePascalString(info.Id);
                access.Store8(info.Enabled ? (byte)1 : (byte)0);
            }
            access.Close();
        }

        public void LoadModConfigs(Mod mod)
        {
            var path = $"user://mod-configs/{mod.ModInfo.Id}.bin";
            if (!FileAccess.FileExists(path))
            {
                Logger.Warn($"Mod config file not found, using defaults: {mod.ModInfo.RefString}");
                mod._InitConfigs();
                return;
            }

            Logger.Info($"Loading mod configs: {mod.ModInfo.RefString}");
            var io = new GodotFileIO(path, FileAccess.ModeFlags.Read);
            mod._LoadConfigs(io.Reader());
            io.Close();
        }

        public void SaveModConfigs(Mod mod)
        {
            Logger.Info($"Saving mod configs: {mod.ModInfo.RefString}");
            var path = $"user://mod-configs/{mod.ModInfo.Id}.bin";
            var io = new GodotFileIO(path, FileAccess.ModeFlags.Write);
            mod._SaveConfigs(io.Writer());
            io.Close();
        }

        public Dictionary<string, List<string>> CheckErrors()
        {
            var output = new Dictionary<string, List<string>>();
            foreach (var info in ModInfoList.Values)
            {
                if (!info.Enabled) continue;
                var errors = new List<string>();
                foreach (var id in info.Depends.Keys)
                {
                    var dependence = info.Depends[id];
                    if (!ModInfoList.ContainsKey(id))
                    {
                        errors.Add($"Missing dependence: {dependence.RefString}");
                        continue;
                    }

                    var dependenceInfo = ModInfoList[id];
                    var minVersionMatched = Utils.CompareVersionStringGe(dependenceInfo.Version, dependence.Min);
                    var maxVersionMatched = dependence.Max == "none" || !Utils.CompareVersionStringGe(dependenceInfo.Version, dependence.Max);
                    var matched = minVersionMatched && maxVersionMatched;

                    if (!matched)
                    {
                        errors.Add($"Dependence version mismatch: Required {dependence.RefString}, got {info.RefString}");
                        continue;
                    }

                    if (!dependenceInfo.Enabled)
                    {
                        errors.Add($"Dependence disabled: {info.RefString}");
                        continue;
                    }
                }

                foreach (var id in info.Excepts.Keys)
                {
                    if (!ModInfoList.ContainsKey(id))
                        continue;
                    if (!ModInfoList[id].Enabled)
                        continue;
                    errors.Add($"Unexpected mod: {ModInfoList[id].RefString}");
                }

                if (errors.Count >= 0)
                    output[info.RefString] = errors;
            }
            return output;
        }
        
        // Thanks DeepSeek-R1 for optimizing
        private class LoadListFinder
        {
            public Log.Logger logger { get; set; }

            public List<string> GetSolve(List<ModInfo> list)
            {
                var modIds = new HashSet<string>(list.Select(m => m.Id));
                var inDegree = new Dictionary<string, int>();
                var adjacency = new Dictionary<string, List<string>>();
                var queue = new Queue<string>();
                var loadList = new List<string>();

                // 初始化入度和邻接表
                foreach (var info in list)
                {
                    int dependenciesCount = info.Depends.Count;
                    inDegree[info.Id] = dependenciesCount;

                    foreach (var depend in info.Depends.Keys)
                    {
                        // 只处理存在于列表中的依赖
                        if (modIds.Contains(depend))
                        {
                            if (!adjacency.ContainsKey(depend))
                                adjacency[depend] = new List<string>();
                            adjacency[depend].Add(info.Id);
                        }
                    }

                    // 没有依赖或所有依赖都不在列表中且dependenciesCount为0的情况
                    if (dependenciesCount == 0)
                    {
                        queue.Enqueue(info.Id);
                    }
                }

                // Kahn算法处理拓扑排序
                while (queue.Count > 0)
                {
                    var modId = queue.Dequeue();
                    loadList.Add(modId);

                    if (adjacency.TryGetValue(modId, out var dependents))
                    {
                        foreach (var dependent in dependents)
                        {
                            inDegree[dependent]--;
                            if (inDegree[dependent] == 0)
                            {
                                queue.Enqueue(dependent);
                            }
                        }
                    }
                }

                // 可选：检查循环依赖或无法满足的依赖
                if (loadList.Count != list.Count)
                {
                    // 根据需求处理错误情况，例如抛出异常或记录日志
                    var mods = string.Join(", ", list.Where(m => !loadList.Contains(m.Id)).Select(m => m.RefString));
                    logger.Warn($"Cyclic dependency detected, ignoring mods: {mods}");
                }

                return loadList;
            }
        }

        private LoadListFinder _loadListFinder = new LoadListFinder();

        private List<string> LoadList = new List<string>();
        public List<string> DisplayOrder { get; set; } = new List<string>();

        public async Task LoadModsInit()
        {
            var enabledList = ModInfoList.Values.Where(info => info.Enabled).ToList();
            var disabledList = ModInfoList.Values.Where(info => !info.Enabled).ToList();

            var progress = Log.RegisterProgressTracker(100 * enabledList.Count, "Loading mods: Initialization", Logger.source);
            _loadListFinder.logger = Logger;
            LoadList = _loadListFinder.GetSolve(enabledList);
            DisplayOrder = LoadList.ToList();
            disabledList.Sort((a, b) => string.Compare(a.Id, b.Id, StringComparison.Ordinal));
            DisplayOrder.AddRange(disabledList.Select(info => info.Id));

            foreach (var id in LoadList)
            {
                var info = ModInfoList[id];
                if (string.IsNullOrEmpty(info.Main))
                {
                    progress.Progress += 100;
                    continue;
                }

                progress.Name = $"Loading mods: Initialization: {info.RefString}: Resource";
                Logger.Info(progress.Name);

                if (!string.IsNullOrEmpty(info.FilePath) && !info.Folder)
                {
                    ProjectSettings.LoadResourcePack(info.FilePath);
                }

                progress.Progress += 30;
                var mainScript = GD.Load<Script>(info.Root + info.Main);
                Mod mod = null;
                if (mainScript is GDScript gDScript)
                    mod = (Mod)gDScript.New();
                else if (mainScript is CSharpScript cSharpScript)
                    mod = (Mod)cSharpScript.New();
                else
                {
                    Logger.Error($"Unknown main script type: {info.RefString}");
                    progress.Progress += 100;
                    continue;
                }
                CurrentLoadingMod = mod;
                ModInstList[info.Id] = mod;
                mod._ModInit(new CoroutineBridge(out var task));
                await task;
                progress.Progress += 25;

                progress.Name = $"Loading mods: Initialization: {info.RefString}: Contents";
                Logger.Info(progress.Name);
                LoadModConfigs(mod);
                progress.Progress += 15;
                mod._InitContents(new CoroutineBridge(out task));
                await task;
                progress.Progress += 30;
            }

            Logger.Info($"Mods initialization complete with {LoadList.Count} mods");
            progress.Finish();
        }

        public async Task LoadModsContents()
        {
            var progress = Log.RegisterProgressTracker(100 * LoadList.Count, "Loading mods: Contents", Logger.source);
            foreach (var id in LoadList)
            {
                var inst = ModInstList[id];
                if (inst == null)
                {
                    progress.Progress += 100;
                    continue;
                }

                CurrentLoadingMod = inst;
                progress.Name = $"Loading mods: Contents: {inst.ModInfo.RefString}";
                Logger.Info(progress.Name);

                Task task;

                foreach (var type in inst.Types)
                {
                    type._Load(new CoroutineBridge(out task));
                    await task;
                }

                foreach (var content in inst.Contents)
                {
                    content._Load(new CoroutineBridge(out task));
                    await task;
                }

                inst._LoadContents(new CoroutineBridge(out task));
                await task;
                progress.Progress += 100;
            }
            progress.Finish();
        }

        public async Task LoadModsAssets()
        {
            var headless = Vars.Core.IsHeadlessClient();
            var progress = Log.RegisterProgressTracker(100 * LoadList.Count, "Loading mods: Assets", Logger.source);
            foreach (var id in LoadList)
            {
                var inst = ModInstList[id];
                if (inst == null)
                {
                    progress.Progress += 100;
                    continue;
                }

                CurrentLoadingMod = inst;
                progress.Name = $"Loading mods: Assets: {inst.ModInfo.RefString}";
                Logger.Info(progress.Name);

                var p1 = Log.RegisterProgressTracker(inst.Types.Count + inst.Contents.Count, "-", "Mods assets");
                Task task;
                foreach (var type in inst.Types)
                {
                    p1.Name = type.FullId;
                    if (headless)
                        type._LoadHeadless(new CoroutineBridge(out task));
                    else
                        type._LoadAssets(new CoroutineBridge(out task));
                    await task;
                    p1.Progress += 1;
                }

                foreach (var content in inst.Contents)
                {
                    p1.Name = content.FullId;
                    if (headless)
                        content._LoadHeadless(new CoroutineBridge(out task));
                    else
                        content._LoadAssets(new CoroutineBridge(out task));
                    await task;
                    p1.Progress += 1;
                }
                
                var c = new CoroutineBridge(out var task);
                if (headless)
                    inst._LoadHeadless(c);
                else
                    inst._LoadAssets(c);
                await task;
                p1.Finish();
                progress.Progress += 100;
            }
            progress.Finish();
        }

        public async Task LoadModsPost()
        {
            var progress = Log.RegisterProgressTracker(100 * LoadList.Count, "Loading mods: Post", Logger.source);
            foreach (var id in LoadList)
            {
                var inst = ModInstList[id];
                if (inst == null)
                {
                    progress.Progress += 100;
                    continue;
                }

                CurrentLoadingMod = inst;
                progress.Name = $"Loading mods: Post: {inst.ModInfo.RefString}";
                Logger.Info(progress.Name);
                inst._Post(new CoroutineBridge(out var task));
                await task;
                progress.Progress += 100;
            }
            progress.Finish();
        }
    }
}
