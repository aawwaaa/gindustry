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
        VirtualMethodsAll = 8,
        Comments = 9,
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
                    "virtualMethodsAll" => SectionType.VirtualMethodsAll,
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

    // Helper functions for parameter processing
    private static string GetParamsWithType(Parser.FileContent.Property[] parameters, Template template) {
        return template.Params(parameters.Select(p =>
            template.ParamWithType(p.Type.For(template.Name), template.Identity(p.Name))
        ));
    }

    private static string GetParams(Parser.FileContent.Property[] parameters, Template template) {
        return template.Params(parameters.Select(p => template.Identity(p.Name)));
    }

    private static string GetParamsAppend(Parser.FileContent.Property[] parameters, Template template) {
        return template.ParamsAppend(parameters.Select(p => template.Identity(p.Name)));
    }

    private static string GetParamsVariantConverted(Parser.FileContent.Property[] parameters, Template template) {
        return template.Params(parameters.Select((p, i) =>
            $"global::Godot.NativeInterop.VariantUtils.ConvertTo<{p.Type.For(template.Name)}>(Params[{i}])"
        ));
    }

    // Helper functions for return type handling
    private static bool IsVoidReturnType(Parser.FileContent.Type returnType, Template template) {
        return returnType.For(template.Name) == "void";
    }

    private static Dictionary<string, string> GetReturnTypeData(Parser.FileContent.Type returnType, Template template) {
        var isVoid = IsVoidReturnType(returnType, template);
        var returnTypeString = returnType.For(template.Name);
        
        return new Dictionary<string, string> {
            ["RetIfNotVoid"] = isVoid ? "" : "ret = global::Godot.NativeInterop.VariantUtils.CreateFrom<" + returnTypeString + ">(",
            ["RetIfVoid"] = isVoid ? ";\n            ret = default;" : ");",
            ["ReturnIfNotVoid"] = isVoid ? "" : "return (" + returnTypeString + ")",
            ["ReturnIfVoid"] = isVoid ? "\n            return;" : "",
        };
    }

    // Dictionary builder functions
    private static Dictionary<string, string> BuildConstructorDictionary(Parser.FileContent.Method constructor, Template template) {
        return new Dictionary<string, string> {
            ["ParamsAppendWithType"] = template.ParamsAppend(constructor.Parameters.Select(p =>
                template.ParamWithType(p.Type.For(template.Name), template.Identity(p.Name))
            )),
            ["ParamsWithType"] = GetParamsWithType(constructor.Parameters, template),
            ["ParamsAppend"] = GetParamsAppend(constructor.Parameters, template),
            ["ParamsCount"] = constructor.Parameters.Length.ToString(),
            ["Params"] = GetParams(constructor.Parameters, template),
        };
    }

    private static Dictionary<string, string> BuildMethodDictionary(Parser.FileContent.Method method, Template template) {
        return new Dictionary<string, string> {
            ["Name"] = method.Name,
            ["ReturnType"] = method.ReturnType.For(template.Name),
            ["ParamsWithType"] = GetParamsWithType(method.Parameters, template),
            ["ParamsCount"] = method.Parameters.Length.ToString(),
            ["Params"] = GetParams(method.Parameters, template),
        };
    }

    private static Dictionary<string, string> BuildVirtualMethodDictionary(Parser.FileContent.Method method, Template template) {
        var dictionary = new Dictionary<string, string> {
            ["Name"] = method.Name,
            ["Accessibility"] = method.Accessibility,
            ["ReturnType"] = method.ReturnType.For(template.Name),
            ["ParamsWithType"] = GetParamsWithType(method.Parameters, template),
            ["ParamsVariantConverted"] = GetParamsVariantConverted(method.Parameters, template),
            ["ParamsCount"] = method.Parameters.Length.ToString(),
            ["ParamsAppend"] = GetParamsAppend(method.Parameters, template),
            ["Params"] = GetParams(method.Parameters, template),
        };

        // Add return type handling
        foreach (var kvp in GetReturnTypeData(method.ReturnType, template)) {
            dictionary[kvp.Key] = kvp.Value;
        }

        return dictionary;
    }

    private static Dictionary<string, string> BuildPropertyDictionary(Parser.FileContent.Property property, Template template) {
        return new Dictionary<string, string> {
            ["Name"] = property.Name,
            ["Type"] = property.Type.For(template.Name),
        };
    }

    private static Dictionary<string, string> BuildSignalDictionary(Parser.FileContent.Signal signal, Template template) {
        return new Dictionary<string, string> {
            ["Name"] = signal.Name,
            ["ParamsWithType"] = GetParamsWithType(signal.Parameters, template),
            ["ParamsAppend"] = GetParamsAppend(signal.Parameters, template),
        };
    }

    private static Dictionary<string, string> BuildOwnedSignalDictionary(Parser.FileContent.Signal signal, Template template) {
        return new Dictionary<string, string> {
            ["Name"] = signal.Name,
            ["ParamsWithType"] = GetParamsWithType(signal.Parameters, template),
        };
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
        data.SectionData[SectionType.Constructors] = fileContent.Constructors.Select(c => BuildConstructorDictionary(c, template)).ToList();
        data.SectionData[SectionType.Methods] = fileContent.Methods.Select(m => BuildMethodDictionary(m, template)).ToList();
        data.SectionData[SectionType.VirtualMethods] = fileContent.VirtualMethods.Where(m => m.Owned).Select(m => BuildVirtualMethodDictionary(m, template)).ToList();
        data.SectionData[SectionType.VirtualMethodsAll] = fileContent.VirtualMethods.Select(m => BuildVirtualMethodDictionary(m, template)).ToList();
        data.SectionData[SectionType.Properties] = fileContent.Properties.Where(p => !p.Assignable).Select(p => BuildPropertyDictionary(p, template)).ToList();
        data.SectionData[SectionType.PropertiesAssignable] = fileContent.Properties.Where(p => p.Assignable).Select(p => BuildPropertyDictionary(p, template)).ToList();
        data.SectionData[SectionType.SignalsAll] = fileContent.Signals.Select(s => BuildSignalDictionary(s, template)).ToList();
        data.SectionData[SectionType.Signals] = fileContent.Signals.Where(s => s.Owned).Select(s => BuildOwnedSignalDictionary(s, template)).ToList();
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