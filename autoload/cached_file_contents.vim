" cached_file_contents.vim
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2010-01-03.
" @Revision:    0.3.0

"exec scriptmanager#DefineAndBind('s:c','g:cache_dir_options','{}')
if !exists('g:cache_dir_options') | let g:cache_dir_options = {} | endif | let s:c = g:cache_dir_options 

let s:c['cache_dir'] = get(s:c, 'cache_dir', expand('$HOME').'/.vim-cache')
let s:c['scanned_files'] = get(s:c, 'scanned_files', {})
let s:c['use_file_cache'] = get(s:c, 'use_file_cache', 1)


" read a file, run function to extract contents and cache the result returned
" by that function in memory. Optionally the result can be cached on disk as
" because VimL can be slow!
"
" file     : the file to be read
" func: { 'func': function which will be called by funcref#Call
"       , 'version' : if this version changes cache will be invalidate automatically
"       , 'asLines' : optional, default 1.  If set to 0 the filename will be passed insead of the file contents
"       , 'use_file_cache': optional, default 0. If set to 1 the result will be written to a cache file
"       , 'binary': optional, default ''. Can be set to 'b' See :h readfile
"       }
"
" default: what to return if file doesn't exist
function! tlib#cached_file_contents#CachedFileContents(file, func, ...)
  let default = a:0 > 0 ? a:1 : funcref#Function("throw ".string('file '.a:file.' does not exist'))
  let use_file_cache = get(a:func, 'use_file_cache', 0) && s:c['use_file_cache']
  let file = expand(a:file) " simple kind of normalization. necessary when using file caching
  let Func = get(a:func, 'func', funcref#Function('return ARGS[0]'))
  let asLines = get(a:func, 'asLines', 1)
  let binary = get(a:func, 'binary', '')
  let func_as_string = string(Func)
  let v = get(a:func, 'version', 0)

  let useCached = 1
  
  let dict = s:c['scanned_files']

  if (!has_key(dict, func_as_string))
    let dict[func_as_string] = {}
  endif

  let dict = dict[func_as_string]

  if !filereadable(a:file)
    return funcref#Call(default)
  endif

  if use_file_cache
    let this_dir = s:c['cache_dir'].'/cached-file-conents'
    " I'd like to use a hash function. Does Vim has one?
    let cache_file = expand(this_dir.'/'.substitute(string([func_as_string, a:file]),'[[\]{}:/\,''"# ]\+','_','g'))
    if !has_key(dict, a:file) " try getting from file cache
      if filereadable(cache_file)
        let dict[file] = eval(readfile(cache_file,'b')[0])
      endif
    endif
  endif
  if has_key(dict, a:file)
    if useCached
          \ && getftime(a:file) <= dict[a:file]['ftime']
          \ && dict[a:file]['version'] == v
      return dict[a:file]['scan_result']
    endif
  endif
  let Func = a:func['func']
  let scan_result = funcref#Call(Func, [ asLines ? readfile(a:file, binary) : a:file ] )
  let  dict[a:file] = {"ftime": getftime(a:file), 'version': v, "scan_result": scan_result }
  if use_file_cache
    if !isdirectory(this_dir) | call mkdir(this_dir,'p',0700) | endif
    call writefile([string(dict[a:file])], cache_file)
  endif
  return scan_result
endfunction

fun! tlib#cached_file_contents#ClearScanCache()
  let s:c['scanned_files'] = {}

  " Don't run rm -fr. Ask user to run it. It cache_dir may have been set to
  " $HOME ! (should nevere be the case but who knows
  echoe "run manually in your shell:  rm -fr ".shellescape(s:c['cache_dir'])."/*"
endf

fun! tlib#cached_file_contents#Test()

  " usually you use a global option so that the function can be reused
  let my_interpreting_func  = {'func' : funcref#Function('return len(ARGS[0])'), 'version': 2, 'use_file_cache':1, 'asLines':1}
  let my_interpreting_func2 = {'func' : funcref#Function('return ARGS[0]')     , 'version': 2, 'use_file_cache':1, 'asLines':0}

  let tmp = tempname()
  call writefile(['some text','2nd line'], tmp)

  let r = [ tlib#cached_file_contents#CachedFileContents(tmp, my_interpreting_func)
        \ , tlib#cached_file_contents#CachedFileContents(tmp, my_interpreting_func2) ]
   if r != [2, tmp]
    throw "test failed 1, got ".string(r)
  endif
  unlet r

  sleep 3

  " now let's change contents
  call writefile(['some text','2nd line','3rd line'], tmp)

  let r = tlib#cached_file_contents#CachedFileContents(tmp, my_interpreting_func)
  if 3 != r
    throw "test failed 2, got ".string(r)
  endif

  echo "test passed"
endf
