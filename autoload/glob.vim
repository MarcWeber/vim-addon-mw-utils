exec scriptmanager#DefineAndBind('s:c','g:glob_like', '{}')

" ignore vcs stuff, Don't think you want those..
let s:c['regex_ignore_directory'] = '\<\%([_.]darcs\|\.git\|.svn\|.hg\|.cvs\|.bzr\)\>'

fun! glob#Glob(pattern)
  " FIXME: don't recurse into \.git directory (thus reimplement glob in vimL!)
  return filter(split(glob(a:pattern),"\n"),'v:val !~ '.string(s:c['regex_ignore_directory']))
endf
