
**Syntax is not standard! If something doesn't work, that's not my problem!**

# `#`
Anything starting with # will not get compiled in. Instead, you can use two 'special' commands with #. You are free to use # for anything other than these two commands, of course.

ex. `#This is a comment`

## #NEXT
Set the next cutscene manually. Because it does not support branching or logic, this isn't nearly as useful as using `next` opcode (but that isn't implemented yet).

## #LANGUAGES
Set the language order if this cutscene has multiple languages.

Languages match the ISO-639-1 standard: https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes

CH is also aliased to ZH and JP is aliased to JA. Because I am clearly not an expert at language standards.

You will usually see `#LANGUAGES	KEY	EN	ZH	JA	PT` at the top of the story scripts included in the VN engine.

If an unsupported language is selected in the options and the file doesn't have that language, it will fall back to the first column.

# /
Special opcode that gets turned into speaker & msg internally. Sets speaker and message in one line.

Example: `/Kyuushou	Hello world!`

# tn
If used right before a message, display a translation note button that can be clicked or viewed by holding shift.

# msg
Display a message.

## Text modifiers

### Text colors
Text can be colored at any time.

Example: `You can combine normal and [color=#FF0000]colored[/color] text in the same message.`

### Italics

Use `[i]this[/i]` For italic text.

### variables

Use %var_name% to do it. Refer to 'setting variables' for more information.

Variables cannot have spaces in their names.

**strings and integers are the only types truly stored internally. This means printing booleans and bitflags will simply print their 'real' integer.**

As an alternative for booleans, you can do this:
```
if	my_boolean	true:
	var	_temporary	"true"
else:
	var	_temporary	"false"
msg	You set my_boolean to %_temporary%!
```


### {w=}
Wait w seconds before continuing. Works anywhere.

`I am a message with pauses. H{w=.2}e{w=.2}l{w=.2}l{w=.2}o World.`

## Modifier commands
Some message modifier commands are available. Modifier commands must be at the start of the message.

### /hl[X]
Highlights the portrait specified in the argument by dimming all the others. 0-indexed.

### /close
Equivalent to close_textbox opcode, but takes no arguments.

### /open
Equivalent to open_textbox opcode, but takes no arguments.

### /setDispChr[XX]
Starts off this message already displaying the number of characters in the argument. You probably don't need to use this, as the `extend` opcode will automatically calculate and convert it for you.


# extend
Special opcode that makes a line extend from the previous message. Can be stacked infinitely.

Internally this just converts your message into another `msg` command with a `/setDispChr[]` modifier at the beginning.

# set_fs
Sets fullscreen mode, somewhat like old VNs.
Argument 1: true or false. Duh.

# popup

Instead of displaying text normally, turns it into a popup box.

This opcode takes two kinds of arguments. You can use `popup	false` or `popup	off` to turn it off when you're done, or you can specify x/y coordinates.

Argument 1: x position. Random if -1.
Argument 2: y position. Random if -1.

# msgbox_open, msgbox_close, 
Take a wild guess.

msgbox_close takes `instant` as a an argument in case you want to display a graphic right when the cutscene starts.

# msgbox_transition
Run `msgbox_open` and `msgbox_close` one after another.

# choice
Add to choice table. Choices are displayed when a msg opcode is used. Afterwards, you can use condjmp_c to jump based on the choice result.

Example:
```py
choice	Test Choice 1
choice	Test Choice 2
choice	Test Choice 3
msg	This is a choice test. Select a choice.
```

# dchoice

Add to choice table, set custom result when choice picked. Short for "destination choice", since I can't come up with anything better.

Mixing dchoice and choice can cause choices to be overwritten, so you should only use one. The only time you should ever need dchoice is if you want to make disappearing choices.

```py
dchoice	100	Test choice 1
dchoice	200	Test choice 2
msg	Pick a choice

# Jump if dchoice 2 was picked.
condjmp_c	choice_2	200
```

# nop
No-operation. This opcode does nothing.

# label
This opcode does nothing on its own, but a `condjmp_c` can jump to it.

**The label __fi__ is reserved and necessary for if statements. Using it will break your script.**

# bg
Set background.

Usage examples:
```ini
bg	009/022_1280x720	immediate
bg	white
```

Argument 1 is the file to display (in Backgrounds folder).

Argument 2 can be:

| arg | what it does |
| --- | ------------ |
| fade | Fade from old to new background. |
| immediate <br> instant | Switch immediately. Duh. |
| tween | Use a custom tween to change the background. In this case, argument 3 is the old background, argument 4 is the new background, and argument 5 (optional) is the quad when no backgrounds are displayed. |
| (none) | If argument 2 is empty, the old background will fade to black then show the new background. |

