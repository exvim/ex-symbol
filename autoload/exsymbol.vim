" variables {{{1
let s:title = "-Symbol-" 

let s:zoom_in = 0
let s:keymap = {}

let s:help_open = 0
let s:help_text_short = [
            \ '" Press <F1> for help',
            \ '',
            \ ]
let s:help_text = s:help_text_short
" }}}

" functions {{{1
" exsymbol#bind_mappings {{{2
function exsymbol#bind_mappings()
    call ex#keymap#bind( s:keymap )
endfunction

" exsymbol#register_hotkey {{{2
function exsymbol#register_hotkey( priority, key, action, desc )
    call ex#keymap#register( s:keymap, a:priority, a:key, a:action, a:desc )
endfunction

" exsymbol#toggle_help {{{2
" s:update_help_text {{{2
function s:update_help_text()
    if s:help_open
        let s:help_text = ex#keymap#helptext(s:keymap)
    else
        let s:help_text = s:help_text_short
    endif
endfunction

function exsymbol#toggle_help()
    let s:help_open = !s:help_open
    silent exec '1,' . len(s:help_text) . 'd _'
    call s:update_help_text()
    silent call append ( 0, s:help_text )
    silent keepjumps normal! gg
endfunction

" exsymbol#open_window {{{2

function exsymbol#init_buffer()
    set filetype=exsymbol

    if ( line('$') <= 1 )
        silent call append ( 0, s:help_text )
        silent exec '$d'
    endif
endfunction

function exsymbol#open_window()
    call ex#window#goto_edit_window()

    let winnr = bufwinnr(s:title)
    if winnr == -1
        call ex#window#open( 
                    \ s:title, 
                    \ g:ex_symbol_winsize,
                    \ g:ex_symbol_winpos,
                    \ 1,
                    \ 1,
                    \ function('exsymbol#init_buffer')
                    \ )
    else
        exe winnr . 'wincmd w'
    endif
endfunction

" exsymbol#toggle_window {{{2
function exsymbol#toggle_window()
    let result = exsymbol#close_window()
    if result == 0
        call exsymbol#open_window()
    endif
endfunction

" exsymbol#close_window {{{2
function exsymbol#close_window()
    let winnr = bufwinnr(s:title)
    if winnr != -1
        call ex#window#close(winnr)
        return 1
    endif
    return 0
endfunction

" exsymbol#toggle_zoom {{{2
function exsymbol#toggle_zoom()
    let winnr = bufwinnr(s:title)
    if winnr != -1
        if s:zoom_in == 0
            let s:zoom_in = 1
            call ex#window#resize( winnr, g:ex_symbol_winpos, g:ex_symbol_winsize_zoom )
        else
            let s:zoom_in = 0
            call ex#window#resize( winnr, g:ex_symbol_winpos, g:ex_symbol_winsize )
        endif
    endif
endfunction

" exsymbol#confirm_select {{{2
function exsymbol#confirm_select()
    let word = getline('.')
    if word == ''
        call ex#warning('Please select a symbol')
    endif

    " close the symbol window
    call exsymbol#close_window()

    " goto edit window
    call ex#window#goto_edit_window()

    exec 'redraw!'

    " tag select
    exec 'ts ' . word
endfunction

" exsymbol#read_symbols {{{2
function exsymbol#list_all()
    let symbols_file = g:exvim_folder . '/symbols'
    if findfile(symbols_file) == ''
        call ex#warning( 'Can not find symbol file: ' . symbols_file )
        return
    endif

    " open the symbol window
    call exsymbol#open_window()

    " clear screen and put new result
    silent exec '1,$d _'

    " add online help 
    silent call append ( 0, s:help_text )
    silent exec '$d'
    let start_line = len(s:help_text)

    " read symbol files
    let symbols = readfile(symbols_file)
    call append( start_line, symbols )
endfunction

" exsymbol#list {{{2
function exsymbol#list( pattern )
    call exsymbol#list_all()
    call exsymbol#filter(a:pattern,0)
endfunction

" exsymbol#filter {{{2
" reverse: 0, 1
function exsymbol#filter( pattern, reverse )
    if a:pattern == ''
        call ex#warning('Search pattern is empty. Please provide your search pattern')
        return
    endif

    let start_line = len(s:help_text)+1
    let range = start_line.',$'

    " if reverse search, we first filter out not pattern line, then then filter pattern
    if a:reverse 
        silent exec range . 'g/' . a:pattern . '/d'
    else
        silent exec range . 'v/' . a:pattern . '/d'
    endif
    silent call cursor( start_line, 1 )
    call ex#hint('Filter: ' . a:pattern )
endfunction

" }}}1

" vim:ts=4:sw=4:sts=4 et fdm=marker:
