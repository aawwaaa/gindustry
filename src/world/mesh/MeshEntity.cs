using Gindustry.Attributes;
using Gindustry.Entities.Type.Base;
using Godot;

namespace Gindustry.World.Mesh;

[GDScriptAdapterTarget("GA_MeshEntity")]
[GlobalClass]
public partial class MeshEntity : StandaloneEntity
{
    protected override void UpdateChunks()
    {
        foreach (var child in Children)
        {
            if (child is MeshChunk meshChunk)
            {
                // TODO
            }
        }
    }

    public override void _LoadData(Gindustry.IO.Reader r)
    {
        base._LoadData(r);
    }

    public override void _SaveData(Gindustry.IO.Writer w)
    {
        base._SaveData(w);
    }
}