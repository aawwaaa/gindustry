using System;
using System.Text;
using System.Collections.Generic;
using System.Diagnostics;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.Text;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;

namespace Gen {};

[Generator]
public class CSharpScriptGenerator : ISourceGenerator
{
    private static string projectBase = "";

    private static void Cleanup(GeneratorExecutionContext context, string path)
    {
        path = Path.Combine(projectBase, "gen", path);

        if (File.Exists(path))
        {
            File.Delete(path);
        }
    }

    private static void GenerateFile(GeneratorExecutionContext context, string path, string data)
    {
        var fullPath = Path.Combine(projectBase, "gen", path);
        var dir = Path.GetDirectoryName(fullPath)!;
        if (!Directory.Exists(dir))
        {
            Directory.CreateDirectory(dir);
        }
        File.WriteAllText(fullPath, data);
    }


    public void Initialize(GeneratorInitializationContext context)
    {
        // 注册一个语法接收器，用于查找带有特定属性的类
        context.RegisterForSyntaxNotifications(() => new SyntaxReceiver());
    }
    public void Execute(GeneratorExecutionContext context)
    {
        if (context.SyntaxReceiver is not SyntaxReceiver receiver)
            return;

        foreach (var file in context.AdditionalFiles)
        {
            if (file.Path.EndsWith("gindustry.csproj"))
               projectBase = Path.GetDirectoryName(file.Path)!;
        }

        var output = new StringBuilder();

        output.Append("class_name CSScript\n");

        foreach (var pair in receiver.Targets)
        {
            var classDeclaration = pair.Key;
            var attributeData = pair.Value;
            if (attributeData is null)
                continue;
            var targetName = attributeData.ArgumentList?.Arguments.FirstOrDefault()?.GetText().ToString().Replace("\"", "");
            if (targetName is null) 
                continue;
            var path = classDeclaration.SyntaxTree.FilePath;
            path = Path.GetRelativePath(projectBase, path);
            output.Append($@"
static var {targetName}: CSharpScript:
    get:
        if {targetName}:
            return {targetName}
        {targetName} = load(""res://{path}"")
        return {targetName}
");
        }
        
        GenerateFile(context, "gdscript/CSharpScript.gd", output.ToString());
    }

    class SyntaxReceiver : ISyntaxReceiver
    {
        public Dictionary<ClassDeclarationSyntax, AttributeSyntax> Targets { get; } = new();

        public void OnVisitSyntaxNode(SyntaxNode syntaxNode)
        {
            if (syntaxNode is not ClassDeclarationSyntax classDeclaration) return;
            if (classDeclaration.AttributeLists.Count == 0) return;
            foreach (var attributes in classDeclaration.AttributeLists)
            {
                foreach (var attribute in attributes.Attributes)
                {
                    if (attribute.Name.ToString() == "CSharpScriptName")
                        Targets.Add(classDeclaration, attribute);
                }
            }
        }
    }

}


[AttributeUsage(AttributeTargets.Class)]
public class CSharpScriptNameAttribute : Attribute
{
    public String Name { get; }

    public CSharpScriptNameAttribute(String targetName)
    {
        Name = targetName;
    }
}

