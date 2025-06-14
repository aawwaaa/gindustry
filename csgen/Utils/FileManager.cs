using System;
using System.IO;

namespace Gen.Utils
{
    public class FileManager
    {
        private string _projectBase = "";

        public void SetProjectBase(string path)
        {
            _projectBase = path;
        }

        public void Cleanup(string path)
        {
            path = Path.Combine(_projectBase, "gen", path);
            if (File.Exists(path))
            {
                File.Delete(path);
            }
        }

        public void GenerateFile(string path, string data)
        {
            var fullPath = Path.Combine(_projectBase, "gen", path);
            var dir = Path.GetDirectoryName(fullPath)!;
            if (!Directory.Exists(dir))
            {
                Directory.CreateDirectory(dir);
            }
            File.WriteAllText(fullPath, data);
        }
    }
} 