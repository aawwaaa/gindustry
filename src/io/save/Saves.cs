using Godot;
using System;
using System.Linq;
using System.Collections.Generic;

public partial class Vars
{
    public partial class Vars_Saves : Node
    {
        [Signal]
        public delegate void SavesChangedEventHandler();

        private Log.Logger logger = Log.RegisterLogger("Saves");

        private Dictionary<string, SaveMeta> saves = new Dictionary<string, SaveMeta>();

        public void SearchSaveFolder(string path, Dictionary<string, SaveMeta> dict = null)
        {
            if (dict == null)
            {
                dict = saves;
            }

            var dirAccess = DirAccess.Open(path);
            if (dirAccess == null)
            {
                logger.Warn("Search saves failed: " + path);
                return;
            }

            int count = 0;
            var progress = Log.RegisterProgressTracker(5, $"Searching saves for {path}", logger.source);

            dirAccess.ListDirBegin();
            string dirName = dirAccess.GetNext();
            while (dirName != "")
            {
                string file = path + dirName;
                if (!dirAccess.CurrentIsDir())
                {
                    // dict[dirName] = new Dictionary<string, SaveMeta>();
                    // SearchSaveFolder(file + "/", dict);
                    continue;
                }

                var io = new GodotFileIO(file + "/save.bin", FileAccess.ModeFlags.Read);
                var reader = io.Reader();
                var info = new SaveMeta();
                try
                {
                    info.LoadFrom(reader);
                }
                catch(Exception e)
                {
                    logger.Error($"Invalid save file: Error during load: {file} {e}");
                    io.Close();
                    dirName = dirAccess.GetNext();
                    continue;
                }
                
                info.SaveName = dirName;
                info.FilePath = file;
                dict[info.SaveName] = info;
                io.Close();
                count++;
                dirName = dirAccess.GetNext();
            }
            
            logger.Info($"Found {count} saves in {path}");
            progress.Finish();
            EmitSignal(SignalName.SavesChanged);
        }

        public void LoadSaves()
        {
            SearchSaveFolder("user://saves/");
        }

        public void CreateSave(string saveName)
        {
            logger.Info($"Creating save {saveName}");
            string path = "user://saves/" + saveName;
            Vars.Game.SaveMeta.SaveName = saveName;
            Vars.Game.SaveMeta.FilePath = path;
            Vars.Game.SaveDataLayer.QueueFree();
            Vars.Game.SaveDataLayer = new SaveFileSaveDataLayer(Vars.Game.SaveMeta);
            Vars.Game.SaveDataLayer.SaveAll();
            saves[saveName] = Vars.Game.SaveMeta;
            EmitSignal(SignalName.SavesChanged);
        }

        public void LoadSave(string saveName)
        {
            logger.Info("Loading save " + saveName);
            if (!saves.ContainsKey(saveName)) throw new Exception($"Save {saveName} not found");
            var meta = saves[saveName];
            Vars.Game.SaveDataLayer = new SaveFileSaveDataLayer(meta);
            Vars.Game.SaveDataLayer.RequestLoadGameMeta();
            Vars.Game.MakeReadyGame();
            var player = Vars.Client.JoinLocal();
            Vars.Game.EnterGame();
            Vars.Game.SavePreset._AfterReady();
        }

        public void DeleteSave(string saveName)
        {
            logger.Info("Deleting save " + saveName);
            if (!saves.ContainsKey(saveName)) throw new Exception($"Save {saveName} not found");
            var info = saves[saveName];
            var err = DirAccess.RemoveAbsolute(info.FilePath);
            if (err != Error.Ok) throw new Exception($"Failed to delete save {saveName}");
            saves.Remove(saveName);
            EmitSignal(SignalName.SavesChanged);
        }

        public void RenameSave(string saveName, string newName)
        {
            logger.Info("Renaming save " + saveName + " to " + newName);
            if (!saves.ContainsKey(saveName)) throw new Exception($"Save {saveName} not found");
            var info = saves[saveName];
            var newPath = "user://saves/" + newName;
            DirAccess.RenameAbsolute(info.FilePath, newPath);
            info.FilePath = newPath;
            saves.Remove(saveName);
            saves[newName] = info;
            EmitSignal(SignalName.SavesChanged);
        }

        public void CopySave(string saveName, string newName)
        {
            logger.Info("Copying save " + saveName + " to " + newName);
            if (!saves.ContainsKey(saveName)) throw new Exception($"Save {saveName} not found");
            var info = saves[saveName];
            ByteArrayIO.Temp.Clear();
            info.SaveTo(ByteArrayIO.Temp.Writer());
            var data = ByteArrayIO.Temp.DumpData();
            var newPath = "user://saves/" + newName;
            DirAccess.CopyAbsolute(info.FilePath, newPath);
            info.FilePath = newPath;
            var another = new SaveMeta();
            ByteArrayIO.Temp.Clear();
            ByteArrayIO.Temp.SetData(data);
            another.LoadFrom(ByteArrayIO.Temp.Reader());
            ByteArrayIO.Temp.Clear();
            saves[saveName] = another;
            saves[newName] = info;
            EmitSignal(SignalName.SavesChanged);
        }
    }
}
