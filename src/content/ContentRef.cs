using Gindustry.IO;
using Godot;
using System;
using System.Threading.Tasks;

namespace Gindustry.Content;

[GlobalClass]
public partial class ContentRef : RefCounted, Saveable
{
    private string fullId;
    public string FullId
    {
        get => fullId;
        set
        {
            fullId = value;
            IdUpdated();
        }
    }

    private Content v;
    public Content V
    {
        get => v;
        set 
        {
            v = value;
            fullId = value.FullId;
            IdUpdated();
        }
    }

    private void IdUpdated()
    {
        if (v is null && String.IsNullOrEmpty(fullId)) return;
        if (v is not null && fullId == v.FullId) return;
        var nid = fullId;
        Vars.Contents.GetContentCallback(fullId, (obj) => {
            if (fullId != nid) return;
            v = obj;
        });
    }

    public void _LoadData(Reader r)
    {
        FullId = r.S();
    }
    public void _SaveData(Writer w)
    {
        w.S(fullId);
    }

    public static implicit operator Content(ContentRef v)
    {
        return v.V;
    }
}
