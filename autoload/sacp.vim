

"""
" neocomplete needs if_lua, currently not possible with nvim
" deoplete's php engine only work with the unmaintained phpcomplete_extended
" So I do it my self
"
" I hope this will be more extensible then the original AutoComplPop.
" Key mappings are enabled on per-buffer basis, which will make it more easily to be compatible with
" other auto complete plugins.


" call this funciton to enable auto complete pop
function sacp#enableForThisBuffer(options)

	if exists("b:options")
		call sacp#unmapForMappingDriven()
	endif

	let b:lockCount = 0
	let b:options = copy(a:options)

	let &l:completeopt = get(a:options,'completeopt','menu,menuone,noinsert,noselect')
	let b:keysMappingDriven = get(a:options,"inoremap",[
				\ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
				\ 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
				\ 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
				\ 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
				\ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
				\ '-', '_', '~', '^', '.', ',', ':', '!', '#', '=', '%', '$', '@', '<', '>', '/', '\',
				\ '<Space>', '<C-h>', '<BS>', ])

	" Supress the anoying messages like '-- Keyword completion (^N^P)' when
	" press '<C-n>' key. This option is only supported after vim 7.4.314 
	" https://groups.google.com/forum/#!topic/vim_dev/WeBBjkXE8H8
	silent! setlocal shortmess+=c

	inoremap <expr> <buffer> <silent> <TAB>  pumvisible()?"\<C-n>":"\<TAB>"
	inoremap <expr> <buffer> <silent> <S-TAB>  pumvisible()?"\<C-p>":"\<TAB>"
	inoremap <expr> <buffer> <silent> <CR>  pumvisible()?"\<C-y>":"\<CR>"

	call sacp#bufferMapForMappingDriven()

endfunction

function sacp#bufferMapForMappingDriven()
	for key in b:keysMappingDriven
		execute printf('inoremap <buffer> <silent> %s %s<C-r>=sacp#feedPopup()<CR>',
					\        key, key)
	endfor
endfunction

function sacp#unmapForMappingDriven()
	if !exists('b:keysMappingDriven')
		return
	endif
	for key in b:keysMappingDriven
		execute 'silent! iunmap <buffer> ' . key
	endfor
	let b:keysMappingDriven = []
endfunction

function sacp#lock()
	let b:lockCount = get(b:,'lockCount',0);
	let b:lockCount += 1
endfunction

function sacp#unlock()
	let b:lockCount -= 1
	if b:lockCount < 0
		let b:lockCount = 0
		throw "AutoComplPop: not locked"
	endif
endfunction

function sacp#writeLog(line)
	return writefile([a:line],"acp.log","a")
endfunction 

function sacp#feedPopup()

	if &paste
		return ''
	endif

	" NOTE: CursorMovedI is not triggered while the popup menu is visible. And
	"       it will be triggered when popup menu is disappeared.

	if b:lockCount > 0
		return ''
	endif

	let l:needIgnoreCompletionMode = pumvisible() || (b:sacpCompleteDone==0)

	let l:match = s:getFirstMatch(l:needIgnoreCompletionMode)
	if empty(l:match)
		return ''
	endif

	" In case of dividing words by symbols (e.g. "for(int", "ab==cd") while a
	" popup menu is visible, another popup is not available unless input <C-e>
	" or try popup once. So first completion is duplicated.
	" call s:setTempOption(s:GROUP0, 'spell', 0)
	" call s:setTempOption(s:GROUP0, 'complete', g:acp_completeOption)
	" call s:setTempOption(s:GROUP0, 'ignorecase', g:acp_ignorecaseOption)
	" NOTE: With CursorMovedI driven, Set 'lazyredraw' to avoid flickering.
	"       With Mapping driven, set 'nolazyredraw' to make a popup menu visible.
	" call s:setTempOption(s:GROUP0, 'lazyredraw', !g:acp_mappingDriven)
	" NOTE: 'textwidth' must be restored after <C-e>.
	" call s:setTempOption(s:GROUP1, 'textwidth', 0)
	" call s:setCompletefunc()

	" call sacp#writeLog("feedkeys: " . l:match["=~"] . ":" )
	call feedkeys(l:match.feedkeys, 'n')
	let b:sacpCompleteDone = 0
	return '' " this function is called by <C-r>=

endfunction

function s:getCurrentText()
	return strpart(getline('.'), 0, col('.') - 1)
endfunction

function s:getFirstMatch(needIgnoreCompletionMode)

	let l:text = s:getCurrentText()

	for l:m in b:options['matches']

		for [l:operator,l:pattern] in items(l:m)
			if l:operator =~ '^[=~=!#]\{1,}$' " is operator
				let l:r = eval("l:text ".l:operator." l:pattern")
				if l:r == 1
					if (a:needIgnoreCompletionMode==1) && get(l:m,"ignoreCompletionMode",0)==0
						continue
					endif
					return l:m
				endif
			endif
		endfo

		" if call(l:b.meets,[text]) == 1
		" 	return l:b
		" endif
	endfor

	return {}
endfunction

" function sacp#setupCacheFuzzyOmniComplete()
" 	let b:originalLocalOmnifunc = &l:omnifunc
" 	let b:originalOmnifunc      = &omnifunc
" 	if b:originalLocalOmnifunc=="" && b:originalOmnifunc==""
" 		return ""
" 	let &l:omnifunc = 'sacp#cacheFuzzyOmniComplete'
" 	return ''
" endfunction
" 
" " wrapped omni func
" function sacp#cacheFuzzyOmniComplete(findstart,base)
" 
" 	if a:findstart == 1
" 
" 		if b:originalLocalOmnifunc != ""
" 			let b:completeStartColumn = call(b:originalLocalOmnifunc,[a:findstart,a:base])
" 		else
" 			let b:completeStartColumn = call(b:originalOmnifunc,[a:findstart,a:base])
" 		endif
" 		let b:completeCache = []
" 		return b:completeStartColumn
" 
" 	else
" 
" 	" keep calling until returns error?
" 
" 		" read cached complete
" 		if empty(b:completeCache)
" 			if b:originalLocalOmnifunc != ""
" 				let b:completeCache = call(b:originalLocalOmnifunc,[a:findstart,a:base])
" 			else
" 				let b:ompleteCache = call(b:originalOmnifunc,[a:findstart,a:base])
" 			endif
" 		endif
" 
" 		let l:ret = []
" 
" 		" filter return result
" 		let l:typedWord = strpart(getline('.'), b:completeStartColumn, col('.') - 1)
" 
" 	endif
" 
" endfunction

function sacp#setCompleteDone()
	" call sacp#writeLog('sacp#setCompleteDone') " debug
	let b:sacpCompleteDone=1

	" restore omni func, destroys variables
	if &l:omnifunc =~ '^sacp#'
		let &l:omnifunc = b:originalLocalOmnifunc
		let &omnifunc   = b:originalOmnifunc
		unlet b:originalLocalOmnifunc
		unlet b:originalOmnifunc
		unlet b:completeStartColumn
		unlet b:completeCache
	endif

	return ''

endfunction

autocmd InsertEnter,CompleteDone * call sacp#setCompleteDone()

