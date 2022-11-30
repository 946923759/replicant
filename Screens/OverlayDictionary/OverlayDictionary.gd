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
onready var termList:VBoxContainer = $Container/Container/ItemSelect/TermList

onready var rightPanelHeader=$Container/RightPanel/HeaderLabel
onready var rightPanelDesc=$Container/RightPanel/ScrollContainer/RichTextLabel

var cActor=preload("res://Screens/OverlayDictionary/DictionaryCategoryActor.tscn")
var tActor=preload("res://Screens/OverlayDictionary/DictionaryTermActor.tscn")

func _ready():
	itemLengths.resize(dictionaryItems.size())
	for i in dictionaryItems.size():
		var k = dictionaryItems[i]['name']
		#for i in dictionaryItems[k]:
		var cInst = cActor.instance()
		categoryList.add_child(cInst)
		cInst.connect("clicked",self,"category_click",[k,0])
		cInst.text=k
		
		var thisCategoryEntries=dictionaryItems[i]['entries']
		var numEntries=thisCategoryEntries.size()
		itemLengths[i]=numEntries
		for j in numEntries:
			var tInst = tActor.instance()
			termList.add_child(tInst)
			tInst.text=thisCategoryEntries[j]
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
	#print(c)

func term_click(t:String,i:int=0):
	rightPanelHeader.text=INITrans.GetString("DictionaryTerms",t,false)
	rightPanelDesc.text=INITrans.GetString("DictionaryDescriptions",t)
