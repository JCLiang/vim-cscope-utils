""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" CSCOPE utilities for vim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! FindGitRepoPath()
python << EOF
import os

curr_dir = vim.current.buffer.name or os.getcwd()
while curr_dir and curr_dir != '/':
  git_path = os.path.join(curr_dir, '.git')
  if os.path.exists(git_path):
    vim.command('return %r' % git_path)
  curr_dir = os.path.dirname(curr_dir)

EOF
endfunction

" Adds the cscope databse found.
function! ConnectCscopeDatabase()
python << EOF

import os
import vim

db_path = vim.eval('FindGitRepoPath()') or '.'
base_path = os.path.dirname(db_path)

cscope_db = None
for path in [os.path.join(db_path, 'cscope.out'),  # local repo
             os.environ.get('CSCOPE_DB', '')  # environment variable
            ]:
  if os.path.exists(path):
    cscope_db = path
    break
if cscope_db:
  vim.command('cs add %s %s' % (cscope_db, base_path))

pycscope_db = os.path.join(db_path, 'pycscope.out')
if os.path.exists(pycscope_db):
  # add pycscope database from local repo
  vim.command('cs add %s %s' % (pycscope_db, base_path))

EOF
endfunction


" Rebuilds the cscope database.
function! BuildCscopeDatabase()
python << EOF

import os
import vim
from subprocess import Popen, PIPE

CTAGS_OUT = 'tags'
CTAGS_FILES = 'tags.files'
CSCOPE_OUT = 'cscope.out'
CSCOPE_FILES = 'cscope.files'
PYCSCOPE_OUT = 'pycscope.out'
PYCSCOPE_FILES = 'pycscope.files'
IGNORE_PATH_FILE = 'ignore_paths'

db_path = vim.eval('FindGitRepoPath()') or '.'
base_path = os.path.dirname(db_path)

class Spawn(Popen):
  def __init__(self, args, cwd=None):
    self.process = Popen(args, stdout=PIPE, stderr=PIPE, close_fds=True,
                         cwd=cwd)
    self.stdout = None
    self.stderr = None
    self.stdout, self.stderr = self.process.communicate()

def ConstructFindArgs(path, patterns, output_file, ignore_paths=None):
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

if os.path.exists(base_path):
  ignore_paths = ['*/.git']
  ignore_path_file = os.path.join(db_path, IGNORE_PATH_FILE)
  if os.path.exists(ignore_path_file):
    with open(ignore_path_file, 'r') as f:
      ignore_paths += [path.strip() for path in f.readlines()]

  print 'Building ctags...'
  ctags_files = os.path.join(db_path, CTAGS_FILES)
  Spawn(ConstructFindArgs('.', ['*'], ctags_files, ignore_paths=ignore_paths),
        cwd=base_path)
  Spawn(['ctags', '-L', '%s' % ctags_files, '--tag-relative=yes', '-f',
        '%s' % os.path.join(db_path, CTAGS_OUT)],
        cwd=base_path)

  print 'Building cscope...'
  cscope_files = os.path.join(db_path, CSCOPE_FILES)
  Spawn(ConstructFindArgs('.', ['*.c', '*.cc', '*.cpp', '*.h'], cscope_files,
                          ignore_paths=ignore_paths),
        cwd=base_path)
  Spawn(['cscope', '-bqk', '-i', '%s' % cscope_files, '-f',
         '%s' % os.path.join(db_path, CSCOPE_OUT)],
        cwd=base_path)

  print 'Building pycscope...'
  pycscope_files = os.path.join(db_path, PYCSCOPE_FILES)
  Spawn(ConstructFindArgs('.', ['*.py'], pycscope_files,
                          ignore_paths=ignore_paths),
        cwd=base_path)
  Spawn(['pycscope', '-i', '%s' % pycscope_files,
         '-f', '%s' % os.path.join(db_path, PYCSCOPE_OUT)],
        cwd=base_path)

  vim.command('cs reset')
  print 'Cscope, pycscope, and ctags updated.'

EOF
endfunction

nnoremap <leader>cs :call call(function('BuildCscopeDatabase'), [])<CR>

if has("cscope")
  call ConnectCscopeDatabase()
endif
