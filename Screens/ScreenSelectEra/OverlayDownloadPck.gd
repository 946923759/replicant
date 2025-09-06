extends "res://Screens/ScreenWithMenuElements.gd"

#I don't need github spambots scraping this repo and then my website, thanks
var CDN_URL = Marshalls.base64_to_utf8("aHR0cHM6Ly93d3cuYW1hcnlsbGlzd29ya3MucHcvZ2FtZXMvcmVwbGljYW50")
export(String) var fileToDownload = "Reborn.pck"

func _ready():
	fileToDownload = Globals.getenv("fileToDownload",fileToDownload)
	var downloadFilePath = "user://"
	#print(OS.get_executable_path().get_base_dir())
	#if Globals.is_pc_filesystem():
	#	downloadFilePath = OS.get_executable_path().get_base_dir()
		#print(downloadFilePath)
		#return
	#assert(downloadFilePath)
	var fullDownloadURLPath = CDN_URL+"/"+fileToDownload
	
	print("Downloading "+fullDownloadURLPath)
	print("Saving download to "+downloadFilePath)
	$VBoxContainer/Label.text = "Downloading "+fileToDownload
	$FileDownloader.start_download([fullDownloadURLPath], downloadFilePath)

#emit_signal("stats_updated",
#    _downloaded_size,
#    _downloaded_percent,
#    _file_name,
#    _file_size)
func _on_FileDownloader_stats_updated(
	_downloaded_size,
	_downloaded_percent,
	_file_name,
	_file_size):
	$VBoxContainer/ProgressBar.value = _downloaded_percent


func _on_FileDownloader_downloads_finished():
	Globals.load_dlc()
	OffCommandNextScreen()
