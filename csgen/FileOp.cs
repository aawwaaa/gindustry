using System.Runtime.CompilerServices;

namespace Gindustry.Generator;

public class FileOp {
    public static string CallerPath([CallerFilePath] string? callerPath = null) => callerPath ?? "";
    public static string CallerDir([CallerFilePath] string? callerPath = null) => Path.GetDirectoryName(callerPath ?? "") ?? "";
    public static string ProjectRoot => Path.GetDirectoryName(CallerDir() ?? "") ?? "";
}