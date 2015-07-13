""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" CSCOPE utilities for vim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! FindGitRepoPath()
python << EOF
"""Find the path to the .git directory.

Returns:
  The full path to the .git directory, or current working directory if the .git
  directory is not found.
"""
import os

curr_dir = vim.current.buffer.name or os.getcwd()
while curr_dir and curr_dir != '/':
  git_path = os.path.join(curr_dir, '.git')
  if os.path.exists(git_path):
    vim.command('return %r' % git_path)
    break
  curr_dir = os.path.dirname(curr_dir)
else:
  vim.command('return %r' % os.path.realpath('.'))

EOF
endfunction


function! GetCurrentGitBranch()
python << EOF
"""Get the name of the current git branch.

Returns:
  The name of the current git branch.
"""
import subprocess

try:
  branch = subprocess.check_output(['git', 'rev-parse', '--abbrev-ref', 'HEAD'])
  vim.command('return %r' % branch.strip())
except:
  vim.command('return ""')
EOF
endfunction


function! GetIndexDatabasePath()
python << EOF
"""Get the path to the index database.

The path to the index database is:

  '<git_repo_path|src_path>/<INDEX_DB_DIR>/<current_branch>'

Returns:
  The path to the index database.
"""
import os

INDEX_DB_DIR = 'index_db'
git_repo_path = vim.eval('FindGitRepoPath()')
current_branch = vim.eval('GetCurrentGitBranch()')
vim.command('return %r' % os.path.join(
    git_repo_path, INDEX_DB_DIR, current_branch))
EOF
endfunction


" Adds the cscope databse found.
function! ConnectCscopeDatabase()
python << EOF

import os
import vim

CTAGS_OUT = 'tags'
CSCOPE_OUT = 'cscope.out'
PYCSCOPE_OUT = 'pycscope.out'

def LocateIndexDatabaseFile(file_name):
  """
  Locates the directory containing the index database file.

  Args:
    file_name: A string indicating the file name of the index database file to
        find.

  Returns:
    The path to the index database file, or None if the database file could not
    be found.
  """
  index_db_path = vim.eval('GetIndexDatabasePath()')
  file_path = os.path.join(index_db_path, file_name)
  if file_path:
    return file_path
  return None

# Kill all cscope connections first.
vim.command('cs kill -1')

# Load ctags index database.
ctags_db = LocateIndexDatabaseFile(CTAGS_OUT)
if ctags_db and os.path.exists(ctags_db):
  vim.command('set tags+=%s' % ctags_db)
  print 'Loaded ctags database.'

git_repo_path = vim.eval('FindGitRepoPath()')
src_path = (os.path.dirname(git_repo_path) if git_repo_path.endswith('.git')
             else git_repo_path)

# Load cscope index database.
cscope_db = LocateIndexDatabaseFile(CSCOPE_OUT)
if cscope_db is None:
  path = os.environ.get('CSCOPE_DB', '')
  if os.path.exists(path):
    cscope_db = cscope_path
    src_path = ''
if cscope_db and os.path.exists(cscope_db):
  vim.command('cs add %s %s' % (cscope_db, src_path))
  print 'Loaded cscope database.'

# Load pycscope index database.
pycscope_db = LocateIndexDatabaseFile(PYCSCOPE_OUT)
if pycscope_db and os.path.exists(pycscope_db):
  vim.command('cs add %s %s' % (pycscope_db, src_path))
  print 'Loaded pycscope database.'

EOF
endfunction


" Rebuilds the cscope database.
function! BuildCscopeDatabase()
python << EOF

import os
import vim
from subprocess import Popen, PIPE, CalledProcessError

CTAGS_OUT = 'tags'
CTAGS_FILES = 'tags.files'
CSCOPE_OUT = 'cscope.out'
CSCOPE_FILES = 'cscope.files'
PYCSCOPE_OUT = 'pycscope.out'
PYCSCOPE_FILES = 'pycscope.files'
IGNORE_PATH_FILE = 'ignore_paths'


