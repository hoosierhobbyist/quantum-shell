## 0.2.0 - Initial work on builtins
* Print error when trying to use unimplemented builtin with link to issue

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