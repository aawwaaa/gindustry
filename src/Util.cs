using Godot;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
using static Gindustry.Util;

namespace Gindustry;

public partial class Util : Node
{
    public static Util Instance { get; private set; }
    private Serialization serialize; // GDscript history problem

    public static ImageTexture ParseImageData(byte[] data, string type)
    {
        var image = new Image();
        switch (type)
        {
            case "jpg":
                image.LoadJpgFromBuffer(data);
                break;
            case "ktx":
                image.LoadKtxFromBuffer(data);
                break;
            case "png":
                image.LoadPngFromBuffer(data);
                break;
            case "svg":
                image.LoadSvgFromBuffer(data);
                break;
            case "tga":
                image.LoadTgaFromBuffer(data);
                break;
            case "webp":
                image.LoadWebpFromBuffer(data);
                break;
            case "bmp":
                image.LoadBmpFromBuffer(data);
                break;
        }
        return ImageTexture.CreateFromImage(image);
    }

    public static bool CompareVersionStringGe(string v1, string v2, bool useGt = false)
    {
        var split1 = v1.Split('.').ToList();
        var split2 = v2.Split('.').ToList();
        while (split1.Count > 0 && split2.Count > 0)
        {
            var a1 = split1[0].Split('-')[0];
            var a2 = split2[0].Split('-')[0];
            split1.RemoveAt(0);
            split2.RemoveAt(0);
            if ((!useGt && int.Parse(a1) >= int.Parse(a2)) || (useGt && int.Parse(a1) > int.Parse(a2)))
            {
                return true;
            }
        }
        return false;
    }

    private static Log.Logger loaderLogger = Log.RegisterLogger("Loader");

    public static async Task<List<Resource>> LoadContentsAsync(string header, List<string> contentsInput, string hint = "Loader_LoadContents", string source = "Unknown")
    {
        var contents = contentsInput.Select(x => header + x).ToList();
        var progress = Log.RegisterProgressTracker(1 * contents.Count, hint, source);
        var output = new List<Resource>();
        var removes = new List<string>();

        foreach (var content in contents)
        {
            var error = ResourceLoader.LoadThreadedRequest(content, "", true);
            if (error != Error.Ok)
            {
                loaderLogger.Error($"Load failed: Request failed: {content}");
                removes.Add(content);
                progress.Progress += 1;
            }
        }

        while (contents.Count > 0)
        {
            foreach (var content in contents)
            {
                var status = ResourceLoader.LoadThreadedGetStatus(content);
                switch (status)
                {
                    case ResourceLoader.ThreadLoadStatus.InvalidResource:
                        loaderLogger.Error($"Load failed: Invalid resource: {content}");
                        removes.Add(content);
                        break;
                    case ResourceLoader.ThreadLoadStatus.Failed:
                        loaderLogger.Error($"Load failed: Failed: {content}");
                        ResourceLoader.LoadThreadedGet(content);
                        removes.Add(content);
                        break;
                    case ResourceLoader.ThreadLoadStatus.Loaded:
                        output.Add(ResourceLoader.LoadThreadedGet(content));
                        removes.Add(content);
                        break;
                }

                if (status != ResourceLoader.ThreadLoadStatus.InProgress)
                {
                    progress.Progress += 1;
                }
            }

            foreach (var content in removes)
            {
                contents.Remove(content);
            }
            removes.Clear();
            await Instance.ToSignal(Vars.Tree, SceneTree.SignalName.ProcessFrame);
        }

        progress.Finish();
        return output;
    }

    public static void MergeTranslations(Translation translation)
    {
        var mainTranslation = TranslationServer.GetTranslationObject(translation.Locale);
        foreach (var message in translation.GetMessageList())
        {
            mainTranslation.AddMessage(message, translation.GetMessage(message));
        }
    }

    private static string tokenStrings = "23456789abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ";

    public static string GenerateToken()
    {
        var token = "";
        var random = new Random();
        for (int i = 0; i < 32; i++)
        {
            token += tokenStrings[random.Next(0, tokenStrings.Length - 1)];
        }
        return token;
    }

    public static void SignalDynamicConnect(GodotObject obj, GodotObject from, StringName signalName, Callable callable)
    {
        if (from != null && from.IsConnected(signalName, callable))
        {
            from.Disconnect(signalName, callable);
        }
        if (obj != null)
        {
            obj.Connect(signalName, callable);
        }
    }

    public static void ConnectSignalByTable(Node target, Godot.Collections.Dictionary table)
    {
        foreach (var signalName in table.Keys)
        {
            target.Connect((StringName)signalName, (Callable)table[signalName]);
        }
    }

    public static void DisconnectSignalByTable(Node target, Godot.Collections.Dictionary table)
    {
        foreach (var signalName in table.Keys)
        {
            target.Disconnect((StringName)signalName, (Callable)table[signalName]);
        }
    }

    public Util()
    {
        Instance = this;
        serialize = new Serialization();
        serialize.add_defaults();
    }

    // Snake_case instance methods to call static methods
    public ImageTexture parse_image_data(byte[] data, string type)
    {
        return ParseImageData(data, type);
    }

    public bool compare_version_string_ge(string v1, string v2, bool useGt = false)
    {
        return CompareVersionStringGe(v1, v2, useGt);
    }

    public async Task<List<Resource>> load_contents_async(string header, List<string> contentsInput, string hint = "Loader_LoadContents", string source = "Unknown")
    {
        return await LoadContentsAsync(header, contentsInput, hint, source);
    }

    public void merge_translations(Translation translation)
    {
        MergeTranslations(translation);
    }

    public string generate_token()
    {
        return GenerateToken();
    }

    public void signal_dynamic_connect(GodotObject obj, GodotObject from, StringName signalName, Callable callable)
    {
        SignalDynamicConnect(obj, from, signalName, callable);
    }

    public void connect_signal_by_table(Node target, Godot.Collections.Dictionary table)
    {
        ConnectSignalByTable(target, table);
    }

    public void disconnect_signal_by_table(Node target, Godot.Collections.Dictionary table)
    {
        DisconnectSignalByTable(target, table);
    }
}
