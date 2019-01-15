" PaG Vim Config.
set encoding=utf-8
language messages English_United States

" "Infect Vim!"
set nocp
execute pathogen#infect()

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
colorscheme dracula

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
let g:airline_theme='dracula'

" ---- Vim-Gitgutter ----
if executable('git')
	let g:gitgutter_highlight_lines = 1  " Turn on gitgutter highlighting
else
    let g:gitgutter_git_executable = 'vimrun'
    let g:gitgutter_enabled = 0
endif

" ---- FZF ----
nnoremap <C-p> :Files<Cr>

