auto-complete via tab key. third parameter is command list as string list.

providing the user has entered 2 characters (inputbuf) and then presses tab key 

the function will lookup command list for word starting with inputbuf and auto-complete word. 
============

if the user presses tab then 
  if not auto-complete then
    save inputbuf to auto complete buffer
    set auto-complete mode = true
  end;

  lookup command list for next word starting with auto complete buffer
  if found then 
    set input buf to command
end;

if user presses ESC then 
  exits auto-complete mode and 
  restore original input buf from auto complete buffer

if user presses space then 
  exits auto-complete mode and 
  new input buffer is set

