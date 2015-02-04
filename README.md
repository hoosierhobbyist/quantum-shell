# Quantum Shell for Github's Atom! 
A command line interface built directly into Atom! This package is largely inspired by (but not a direct fork of) [terminal-panel](http://github.com/thedaniel/terminal-panel). The goal of this project is to provide users with a simple, yet powerful tool, that no self-proclaimed 'Hackable' editor should be without. It will maintain strict compliance to the 1.0.0-pre Atom API for now, and once its official, the 1.x API. Currently, this package should run as expected on Atom >=0.174.0 with any standard Linux machine. It will likely perform well on OS X as well, however, that has not yet been tested. Complete Cross-platform compatibility is an eventual goal as are many other things (see the [CHANGELOG](https://github.com/sedabull/quantum-shell/blob/master/CHANGELOG.md) for details).To get started just search for and download 'quantum-shell' in the Atom package manager and press `ctrl-shift-q` to get started. Happy Hacking!
## Features
### Proper `cd` and `pwd` support
The initial release of quantum-shell did not allow a user to change directories from wherever the current `process` was running, which is obviously unacceptable. There are now proper `cd` and `pwd` builtin commands so that this will no longer be an issue.
### Full `history` support just like you're used to in bash
Just use the `up` and `down` arrow keys when the input field is focused to quickly navigate through your history. Or use the `history` builtin to view a list of your past 100 commands.
### Full `alias` and `unalias` support
For the sake of simplicity of implementation, the syntax is a little different in quantum-shell than other shells. The syntax is:`alias <key> = <expansion>`.

There are a few things to know about this syntax. First, the `key` must be a single word, with absolutely no whitespace. Second, the `=` must have whitespace on either side of it (i.e. not touching anything). And finally, all of the words to the left of the `=` will be concatenated together and seperated by a single `space`. Whenever quantum-shell detects the `key` in an input command, it will be replaced with `expansion`. A common and useful example would be `alias ll = ls -l`.
### Full `env` support
Any word prefixed with a `$` will be interpreted by quantum-shell as an environment variable and replaced with the appropriate value. What this means is that the command `echo $PATH` should return something like `/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin`. In addition, the entire environment can be viewed at once with the builtin command `printenv`. You can even add to the environment using the `export` command. The syntax for this command is exactly the same as `alias` (see above).
### Looks Good in any Theme!
![light](https://raw.githubusercontent.com/sedabull/quantum-shell/master/resources/quantum-shell-light.png)

![dark](https://raw.githubusercontent.com/sedabull/quantum-shell/master/resources/quantum-shell-dark.png)
