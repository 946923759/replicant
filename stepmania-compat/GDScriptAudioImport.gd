#GDScriptAudioImport v0.1

#MIT License
#
#Copyright (c) 2020 Gianclgar (Giannino Clemente) gianclgar@gmail.com
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

#I honestly don't care that much, Kopimi ftw, but it's my little baby and I want it to look nice :3

extends Node

func report_errors(err, filepath):
	# See: https://docs.godotengine.org/en/latest/classes/class_@globalscope.html#enum-globalscope-error
	var result_hash = {
		ERR_FILE_NOT_FOUND: "File: not found",
		ERR_FILE_BAD_DRIVE: "File: Bad drive error",
		ERR_FILE_BAD_PATH: "File: Bad path error.",
		ERR_FILE_NO_PERMISSION: "File: No permission error.",
		ERR_FILE_ALREADY_IN_USE: "File: Already in use error.",
		ERR_FILE_CANT_OPEN: "File: Can't open error.",
		ERR_FILE_CANT_WRITE: "File: Can't write error.",
		ERR_FILE_CANT_READ: "File: Can't read error.",
		ERR_FILE_UNRECOGNIZED: "File: Unrecognized error.",
		ERR_FILE_CORRUPT: "File: Corrupt error.",
		ERR_FILE_MISSING_DEPENDENCIES: "File: Missing dependencies error.",
		ERR_FILE_EOF: "File: End of file (EOF) error."
	}
	if err in result_hash:
		printerr("Error: ", result_hash[err], " ", filepath)
	else:
		printerr("Unknown error with file ", filepath, " error code: ", err)

func loadfile(filepath,loop=true):
	var file = File.new()
	var err = file.open(filepath, File.READ)
	if err != OK:
		report_errors(err, filepath)
		file.close()
		return AudioStreamSample.new()

	var bytes = file.get_buffer(file.get_len())

	# if File is wav
	if filepath.ends_with(".wav"):

		var newstream = AudioStreamSample.new()

		#---------------------------
		#parrrrseeeeee!!! :D

		for i in range(0, 100):
			var those4bytes = str(char(bytes[i])+char(bytes[i+1])+char(bytes[i+2])+char(bytes[i+3]))
			
			if those4bytes == "RIFF": 
				print ("RIFF OK at bytes " + str(i) + "-" + str(i+3))
				#RIP bytes 4-7 integer for now
			if those4bytes == "WAVE": 
				print ("WAVE OK at bytes " + str(i) + "-" + str(i+3))

			if those4bytes == "fmt ":
				print ("fmt OK at bytes " + str(i) + "-" + str(i+3))
				
				#get format subchunk size, 4 bytes next to "fmt " are an int32
				var formatsubchunksize = bytes[i+4] + (bytes[i+5] << 8) + (bytes[i+6] << 16) + (bytes[i+7] << 24)
				print ("Format subchunk size: " + str(formatsubchunksize))
				
				#using formatsubchunk index so it's easier to understand what's going on
				var fsc0 = i+8 #fsc0 is byte 8 after start of "fmt "

				#get format code [Bytes 0-1]
				var format_code = bytes[fsc0] + (bytes[fsc0+1] << 8)
				var format_name
				if format_code == 0: format_name = "8_BITS"
				elif format_code == 1: format_name = "16_BITS"
				elif format_code == 2: format_name = "IMA_ADPCM"
				print ("Format: " + str(format_code) + " " + format_name)
				#assign format to our AudioStreamSample
				newstream.format = format_code
				
				#get channel num [Bytes 2-3]
				var channel_num = bytes[fsc0+2] + (bytes[fsc0+3] << 8)
				print ("Number of channels: " + str(channel_num))
				#set our AudioStreamSample to stereo if needed
				if channel_num == 2: newstream.stereo = true
				
				#get sample rate [Bytes 4-7]
				var sample_rate = bytes[fsc0+4] + (bytes[fsc0+5] << 8) + (bytes[fsc0+6] << 16) + (bytes[fsc0+7] << 24)
				print ("Sample rate: " + str(sample_rate))
				#set our AudioStreamSample mixrate
				newstream.mix_rate = sample_rate
				
				#get byte_rate [Bytes 8-11] because we can
				var byte_rate = bytes[fsc0+8] + (bytes[fsc0+9] << 8) + (bytes[fsc0+10] << 16) + (bytes[fsc0+11] << 24)
				print ("Byte rate: " + str(byte_rate))
				
				#same with bits*sample*channel [Bytes 12-13]
				var bits_sample_channel = bytes[fsc0+12] + (bytes[fsc0+13] << 8)
				print ("BitsPerSample * Channel / 8: " + str(bits_sample_channel))
				
				#aaaand bits per sample/bitrate [Bytes 14-15] - TODO: Handle different bitrates
				var bits_per_sample = bytes[fsc0+14] + (bytes[fsc0+15] << 8)
				print ("Bits per sample: " + str(bits_per_sample))
				
				
			if those4bytes == "data":
				var audio_data_size = bytes[i+4] + (bytes[i+5] << 8) + (bytes[i+6] << 16) + (bytes[i+7] << 24)
				print ("Audio data/stream size is " + str(audio_data_size) + " bytes")

				var data_entry_point = (i+8)
				print ("Audio data starts at byte " + str(data_entry_point))
				
				newstream.data = bytes.subarray(data_entry_point, data_entry_point+audio_data_size-1)
				
			# end of parsing
			#---------------------------

		#get samples and set loop end
		var samplenum = newstream.data.size() / 4
		newstream.loop_end = samplenum
		newstream.loop_mode = 1 #change to 0 or delete this line if you don't want loop, also check out modes 2 and 3 in the docs
		return newstream  #:D

	#if file is ogg
	elif filepath.ends_with(".ogg"):
		var newstream = AudioStreamOGGVorbis.new()
		newstream.loop = loop #set to false or delete this line if you don't want to loop
		newstream.data = bytes
		return newstream

	#if file is mp3
	elif filepath.ends_with(".mp3"):
		var newstream = AudioStreamMP3.new()
		newstream.loop = loop #set to false or delete this line if you don't want to loop
		newstream.data = bytes
		return newstream

	else:
		printerr("ERROR: Wrong filetype or format")
	file.close()


