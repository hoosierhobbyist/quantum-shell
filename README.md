# Quantum Shell for Github's Atom!
A command line interface built directly into Atom! This package is largely inspired by (but not a direct fork of) [terminal-panel](http://github.com/thedaniel/terminal-panel). The goal of this project is to provide users with a simple, yet powerful tool, that no self-proclaimed 'Hackable' editor should be without. It will maintain strict compliance to the 1.0.0-pre Atom API for now, and once its official, the 1.x API. Currently, this package should run as expected on Atom >=0.174.0 with any standard Linux machine. It will likely perform well on OS X as well, however, that has not yet been tested. Complete Cross-platform compatibility is an eventual goal as are many other things (see the [CHANGELOG](https://github.com/sedabull/quantum-shell/blob/master/CHANGELOG.md) for details).To get started just search for and download 'quantum-shell' in the Atom package manager and press `ctrl-shift-q` to get started. Happy Hacking!
## Features
### Proper `cd` and `pwd` support
The initial release of quantum-shell did not allow a user to change directories from wherever the current `process` was running, which is obviously unacceptable. There are now proper `cd` and `pwd` builtin commands so that this will no longer be an issue.
### Full `history` support just like you're used to in bash
Just use the `up` and `down` arrow keys when the input field is focused to quickly navigate through your history. Or use the `history` builtin to view a list of your past 100 commands.
### Full `alias` and `unalias` support
For the sake of simplicity of implementation, the syntax is a little different in quantum-shell than other shells. It is:
```
alias <key> = <expansion>
```

There are a few things to know about this syntax. First, you can only define one alias at a time. Second, the `key` must be a single word, containing absolutely no whitespace. Third, the `=` must have whitespace on either side of it (i.e. not touching anything). And finally, all of the words to the left of the `=` will be concatenated together and seperated by a single `space`. Whenever quantum-shell detects the `key` in an input command, it will be replaced with `expansion`, unless the key is contained within single `''` or  double `""` quotes. A common and useful example would be
```
alias ll = ls -l
```
### Full `env` support
Any word prefixed with a `$` will be interpreted by quantum-shell as an environment variable and replaced with the appropriate value, unless the word is contained within single `''` or  double `""` quotes. What this means is that the command
```
echo $PATH
```
should return something like
```
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```
In addition, the entire environment can be viewed at once with the builtin command `printenv`.

You can also modify or add to the environment using the `export` command. The syntax is similar to the `alias` command, except that only one word is allowed on the right hand side of the assignment. Formally, it is:
```
export <key> = <value>
```
What this means is that if you need whitespace in the `<value>` (which you normally shouldn't), you'll have to wrap it in single `''` or double `""` quotes.
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
