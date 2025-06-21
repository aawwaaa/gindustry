using Godot;
using System;
using System.Collections.Generic;
using System.Reflection;
using System.IO;
using System.Threading.Tasks;
using System.Linq;

namespace Gindustry.Test
{
    public partial class Vars_Tests: Node
    {
        private readonly Log.Logger logger;
        public Dictionary<string, TestGroup> groups = new();

        public Vars_Tests()
        {
            logger = Log.RegisterLogger("Test");
        }

        public TestGroup GetOrCreateGroup(string name)
        {
            if (!groups.ContainsKey(name))
                groups[name] = new TestGroup { name = name };
            return groups[name];
        }

        private List<string> IterDir(DirAccess dir, string dirPath)
        {
            var scripts = new List<string>();
            dir.ListDirBegin();
            var fileName = dir.GetNext();
            while (!string.IsNullOrEmpty(fileName))
            {
                var fullPath = dirPath + "/" + fileName;
                if (dir.CurrentIsDir())
                {
                    // 使用新的 DirAccess 实例递归子目录
                    using var subDir = DirAccess.Open(fullPath);
                    if (subDir != null)
                        scripts.AddRange(IterDir(subDir, fullPath));
                    else
                        logger.Warn($"Failed to open subdirectory: {fullPath}");
                }
                else if (!fileName.EndsWith(".uid"))
                {
                    scripts.Add(fullPath);
                    logger.Debug($"Found test file: {fullPath}");
                }
                fileName = dir.GetNext();
            }
            dir.ListDirEnd();
            return scripts.Where(s => Path.GetFileName(s).ToLower().Contains("test")).ToList();
        }

        public async Task DiscoverTestsDir(string dirPath)
        {
            logger.Info($"Discovering tests in {dirPath}");
            var dir = DirAccess.Open(dirPath);
            if (dir == null)
            {
                logger.Error($"Failed to open directory: {dirPath}");
                return;
            }

            var count = 0;

            var scripts = IterDir(dir, dirPath);
            var contents = await Util.LoadContentsAsync("", scripts, "Tests_LoadTests", logger.source);

            foreach (var content in contents)
            {
                if (content is GDScript gdScript)
                {
                    var methods = gdScript.GetMethodList();
                    var instance = gdScript.New().AsGodotObject();
                    foreach (var method in methods)
                    {
                        if (((string)method["name"]).StartsWith("test_")) {
                            var test = new Test
                            {
                                name = ((string)method["name"])[5..],
                                action = r =>
                                {
                                    return (TestRun)instance.Call((string)method["name"], r);
                                }
                            };
                            GetOrCreateGroup(gdScript.ResourcePath).Add(test);
                            count++;
                            logger.Debug($"Found test: {gdScript.ResourcePath}.{method["name"]}");
                        }
                    }
                }
                else if (content is CSharpScript cSharpScript)
                {
                    var instance = cSharpScript.New().AsGodotObject();
                    var methods = instance.GetType().GetMethods(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static);
                    foreach (var method in methods)
                    {
                        var attr = method.GetCustomAttribute<TestAttribute>();
                        if (attr != null) {
                            var test = new Test
                            {
                                name = attr.Name,
                                action = r =>
                                {
                                    return (TestRun)method.Invoke(instance, [r]);
                                }
                            };
                            GetOrCreateGroup(attr.Group).Add(test);
                            count++;
                            logger.Debug($"Found test: {attr.Group}.{attr.Name}");
                        }
                    }
                }
            }
            logger.Info($"Discovered {count} tests in {dirPath}");
        }

        public Dictionary<string, Dictionary<string, TestRun>> RunAll(Action<Dictionary<string, Dictionary<string, TestRun>>> callback)
        {
            var results = new Dictionary<string, Dictionary<string, TestRun>>();

            foreach (var group in groups.Values)
            {
                results[group.name] = group.RunAll(null);
            }

            callback?.Invoke(results);
            return results;
        }
    }
} 