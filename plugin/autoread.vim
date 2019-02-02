" vim-autoread - Read a buffer periodically
" -------------------------------------------------------------
" Version: 0.2
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Copyright:   (c) 2009-2017 by Christian Brabandt
"          The VIM LICENSE applies to vim-autoread
"          (see |copyright|) except use "vim-autoread"
"          instead of "Vim".
"          No warranty, express or implied.
"    *** ***   Use At-Your-Own-Risk!   *** ***
" Init: {{{1
let s:cpo= &cpo
if exists("g:loaded_autoread") || &cp
  finish
elseif has("nvim")
  " disabled for neovim, because it uses a different API
  finish
elseif !has('job')
  echohl WarningMsg
  echomsg "The vim-autoread Plugin needs at least a Vim version 8 (with +job feature)"
  echohl Normal
  finish
endif
set cpo&vim
let g:loaded_autoread = 1

" Commands: {{{1 
com! -bang AutoRead :call autoread#AutoRead(<q-bang>, expand('%'))

" Reset cpo
let &cpo=s:cpo

" vim: ts=2 sts=2 sw=2 et fdm=marker com+=l\:\"
