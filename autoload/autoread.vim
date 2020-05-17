let s:jobs = {}

function! s:autoread_on_exit(channel) dict abort "{{{1
  " Remove from s:jobs
  call remove(s:jobs, self.file)
endfunction

function! s:autoread_cb(channel, msg) dict abort "{{{1
  let switch_buffer = 0
  if bufnr('%') != self.buffer
    " switch to buffer
    let bufinfo = getbufinfo(self.buffer)
    if len(bufinfo[0].windows) == 0
      return
    endif
    let winfo   = getwininfo(bufinfo[0].windows[0])
    let winnr   = winfo[0].winnr
    let tabnr   = winfo[0].tabnr
    let curtabnr = tabpagenr()
    let curwinnr = winnr()
    if tabnr != curtabnr
      exe "noa ". tabnr. "tabnext"
    endif
    if winnr != curwinnr
      exe "noa ". winnr. "wincmd w"
    endif
    let switch_buffer = 1
    if bufnr('%') != self.buffer
      " shouldn't happen
      exe "noa :". self.buffer. "b"
    endif
  endif
  let fsize = getfsize(self.file)
  if fsize < get(b:, 'autoread_fsize', 0)
    call s:StoreMessage('Truncating Buffer, as file seemed to have changed', 'error')
    sil! %d
  endif
  let b:autoread_fsize = fsize
  if line('$') == 1 && empty(getline(1))
    call setline(1, a:msg)
  else
    call append('$', a:msg)
  endif
  norm! G
  if switch_buffer
    exe "noa ". curtabnr. "tabnext"
    exe "noa ". curwinnr. "wincmd w"
  endif
  call s:OutputMessage()
endfunction

function! s:autoread_on_error(channel, msg) dict abort "{{{1
  call s:StoreMessage(a:msg, 'error')
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

  let options = {'file': a:file, 'cmd': a:cmd, 'buffer': a:buffer}
  if has_key(s:jobs, a:file) && job_status(get(s:jobs, a:file)) == 'run'
    call s:StoreMessage("Job still running", 'error')
    return
  endif
  call s:StoreMessage(printf("Starting Job for file %s buffer %d", a:file, a:buffer), 'warning')
  let id = job_start(cmd, {
    \ 'out_io':   'buffer',
    \ 'out_cb':   function('s:autoread_cb', options),
    \ 'close_cb': function('s:autoread_on_exit', options),
    \ 'err_cb':   function('s:autoread_on_error', options)})
  let s:jobs[a:file] = id
endfu

function! s:StoreMessage(msg, type) "{{{1
  if !exists("s:msg_{a:type}")
    let s:msg_{a:type} = []
  endif
  call add(s:msg_{a:type}, a:msg)
endfu

function! s:OutputMessage() "{{{1
  for type in ['warning', 'error']
    if !exists("s:msg_{type}")
      continue
    endif
    let msg=s:msg_{type}
    if empty(msg)
      continue
    endif
    " Always store messages in history
    if get(g:, 'autoread_debug', 0) || type ==# 'error'
      let i=0
      for line in msg
        echom (i == 0 ? ('vim-autoread:'.toupper(type[0]).':') : ''). line
        let i += 1
      endfor
      " Add last message to error message
      if type ==# 'error'
        let v:errmsg = line
      endif
    endif
    unlet! s:msg_{type}
  endfor
endfu

function! autoread#AutoRead(bang, file) "{{{1
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
    call s:StoreMessage('tail not found', 'error')
    return
  elseif empty(file)
    call s:StoreMessage(printf('Filename "%s" not given', file), 'error')
    return
  elseif !filereadable(file)
    call s:StoreMessage(printf('File "%s" not readable', a:file), 'error')
    return
  endif
  let cmd=printf('tail -n0 -F -- %s', file)
  if !exists("#".agroup."#FileChangedShell")
    exe agroup_cmd
      au! FileChangedShell <buffer> :let v:fcs_choice='reload'
    augroup end
  endif
  call s:ReadOutputAsync(cmd, file, bufnr(''))
endfunction

" Modeline {{{1
" vim: ts=2 sts=2 sw=2 et fdm=marker com+=l\:\"
