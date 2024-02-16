class_name techTree
var all:Array[techNode]=[]
var roots:Array[techNode]=[]
var context:techNode
func nodeRoot(con:unlockableContent,itemR:Array[Item],children:Callable,need:bool)-> techNode:
	var root=node(con,itemR,children,need)
	roots.append(root)
	return root

func node(content:unlockableContent,itemReq:Array[Item],children:Callable,need:bool)-> techNode:
	var node=techNode.new(context,itemReq,content,need)
	var prev=context
	context=node
	children.call()
	all.append(node)
	context=prev
	return node
	
	
