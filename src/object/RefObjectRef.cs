using Godot;
using System.Threading.Tasks;
using Gindustry.IO;
using System;

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

public partial class RefObjectRefGeneric<T> : RefObjectRef where T : RefObject
{
    public new T V
    {
        get => base.V as T;
        set => base.V = value;
    }

    public void LoadData(Reader r)
    {
        this._LoadData(r);
    }
    public void SaveData(Writer w)
    {
        this._SaveData(w);
    }

    public static implicit operator T(RefObjectRefGeneric<T> v)
    {
        return v?.V as T;
    }
}