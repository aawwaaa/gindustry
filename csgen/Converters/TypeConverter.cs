using System;
using System.Linq;
using System.Collections.Generic;
using Microsoft.CodeAnalysis;

namespace Gen.Converters
{
    public class TypeConverter
    {
        private readonly Dictionary<string, string> _type2target;

        public TypeConverter(Dictionary<string, string> type2target)
        {
            _type2target = type2target;
        }

        public string ToGDScriptType(ITypeSymbol type)
        {
            if (type.SpecialType != SpecialType.None)
            {
                return ConvertSpecialType(type.SpecialType);
            }

            if (type.TypeKind == TypeKind.Array)
            {
                var arrayType = (IArrayTypeSymbol)type;
                return $"Array[{ToGDScriptType(arrayType.ElementType)}]";
            }

            if (type is INamedTypeSymbol namedType)
            {
                return ConvertNamedType(namedType);
            }

            return $"GenerateError_{type}";
        }

        private string ConvertSpecialType(SpecialType specialType)
        {
            return specialType switch
            {
                SpecialType.System_String => "String",
                SpecialType.System_Boolean => "bool",
                SpecialType.System_Single or SpecialType.System_Double => "float",
                SpecialType.System_Byte or SpecialType.System_SByte or
                SpecialType.System_Int16 or SpecialType.System_Int32 or
                SpecialType.System_Int64 or SpecialType.System_UInt16 or
                SpecialType.System_UInt32 or SpecialType.System_UInt64 or
                SpecialType.System_Decimal => "int",
                SpecialType.System_Object => "Variant",
                SpecialType.System_Void => "void",
                _ => $"GenerateError_{specialType}"
            };
        }

        private string ConvertNamedType(INamedTypeSymbol namedType)
        {
            if (_type2target.TryGetValue(namedType.Name, out var targetName))
            {
                return "Object";
            }

            if (namedType.ContainingNamespace.ToDisplayString().StartsWith("Godot"))
            {
                targetName = namedType.Name;
            }

            if (targetName == null && namedType.GetAttributes().Any(attr => attr?.AttributeClass?.Name == "GlobalClassAttribute"))
            {
                targetName = namedType.Name;
            }

            if (targetName == null)
            {
                return $"GenerateError_{namedType.Name}";
            }

            if (namedType.Name.EndsWith("Enum"))
            {
                return "int";
            }

            if (namedType.Name == "MultiplayerApi")
            {
                return "MultiplayerAPI";
            }

            if (namedType.Name == "Rid")
            {
                return "RID";
            }

            if (namedType.Name == "GodotObject")
            {
                return "Object";
            }

            if (namedType.IsGenericType)
            {
                var genericType = (INamedTypeSymbol)namedType.TypeArguments[0];
                return $"{targetName}[{ToGDScriptType(genericType)}]";
            }

            return targetName;
        }

        public string GetDefaultValue(string type)
        {
            if (type.StartsWith("Array"))
            {
                return "[]";
            }

            return type switch
            {
                "bool" => "false",
                "int" => "0",
                "float" => "0.0",
                "String" => "\"\"",
                "void" => "pass",
                "StringName" => "&\"\"",
                "RID" => "RID()",
                _ => "null"
            };
        }
    }
} 