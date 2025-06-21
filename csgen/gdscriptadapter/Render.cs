using System.Text;
using System.Text.RegularExpressions;

namespace Gindustry.Generator.GDScriptAdapter;

internal class Render {
    public enum SectionType {
        None = 0,
        Constructors = 1,
        Signals = 2,
        SignalsAll = 3,
        Properties = 4,
        PropertiesAssignable = 5,
        Methods = 6,
        VirtualMethods = 7,
        Comments = 8,
    }
    public struct RenderData {
        public Dictionary<string, string> Data;
        public Dictionary<SectionType, List<Dictionary<string, string>>> SectionData;
        public RenderData() {
            Data = [];
            SectionData = [];
        }
    }
    public class Template {
        public struct TemplateSection {
            public SectionType Type;
            public string Content;
        }
        public List<TemplateSection> Sections = [];
        public string Name;
        public string ParamWithTypeT = "";
        public string BaseClassTargetName = "";
        public string IdentityPrefix = "";

        private void AddSection(string current, StringBuilder buffer) {
            Sections.Add(new TemplateSection {
                Type = current switch {
                    "data" => SectionType.None,
                    "constructors" => SectionType.Constructors,
                    "signals" => SectionType.Signals,
                    "signalsAll" => SectionType.SignalsAll,
                    "properties" => SectionType.Properties,
                    "propertiesAssignable" => SectionType.PropertiesAssignable,
                    "methods" => SectionType.Methods,
                    "virtualMethods" => SectionType.VirtualMethods,
                    "comments" => SectionType.Comments,
                    _ => throw new Exception($"Unknown section: {current}"),
                },
                Content = buffer.ToString(),
            });
        }

        public Template(string name, IEnumerable<string> lines){
            Name = name;
            var buffer = new StringBuilder();
            var current = "data";

            foreach (var line in lines) {
                if (line.StartsWith("<<< =")) {
                    AddSection(current, buffer);
                    current = line.Substring(5).Trim();
                    buffer.Clear();
                    continue;
                }
                if (line.StartsWith(">>>")) {
                    AddSection(current, buffer);
                    current = "data";
                    buffer.Clear();
                    continue;
                }
                if (line.StartsWith("##")) {
                    var parts = line.Substring(2).Trim().Split(' ');
                    var key = parts[0];
                    var value = string.Join(" ", parts.Skip(1));
                    switch (key) {
                        case "paramWithType":
                            ParamWithTypeT = value;
                            break;
                        case "baseClassTargetName":
                            BaseClassTargetName = value;
                            break;
                        case "identityPrefix":
                            IdentityPrefix = value;
                            break;
                        default:
                            throw new Exception($"Unknown key: {key}");
                    }
                    continue;
                }
                buffer.AppendLine(line);
            }
            AddSection(current, buffer);
        }

        public string ParamWithType(string type, string name) {
            return ParamWithTypeT.Replace("{type}", type).Replace("{name}", name);
        }
        public string Params(IEnumerable<string> @params) {
            return string.Join(", ", @params);
        }
        public string ParamsAppend(IEnumerable<string> @params) {
            var @out = Params(@params);
            if (string.IsNullOrEmpty(@out)) {
                return "";
            }
            return $", {@out}";
        }

        public string Identity(string name) {
            return IdentityPrefix + name;
        }

        public string RenderWithData(Parser.FileContent fileContent) {
            var data = GenerateData(fileContent, this);
            return Render(data);
        }

        public string Render(RenderData data) {
            var builder = new StringBuilder();
            foreach(var section in Sections) {
                var content = section.Content;
                foreach(var kvp in data.Data) {
                    content = content.Replace($"={kvp.Key}", kvp.Value);
                }
                if (section.Type == SectionType.None) {
                    builder.Append(content);
                    continue;
                }
                foreach (var item in data.SectionData[section.Type]) {
                    var newContent = content;
                    foreach(var kvp in item) {
                        newContent = newContent.Replace($"={kvp.Key}", kvp.Value);
                    }
                    builder.Append(newContent);
                }
            }
            return builder.ToString();
        }
    }
    public static Dictionary<string, Template> templates = [];
    public static Template LoadTemplate(string name) {
        if (templates.TryGetValue(name, out var template)) {
            return template;
        }
        var path = Path.Combine(FileOp.CallerDir(), "template", name);
        var content = File.ReadAllText(path);
        Log($"Loaded template: {name}");
        templates[name] = new Template(name, content.Split("\n"));
        return templates[name];
    }

    public static FileStream? LogFile;
    public static void Log(params object[] messages) {
        LogFile?.Write(Encoding.UTF8.GetBytes(string.Join(" ", messages) + "\n"));
        LogFile?.Flush();
    }

