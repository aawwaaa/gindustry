class_name techNode
var content:unlockableContent
var depth:int
var name:String
var requiresUnlock:bool
var parent:techNode
var children:Array[techNode]=[]
var finishedRequirements:Array[Item]=[]
var itemsMap:={}
var requirements:Array[Item]=[]

func _init(par:techNode,requirements:Array[Item],con:unlockableContent,need:bool):
	requiresUnlock=need
	content=con
	finishedRequirements=[]
	for it in requirements:
		var item=Item.new()
		item.item_type = it.item_type
		item.amount = it.amount
		finishedRequirements.append(item)
		itemsMap[it.item_type.index]=it.item_type
	if par==null:
		depth=0
	else:
		depth=parent.depth+1
		parent.children.append(self)
		
func save_data(stream:Stream):
	stream.store_8(finishedRequirements.size())
	for item in finishedRequirements:
		stream.store_16(item.item_type.index)
		stream.store_16(item.amount)

func load_data(stream:Stream):
	finishedRequirements.clear()
	var size=stream.get_8()
	for it in range(size):#TODO itemType
		var index=stream.get_16()
		var item=itemsMap.get(index)
		var amount=stream.get_16()
		var i=Item.new()
		i.item_type = item
		i.amount = amount
		finishedRequirements.append(i)
