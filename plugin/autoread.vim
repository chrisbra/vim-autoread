" vim-autoread - Read a buffer periodically
" -------------------------------------------------------------
" Version: 0.1
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Thu, 05 Mar 2015 08:11:46 +0100
" Script: http://www.vim.org/scripts/script.php?script_id=
" Copyright:   (c) 2009-2016 by Christian Brabandt
"          The VIM LICENSE applies to vim-autoread
"          (see |copyright|) except use "vim-autoread"
"          instead of "Vim".
"          No warranty, express or implied.
"    *** ***   Use At-Your-Own-Risk!   *** ***
" Init: {{{1
let s:cpo= &cpo
if exists("g:loaded_autoread") || &cp
  finish
elseif !has('job')
  echohl WarningMsg
  echomsg "The vim-autoread Plugin needs at least a Vim version 8 (with +job feature)"
  echohl Normal
  finish
endif
set cpo&vim
let g:loaded_autoread = 1

let s:jobs = {}

function! s:on_exit(channel) dict abort "{{{1
  " Remove from s:jobs
  call remove(s:jobs, self.file)
endfunction

function! s:ReadOutputAsync(cmd, file, buffer) "{{{1
  if has("win32") || has("win64")
    let cmd = a:cmd
  else
    let cmd = ['sh', '-c', a:cmd]
  endif
  if empty(a:file)
    call s:StoreMessage("Buffername empty")
    return
  endif

  let options = {'file': a:file, 'cmd': a:cmd, 'buffer': a:buffer}
  if has_key(s:jobs, a:file) && job_status(get(s:jobs, a:file)) == 'run'
    call s:StoreMessage("Job still running")
    return
  endif
  call s:StoreMessage(printf("Starting Job for file %s buffer %d", a:file, a:buffer))
  let id = job_start(cmd, {
    \ 'err_io':   'out',
    \ 'out_io':   'buffer',
    \ 'out_buf':  a:buffer,
    \ 'close_cb': function('s:on_exit', options)})
  let s:jobs[a:file] = id
endfu

function! s:StoreMessage(msg) "{{{1
  if !exists("s:msg")
    let s:msg = []
  endif
  call add(s:msg, a:msg)
endfu

function! s:OutputMessage() "{{{1
  if empty(s:msg)
    return
  endif
  if get(g:, 'autoread_debug', 0)
    let i=0
    for line in s:msg
      echom (i == 0 ? 'vim-autoread' : ''). line
    endfor
  endif
endfu

function! s:AutoRead(file) "{{{1
  let file=fnamemodify(a:file, ':p')
  if !executable('tail')
    call s:StoreMessage('tail not found')
    return
  elseif !filereadable(file)
    call s:StoreMessage(printf('File "%s" not readable', a:file))
    return
  endif
  let cmd=printf('tail -f -- %s', file)
  norm! G
  call s:ReadOutputAsync(cmd, file, bufnr(''))
endfunction

com! AutoRead :call s:AutoRead(expand('%'))

" vim: ts=2 sts=2 sw=2 et fdm=marker com+=l\:\"
