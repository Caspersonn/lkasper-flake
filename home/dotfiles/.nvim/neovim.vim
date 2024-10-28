call plug#begin('~/.local/share/nvim/plugged')
  Plug 'preservim/nerdtree'
  Plug 'Xuyuanp/nerdtree-git-plugin'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'junegunn/fzf.vim'
  Plug 'junegunn/fzf'
  Plug 'hashivim/vim-terraform'
  Plug 'LnL7/vim-nix'
  Plug 'luizribeiro/vim-cooklang', { 'for': 'cook' }
 "Plug 'ayu-theme/ayu-vim' 
  Plug 'ajmwagar/vim-deus'
 "Plug 'linden-project/linny.vim' 
  Plug 'airblade/vim-gitgutter'

call plug#end()

nmap ,, :NERDTreeFind <CR>
nmap ,/ :Ag 
nmap ,\ :Rg 
nmap ,b :Buffers
nmap ,f :Files
nmap ,n :NERDTree <CR>
set number
set hlsearch    " highlight matches
set ignorecase  " searches are case insensitive...
set smartcase   " ... unless they contain at least one capital letter
set belloff=all
set tabstop=2
set shiftwidth=2
set expandtab
silent !mkdir -p ~/.vim_temp/undodir > /dev/null 2>&1
set undofile " Maintain undo history between sessions
set undodir=~/.vim_temp/undodir
let NERDTreeShowBookmarks=1
let NERDTreeShowHidden=1
let NERDTreeIgnore = ['^\.DS_Store$', '\.dat.nosync', '\.swp', '\.repl_history', '\.cxx', '\.cxx_parameters' ]
let NERDTreeChDirMode=2
"let g:NERDTreeWinSize=50
let NERDTreeAutoDeleteBuffer = 1
let NERDTreeMinimalUI = 0
set termguicolors     " enable true colors support
set background="dark"   " for dark
colorscheme deus

" Change update time for GitGutter
set updatetime=100

" coc config
let g:coc_global_extensions = [
  \ 'coc-snippets',
  \ 'coc-pairs',
  \ 'coc-tsserver',
  \ 'coc-eslint', 
  \ 'coc-prettier', 
  \ 'coc-json', 
  \ 'coc-python',
  \ ]

" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

let g:NERDTreeGitStatusWithFlags = 1
"let g:WebDevIconsUnicodeDecorateFolderNodes = 1
"let g:NERDTreeGitStatusNodeColorization = 1
"let g:NERDTreeColorMapCustom = {
    "\ "Staged"    : "#0ee375",  
    "\ "Modified"  : "#d9bf91",  
    "\ "Renamed"   : "#51C9FC",  
    "\ "Untracked" : "#FCE77C",  
    "\ "Unmerged"  : "#FC51E6",  
    "\ "Dirty"     : "#FFBD61",  
    "\ "Clean"     : "#87939A",   
    "\ "Ignored"   : "#808080"   
    "\ }                         




"let g:linny_open_notebook_path       = $HOME . '/git/personal/LinnyNotes'
"let g:linnycfg_path_wiki_content     = $HOME . '/git/personal/LinnyNotes/content'
"call linny#Init()