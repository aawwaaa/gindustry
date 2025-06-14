using System;
using Microsoft.CodeAnalysis;

namespace Gen.Utils
{
    public class TemplateManager
    {
        private string _csharpTemplate = "";
        private string _csharpCompatibilityTemplate = "";
        private string _gdscriptTemplate = "";

        public void Initialize(GeneratorExecutionContext context)
        {
            foreach (var file in context.AdditionalFiles)
            {
                if (file.Path.EndsWith("GDScriptAdapterTemplate.t.cs"))
                    _csharpTemplate = file.GetText(context.CancellationToken)!.ToString();
                if (file.Path.EndsWith("GDScriptCompatibilityTemplate.t.cs"))
                    _csharpCompatibilityTemplate = file.GetText(context.CancellationToken)!.ToString();
                if (file.Path.EndsWith("gdscript_adapter_template.t.gd"))
                    _gdscriptTemplate = file.GetText(context.CancellationToken)!.ToString();
            }

            _csharpTemplate = _csharpTemplate.Replace("# if NEVER", "").Replace("# endif", "");
            _csharpCompatibilityTemplate = _csharpCompatibilityTemplate.Replace("# if NEVER", "").Replace("# endif", "");
        }

        public string GetCSharpTemplate() => _csharpTemplate;
        public string GetCSharpCompatibilityTemplate() => _csharpCompatibilityTemplate;
        public string GetGDScriptTemplate() => _gdscriptTemplate;
    }
} 