# ---------- REFERENCE ---------------
# note: typical values doesn't always match

#Positions  Typical Value Description
#
#1 - 4      "RIFF"        Marks the file as a RIFF multimedia file.
#                         Characters are each 1 byte long.
#
#5 - 8      (integer)     The overall file size in bytes (32-bit integer)
#                         minus 8 bytes. Typically, you'd fill this in after
#                         file creation is complete.
#
#9 - 12     "WAVE"        RIFF file format header. For our purposes, it
#                         always equals "WAVE".
#
#13-16      "fmt "        Format sub-chunk marker. Includes trailing null.
#
#17-20      16            Length of the rest of the format sub-chunk below.
#
#21-22      1             Audio format code, a 2 byte (16 bit) integer. 
#                         1 = PCM (pulse code modulation).
#
#23-24      2             Number of channels as a 2 byte (16 bit) integer.
#                         1 = mono, 2 = stereo, etc.
#
#25-28      44100         Sample rate as a 4 byte (32 bit) integer. Common
#                         values are 44100 (CD), 48000 (DAT). Sample rate =
#                         number of samples per second, or Hertz.
#
#29-32      176400        (SampleRate * BitsPerSample * Channels) / 8
#                         This is the Byte rate.
#
#33-34      4             (BitsPerSample * Channels) / 8
#                         1 = 8 bit mono, 2 = 8 bit stereo or 16 bit mono, 4
#                         = 16 bit stereo.
#
#35-36      16            Bits per sample. 
#
#37-40      "data"        Data sub-chunk header. Marks the beginning of the
#                         raw data section.
#
#41-44      (integer)     The number of bytes of the data section below this
#                         point. Also equal to (#ofSamples * #ofChannels *
#                         BitsPerSample) / 8
#
#45+                      The raw audio data.            
