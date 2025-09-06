#!/usr/bin/env python3
import sys

with open(sys.argv[1], 'r') as f:
	lines = f.readlines()
with open(sys.argv[1], 'w') as f:
	for l in lines:
		if l.startswith("emote\t"):
			cmnd = l.split("\t")
			character = int(cmnd[1])
			expression = int(cmnd[2])
			if (character==101 or character==201) and expression>0:
				l = f"emote\t{character}\t{expression+1}\n"
				print(l)
		f.write(l)
	print("Fix "+sys.argv[1])
