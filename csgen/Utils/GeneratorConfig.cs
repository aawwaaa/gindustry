namespace Gen.Utils
{
    public static class GeneratorConfig
    {
        public static readonly string[] MethodBlacklist = new string[] {
            "GetType",
            "_Get",
            "_Set",
            "_GetPropertyList",
            "_PropertyCanRevert",
            "_PropertyGetRevert",
            "_ValidateProperty",
        };

        public static readonly string[] PropertyBlacklist = new string[] {
            "_ImportPath",
        };
    }
} 