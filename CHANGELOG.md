## 0.3.4 - bug fix
* Quantum Shell would throw an error if an empty string was entered

## 0.3.3 - *actually* fix README error
* Whoops...

## 0.3.2 - fix README error
* Removed some unwanted text from the README.md file

## 0.3.1 - fix activation bug
* Addrees issue #4

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
