# Quantum Shell for Github's Atom!
A command line interface built directly into Atom! This package is largely inspired by (but not a direct fork of) [terminal-panel](http://github.com/thedaniel/terminal-panel). The goal of this project is to provide users with a simple, yet powerful tool, that no self-proclaimed 'Hackable' editor should be without. It is 1.0 ready and should make the transition in June seamlessly. Currently, this package should run as expected on Atom >=1.0.12 with any UNIX like operating system. Windows is now fully supported and shouldn't suffer any limitations that aren't also present on other platforms. To get started just search for and download `quantum-shell` in the Atom package manager, or at the command line type `apm install quantum-shell` and press `ctrl-shift-q` to get started. Happy Hacking!

## Features

### Multiple Terminals, as of v-0.6.0!
You can now run as many terminals as you would like side by side. Each will have its own unique history, aliases, environment and even underlying shell program! To run different shells next to one another, simply navigate to `Settings>Packages>quantum-shell>ShellName` and change the default. Now every *new* terminal you create will use that shell program until you destroy it. Even if you close Atom all the way down and restart it, you're settings will be preserved and you can continue to simultaneously run as many different shells as you would like!

### Full `history` support just like you're used to in bash
Just use the `up` and `down` arrow keys when the input field is focused to quickly navigate through your history, or use the `history` builtin to view a list of your past commands. A configuration option for limiting the number of commands to record can now be found under `Settings>Packages>quantum-shell>MaxHistory`. The default is 100.

### Rotating Tab Completion
At the request of user [@clebrun](http://github.com/clebrun), I have added a rotating tab completion feature! The way it works is simple. If you have not yet pressed the space-bar, pressing the `tab` key will cause `quantum-shell` to rotate through all of the program names referenced in your $PATH variable (including `quantum-shell` builtins) that match what you have already typed. If you have pressed the space-bar (meaning that you are working on typing word number two or higher), pressing the `tab` key will rotate through all of the file names along the relative path you have typed. This is a very exciting new feature, so please feel free to share any comments and/or bugs that you might discover!

### Customizable Prompt String
The prompt string is one of the defining features of any good shell program, and up until now   `quantum-shell`'s has been rather bland, and hard-coded into the program. But that is no more! From now on, anyone using `quantum-shell` can customize their own prompt string under `Settings>Packages>quantum-shell>PromptString`. Not only that, but I've included semantics for several special escape characters as outlined below:
* `\!` - the current history number of this command
* `\@` - current time in 12-hour `HH:MM {am,pm}` format
* `\#` - the current command number of this command
* `\$` - a `#` if superuser, `$` otherwise
* `\A` - current time in 24-hour `HH:MM {am,pm}` format
* `\d` - current date in `Weekday Month Date` format
* `\h` - the current hostname up to the first `.`
* `\H` - the current hostname
* `\s` - the shell program used to run all non-builtin commands
* `\t` - current time in 24-hour `HH:MM:SS` format
* `\T` - current time in 12-hour `HH:MM:SS` format
* `\u` - the user's preferred username
* `\v` - the current version of `quantum-shell` in `X.Y` format
* `\V` - the current version of `quantum-shell` in `X.Y.Z` format
* `\w` - the full path of the current working directory
* `\W` - the basename only of the current working directory
* `\\` - a literal backslash

Feel free to combine these in any way you see fit, and make `quantum-shell` truly your own!

### Full `alias` and `unalias` support
For the sake of simplicity of implementation, the syntax is a little different in quantum-shell than other shells. It is:
```
alias <key> = <expansion>
```
There are a few things to know about this syntax. First, you can only define one alias at a time. Second, the `key` must be a single word, containing absolutely no whitespace. Third, the `=` must have whitespace on either side of it (i.e. not touching anything). And finally, all of the words to the left of the `=` will be concatenated together and seperated by a single `space`. Whenever quantum-shell detects the `key` in an input command, it will be replaced with `expansion`, unless the key is contained within single `''` or  double `""` quotes. A common and useful example would be
```
alias ll = ls -l
```
Aliases are serialized, so you should only ever have to type them out once. Even if you completely close Atom down, they should still be there when you return.

### A custom `atom` builtin
Using the standard `atom` command line tool is a bit redundant, since you're obviously already running `atom`! For that reason I've provided a custom override for the `atom` command that will allow you to simulate any registered event being dispatched wherever you want. The syntax is pretty simple, there are two options:
```
atom <command>
```
or
```
atom <selector> <command>
```
`<command>` is the (non-humanized) command you would like to dispatch. The optional `<selector>` is where you would like the command to be dispatched. It defaults to the `<atom-workspace>` tag, since that's what you'll probably want to target most often anyway.

As an example, imagine you want to toggle full-screen mode, but you just can't remember what that darn key-binding is. The solution is quite simple; just pull up `quantum-shell`, type `atom window:toggle-full-screen` and *volia!* you're now in full-screen mode.

However, if that seems like a lot to type (probably because it is), try combining the `atom` builtin with the `alias` builtin. Something like:
```
alias tfs = atom window:toggle-full-screen
```
Then whenever you want to activate that command just type a simple `tfs` into the command line and let `quantum-shell` do the rest!

If you're thinking to yourself, "Wow, this is an incredibly powerful alternative to memorizing *all* of those keybindings...", then I'd say you and I think a lot alike, my friend :wink:

### Looks Good in any Theme!
![light](https://raw.githubusercontent.com/sedabull/quantum-shell/master/resources/quantum-shell-light.png)

![dark](https://raw.githubusercontent.com/sedabull/quantum-shell/master/resources/quantum-shell-dark.png)
