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

function! s:autoread_on_exit(channel) dict abort "{{{1
  " Remove from s:jobs
  call remove(s:jobs, self.file)
endfunction

function! s:autoread_on_error(channel, msg) dict abort "{{{1
  echohl ErrorMsg
  echom a:msg
  echohl None
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
    \ 'out_io':   'buffer',
    \ 'out_buf':  a:buffer,
    \ 'close_cb': function('s:autoread_on_exit', options),
    \ 'err_cb':   function('s:autoread_on_error', options)})
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

function! s:AutoRead(bang, file) "{{{1
  let file=fnamemodify(a:file, ':p')
  let buff=bufnr('%')
  let agroup='vim-autoread-'.buff
  let agroup_cmd='augroup '.agroup
  if !empty(a:bang)
    if has_key(s:jobs, file)
      call job_stop(s:jobs[file])
    endif
    exe agroup_cmd
      au!
    augroup end
    exe "augroup!" agroup
    return
  endif
  if !executable('tail')
    call s:StoreMessage('tail not found')
    return
  elseif !filereadable(file)
    call s:StoreMessage(printf('File "%s" not readable', a:file))
    return
  endif
  let cmd=printf('tail -n0 -F -- %s', file)
  norm! G
  if !exists("#".agroup."#FileChangedShell")
    exe agroup_cmd
      au! FileChangedShell <buffer> :let v:fcs_choice='reload'
    augroup end
  endif
  call s:ReadOutputAsync(cmd, file, bufnr(''))
endfunction

" Commands: {{{1 
com! -bang AutoRead :call s:AutoRead(<q-bang>, expand('%'))

" vim: ts=2 sts=2 sw=2 et fdm=marker com+=l\:\"
