using Godot;
using Gindustry.World;
using Gindustry.Entities;

namespace Gindustry.Test;

// 创建一个具体的测试实体类
public partial class TestEntity : Entity
{
    // TestEntity now inherits directly from Entity which has default implementations
    // No need to override Dimension and Position properties unless custom behavior is needed
}

[GlobalClass]
public partial class EntityTest: RefCounted
{
    [Test("Entity", "IdAllocation")]
    public void TestIdAllocation(TestReporter r)
    {
        var entity = new TestEntity();
        entity.ObjectCreate();
        var id1 = entity.objectId;
        var entity2 = new TestEntity();
        entity2.ObjectCreate();
        var id2 = entity2.objectId;
        r.NotEqual(id1, id2);
        entity.ObjectFree();
        entity2.ObjectFree();
        r.Assert(!Vars.Objects.objects.ContainsKey(id1));
        r.Assert(!Vars.Objects.objects.ContainsKey(id2));
    }

    [Test("Entity", "PropertyAccess")]
    public void TestPropertyAccess(TestReporter r)
    {
        var entity = new TestEntity();
        var dimension = new Dimension();
        var position = new Vector3(1, 2, 3);
        
        // 测试属性设置
        entity.Dim = dimension;
        entity.Position = position;
        
        // 测试属性获取
        r.Equal(entity.Dim, dimension);
        r.Equal(entity.Position, position);
        
        entity.ObjectFree();
        dimension.ObjectFree();
    }
}