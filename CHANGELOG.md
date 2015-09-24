## 0.7.0 - Windows Support
* correct Windows prompt string
* correct default settings for Windows
* this version requires `Atom` version 1.0.12 or higher because that is when the switch to `io.js` version 2.x was made

## 0.6.2 - Bug Fix
* proper kill signals
* bug fix, issue [#14](http://github.com/sedabull/quantum-shell/issues/14): `process.getuid` is undefined on windows OS

## 0.6.1 - Bug Fix
* change `a.m.` and `p.m.` to `AM` and `PM`
* bug fix, issue [#13](http://github.com/sedabull/quantum-shell/issues/13): missing `os.hostname()` call

## 0.6.0 - Multiple Terminals
* added simple return codes to builtin commands
* added config options `debug child processes` and `max terminals`
* added prompt string semantics
    * `\\$` - a `#` if superuser, `$` otherwise
    * `\\!` - the current history number of this command
    * `\\#` - the current command number of this command
    * `\\h` - the current hostname up to the first `.`
    * `\\H` - the current hostname
* now supports multiple terminals simultaneously running different shells

## 0.5.0 - Customization
* `quantum-shell:kill-process` will now write `^C` to the error stream
* tab-completion will now provide filename completions along a relative path
* added many configuration options
    * `Home` - the user's home directory
    * `User` - the user's preferred username
    * `Max Height` - the maximum height of the output div
    * `Min Height` - the minimum height of the output div
    * `Shell` - the shell program the user would prefer to run commands
    * `Enable Builtins` - turn custom builtin functions on or off
    * `Prompt String` - the string that serves as a placeholder in the input element
* customizable prompt string with following semantics
    * `\@` - current time in 12-hour `HH:MM {am,pm}` format
    * `\A` - current time in 24-hour `HH:MM {am,pm}` format
    * `\d` - current date in `Weekday Month Date` format
    * `\s` - the shell program used to run all non-builtin commands
    * `\t` - current time in 24-hour `HH:MM:SS` format
    * `\T` - current time in 12-hour `HH:MM:SS` format
    * `\u` - the user's username
    * `\v` - the current version of `quantum-shell` in `X.Y` format
    * `\V` - the current version of `quantum-shell` in `X.Y.Z` format
    * `\w` - the full path of the current working directory
    * `\W` - the basename only of the current working directory
    * `\\` - a literal backslash

## 0.4.2 - Bug fix
* see issue [#9](http://github.com/sedabull/quantum-shell/issues/9), `env.PATH` is sometimes `env.Path`
* a special thank you to user @adrianhall, for reporting and helping to fix this bug!

## 0.4.1 - Bug fix
* fixed a bug in the tab completion feature that would replace the wrong part of the input string

## 0.4.0 - Tab completion
* Added a rotating tab completion feature
* Fixed a bad dependency on a private atom API
* General refactoring in the interest of long term maintainability

## 0.3.4 - Bug fix
* Quantum Shell would throw an error if an empty string was entered

## 0.3.3 - *actually* Fix README error
* Whoops...

## 0.3.2 - Fix README error
* Removed some unwanted text from the README.md file

## 0.3.1 - Fix activation bug
* Addrees issue [#4](http://github.com/sedabull/quantum-shell/issues/4)

## 0.3.0 - `atom` builtin and proper specs
* Proper serialization
* Added new custom builtin `atom`
* Lots of little bug fixes and refactoring
* Added experimental `spawn` method (not yet used)
* Added a whole battery of specs that are passing on Ubuntu 14.04
* Goals for next release:
    * more work with `spawn`
    * continue to improve ui/ux
    * add configuration settings
    * experiment with service provider API

## 0.2.0 - Initial work on builtins
* `cd` builtin
* `pwd` builtin
* `echo` builtin
* `clear` builtin
* `export` builtin
* `alias` builtin
* `unalias` builtin
* `history` builtin
* `printenv` builtin
* Add `ctrl-c` key binding to kill a long running process
* Use `native!` directive for relevant `#quantum-shell-input` commands
* Print error when trying to use unimplemented builtin with link to issue
* Use proper ui-variables to make quantum-shell fit well with any ui-theme
* Builtins are **NOT** ready for use with pipe operator `|` or file redirection `>` `>>`
* Goals for next release:
    * add tests
    * more builtins
    * add configuration settings
    * ui buttons for close and kill actions
    * `atom` builtin to execute any registered atom command
    * more formal parsing of input for use by `child_process.spawn` and builtins

## 0.1.0 - First Release
* Basic functionality using child_process.exec
* Suitable for commands that are only concerned with output
* Doesn't preserve colored output, because streams are not ttys
* **NOT** suitable for commands that expect input `sudo apt-get whatever`
* **NOT** suitable for interactive shell programs `vim` or `nano`, etc.
* Goals for next release:
    * Implement cd feature
    * Implement alias feature
    * Implement history feature
    * Continue to improve the UI
    * Implement kill-process functionality
    * Work towards cross-platform consistency
