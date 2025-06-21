using Godot;
using System.Threading.Tasks;
using Gindustry.IO;

namespace Gindustry.Object;

[GlobalClass]
public partial class RefObjectRef : RefCounted, Saveable
{
    private ulong id;
    public ulong Id
    {
        get => id;
        set
        {
            id = value;
            IdUpdated();
        }
    }

    private RefObject v;
    public RefObject V
    {
        get => v;
        set 
        {
            v = value;
            id = value.objectId;
            IdUpdated();
        }
    }

    private void IdUpdated()
    {
        if (v is null && id == 0) return;
        if (v is not null && id == v.objectId) return;
        var nid = id;
        Vars.Objects.GetObjectCallback(id, (obj) => {
            if (id != nid) return;
            v = obj;
        });
    }

    public void _LoadData(Reader r)
    {
        Id = r.U64();
    }
    public void _SaveData(Writer w)
    {
        w.U64(id);
    }

    public static implicit operator RefObject(RefObjectRef v)
    {
        return v.V;
    }
}
