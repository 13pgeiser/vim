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

" Vim-Gitgutter
if executable('git')
   let g:gitgutter_highlight_lines = 1  " Turn on gitgutter highlighting
else
    let g:gitgutter_git_executable = '/bin/true'
    let g:gitgutter_enabled = 0
endif
