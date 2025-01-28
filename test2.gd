extends Object

func init() -> void:
    GA.LoadStatics();
    var arr: Array[RefObjectA] = []
    arr.append(RefObjectA.new())
    arr.append(A.new().get_instance())
    for obj in arr:
        obj.FooBar()

class A extends GA_RefObjectA:
    func _foo() -> void:
        print("baz")
