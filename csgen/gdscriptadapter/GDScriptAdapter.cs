using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using Microsoft.CodeAnalysis.Text;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;

namespace Gindustry.Generator.GDScriptAdapter;

[Generator]
public class GDScriptAdapterGenerator : ISourceGenerator
{
    public FileStream? logFile;
    public void Initialize(GeneratorInitializationContext context)
    {
        try {
            logFile = new FileStream(FileOp.ProjectRoot + "/log.txt", FileMode.Create, FileAccess.Write, FileShare.ReadWrite);
        } catch (Exception) { }
        Log("Initialize", DateTime.Now);
        context.RegisterForSyntaxNotifications(() => new GDScriptAdapterSyntaxReceiver(logFile));
    }
    public void Log(params object[] messages)
    {
        logFile?.Write(Encoding.UTF8.GetBytes(string.Join(" ", messages) + "\n"));
        logFile?.Flush();
    }

    public void Execute(GeneratorExecutionContext context)
    {
        try {
            ExecuteReal(context);
        } catch (Exception e) {
            Log(" --- Error ---");
            Log(e.Message);
            Log(e.StackTrace!);
            Log(" --- Error ---");
            throw;
        }
    }

    public void ExecuteReal(GeneratorExecutionContext context)
    {
        if (context.SyntaxReceiver is not GDScriptAdapterSyntaxReceiver receiver)
        {
            return;
        }

        var gdOutputDir = FileOp.ProjectRoot + "/gen/gdscript";
        if (Directory.Exists(gdOutputDir))
        {
            foreach (var file in Directory.GetFiles(gdOutputDir))
            {
                if (file.EndsWith(".g.gd"))
                    File.Delete(file);
            }
        }
        Directory.CreateDirectory(gdOutputDir);

        Anaylsis.Init(context, logFile);

        foreach (var target in receiver.Targets)
        {
            Anaylsis.AddSource(target.ClassDeclarationSyntax, target.TargetName);
        }

        Anaylsis.SolveBaseClasses();
        var anaylsisResult = Anaylsis.Execute();
        Anaylsis.Reset();

        Parser.Init(context, logFile);
        var parserResult = Parser.Execute(anaylsisResult);
        Parser.Reset();

        Render.LogFile = logFile;
        Log(" --- Render --- ");
        var cs = Render.LoadTemplate("cs");
        var gd = Render.LoadTemplate("gd");
        foreach (var fileContent in parserResult.FileContents) {
            Log("Render", fileContent.Key);
            var csContent = cs.RenderWithData(fileContent.Value);
            context.AddSource(fileContent.Value.TargetName + ".g.cs", csContent);
            var gdContent = gd.RenderWithData(fileContent.Value);
            File.WriteAllText(Path.Combine(gdOutputDir, fileContent.Value.TargetName + ".g.gd"), gdContent);
        }
        var ga = Render.LoadTemplate("GA_cs");
        var gaContent = Render.RenderGA(ga, parserResult);
        context.AddSource("GA.g.cs", gaContent);
        Log(" --- Render --- ");
    }
}

public class GDScriptAdapterSyntaxReceiver(FileStream? logFile) : ISyntaxReceiver
{
    public struct Target
    {
        public string TargetName;
        public ClassDeclarationSyntax ClassDeclarationSyntax;
    }
    public void Log(params object[] messages)
    {
        logFile?.Write(Encoding.UTF8.GetBytes(string.Join(" ", messages) + "\n"));
        logFile?.Flush();
    }
    public List<Target> Targets = new();
    public void OnVisitSyntaxNode(SyntaxNode syntaxNode)
    {
        if (syntaxNode is ClassDeclarationSyntax classDeclarationSyntax)
        {
            var attribute = classDeclarationSyntax.AttributeLists.SelectMany(x => x.Attributes).FirstOrDefault(x => x.Name.ToString() == "GDScriptAdapterTarget");
            if (attribute != null && attribute.ArgumentList != null)
            {
                var firstArgument = attribute.ArgumentList.Arguments.FirstOrDefault();
                if (firstArgument != null && firstArgument.Expression is LiteralExpressionSyntax literalExpression)
                {
                    var targetName = literalExpression.Token.ValueText;
                    if (!string.IsNullOrEmpty(targetName))
                    {
                        Targets.Add(new Target()
                        {
                            TargetName = targetName,
                            ClassDeclarationSyntax = classDeclarationSyntax
                        });
                        Log("Found target:", targetName);
                    }
                }
            }
        }
    }
}