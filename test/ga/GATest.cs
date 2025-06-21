using Godot;
using Gindustry.Attributes;
using Gindustry.Test;
using Gindustry.Object;

namespace Gindustry.Test.GA;

[GlobalClass]
public partial class GATest: RefCounted {
	[Test("GA", "CSharpClass")]
	public void TestCSharpClass(TestReporter r) {
		var c = new CSharpClass();
		r.Equal(c.A, 100);
		c.Test();
		r.Equal(c.A, 1000);
		c.Test2();
		r.Equal(c.A, 2000);
		c.Free();
		
		var s = GD.Load<GDScript>("res://test/ga/godot_class.gd" /*res://test/ga/godot_class.gd*/);
		var v = s.New();
		c = Gindustry.Object.GA.U<CSharpClass>(v.AsGodotObject());
		
		if (c == null) {
			r.Failed("无法通过GA系统创建CSharpClass实例");
			return;
		}
		
		r.Equal(c.A, 100);
		c.Test();
		r.Equal(c.A, 3000);
		c.Test2();
		r.Equal(c.A, 2000);
		c.Free();
	}
}
