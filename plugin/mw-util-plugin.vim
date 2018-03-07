if exists('did_mw_util_plugin') || &cp || version < 700
  finish
endif
let did_mw_util_plugin = 1

command! -nargs=0 ClearScanCache call cached_file_contents#ClearScanCache()
