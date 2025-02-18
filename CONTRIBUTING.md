Anybody is welcome to contribute to this project. If you have any idea, how to improve any
features or you have an idea for a new feature do not hesitate to fork this project
and create a PR. Any improvement is welocme.

In case you want to contribute to this project, here is the structure of the project:

**/core**
 - *compatibility.lua*
    - All the functions that change during the nvim versions.

 - *util.lua*
    - Utility project functions.

**/parser**
 - *init.lua*
    - Parser module public implementation. This should be used to parse the
      buffer. It is used internally by the plugin, too.

 - *parser.lua*
    - Internal implementation of the parser. The parser improvement or functionality has to be extended here.

 - *references.lua*
    - Parses the lines and detects the references in the buffer.

**/**
- *config.lua*
    - Default configuration of the plugin. This is used to set the default configuration of the plugin.

- *highlight.lua*
    - Module applying the highlighting detected by the parser.

- *init.lua*
    - The main module of the plugin. This supplys the public API of the plugin.

- *number.lua*
    - Module that creates a popup window with the number interpratation in multiple bases.
