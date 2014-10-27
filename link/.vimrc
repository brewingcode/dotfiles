" Auto-reload vimrc
augroup reload_vimrc
  autocmd!
  autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END

" Change mapleader
let mapleader=","

" Now ; works just like : but with 866% less keypresses!
nnoremap ; :

" Move more naturally up/down when wrapping is enabled.
nnoremap j gj
nnoremap k gk

" Quickly edit/reload the vimrc file
nmap <silent> <leader>ev :edit $MYVIMRC<CR>
nmap <silent> <leader>sv :source $MYVIMRC<CR>

" Disable arrow keys
nnoremap <Left> :echoe "Use h"<CR>
nnoremap <Right> :echoe "Use l"<CR>
nnoremap <Up> :echoe "Use k"<CR>
nnoremap <Down> :echoe "Use j"<CR>

" Local dirs
set backupdir=$DOTFILES/caches/vim
set directory=$DOTFILES/caches/vim
set undodir=$DOTFILES/caches/vim
let g:netrw_home = expand('$DOTFILES/caches/vim')

" Theme / Syntax highlighting
augroup color_scheme
  autocmd!
  " Make invisible chars less visible in terminal.
  autocmd ColorScheme * :hi NonText ctermfg=236
  autocmd ColorScheme * :hi SpecialKey ctermfg=236
augroup END
colorscheme molokai
set background=dark

" Visual settings
set cursorline " Highlight current line
set number " Enable line numbers.
set showtabline=2 " Always show tab bar.
set relativenumber " Use relative line numbers. Current line is still in status bar.
set title " Show the filename in the window titlebar.
set nowrap " Do not wrap lines.
set noshowmode " Don't show the current mode (airline.vim takes care of us)
set laststatus=2 " Always show status line

" Toggle between absolute and relative line numbers
augroup relative_numbers
  autocmd!
  " Show absolute numbers when vim loses focus
  autocmd FocusLost *   :set norelativenumber
  autocmd FocusGained * :set relativenumber
  " Show absolute numbers in insert mode
  autocmd InsertEnter * :set norelativenumber
  autocmd InsertLeave * :set relativenumber
augroup END

" Make it obvious where 80 characters is
set textwidth=80
set colorcolumn=+1

" Scrolling
set scrolloff=3 " Start scrolling three lines before horizontal border of window.
set sidescrolloff=3 " Start scrolling three columns before vertical border of window.

" Indentation
set autoindent " Copy indent from last line when starting new line.
set shiftwidth=2 " The # of spaces for indenting.
set smarttab " At start of line, <Tab> inserts shiftwidth spaces, <Bs> deletes shiftwidth spaces.
set softtabstop=2 " Tab key results in 2 spaces
set tabstop=2 " Tabs indent only 2 spaces
set expandtab " Expand tabs to spaces

" Reformatting
set nojoinspaces " Only insert single space after a '.', '?' and '!' with a join command.

" Toggle show tabs and trailing spaces (,c)
set listchars=tab:▸\ ,trail:·,eol:¬,nbsp:_,extends:>,precedes:<
"set listchars=tab:>\ ,trail:.,eol:$,nbsp:_,extends:>,precedes:<
"set fillchars=fold:-
nnoremap <silent> <leader>c :set nolist!<CR>
set list

" Search / replace
set gdefault " By default add g flag to search/replace. Add g to toggle.
set hlsearch " Highlight searches
set incsearch " Highlight dynamically as pattern is typed.
set ignorecase " Ignore case of searches.
set smartcase " Ignore 'ignorecase' if search pattern contains uppercase characters.

" Clear last search
map <silent> <leader>/ <Esc>:nohlsearch<CR>

" Ignore things
set wildignore+=*.jpg,*.jpeg,*.gif,*.png,*.gif,*.psd,*.o,*.obj,*.min.js
set wildignore+=*/bower_components/*,*/node_modules/*
set wildignore+=*/vendor/*,*/.git/*,*/.hg/*,*/.svn/*,*/log/*,*/tmp/*

" Vim commands
set hidden " When a buffer is brought to foreground, remember undo history and marks.
set report=0 " Show all changes.
set mouse=a " Enable mouse in all modes.
set shortmess+=I " Hide intro menu.

" Splits
set splitbelow " New split goes below
set splitright " New split goes right

" Ctrl-J/K/L/H select split
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Ctrl-Shift-J/K/L/H move current window
nnoremap <C-S-J> <C-W>J
nnoremap <C-S-K> <C-W>K
nnoremap <C-S-L> <C-W>L
nnoremap <C-S-H> <C-W>H

" Buffer navigation
nnoremap <leader>b :CtrlPBuffer<CR>
map <Leader>, <C-^>
map gb :bnext<CR>
map gB :bprev<CR>

" Jump to buffer number (<N>gb)
let c = 1
while c <= 99
  execute "nnoremap " . c . "gb :" . c . "b\<CR>"
  let c += 1
endwhile

" Switch between the last two files
nnoremap <leader><leader> <C-^>

" Fix page up and down
map <PageUp> <C-U>
map <PageDown> <C-D>
imap <PageUp> <C-O><C-U>
imap <PageDown> <C-O><C-D>

" Use Q for formatting the current paragraph (or selection)
" vmap Q gq
" nmap Q gqap

" When editing a file, always jump to the last known cursor position. Don't do
" it for commit messages, when the position is invalid, or when inside an event
" handler (happens when dropping a file on gvim).
augroup vimrcEx
  autocmd!
  autocmd BufReadPost *
    \ if &ft != 'gitcommit' && line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif
augroup END

" FILE TYPES
augroup file_types
  autocmd!

  " vim
  autocmd BufRead .vimrc,*.vim set keywordprg=:help

augroup END

" PLUGINS

" Airline
let g:airline_powerline_fonts = 1 " TODO: detect this?
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_nr_format = '%s '
let g:airline#extensions#tabline#buffer_nr_show = 1
"let g:airline#extensions#tabline#fnamecollapse = 0
"let g:airline#extensions#tabline#fnamemod = ':t'

" CtrlP.vim
map <leader>p <C-P>
map <leader>r :CtrlPMRUFiles<CR>
"let g:ctrlp_match_window_bottom = 0 " Show at top of window

" Indent Guides
let g:indent_guides_start_level = 2
let g:indent_guides_guide_size = 1

" https://github.com/junegunn/vim-plug
" Reload .vimrc and :PlugInstall to install plugins.
call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-sensible'
Plug 'bling/vim-airline'
Plug 'kien/ctrlp.vim'
Plug 'fatih/vim-go'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'pangloss/vim-javascript'
call plug#end()

