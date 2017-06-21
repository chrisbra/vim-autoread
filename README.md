# vim-autoread
============
> A plugin to automatically re-read your buffers, when they change

This plugin uses Vim 8 async jobs to append new buffer content. Internally, it
works by running tail -f on a file and the output will be appended to the
buffer, which displays this buffer.

## Installation
---

Use the plugin manager of your choice.

Alternatively, since Vim 8 includes a package manager by default, clone this repository below
`~/.vim/pack/dist/start/`

You should have a directory `~/.vim/pack/dist/start/vim-autoread`
That directory will be loaded automatically by Vim.

## Usage
---
Once installed, take a look at the help at `:h vim-autoread`.

Here is a short overview of the functionality provided by the plugin:

### Ex commands:

    :AutoRead     - starts a async job and will append new buffer content
                    to the current buffer once it is noticed.
    :AutoRead!    - stop autoreading

## License & Copyright
-------

Developed by Christian Brabandt. 
The Vim License applies. See `:h license`

© 2009-2016 by Christian Brabandt

__NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK__
