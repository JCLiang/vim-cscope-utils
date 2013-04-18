vim-cscope-utils
================

A vim plugin that creates and auto-loads ctags, cscope, and pycscope index
database for you.


## To use this plugin, you'll need:

1. vim compiled with cscope (*--enable-cscope*) and Python interpreter
    (*--enable-pythoninterp=yes*) support.
2. ctags: http://ctags.sourceforge.net/
3. cscope: http://cscope.sourceforge.net/
4. pycscope installed: https://github.com/portante/pycscope


## How to use it:

This plugin works the best with Git repositories. It tries to create and load
from the *.git* directory your index database files. If you're not using Git,
please refer to the Notes section for further information.

1. Install the plugin with your favorite vim bundle manager.
2. Change dir to your source code directory.
3. Open up vim.
4. Hit *&lt;leader&gt;cs* to build and load all the database for you.
5. Open up source files, and happy code tracing with *ctrl + ]*.
6. More infos can be found in vim with *:help cscope*.


## When you hit *&lt;leader&gt;cs* in vim, a function is called to do the
    following:

1. Look for the *.git* directory, starting from current working directory and
    going up the directory tree until *.git* is found or '/' is reached.
2. Create ctags index database in the *.git* directory.
3. Create cscope index database in the *.git* directory for *.c*, *.cc*, *.cpp*,
    *.h* files.
4. Create pycscope index database in the *.git* directory for *.py* files.
5. (Re)connect vim to the cscope index databases.

## Notes:

1. You can ignore certain paths by creating an 'ignore_paths' file in the *.git*
    directory and list all the path patterns you want to ignore in it.
2. If *.git* directory is not found, then the index database files would be
    created in the current working directory.