## bg custom tweens

Because being limited to in-engine tweens would be a terrible idea. This is for applying a custom transition.

### Flash BG white before changing

arg 3: diffusealpha,0;

arg 4: sleep,.1;diffusealpha,1

arg 5: diffuse,#FFFFFF

# bg_custom

Load a background image with custom parameters. Other than the first argument, everything else is identical to bg.

Parameters are separated by `;` and in the format of `key=value`. Any parameter that is exposed in Godot is supported. `SCREEN_CENTER_X` and `SCREEN_CENTER_Y` are also exposed as constants, and math is also supported.

Texture must be specified as a parameter (obviously). Everything else is optional. name defaults to texture if not specified.

Examples:
```
bg_custom	modulate="#FFFFFF"; Texture="aliceroom1"; name="aliceroom1"	tween		y,500;linear,5;addy,-500
bg_custom	Texture="aliceroom1"; name="aliceroom1"; rect_scale=Vector2(3,3); rect_position=Vector2(828,424);
bg_custom	Texture="aliceroom1"; name="aliceroom1"; rect_position=Vector2(SCREEN_CENTER_X,SCREEN_CENTER_Y);
```

# bg_fade_out_in

**This opcode is planned to be removed at some point.** It will fade the current background to black, then visible. It's obvious why this is unnecessary.


# flash
Flash the screen. You probably don't want to use this.

# portrait / portraits
Set portraits. Portraits can be a single argument, or can take additional parameters like positions.

I got tired of remembering which one was valid, so both are allowed.

Examples: `portraits	Kyuushou,false,0	Bronya,false,1`

Supports up to five portraits.

Portrait arguments:

arg1: if masked (this doesn't work so don't bother)

arg2: offset from default position, from -6 to 6 usually (but can go higher)

arg3: if automatic tweening should be enabled.

# emote
Set portrait emote.

ARgument 1 = portrait to set, by name
Argument 2 = emote to set

# dim
Dims a portrait. 0-indexed. Unlike /hl[] this does NOT affect other portraits.

# music

Take a wild guess. Only mp3, ogg, and wav works. **If your music filename has special characters like $ it will not work.**

Argument 1 (optional): How long to fade in music. Defaults to immediate.

# se

Plays a sound effect. **Again, do not use $ in filenames.**

# stopmusic or stop_music

Stops music. Defaults to immediate.

Argument 1 (optional): how long to fade out music.

# shake_camera
Shakes the camera. This effect is somewhat buggy due to being tied to your computer's processing speed.

Argument 1 (optional): How much to shake the camera. Defaults to 3.0 if not present.

# Setting Variables

The `var` opcode will set a variable. A variable can either be a boolean, a string, an integer, or a bitflag.

Examples: `var testvar 7`, `var testvar "Hello!"`, `var testvar &0`, `var testvar false`

Argument 1: Variable name to set. `____` and `__choice__` are reserved variables and setting them will fail. Generally you should not prefix and suffix your variables with __. Prefix variables with `G_` to make them global.

Variables are saved per-slot like any other VN, but if you want a variable to be accessible from all slots, prefix it with S_ (Short for SYSTEM, as in the systemwide save data).

Argument 2: operand.

| operand examples | what it does |
| ---------------- | ------------ |
| 7 | Sets the variable to value '7' |
| false <br> true | Sets the variable to true or false. Capitalization does not matter. |
| "A string here" | Sets the variable to the string "A string here". DOUBLE quotes must be used, not single. |
| &0 | Sets bitflag 0 in the variable to TRUE. If the variable is already set and not an integer type, it will fail while printing an error. |
| ~0 | Sets bitflag 0 in the variable to FALSE. If the variable is already set and not an integer type, it will fail while printing an error. |
| +1 | Adds 1 to the variable that has been set already. |
| -1 | Subtracts 1. |
| /2 | Divides by 2. Yes, division by 0 will crash. |
| *2 | ... |
| =testvar2 | Copies the contents of 'testvar2' into the variable specified in argument 1. This way you can duplicate a variable and modify it instead of modifying the original. |
# Conditional Jumps

## if
A special statement that simplifies logic branches by handling conditional jumps for you. Refer to condjumps section for possible parameters.

You may choose to put ":" at the end of the conditional (ex. `if hasItem true:`), but it is not required and the ":" will be ignored. This is also true for "else" statements, you can write them with or without the ":".

Starting with this statement:
```
label	choice_loop
dchoice	0	What's your full name?
dchoice	1	You're a Herrscher, right?
msg	What should I ask...
```

