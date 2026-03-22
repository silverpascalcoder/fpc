" --- General Essentials ---
set nocompatible         " Use Vim defaults instead of old Vi
let pascal_fpc = 1

filetype on
syntax on                " Enable syntax highlighting for Pascal/Git
set number               " Show line numbers (essential for debugging)
set relativenumber       " Great for jumping lines (e.g., 10j)
colorscheme slate 

" --- Indentation for Pascal ---
set tabstop=2            " Standard Pascal indentation
set shiftwidth=2
set expandtab            " Use spaces instead of tabs for portability
set autoindent
set nosmartindent

" --- Enhanced Completion ---
set wildmenu             " Visual menu for command-line completion
set showmatch            " Highlight matching brackets (begin/end)
set completeopt=menuone  " Show the menu even if there is only one match

" --- Searching ---
set hlsearch             " Highlight search results
set incsearch            " Search as you type