    private static RenderData GenerateData(Parser.FileContent fileContent, Template template) {
        var data = new RenderData();
        data.Data = new () {
            ["ClassName"] = fileContent.ClassName,
            ["FullName"] = fileContent.FullName,
            ["TargetName"] = fileContent.TargetName,
            ["BaseClassTargetName"] = fileContent.BaseClassTargetName != ""? fileContent.BaseClassTargetName: template.BaseClassTargetName,
            ["BaseClassFullName"] = fileContent.BaseClassFullName,
        };
        data.SectionData[SectionType.Constructors] = fileContent.Constructors.Select(c => new Dictionary<string, string> {
            ["ParamsAppendWithType"] = template.ParamsAppend(c.Parameters.Select(p =>
                template.ParamWithType(p.Type.For(template.Name), template.Identity(p.Name))
            )),
            ["ParamsWithType"] = template.Params(c.Parameters.Select(p =>
                template.ParamWithType(p.Type.For(template.Name), template.Identity(p.Name))
            )),
            ["ParamsAppend"] = template.ParamsAppend(c.Parameters.Select(p => template.Identity(p.Name))),
            ["ParamsCount"] = c.Parameters.Length.ToString(),
            ["Params"] = template.Params(c.Parameters.Select(p => template.Identity(p.Name))),
        }).ToList();
        data.SectionData[SectionType.Methods] = fileContent.Methods.Select(m => new Dictionary<string, string> {
            ["Name"] = m.Name,
            ["ReturnType"] = m.ReturnType.For(template.Name),
            ["ParamsWithType"] = template.Params(m.Parameters.Select(p =>
                template.ParamWithType(p.Type.For(template.Name), template.Identity(p.Name))
            )),
            ["ParamsCount"] = m.Parameters.Length.ToString(),
            ["Params"] = template.Params(m.Parameters.Select(p => template.Identity(p.Name))),
        }).ToList();
        data.SectionData[SectionType.VirtualMethods] = fileContent.VirtualMethods.Select(m => new Dictionary<string, string> {
            ["Name"] = m.Name,
            ["Accessibility"] = m.Accessibility,
            ["ReturnType"] = m.ReturnType.For(template.Name),
            ["ParamsWithType"] = template.Params(m.Parameters.Select(p =>
                template.ParamWithType(p.Type.For(template.Name), template.Identity(p.Name))
            )),
            ["ParamsVariantConverted"] = template.Params(m.Parameters.Select((p, i) =>
                $"global::Godot.NativeInterop.VariantUtils.ConvertTo<{p.Type.For(template.Name)}>(Params[{i}])"
            )),
            ["ParamsCount"] = m.Parameters.Length.ToString(),
            ["ParamsAppend"] = template.ParamsAppend(m.Parameters.Select(p => template.Identity(p.Name))),
            ["Params"] = template.Params(m.Parameters.Select(p => template.Identity(p.Name))),
            ["RetIfNotVoid"] = m.ReturnType.For(template.Name) == "void" ? "" : "ret = global::Godot.NativeInterop.VariantUtils.CreateFrom<"
                + m.ReturnType.For(template.Name) + ">(",
            ["RetIfVoid"] = m.ReturnType.For(template.Name) == "void" ? ";\n            ret = default;" : ");",
            ["ReturnIfNotVoid"] = m.ReturnType.For(template.Name) == "void" ? "" : "return (" + m.ReturnType.For(template.Name) + ")",
            ["ReturnIfVoid"] = m.ReturnType.For(template.Name) == "void" ? "\n            return;" : "",
        }).ToList();
        data.SectionData[SectionType.Properties] = fileContent.Properties.Where(p => !p.Assignable).Select(p => new Dictionary<string, string> {
            ["Name"] = p.Name,
            ["Type"] = p.Type.For(template.Name),
        }).ToList();
        data.SectionData[SectionType.PropertiesAssignable] = fileContent.Properties.Where(p => p.Assignable).Select(p => new Dictionary<string, string> {
            ["Name"] = p.Name,
            ["Type"] = p.Type.For(template.Name),
        }).ToList();
        data.SectionData[SectionType.SignalsAll] = fileContent.Signals.Select(s => new Dictionary<string, string> {
            ["Name"] = s.Name,
            ["ParamsWithType"] = template.Params(s.Parameters.Select(p =>
                template.ParamWithType(p.Type.For(template.Name), template.Identity(p.Name))
            )),
            ["ParamsAppend"] = template.ParamsAppend(s.Parameters.Select(p => template.Identity(p.Name))),
        }).ToList();
        data.SectionData[SectionType.Signals] = fileContent.Signals.Where(s => s.Owned).Select(s => new Dictionary<string, string> {
            ["Name"] = s.Name,
            ["ParamsWithType"] = template.Params(s.Parameters.Select(p =>
                template.ParamWithType(p.Type.For(template.Name), template.Identity(p.Name))
            )),
        }).ToList();
        data.SectionData[SectionType.Comments] = fileContent.Comments.Select(c => new Dictionary<string, string> {
            ["Comment"] = c,
        }).ToList();
        return data;
    }

    public static string RenderGA(Template template, ParserResult parserResult) {
        var data = new RenderData();
        data.SectionData[SectionType.Constructors] = parserResult.FileContents.Select(f => new Dictionary<string, string> {
            ["TargetName"] = f.Value.TargetName,
            ["ParamsArgs"] = "(Godot.GodotObject)args[0]"
                + template.ParamsAppend(f.Value.Constructors.FirstOrDefault().Parameters.Select((p, i) => $"({p.Type.For("cs")})args[{i+1}]")),
        }).ToList();
        var content = template.Render(data);
        return content;
    }
}