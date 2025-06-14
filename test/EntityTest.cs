using Godot;

namespace Gindustry.Test;

[GlobalClass]
public partial class EntityTest: RefCounted
{
    [Test("Entity", "IdAllocation")]
    public void TestIdAllocation(TestReporter r)
    {
        var entity = new Entity();
        entity.ObjectCreate();
        var id1 = entity.objectId;
        var entity2 = new Entity();
        entity2.ObjectCreate();
        var id2 = entity2.objectId;
        r.NotEqual(id1, id2);
        entity.ObjectFree();
        entity2.ObjectFree();
        r.Assert(!Vars.Objects.objects.ContainsKey(id1));
        r.Assert(!Vars.Objects.objects.ContainsKey(id2));
    }
}