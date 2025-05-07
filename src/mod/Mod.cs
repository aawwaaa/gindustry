using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Reflection;

[GDScriptAdapterTarget("GA_Mod")]
[GlobalClass]
public partial class Mod : Node
{
    [Signal]
    public delegate void SignalConfigsChangedEventHandler(Mod mod);

    public ModInfo ModInfo { get; internal set; }
    public ConfigsGroup ModConfigs { get; private set; }

    public string Root => ModInfo.Root;

    public List<Content> Contents { get; private set; } = new List<Content>();
    public List<ResourceType> Types { get; private set; } = new List<ResourceType>();

    public static Mod Current()
    {
        return Vars.Mods.CurrentLoadingMod;
    }

    /// <summary>
    /// When mod is instanced, this function will be called first
    /// Before config loading
    /// In stage of init
    /// </summary>
    public virtual void _ModInit(CoroutineBridge c) {
        c.Finish();
    }

    /// <summary>
    /// After _mod_init and config loading
    /// In stage of init
    /// </summary>
    public virtual void _InitContents(CoroutineBridge c) {
        c.Finish();
    }

    /// <summary>
    /// After _init_contents, in stage of load contents
    /// </summary>
    public virtual void _LoadContents(CoroutineBridge c) {
        c.Finish();
    }

    public virtual void _LoadAssets(CoroutineBridge c) {
        c.Finish();
    }
    public virtual void _LoadHeadless(CoroutineBridge c) {
        c.Finish();
    }

    /// <summary>
    /// After _load_contents, in stage of post
    /// </summary>
    public virtual void _Post(CoroutineBridge c) {
        c.Finish();
    }

    public virtual void _LoadConfigs(Reader r)
    {
        ModConfigs = new ConfigsGroup();
        ModConfigs.LoadFrom(r);
    }

    public virtual void _InitConfigs()
    {
        ModConfigs = new ConfigsGroup();
    }

    public virtual void _SaveConfigs(Writer w)
    {
        ModConfigs.SaveConfigs(w);
    }

    public void ConfigsChanged()
    {
        EmitSignal(SignalName.SignalConfigsChanged, this);
    }

    public List<string> GetFiles(string path)
    {
        path = ToAbsolute(path);
        var arr = new List<string>();
        var access = DirAccess.Open(path);
        if (access == null)
            return arr;
        access.ListDirBegin();
        var fileName = access.GetNext();
        while (fileName != "")
        {
            var file = ToRelative(path + "/" + fileName);
            if (access.CurrentIsDir())
                arr.AddRange(GetFiles(file));
            else
                arr.Add(file);
            fileName = access.GetNext();
        }
        access.ListDirEnd();
        return arr;
    }

    public string ToAbsolute(string path)
    {
        if (path.StartsWith("mod://"))
            return Root + "/" + path.Substring(6);
        return path;
    }

    public string ToRelative(string path)
    {
        if (path.StartsWith(Root))
            return "mod://" + path.Substring(Root.Length + 1);
        return path;
    }

    public Resource LoadRelative(string path)
    {
        return ResourceLoader.Load(ToAbsolute(path));
    }

    public async Task EachResource(string path, Callable callback, string hint = "Load_LoadResources", string source = "Unknown")
        =>  await EachResource(path, callback, Callable.From(() => true), hint, source);
    public async Task EachResource(string path, Callable callback, Callable filter, string hint = "Load_LoadResources", string source = "Unknown")
    {
        var resesPath = GetFiles(path);
        for (var index = 0; index < resesPath.Count; index++)
        {
            if (!(bool)filter.Call(resesPath[index])) continue;
            resesPath[index] = ToAbsolute(resesPath[index]);
        }
        var reses = await Utils.LoadContentsAsync("", resesPath, hint, source);
        reses.Sort((a, b) => string.Compare(a.ResourcePath, b.ResourcePath));
        foreach (var res in reses)
            callback.Call(res);
    }

    public void RegisterResource(Resource res)
    {
        if (res.HasMethod("__resource__static_init"))
        {
            res.Call("__resource__static_init", this);
            return;
        }
        if (res.HasMethod("__Resource__StaticInit"))
        {
            res.Call("__Resource__StaticInit", res, this);
            return;
        }
        if (res is PackedScene packedScene)
        {
            var node = packedScene.Instantiate();
            var free = (bool)node.Call("__PackedScene__Init", this);
            RegisterResource((Resource)node.Call("__PackedScene__GetResource"));
            if (free) node.QueueFree();
            return;
        }
        if (res is GDScript gdScript)
        {
            if (gdScript.HasMethod("__resource__ignore"))
                return;
            var inst = gdScript.New();
            if (!RegisterObject((GodotObject)inst))
                GD.PushError($"Unknown instance type: {res.ResourcePath}");
            return;
        }
        if (res is CSharpScript cSharpScript)
        {
            if (cSharpScript.HasMethod("__Resource__Ignore"))
                return;
            var inst = cSharpScript.New();
            if (!RegisterObject((GodotObject)inst))
                GD.PushError($"Unknown instance type: {res.ResourcePath}");
            return;
        }
        if (!RegisterObject(res))
            GD.PushError($"Unknown resource type: {res.ResourcePath}");
    }

    public bool RegisterObject(GodotObject inst)
    {
        if (inst.HasMethod("__resource__init"))
            inst.Call("__resource__init", this);
        if (inst.HasMethod("__Resource__Init"))
            inst.Call("__Resource__Init", this);
        if (inst is ResourceType resourceType)
            Vars.Types.RegisterType(resourceType);
        else if (inst is Content content)
            Vars.Contents.RegisterContent(content);
        else if (inst is ObjectType objectType)
            Vars.Vars_Objects.AddObjectType(objectType);
        else
            return false;
        return true;
    }

    public async Task LoadResources(string path, string hint = "Load_LoadTypes", string source = "Unknown")
    {
        await EachResource(path, new Callable(this, nameof(RegisterResource)), hint, source);
    }

    public async Task LoadScripts(string path, string source = "Unknown")
    {
        var typesPath = GetFiles(path);
        var removes = new List<string>();
        foreach (var p in typesPath)
            if (p.Contains("__ignore__"))
                removes.Add(p);
        foreach (var p in removes)
            typesPath.Remove(p);
        for (var i = 0; i < typesPath.Count; i++)
            typesPath[i] = ToAbsolute(typesPath[i]);
        var scripts = await Utils.LoadContentsAsync("", typesPath, "Load_LoadScripts", source);
        foreach (var script in scripts)
            if (script.HasMethod("__script__init"))
                script.Call("__script__init");
    }

    public Window OpenConfigs()
    {
        var window = new AcceptDialog();
        window.Title = "";
        window.DialogText = "Mods_NoConfigs";
        return window;
    }
}
