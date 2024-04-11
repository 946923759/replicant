extends Control

#class dictItem:
#	name=

#Key/value cannot be done because of how pooling works
var dictionaryItems = [
	{
		"name":"All",
		"sort":"All",
		"entries":[]
	},
	{
		"name":"Overview",
		"entries":[
			"Honkai",
			"The First Honkai Outbreak",
			"The Second Honkai Outbreak",
			"The Third Honkai Outbreak",
			"Honkai Beasts",
			"Herrscher"
			#""
		],
	},
	{
		"name":"The World",
		"entries":[
			"Nagazora",
			"HOMU Paradise",
			#"Anti-Entropy",
			"ME Corporation"
		]
	},
	{
		"name":"Characters",
		"entries":[
			"Bronya Zaychik",
			"Seele Vollerei",
			"Sin Mal",
			"Cocolia",
			"Himeko Murata",
			"Houraiji Kyuushou",
		]
	},
	{
		"name":"Powers",
		"entries":[
			"Project Bunny"
		]
	}
]

var itemLengths:PoolIntArray=[]

onready var categoryList:VBoxContainer = $Container/CategorySelect/CategoryList
onready var termList:VBoxContainer = $Container/Panel/MarginContainer/ItemSelect/TermList

onready var rightPanelHeader=$Container/RightPanel/VBoxContainer/HeaderLabel
onready var rightPanelDesc=$Container/RightPanel/VBoxContainer/ScrollContainer/MarginContainer/RichTextLabel

var cActor=preload("res://Screens/OverlayDictionary/DictionaryCategoryActor.tscn")
var tActor=preload("res://Screens/OverlayDictionary/DictionaryTermActor.tscn")

func _ready():
	itemLengths.resize(dictionaryItems.size())
	for i in dictionaryItems.size():
		var categoryName = dictionaryItems[i]['name']
		#for i in dictionaryItems[k]:
		var cInst = cActor.instance()
		categoryList.add_child(cInst)
		cInst.connect("clicked",self,"category_click",[categoryName,0])
		cInst.text=categoryName
		
		var thisCategoryEntries=dictionaryItems[i]['entries']
		var numEntries=thisCategoryEntries.size()
		itemLengths[i]=numEntries
		for j in numEntries:
			var tInst = tActor.instance()
			termList.add_child(tInst)
			tInst.text=thisCategoryEntries[j]
			tInst.category = categoryName
	for i in termList.get_child_count():
		var tInst = termList.get_child(i)
		tInst.connect("clicked",self,"term_click",[tInst.text,i])
	#categoryList.add_item("Fuck")
	pass

func shitty_termlist_pool():
	pass

func category_click(c:String,i:int=0):
	for o in categoryList.get_children():
		if o.text==c:
			o.GainFocus()
			#break
		else:
			o.LoseFocus()
	print(c)
	
	#var t:SceneTreeTween = get_tree().create_tween()
	#t.set_parallel()
	var numVisible = 0
	if c=="All":
		for obj in termList.get_children():
			obj.visible = true
			#obj.modulate.a = 0.0
			#t.tween_property(obj,"modulate:a", 1.0, .1).set_delay(numVisible*.05)
			numVisible+=1
	else:
		for obj in termList.get_children():
			obj.visible = (obj.category == c)
			if obj.visible:
				#obj.modulate.a = 0.0
				#t.tween_property(obj,"modulate:a", 1.0, .1).set_delay(numVisible*.05)
				numVisible+=1
	#for obj in termList.get_children():

func term_click(t:String,i:int=0):
	rightPanelHeader.text=INITrans.GetString("DictionaryTerms",t,false)
	rightPanelDesc.text=INITrans.GetString("DictionaryDescriptions",t)
