exec scriptmanager#DefineAndBind('s:c','g:cache_dir_options','{}')
let s:c['cache_dir'] = get(s:c, 'cache_dir', expand('$HOME').'/.vim-cache')

"TODO add command to clear cache.. because it will grow and grow.

" opts: scan_func: This function will be applied before returning contents
"       fileCache : write the result to a file (default no)
"       asLines   : if set then read the file and feed file contents into
"                   functions. If not set pass the filename (Maybe you want to
"                   use and external application to process the file)
"       useCached : don't update file, use cache if already present
"       default: what to return if file doesn't exist
function! cached_interpretation_of_file#ScanIfNewer(file, opts)
  let cache = get(a:opts, 'fileCache', 0)
  let file = expand(a:file) " simple kind of normalization. necessary when using file caching
  let Func = get(a:opts, 'scan_func', library#Function('library#Id'))
  let asLines = get(a:opts, 'asLines', 1)
  let func_as_string = string(Func)
  let path = ['scanned_files',func_as_string]
  
  let dict = config#GetG(path, {'set': 1, 'default' : {}})

  if cache
    let this_dir = s:c['cache_dir'].'/scan-and-cache'
    let cache_file = expand(this_dir.'/'.substitute(string([Func, a:file]),'[[\]{}:/\,''"# ]\+','_','g'))
    if !has_key(dict, a:file) " try getting from file cache
      if filereadable(cache_file)
        let dict[file] = eval(readfile(cache_file)[0])
      endif
    endif
  endif
  if has_key(dict, a:file)
    " return cached value if up to date
    if get(a:opts, 'useCached', 1)
          \ && getftime(a:file) <= dict[a:file]['ftime']
      return dict[a:file]['scan_result']
    endif
  endif
  if asLines
    try 
      let contents = readfile(a:file)
    catch /.*/
      if has_key(a:opts,'default')
        let contents = a:opts['default']
      else
        throw "ScanIfNewer: Could'n read file ".a:file." error: ".tovl#log#FormatException()
      endif
    endtry
    let scan_result = funcref#Call(Func, [contents])
  else
    let scan_result = funcref#Call(Func, [a:file])
  endif
  let  dict[a:file] = {"ftime": getftime(a:file), "scan_result": scan_result }
  if cache
    if !isdirectory(this_dir) | call mkdir(this_dir,'p',0700) | endif
    call writefile([string(dict[a:file])], cache_file)
  endif
  return scan_result
endfunction