It can be written with an if statement like this:
```
if	choice	0:
  /Kyuushou	My name is Kyuushou Houraiji, the savior of the world!
  var	kyuu	&0
if	choice	1:
  /Kyuushou	I'm the Herrscher of the Void.
  var	kyuu	&1
```

Or written flat like this (notice how jmp statements are required):
```
condjmp_c	c2dest	1
/Kyuushou	My name is Kyuushou Houraiji, the savior of the world!
var	kyuu	&0
jmp	end_choices

label	c2dest
/Kyuushou	I'm the Herrscher of the Void.
var	kyuu	&1
jmp	end_choices
```

However, writing an if-else statement is not so easy, and that's where the if/else command helps significantly.
```
if	kyuu_affection	>1:
	/Kyuushou	Hey, player! Nice day, isn't it?
else:
	/Kyuushou	Hi, player.
msg	Let's complete our mission.
```

Flat statement:
```
condjmp_neg	else	kyuu_affection	>1
/Kyuushou	Hey, player! Nice day, isn't it?
jmp	fi

label	else
/Kyuushou	Hi, player. 

label	fi
msg	Let's complete our mission.
```




## condjmp_c

The simplest jump. jump to label if choice result is equal.

Argument 1: label

Argument 2: choice result, aka what choice was picked.

`condjmp_c	c2dest	2`

## condjmp & condjmp_neg


Argument 1: What label to jump to.

Argument 2: Variable to check. You can also check choices using __choice__.

Argument 3: How to compare. Will be false if the type comparison does not match the variable, unless you try to compare an integer and boolean. In which case, you're an idiot.

condjmp_neg jumps if result of comparison is false.

| operand examples | what it does |
| ---------------- | ------------ |
| true | Take a wild guess. Attempting to compare this with an integer makes it true for anything other than 0. |
| false | Take a wild guess. Attempting to compare this with an integer makes it false only if the variable is 0. |
| null | Special check. True if this variable doesn't exist. |
| 7 | Simply checks if an integer is equal to 7. |
| >7 | Take a wild guess. |
| >=7 | Take a wild guess. |
| <7 | Take a wild guess. |
| !7 | Check if not equal to 7. |
| "Matching?" | Checks if the variable matches the string "matching?". |
| &1 | Checks if bitflag 1 in the integer is TRUE. |
| ~1 | Checks if bitflag 1 in the integer is FALSE. |

## jmp
Jumps to a label. Argument 1 is the label to jump to, obviously.

Internally, all jump commands are converted to condjumps with "TRUE" as the variable to check.

If you want to jump to the end, put a label at the end of the file and a jump statement to that label. Calling it `__end__` is the standard.

# tween

Argument 1: Before, during, or after text displays.

Argument 2: Portrait or background to tween. Giving the background and portrait the same file name will cause it to pick the portrait first, but GGZ groups backgrounds in folders so this shouldn't happen normally. If for some reason you want to do this (which you really shouldn't), you may load a background with custom parameters and override the name field.

Argument 3: tween like StepMania's language. Ex. `decelerate,.2;x,1;decelerate,.2;x,-1;decelerate,.2;x,0`

Refer to smTween.gd for a list of commands, and test_tween.txt for an example of this in action.


Example of tweening a portrait:
```
portraits	58
msg	This is a tween test.
tween	current	58	linear,.5;addx,-100
msg	This tween moved me to the left!
```

Example of tweening a background:
```
bg	009/022_1280x720	immediate
msg	This is a background. Woah!
tween	current	009/022_1280x720

```
# vibrate
Vibrates the controller or a mobile phone.

Argument 1: duration. If not specified, defaults to 0.5.

~~Argument 2: weak magnitude (vibrates the weak motor in the controller)~~

~~Argument 3: strong magnitude (vibrates the strong motor in the controller)~~



# IMPLEMENT SOON
## screen
Next screen to go to. Screens are defined in Globals.SCREENS. Short list of screens:

| screen | description |
| ------ | ----------- |
| ScreenTitleMenu | The main menu. |
| ScreenGallery | Gallery. |
| ScreenSoundTest | Sound Test / Music player. |
| ScreenFirstRun | Take a wild guess. |
| ScreenWebWarning | Screen informing the user that this is a demo. |
| ScreenSelectChapter | Chapter select. |
| **CutsceneFromFile** | This is the main cutscene player. By default, the cutscene player will loop at this screen so you don't need to set it. |
| ScreenProgrammerCredits | Programmer credits. |
| ScreenSelectEra (Unused) | Set Retro, Reborn, or Fire Moth modes. Only Fire Moth is implemented... |


## next
Next cutscene to go to. Automatically selected based on ch-sel-db.tsv, but this command can override it if you want to branch to a different cutscene depending on a choice.
