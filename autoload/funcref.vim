" using function("path#Func") causes vim to load the file.
" I think this is not lazy enough.


" vim requires that the function has already been loaded
" That's why I'm using a faked function reference type here
" funcref#Function("Foo", { 'args' : [2, "foo"], 'self' : dict}) will create a closure. args
" these args + args passed to Call will be the list of args passed to call()
" optional self can be the "object".
function! funcref#Function(name,...)
  let d = a:0 > 0 ? a:1 : {}
  let d['faked_function_reference'] = a:name
  return d
endfunction

" args : same as used for call(f,[list], self), f must be a funcref
" the last "self" argument can be overriden by the function reference
" You can pass arguments in a closure like style
" You can also define lambdas by strings. Example:
"   funcref#Call({'faked_function_reference':'return ARGS[0]'})
" more documentation will be added later
function! funcref#Call(...)
  let args = copy(a:000)
  if (len(args) < 2)
    call add(args, [])
  endif
  " always pass self. this way you can call functions from dictionaries not
  " refering to self
  if (len(args) < 3)
    call add(args, {})
  endif
  if type(a:1) == 2
    " funcref: function must have been laoded
    return call(function('call'), args)
  elseif has_key(a:1, 'faked_function_reference')
    let Fun = args[0]['faked_function_reference']
    if type(Fun) == type('')
        \ && (Fun[:len('return ')-1] == 'return ' 
              \ || Fun[:len('call ')-1] == 'call '
              \ || Fun[:len('if ')-1] == 'if '
              \ || Fun[:len('let ')-1] == 'let '
              \ || Fun[:len('echo ')-1] == 'echo '
              \ || Fun[:len('exec ')-1] == 'exec '
              \ || Fun[:len('debug ')-1] == 'debug ')
      " it doesn't make sense to list all vim commands here
      " So if you want to execute another action consider using 
      " funcref#Function('exec  '.string('aw')) or such

      " function is a String, call exec
      let ARGS = args[1]
      let SELF = args[2]
      exec Fun
    else 
      " pseudo function, let's load it..
      if type(Fun) == 1
        if !exists('*'.Fun)
          " lazily load function
          let file = substitute(substitute(Fun,'#[^#]*$','',''),'#','/','g')
          exec 'runtime /autoload/'.file.'.vim'
        endif
        let Fun2 = function(Fun)
      else
        let Fun2 = Fun
      endif
      if has_key(args[0], 'args') " add args from closure
        if get(args[0], 'evalLazyClosedArgs', 1)
          let args[1] = map(args[0]['args'], 'library#EvalLazy(v:val)')+args[1]
        else
          let args[1] = args[0]['args']+args[1]
        endif
      endif
      if has_key(args[0], 'self')
        let args[2] = args[0]['self']
      endif
      let args[0] = Fun
      return call(function('call'), args)
    endif
  else
    " no function, return the value
    return args[0]
  endif
endfunction
