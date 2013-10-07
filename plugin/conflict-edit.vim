function! EditConflictFiles()
    let filter = system('git diff --name-only --diff-filter=U')
    let conflicted = split( filter, '\r')
    let massaged = []

    for conflict in conflicted
        let tmp = substitute(conflict, '\_s\+', '', 'g')
        if len( tmp ) > 0
            call add( massaged, tmp )
        endif
    endfor

    call ProcessConflictFiles( massaged )
endfunction

" Experimental function to load vim with all conflicted files
function! ProcessConflictFiles( files )
    " These will be conflict files to edit
    let conflicts = []

    " Read git attributes file into a string
    let gitignore = join(readfile('.gitattributes'), '')

    let conflictFiles = len( a:files ) ? a:files : argv()

    " Loop over each file in the arglist (passed in to vim from bash)
    for conflict in conflictFiles

        " If this file is not ignored in gitattributes (this could be improved)
        if gitignore !~ conflict

            " Grep each file for the starting error marker
            let cmd = system("grep -n '<<<<<<<' ".conflict)

            " Remove the first line (grep command) and split on linebreak
            let markers = split( cmd, '\r' )

            for marker in markers
                let spl = split( marker, ':' )
                echo spl

                " If this line had a colon in it (otherwise it's an empty line
                " from command output)
                if len( spl ) == 2

                    " Get the line number by removing the white space around it,
                    " because vim is a piece of shit
                    let line = substitute(spl[0], '\_s\+', '', 'g')
                    
                    " Add this file to the list with the data format for the quickfix
                    " window
                    call add( conflicts, {'filename': conflict, 'lnum': line, 'text': spl[1]} )
                endif
            endfor
        endif
        
    endfor

    " Set the quickfix files and open the list
    call setqflist( conflicts )
    execute 'copen'
    execute 'cfirst'

    " Highlight diff markers and then party until you shit
    highlight Conflict guifg=white guibg=red
    match Conflict /^=\{7}.*\|^>\{7}.*\|^<\{7}.*/
    let @/ = '>>>>>>>\|=======\|<<<<<<<'
endfunction
