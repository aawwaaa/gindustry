class_name TechTree
var all:Array[TechNode]=[]
var roots:Array[TechNode]=[]
var context:TechNode
func nodeRoot(con:UnlockableContent,itemR:Array[Item],children:Callable,need:bool)-> TechNode:
	var root=node(con,itemR,children,need)
	roots.append(root)
	return root

func node(content:UnlockableContent,itemReq:Array[Item],children:Callable,need:bool)-> TechNode:
	var node=TechNode.new(context,itemReq,content,need)
	var prev=context
	context=node
	children.call()
	all.append(node)
	context=prev
	return node
	
	
