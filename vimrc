" PaG Vim Config.
"
" F2 -> toggle NerdTree
" F3 -> previous error
" F4 -> next error
" F5 -> YCM Force compile and diagnostics
" F6 -> YCM Goto
" F7 -> Call make
"
set encoding=utf-8
set langmenu=en_US.UTF-8
:let $LANG = 'en'

" "Infect Vim!"
set nocompatible
execute pathogen#infect()

" ---- Change font ----
if has('gui_running')
    if has("win64") || has("win32")
        set guifont=Consolas:h10:cDEFAULT
        au GUIEnter * simalt ~x " Maximize
    else
        set guifont=Liberation\ Mono\ 10.
    endif
endif

" Basic stuff not in sensible.vim
set number
set nowrap
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set ignorecase
set smartcase
set spell
set colorcolumn=120

" ---- SYNTAX ----
syntax on
set showmatch
set modeline
filetype plugin on
au FileType python setlocal tabstop=8 expandtab shiftwidth=4 softtabstop=4
au FileType text setlocal tw=140

" ---- Finding files ----
set path+=**
set wildmenu

" ---- Disable directional keys ----
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>
imap <up> <nop>
imap <down> <nop>
imap <left> <nop>
imap <right> <nop>

" Map tab and shift-tab to cycle through buffers
nnoremap <TAB> :bn<CR>
nnoremap <S-TAB> :bp<CR>
nnoremap § :bdelete<CR>

" Map F3 & F4 to cycle through errors in quickfix
nnoremap <F3> :cnext<CR>
nnoremap <F4> :cprev<CR>

" Theme
colorscheme onedark

" ---- NerdTree ----
map <F2> :NERDTreeToggle<CR>

" ---- Ack ----
if executable('ag')
	let grepprg = "ag --nogroup --nocolor"
	let g:ackhighlight = 1 " Ack should highlight the findings
	let g:ackprg = "ag --vimgrep -U" " Ack uses silversearcher instead of pure vimgrep.
endif

" ---- Airline ----
let g:airline#extensions#tabline#enabled = 1 " Enable the list of buffers
let g:airline#extensions#tabline#fnamemod = ':t' " Show just the filename
let g:airline#extensions#tabline#switch_buffers_and_tabs = 1
let g:airline#extensions#tabline#buffer_idx_mode = 1
" let g:airline_powerline_fonts = 1

" ---- Vim-Gitgutter ----
if executable('git')
  let g:gitgutter_max_signs = 200
else
  let g:gitgutter_git_executable = 'vimrun'
  let g:gitgutter_enabled = 0
endif

" ---- FZF ----
nnoremap <C-p> :Files<Cr>
nnoremap <C-S-r> :Files<Cr>

" ---- YouCompleteMe ----
let g:ycm_echo_current_diagnostic = 1
let g:ycm_collect_identifiers_from_tags_files = 1
let g:ycm_autoclose_preview_window_after_completion = 1
nnoremap <F5> :YcmDiags<CR>
nnoremap <F6> :YcmCompleter GoTo<CR>

" ---- Make! ----
nnoremap <F7> :make<CR>
set makeprg=make

