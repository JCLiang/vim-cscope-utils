vim-cscope-utils
================

A vim plugin that creates and auto-loads ctags, cscope, and pycscope index
database for you.


## To use this plugin, you'll need:

1. vim compiled with cscope ( *--enable-cscope* ) and Python interpreter
    ( *--enable-pythoninterp=yes* ) support. You probably have to patch your vim
    because there are some bugs in the base vim-7.3 that crashed vim when
    running Python inside it: http://www.vim.org/patches.php
2. I recommend to fetch the latest vim source with mercurial (which includes all
    the patches), include the above options and any other options you want when
    doing *./configure*, and build from it: http://www.vim.org/download.php
3. ctags: http://ctags.sourceforge.net/
4. cscope: http://cscope.sourceforge.net/
5. pycscope: https://github.com/portante/pycscope


## How to use it:

This plugin works the best with Git repositories. It tries to create and load
from the *.git* directory your index database files. If you're not using Git,
please refer to the Notes section for further information.

1. Install the plugin with your favorite vim bundle manager.
2. Change dir to your source code directory.
3. Open up vim.
4. Hit *&lt;leader&gt;ca* to build and load all the database for the current git
    branch.
5. You can also use *&lt;leader&gt;ct*, *&lt;leader&gt;cs*, *&lt;leader&gt;pcs*
    to (re-)build only ctags, cscope, or pycscope database, respectively.
6. Open up source files, and happy code tracing with *ctrl + ]* and *ctrl + T*.
7. If you switch to another git branch, you can use *&lt;leader&gt;cc* to
    reconnect to the databases you previous built.
8. More infos can be found in vim with *:help cscope*.


## When you hit *&lt;leader&gt;ca* in vim, a function is called to do the following:

1. Look for the *.git* directory, starting from current working directory and
    going up the directory tree until *.git* is found or '/' is reached.
2. In the directory found in 1., look for or create the directory
    *index_db/&lt;current_branch&gt;*. The generated index databases will be
    placed in this directory.
3. Create ctags index database in the *.git* directory.
4. Create cscope index database in the *.git* directory for *.c*, *.cc*, *.cpp*,
    *.h* files.
5. Create pycscope index database in the *.git* directory for *.py* files.
6. (Re)connect vim to the cscope index databases.

## Notes:

1. You can ignore certain paths by creating an *ignore_paths* file in the *.git*
    directory and list all the path patterns you want to ignore in it.
2. If *.git* directory is not found, then the index database files would be
    created in the current working directory.
3. You can specify a list of extra arguments to the ctags/cscope/pycscope
    command to build the index file in your .vimrc using the
    *g:cscope_utils_[ctags|cscope|pycscope]_extra_args* variable. For example,
    setting *g:cscope_utils_ctags_extra_args* to *["--fields=+l"]* will add
    *--fields=+l* to the ctags arguments.
