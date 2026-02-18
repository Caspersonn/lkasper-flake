call plug#begin('~/.local/share/nvim/plugged')
  Plug 'preservim/nerdtree'
  Plug 'Xuyuanp/nerdtree-git-plugin'
  Plug 'ryanoasis/vim-devicons'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'junegunn/fzf.vim'
  Plug 'junegunn/fzf'
  Plug 'hashivim/vim-terraform'
  Plug 'LnL7/vim-nix'
  Plug 'luizribeiro/vim-cooklang', { 'for': 'cook' }
  Plug 'sainnhe/gruvbox-material'
  Plug 'junegunn/seoul256.vim'
  Plug 'airblade/vim-gitgutter'
  Plug 'dhruvasagar/vim-table-mode'
  Plug 'linden-project/linny.vim'
  Plug 'rktjmp/lush.nvim'
  Plug 'robitx/gp.nvim'
  Plug 'linden-project/linny-wikitag-jira'
  Plug 'MeanderingProgrammer/render-markdown.nvim'
  Plug 'hat0uma/csvview.nvim'

call plug#end()

" General settings "
nnoremap <space>a :qa!<CR>
nnoremap <space>t :NERDTree<CR>
nnoremap <space>f :Ag<CR>
nmap ,, :NERDTreeFind <CR>
nmap ,b :Buffers <CR>
map <S-ScrollWheelUp> zH
map <S-ScrollWheelDown> zL

" Horizantel scrolling
set nowrap


" Tabs
nmap ,n :tabnew <CR>
nmap ,m :tabclose <CR>

" AI Chats
nmap ,g :GpChatNew popup <CR>
nmap ,t :GpChatToggle popup <CR>

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
let NERDTreeAutoDeleteBuffer = 1
let NERDTreeMinimalUI = 0

" Set colorscheme
set termguicolors     " enable true colors support
set background=dark
let g:gruvbox_material_background = 'soft'
colorscheme gruvbox-material

" Set vim-devicons
set guifont=DroidSansMono\ Nerd\ Font\ 11
set encoding=UTF-8
let g:webdevicons_enable_nerdtree = 1

" Change update time for GitGutter "
set updatetime=100

" coc config "
let g:coc_global_extensions = [
  \ 'coc-snippets',
  \ 'coc-pairs',
  \ 'coc-tsserver',
  \ 'coc-json', 
  \ 'coc-html',
  \ 'coc-go',
  \ ]


" coc pretier "

command! -nargs=0 Prettier :call CocAction('runCommand', 'prettier.formatFile')
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

" GIT Status "
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


" Linny config "
let g:linny_open_notebook_path       = $HOME . '/git/personal/lkasper-linny'
let g:linnycfg_setup_autocommands    = 1
call linny#Init()
let g:linny_wikitag_jira_baseurl     = "https://technative.atlassian.net/browse/"
"nmap lo :LinnyMenuOpen <CR>
"nmap lc :LinnyMenuClose <CR>
