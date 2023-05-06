
**Syntax is not standard! If something doesn't work, that's not my problem!**

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

Argument 1 is the file to display (in Backgrounds folder).

Argument 2 can be:

| arg | what it does |
| --- | ------------ |
| fade | Fade from old to new background. |
| immediate <br> instant | Switch immediately. Duh. |
| (none) | If argument 2 is empty, the old background will fade to black then show the new background. |

# bg_fade_out_in

**This opcode is planned to be removed at some point.** It will fade the current background to black, then visible. It's obvious why this is unnecessary.

# flash
Flash the screen. You probably don't want to use this.

# portraits
Set portraits. Portraits can be a single argument, or can take additional parameters like positions.

Examples: `portraits	Kyuushou,false,0	Bronya,false,1`

Supports up to five main arguments.

Portrait arguments:

arg1: if masked (this doesn't work so don't bother)

arg2: offset from default position, from -6 to 6 usually (but can go higher)

# emote
Set portrait emote.

ARgument 1 = portrait to set, by name
Argument 2 = emote to set

# dim
Dims a portrait. 0-indexed. Unlike /hl[] this does NOT affect other portraits.

# music

Take a wild guess. Only mp3, ogg, and wav works. **If your music filename has special characters like $ it will not work.**

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

Argument 1: Variable name to set. `____` and `__choice__` are reserved variables and setting them will fail. Generally you should not prefix and suffix your variables with __.

Argument 2: operand.

Argument 3 (optional): if this variable is global.

| operand examples | what it does |
| ---------------- | ------------ |
| 7 | Sets the variable to value '7' |
| false <br> true | Sets the variable to true or false. Capitalization does not matter. |
| "A string here" | Sets the variable to the string "A string here". DOUBLE quotes must be used, not single. |
| &0 | Sets bitflag 0 in the variable to TRUE. If the variable is already set and not an integer type, it will fail while printing an error. |
| ~0 | Sets bitflag 0 in the variable to FALSE. If the variable is already set and not an integer type, it will fail while printing an error. |

# Conditional Jumps

## if
A special statement that simplifies logic branches by handling conditional jumps for you.

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
| 7 | Simply checks if an integer is equal to 7. |
| >7 | Take a wild guess. |
| >=7 | Take a wild guess. |
| <7 | Take a wild guess. |
| !7 | Check if not equal to 7. |
| "Matching?" | Checks if the variable matches the string "matching?". |
| &1 | Checks if bitflag 1 in the integer is TRUE. |
| ~1 | Checks if bitflag 1 in the integer is FALSE. |


# tween
NOT IMPLEMENTED YET

Argument 1: Before, during, or after text displays.

Argument 2: tween like StepMania's language. It's name, not position based. Ex. `Kyuushou:decelerate,.2;x,1;decelerate,.2;x,-1;decelerate,.2;x,0`
