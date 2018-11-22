" PaG Vim Config.
set encoding=utf-8
" "Infect Vim!"
execute pathogen#infect()

" Theme
colorscheme dracula

" NerdTree
map <F2> :NERDTreeToggle<CR>

" Syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