def Spawn(args, cwd=None):
  """A wrapper for subprocess.Popen to filter command outputs."""
  process = Popen(args, stdout=PIPE, stderr=PIPE, close_fds=True, cwd=cwd)
  process.stdout, process.stderr = process.communicate()
  return process


def ConstructFindArgs(path, patterns, output_file, ignore_paths=None):
  """A function to construct arguments for the find command.

  Args:
    path: The path for find to start search with.
    patterns: A list of file name patterns to search for.
    output_file: The name of the output file to store the results in.
    ignore_paths: A list of path name patterns to ignore.

  Returns:
    A list of arguments that can be used in Spawn or subprocess.Popen directly.
  """
  cmd = ['find', '%s' % path]
  if ignore_paths:
    cmd += ['(']
    first = True
    for p in ignore_paths:
      if not first:
        cmd += ['-o']
      cmd += ['-path', '%s' % p]
      first = False
    cmd += [')', '-prune', '-o']

  cmd += ['(']
  first = True
  for p in patterns:
    if not first:
      cmd += ['-o']
    cmd += ['-name', '%s' % p]
    first = False
  cmd += [')', '-fprint', '%s' % output_file]
  return cmd


git_repo_path = vim.eval('FindGitRepoPath()')
db_path = vim.eval('GetIndexDatabasePath()')
src_path = (os.path.dirname(git_repo_path) if git_repo_path.endswith('.git')
             else git_repo_path)

if os.path.exists(src_path):
  ignore_paths = ['*/.git']
  ignore_path_file = os.path.join(git_repo_path, IGNORE_PATH_FILE)
  if os.path.exists(ignore_path_file):
    with open(ignore_path_file, 'r') as f:
      ignore_paths += [path.strip() for path in f.readlines()]

  if not os.path.exists(db_path):
    os.makedirs(db_path)

  print 'Building ctags...'
  try:
    ctags_files = os.path.join(db_path, CTAGS_FILES)
    Spawn(ConstructFindArgs('.', ['*'], ctags_files, ignore_paths=ignore_paths),
          cwd=src_path)
    Spawn(['ctags', '-L', '%s' % ctags_files, '--tag-relative=yes', '-f',
          '%s' % os.path.join(db_path, CTAGS_OUT)],
          cwd=src_path)
  except CalledProcessError as e:
    print 'Failed: %s' % e
  except OSError as e:
    print 'Failed: %s' % e

  print 'Building cscope...'
  try:
    cscope_files = os.path.join(db_path, CSCOPE_FILES)
    Spawn(ConstructFindArgs('.', ['*.c', '*.cc', '*.cpp', '*.h'], cscope_files,
                            ignore_paths=ignore_paths),
          cwd=src_path)
    Spawn(['cscope', '-bqk', '-i', '%s' % cscope_files, '-f',
           '%s' % os.path.join(db_path, CSCOPE_OUT)],
          cwd=src_path)
  except CalledProcessError as e:
    print 'Failed: %s' % e
  except OSError as e:
    print 'Failed: %s' % e

  print 'Building pycscope...'
  try:
    pycscope_files = os.path.join(db_path, PYCSCOPE_FILES)
    Spawn(ConstructFindArgs('.', ['*.py'], pycscope_files,
                            ignore_paths=ignore_paths),
          cwd=src_path)
    Spawn(['pycscope', '-i', '%s' % pycscope_files,
           '-f', '%s' % os.path.join(db_path, PYCSCOPE_OUT)],
          cwd=src_path)
  except CalledProcessError as e:
    print 'Failed: %s' % e
  except OSError as e:
    print 'Failed: %s' % e

  vim.command('call ConnectCscopeDatabase()')

EOF
endfunction

nnoremap <leader>cs :call call(function('BuildCscopeDatabase'), [])<CR>
nnoremap <leader>cc :call call(function('ConnectCscopeDatabase'), [])<CR>

if has("cscope")
  call ConnectCscopeDatabase()
endif
