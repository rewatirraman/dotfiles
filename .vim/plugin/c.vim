"#################################################################################
"
"       Filename:  c.vim
"
"    Description:  C/C++-IDE. Write programs by inserting complete statements,
"                  comments, idioms, code snippets, templates and comments.
"                  Compile, link and run one-file-programs without a makefile.
"                  See also help file csupport.txt .
"
"   GVIM Version:  7.0+
"
"  Configuration:  There are some personal details which should be configured
"                   (see the files README.md and csupport.txt).
"
"         Author:  Wolfgang Mehner <wolfgang-mehner@web.de>
"                  (formerly Fritz Mehner <mehner.fritz@web.de>)
"
"        Version:  see variable  g:C_Version  below
"        Created:  04.11.2000
"       Revision:  22.11.2020
"        License:  Copyright (c) 2000-2014, Fritz Mehner
"                  Copyright (c) 2015-2020, Wolfgang Mehner
"                  This program is free software; you can redistribute it and/or
"                  modify it under the terms of the GNU General Public License as
"                  published by the Free Software Foundation, version 2 of the
"                  License.
"                  This program is distributed in the hope that it will be
"                  useful, but WITHOUT ANY WARRANTY; without even the implied
"                  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
"                  PURPOSE.
"                  See the GNU General Public License version 2 for more details.
"
"------------------------------------------------------------------------------

"-------------------------------------------------------------------------------
" === Basic checks ===   {{{1
"-------------------------------------------------------------------------------

" need at least 7.0
if v:version < 700
	echohl WarningMsg
	echo 'The plugin c.vim needs Vim version >= 7.'
	echohl None
	finish
endif

" prevent duplicate loading
" need compatible
if exists("g:C_Version") || &cp
	finish
endif

let g:C_Version= "6.2.1beta"                  " version number of this script; do not change

"-------------------------------------------------------------------------------
" === Auxiliary functions ===   {{{1
"-------------------------------------------------------------------------------

"-------------------------------------------------------------------------------
" s:ApplyDefaultSetting : Write default setting to a global variable.   {{{2
"
" Parameters:
"   varname - name of the variable (string)
"   value   - default value (string)
" Returns:
"   -
"
" If g:<varname> does not exists, assign:
"   g:<varname> = value
"-------------------------------------------------------------------------------

function! s:ApplyDefaultSetting ( varname, value )
	if ! exists( 'g:'.a:varname )
		let {'g:'.a:varname} = a:value
	endif
endfunction

"-------------------------------------------------------------------------------
" s:ErrorMsg : Print an error message.   {{{2
"
" Parameters:
"   line1 - a line (string)
"   line2 - a line (string)
"   ...   - ...
" Returns:
"   -
"-------------------------------------------------------------------------------

function! s:ErrorMsg ( ... )
	echohl WarningMsg
	for line in a:000
		echomsg line
	endfor
	echohl None
endfunction

"-------------------------------------------------------------------------------
" s:GetGlobalSetting : Get a setting from a global variable.   {{{2
"
" Parameters:
"   varname - name of the variable (string)
"   glbname - name of the global variable (string, optional)
" Returns:
"   -
"
" If 'glbname' is given, it is used as the name of the global variable.
" Otherwise the global variable will also be named 'varname'.
"
" If g:<glbname> exists, assign:
"   s:<varname> = g:<glbname>
"-------------------------------------------------------------------------------

function! s:GetGlobalSetting ( varname, ... )
	let lname = a:varname
	let gname = a:0 >= 1 ? a:1 : lname
	if exists( 'g:'.gname )
		let {'s:'.lname} = {'g:'.gname}
	endif
endfunction

"-------------------------------------------------------------------------------
" s:ImportantMsg : Print an important message.   {{{2
"
" Parameters:
"   line1 - a line (string)
"   line2 - a line (string)
"   ...   - ...
" Returns:
"   -
"-------------------------------------------------------------------------------

function! s:ImportantMsg ( ... )
	echohl Search
	echo join ( a:000, "\n" )
	echohl None
endfunction    " ----------  end of function s:ImportantMsg  ----------

"-------------------------------------------------------------------------------
" s:SID : Return the <SID>.   {{{2
"
" Parameters:
"   -
" Returns:
"   SID - the SID of the script (string)
"-------------------------------------------------------------------------------

function! s:SID ()
	return matchstr ( expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$' )
endfunction    " ----------  end of function s:SID  ----------

"-------------------------------------------------------------------------------
" s:UserInput : Input after a highlighted prompt.   {{{2
"
" Parameters:
"   prompt - the prompt (string)
"   text - the default input (string)
"   compl - completion (string, optional)
"   clist - list, if 'compl' is "customlist" (list, optional)
" Returns:
"   input - the user input, an empty sting if the user hit <ESC> (string)
"-------------------------------------------------------------------------------

function! s:UserInput ( prompt, text, ... )

	echohl Search                                         " highlight prompt
	call inputsave()                                      " preserve typeahead
	if a:0 == 0 || a:1 == ''
		let retval = input( a:prompt, a:text )
	elseif a:1 == 'customlist'
		let s:UserInputList = a:2
		let retval = input( a:prompt, a:text, 'customlist,<SNR>'.s:SID().'_UserInputEx' )
		let s:UserInputList = []
	else
		let retval = input( a:prompt, a:text, a:1 )
	endif
	call inputrestore()                                   " restore typeahead
	echohl None                                           " reset highlighting

	let retval  = substitute( retval, '^\s\+', "", "" )   " remove leading whitespaces
	let retval  = substitute( retval, '\s\+$', "", "" )   " remove trailing whitespaces

	return retval

endfunction    " ----------  end of function s:UserInput ----------

"-------------------------------------------------------------------------------
" s:UserInputEx : ex-command for s:UserInput.   {{{3
"-------------------------------------------------------------------------------
function! s:UserInputEx ( ArgLead, CmdLine, CursorPos )
	if empty( a:ArgLead )
		return copy( s:UserInputList )
	endif
	return filter( copy( s:UserInputList ), 'v:val =~ ''\V\<'.escape(a:ArgLead,'\').'\w\*''' )
endfunction    " ----------  end of function s:UserInputEx  ----------
" }}}3
"-------------------------------------------------------------------------------

"-------------------------------------------------------------------------------
" s:WarningMsg : Print a warning/error message.   {{{2
"
" Parameters:
"   line1 - a line (string)
"   line2 - a line (string)
"   ...   - ...
" Returns:
"   -
"-------------------------------------------------------------------------------

function! s:WarningMsg ( ... )
	echohl WarningMsg
	echo join ( a:000, "\n" )
	echohl None
endfunction    " ----------  end of function s:WarningMsg  ----------

" }}}2
"-------------------------------------------------------------------------------

"-------------------------------------------------------------------------------
" === Module setup ===   {{{1
"-------------------------------------------------------------------------------

"-------------------------------------------------------------------------------
" == Platform specific items ==   {{{2
"
" - root directory
" - characters that must be escaped for filenames
"-------------------------------------------------------------------------------

let s:MSWIN = has("win16") || has("win32")   || has("win64")     || has("win95")
let s:UNIX  = has("unix")  || has("macunix") || has("win32unix")

let g:C_Installation				= '*undefined*'
let s:plugin_dir						= ''
"
let s:C_GlobalTemplateFile	= ''
let s:C_LocalTemplateFile		= ''
let s:C_CustomTemplateFile  = ''                " the custom templates
let s:C_FilenameEscChar 		= ''

let s:C_ToolboxDir					= []

if	s:MSWIN
  " ==========  MS Windows  ======================================================
	"
	let s:plugin_dir = substitute( expand('<sfile>:p:h:h'), '\', '/', 'g' )
	"
	" change '\' to '/' to avoid interpretation as escape character
	if match(	substitute( expand("<sfile>"), '\', '/', 'g' ), 
				\		substitute( expand("$HOME"),   '\', '/', 'g' ) ) == 0
		"
		" USER INSTALLATION ASSUMED
		let g:C_Installation				= 'local'
		let s:C_LocalTemplateFile		= s:plugin_dir.'/c-support/templates/Templates'
		let s:C_CustomTemplateFile  = $HOME.'/vimfiles/templates/c.templates'
		let s:C_ToolboxDir				 += [ s:plugin_dir.'/autoload/mmtoolbox/' ]
	else
		"
		" SYSTEM WIDE INSTALLATION
		let g:C_Installation				= 'system'
		let s:C_GlobalTemplateFile  = s:plugin_dir.'/c-support/templates/Templates'
		let s:C_LocalTemplateFile		= $HOME.'/vimfiles/c-support/templates/Templates'
		let s:C_CustomTemplateFile  = $HOME.'/vimfiles/templates/c.templates'
		let s:C_ToolboxDir				 += [
					\	s:plugin_dir.'/autoload/mmtoolbox/',
					\	$HOME.'/vimfiles/autoload/mmtoolbox/' ]
	endif
	"
  let s:C_FilenameEscChar 			= ''
	"
else
  " ==========  Linux/Unix  ======================================================
	"
	let s:plugin_dir	= expand('<sfile>:p:h:h')
	"
	if match( expand("<sfile>"), resolve( expand("$HOME") ) ) == 0
		" USER INSTALLATION ASSUMED
		let g:C_Installation				= 'local'
		let s:C_LocalTemplateFile		= s:plugin_dir.'/c-support/templates/Templates'
		let s:C_CustomTemplateFile  = $HOME.'/.vim/templates/c.templates'
		let s:C_ToolboxDir				 += [ s:plugin_dir.'/autoload/mmtoolbox/' ]
	else
		" SYSTEM WIDE INSTALLATION
		let g:C_Installation				= 'system'
		let s:C_GlobalTemplateFile  = s:plugin_dir.'/c-support/templates/Templates'
		let s:C_LocalTemplateFile		= $HOME.'/.vim/c-support/templates/Templates'
		let s:C_CustomTemplateFile  = $HOME.'/.vim/templates/c.templates'
		let s:C_ToolboxDir				 += [
					\	s:plugin_dir.'/autoload/mmtoolbox/',
					\	$HOME.'/.vim/autoload/mmtoolbox/' ]
	endif
	"
  let s:C_FilenameEscChar 			= ' \%#[]'
	"
endif
"
let s:C_AdditionalTemplates   = mmtemplates#config#GetFt ( 'c' )
let s:C_CodeSnippets  				= s:plugin_dir.'/c-support/codesnippets/'
let s:C_IndentErrorLog				= $HOME.'/.indent.errorlog'

"-------------------------------------------------------------------------------
" == Various settings ==   {{{2
"-------------------------------------------------------------------------------

"-------------------------------------------------------------------------------
" Use of dictionaries   {{{3
"
" - keyword completion is enabled by the function 's:CreateAdditionalMaps' below
"-------------------------------------------------------------------------------

if !exists("g:C_Dictionary_File")
  let g:C_Dictionary_File = s:plugin_dir.'/c-support/wordlists/c-c++-keywords.list,'.
        \                   s:plugin_dir.'/c-support/wordlists/k+r.list,'.
        \                   s:plugin_dir.'/c-support/wordlists/stl_index.list'
endif

"-------------------------------------------------------------------------------
" User configurable options   {{{3
"-------------------------------------------------------------------------------

if	s:MSWIN
	call s:ApplyDefaultSetting ( 'C_CCompiler',     'gcc.exe' )
	call s:ApplyDefaultSetting ( 'C_CplusCompiler', 'g++.exe' )
	let s:C_ExeExtension        = '.exe'     " file extension for executables (leading point required)
	let s:C_ObjExtension        = '.obj'     " file extension for objects (leading point required)
	let s:C_Man                 = 'man.exe'  " the manual program
else
	call s:ApplyDefaultSetting ( 'C_CCompiler',     'gcc' )
	call s:ApplyDefaultSetting ( 'C_CplusCompiler', 'g++-11' )
	let s:C_ExeExtension        = ''         " file extension for executables (leading point required)
	let s:C_ObjExtension        = '.o'       " file extension for objects (leading point required)
	let s:C_Man                 = 'man'      " the manual program
endif
"
call s:ApplyDefaultSetting ( 'C_CFlags', '-Wall -g -O0 -c')
call s:ApplyDefaultSetting ( 'C_LFlags', '-Wall -g -O0'   )
call s:ApplyDefaultSetting ( 'C_Libs',   '-lm'            )
"
call s:ApplyDefaultSetting ( 'C_CplusCFlags', '-Wall -g -O0 -c')
call s:ApplyDefaultSetting ( 'C_CplusLFlags', '-Wall -g -O0'   )
call s:ApplyDefaultSetting ( 'C_CplusLibs',   '-lm'            )
call s:ApplyDefaultSetting ( 'C_Debugger',    'gdb'            )
"
call s:ApplyDefaultSetting ( 'C_MapLeader', '' )       " default: do not overwrite 'maplocalleader'
"
let s:C_CExtension     				= 'c'                    " C file extension; everything else is C++
let s:C_CodeCheckExeName      = 'check'
let s:C_CodeCheckOptions      = '-K13'
let s:C_ExecutableToRun       = ''
let s:C_LineEndCommColDefault = 49
let s:C_LoadMenus      				= 'yes'
let s:C_CreateMenusDelayed    = 'no'
let s:C_OutputGvim            = 'vim'
let s:C_Printheader           = "%<%f%h%m%<  %=%{strftime('%x %X')}     Page %N"
let s:C_RootMenu  	   				= '&C\/C\+\+.'           " the name of the root menu of this plugin
let s:C_TypeOfH               = 'cpp'
let s:C_Wrapper               = s:plugin_dir.'/c-support/scripts/wrapper.sh'
let s:C_GuiSnippetBrowser     = 'gui'										" gui / commandline
let s:C_UseToolbox            = 'yes'
call s:ApplyDefaultSetting ( 'C_UseTool_cmake',   'no' )
call s:ApplyDefaultSetting ( 'C_UseTool_doxygen', 'no' )
call s:ApplyDefaultSetting ( 'C_UseTool_make',    'yes' )

let s:C_Ctrl_j								= 'on'
"
let s:C_SourceCodeExtensions  = 'c cc cp cxx cpp CPP c++ C i ii'
let s:C_CppcheckSeverity			= 'all'
let s:C_InsertFileHeader			= 'yes'
let s:C_NonCComment						= '#'
"
let s:C_MenusVisible          = 'no'		" state variable controlling the C-menus

"-------------------------------------------------------------------------------
" Get user configuration   {{{3
"-------------------------------------------------------------------------------

call s:GetGlobalSetting( 'C_CodeCheckExeName' )
call s:GetGlobalSetting( 'C_CodeCheckOptions' )
call s:GetGlobalSetting( 'C_CodeSnippets' )
call s:GetGlobalSetting( 'C_CreateMenusDelayed' )
call s:GetGlobalSetting( 'C_Ctrl_j' )
call s:GetGlobalSetting( 'C_CustomTemplateFile' )
call s:GetGlobalSetting( 'C_ExeExtension' )
call s:GetGlobalSetting( 'C_GlobalTemplateFile' )
call s:GetGlobalSetting( 'C_GuiSnippetBrowser' )
call s:GetGlobalSetting( 'C_IndentErrorLog' )
call s:GetGlobalSetting( 'C_InsertFileHeader' )
call s:GetGlobalSetting( 'C_LineEndCommColDefault' )
call s:GetGlobalSetting( 'C_LoadMenus' )
call s:GetGlobalSetting( 'C_LocalTemplateFile' )
call s:GetGlobalSetting( 'C_Man' )
call s:GetGlobalSetting( 'C_NonCComment' )
call s:GetGlobalSetting( 'C_ObjExtension' )
call s:GetGlobalSetting( 'C_OutputGvim' )
call s:GetGlobalSetting( 'C_Printheader' )
call s:GetGlobalSetting( 'C_RootMenu' )
call s:GetGlobalSetting( 'C_SourceCodeExtensions' )
call s:GetGlobalSetting( 'C_TypeOfH' )
call s:GetGlobalSetting( 'C_UseToolbox' )

"-------------------------------------------------------------------------------
" Xterm   {{{3
"-------------------------------------------------------------------------------

let s:Xterm_Executable = 'xterm'
let s:C_XtermDefaults  = '-fa courier -fs 12 -geometry 80x24'

" check 'g:C_XtermDefaults' for backwards compatibility
if ! exists ( 'g:Xterm_Options' )
	call s:GetGlobalSetting ( 'C_XtermDefaults' )
	" set default geometry if not specified
	if match( s:C_XtermDefaults, "-geometry\\s\\+\\d\\+x\\d\\+" ) < 0
		let s:C_XtermDefaults = s:C_XtermDefaults." -geometry 80x24"
	endif
endif

call s:GetGlobalSetting ( 'Xterm_Executable' )
call s:ApplyDefaultSetting ( 'Xterm_Options', s:C_XtermDefaults )

"-------------------------------------------------------------------------------
" Control variables (not user configurable)   {{{3
"-------------------------------------------------------------------------------

let s:stdbuf	= ''
if executable( 'stdbuf' )
	" stdbuf : the output stream will be unbuffered
	let s:stdbuf	= 'stdbuf -o0 '
endif

" escape the printheader
"
let s:C_Printheader  = escape( s:C_Printheader, ' %' )
"
let s:C_HlMessage    = ""
"
" characters that must be escaped for filenames
"
let s:C_If0_Counter   = 0
let s:C_If0_Txt		 		= "If0Label_"
"
let s:C_SplintIsExecutable		= executable( "splint" )
let s:C_CppcheckIsExecutable	= executable( "cppcheck" )
let s:C_CodeCheckIsExecutable	= executable( s:C_CodeCheckExeName )
let s:C_IndentIsExecutable		= executable( "indent" )

let s:C_Com1          			= '/*'     " C-style : comment start
let s:C_Com2          			= '*/'     " C-style : comment end
"
let s:C_TemplateJumpTarget  = '<+\i\++>\|{+\i\++}\|<-\i\+->\|{-\i\+-}'

let s:C_ForTypes     = [
    \ 'char'                  ,
    \ 'int'                   ,
    \ 'long'                  ,
    \ 'long int'              ,
    \ 'long long'             ,
    \ 'long long int'         ,
    \ 'short'                 ,
    \ 'short int'             ,
    \ 'size_t'                ,
    \ 'unsigned'              , 
    \ 'unsigned char'         ,
    \ 'unsigned int'          ,
    \ 'unsigned long'         ,
    \ 'unsigned long int'     ,
    \ 'unsigned long long'    ,
    \ 'unsigned long long int',
    \ 'unsigned short'        ,
    \ 'unsigned short int'    ,
    \ ]

let s:MenuRun         = s:C_RootMenu.'&Run'
let s:Output					= [ 'VIM->buffer->xterm', 'BUFFER->xterm->vim', 'XTERM->vim->buffer' ]

let s:C_saved_global_option				= {}
let s:C_SourceCodeExtensionsList	= split( s:C_SourceCodeExtensions, '\s\+' )
"
let s:CppcheckSeverity	= [ "all", "error", "warning", "style", "performance", "portability", "information" ]

" }}}3
"-------------------------------------------------------------------------------

" }}}2
"-------------------------------------------------------------------------------

"-------------------------------------------------------------------------------
" s:InitMenus : Initialize menus.   {{{1
"-------------------------------------------------------------------------------
function! s:InitMenus ()

	if ! has ( 'menu' )
		return
	endif
	"
	" Preparation
	call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'do_reset' )
	"
	" get the mapleader (correctly escaped)
	let [ esc_mapl, err ] = mmtemplates#core#Resource ( g:C_Templates, 'escaped_mapleader' )
	"
	exe 'amenu '.s:C_RootMenu.'C\/C\+\+ <Nop>'
	exe 'amenu '.s:C_RootMenu.'-Sep00-  <Nop>'
	"
	let [ MenuDoxygen, err_dox ] = mmtemplates#core#Resource ( g:C_Templates, 'get', 'property', 'Doxygen::BriefAM::Menu' )
	if err_dox == '' && MenuDoxygen != ''
		let MenuDoxygen	= mmtemplates#core#EscapeMenu( MenuDoxygen, 'menu' )
	endif
	"
	"-------------------------------------------------------------------------------
	" menu headers
	"-------------------------------------------------------------------------------
	"
	call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'sub_menu', '&Comments', 'priority', 500 )
	if err_dox == '' && MenuDoxygen != ''
		call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'sub_menu', MenuDoxygen, 'priority', 500 )
	endif
	" the other, automatically created menus go here; their priority is the standard priority 500
	call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'sub_menu', 'S&nippets', 'priority', 600 )
	call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'sub_menu', '&Run'     , 'priority', 700 )
	if s:C_UseToolbox == 'yes' && mmtoolbox#tools#Property ( s:C_Toolbox, 'empty-menu' ) == 0
		call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'sub_menu', '&Tool\ Box', 'priority', 800 )
	endif
	call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'sub_menu', '&Help'    , 'priority', 900 )
	"
	"===============================================================================================
	"----- Menu : C-Comments --------------------------------------------------   {{{2
	"===============================================================================================
	"
	let	MenuComments	= s:C_RootMenu.'&Comments'
	"
	exe "amenu <silent> ".MenuComments.'.end-of-&line\ comment<Tab>'.esc_mapl.'cl           :call C_EndOfLineComment( )<CR>'
	exe "vmenu <silent> ".MenuComments.'.end-of-&line\ comment<Tab>'.esc_mapl.'cl           :call C_EndOfLineComment( )<CR>'

	exe "amenu <silent> ".MenuComments.'.ad&just\ end-of-line\ com\.<Tab>'.esc_mapl.'cj     :call C_AdjustLineEndComm()<CR>'
	exe "vmenu <silent> ".MenuComments.'.ad&just\ end-of-line\ com\.<Tab>'.esc_mapl.'cj     :call C_AdjustLineEndComm()<CR>'

	exe "amenu <silent> ".MenuComments.'.&set\ end-of-line\ com\.\ col\.<Tab>'.esc_mapl.'cs :call C_GetLineEndCommCol()<CR>'

	exe "amenu  ".MenuComments.'.-SEP10-                              :'
	exe "amenu <silent> ".MenuComments.'.code\ ->\ comment\ \/&*\ *\/<Tab>'.esc_mapl.'c*      :call C_CodeToCommentC()<CR>:nohlsearch<CR>j'
	exe "vmenu <silent> ".MenuComments.'.code\ ->\ comment\ \/&*\ *\/<Tab>'.esc_mapl.'c*      :call C_CodeToCommentC()<CR>:nohlsearch<CR>j'
	exe "imenu <silent> ".MenuComments.'.code\ ->\ comment\ \/&*\ *\/<Tab>'.esc_mapl.'c* <C-C>:call C_CodeToCommentC()<CR>:nohlsearch<CR>j'
	exe "amenu <silent> ".MenuComments.'.code\ ->\ comment\ &\/\/<Tab>'.esc_mapl.'cc          :call C_CodeToCommentCpp()<CR>:nohlsearch<CR>j'
	exe "vmenu <silent> ".MenuComments.'.code\ ->\ comment\ &\/\/<Tab>'.esc_mapl.'cc          :call C_CodeToCommentCpp()<CR>:nohlsearch<CR>j'
	exe "imenu <silent> ".MenuComments.'.code\ ->\ comment\ &\/\/<Tab>'.esc_mapl.'cc     <C-C>:call C_CodeToCommentCpp()<CR>:nohlsearch<CR>j'
	exe "amenu <silent> ".MenuComments.'.c&omment\ ->\ code<Tab>'.esc_mapl.'co                :call C_CommentToCode()<CR>:nohlsearch<CR>'
	exe "vmenu <silent> ".MenuComments.'.c&omment\ ->\ code<Tab>'.esc_mapl.'co                :call C_CommentToCode()<CR>:nohlsearch<CR>'
	exe "imenu <silent> ".MenuComments.'.c&omment\ ->\ code<Tab>'.esc_mapl.'co           <C-C>:call C_CommentToCode()<CR>:nohlsearch<CR>'
	" 
  exe "amenu <silent> ".MenuComments.'.toggle\ &non-C\ comment<Tab>'.esc_mapl.'cn           :call C_NonCCommentToggle()<CR>j'
	exe "vmenu <silent> ".MenuComments.'.toggle\ &non-C\ comment<Tab>'.esc_mapl.'cn           :call C_NonCCommentToggle()<CR>j'
  exe "imenu <silent> ".MenuComments.'.toggle\ &non-C\ comment<Tab>'.esc_mapl.'cn      <C-C>:call C_NonCCommentToggle()<CR>j'

	exe "amenu          ".MenuComments.'.-SEP0-                        :'
	"
	"===============================================================================================
	"----- Menu : GENERATE MENU ITEMS FROM THE TEMPLATES ----------------------   {{{2
	"===============================================================================================
	call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'do_templates' )
	"===============================================================================================
	"===============================================================================================
	"
	"===============================================================================================
	"----- Menu : Snippets ----------------------------------------------------   {{{2
	"===============================================================================================
	"
	let	ahead	= 'anoremenu <silent> '.s:C_RootMenu.'S&nippets.'
	let	vhead	= 'vnoremenu <silent> '.s:C_RootMenu.'S&nippets.'
	let	ihead	= 'inoremenu <silent> '.s:C_RootMenu.'S&nippets.'
	"
	if !empty(s:C_CodeSnippets)
		exe ahead.'&read\ code\ snippet<Tab>'.esc_mapl.'nr       :call C_CodeSnippet("r")<CR>'
		exe ihead.'&read\ code\ snippet<Tab>'.esc_mapl.'nr  <C-C>:call C_CodeSnippet("r")<CR>'
		exe ahead.'&view\ code\ snippet<Tab>'.esc_mapl.'nv       :call C_CodeSnippet("view")<CR>'
		exe ihead.'&view\ code\ snippet<Tab>'.esc_mapl.'nv  <C-C>:call C_CodeSnippet("view")<CR>'
		exe ahead.'&write\ code\ snippet<Tab>'.esc_mapl.'nw      :call C_CodeSnippet("w")<CR>'
		exe vhead.'&write\ code\ snippet<Tab>'.esc_mapl.'nw <C-C>:call C_CodeSnippet("wv")<CR>'
		exe ihead.'&write\ code\ snippet<Tab>'.esc_mapl.'nw <C-C>:call C_CodeSnippet("w")<CR>'
		exe ahead.'&edit\ code\ snippet<Tab>'.esc_mapl.'ne       :call C_CodeSnippet("e")<CR>'
		exe ihead.'&edit\ code\ snippet<Tab>'.esc_mapl.'ne  <C-C>:call C_CodeSnippet("e")<CR>'
		exe ahead.'-SEP1-								:'
	endif
	exe ahead.'&pick\ up\ func\.\ prototype<Tab>'.esc_mapl.'nf,\ '.esc_mapl.'np         :call C_ProtoPick("function")<CR>'
	exe vhead.'&pick\ up\ func\.\ prototype<Tab>'.esc_mapl.'nf,\ '.esc_mapl.'np         :call C_ProtoPick("function")<CR>'
	exe ihead.'&pick\ up\ func\.\ prototype<Tab>'.esc_mapl.'nf,\ '.esc_mapl.'np    <C-C>:call C_ProtoPick("function")<CR>'
	exe ahead.'&pick\ up\ method\ prototype<Tab>'.esc_mapl.'nm                :call C_ProtoPick("method")<CR>'
	exe vhead.'&pick\ up\ method\ prototype<Tab>'.esc_mapl.'nm                :call C_ProtoPick("method")<CR>'
	exe ihead.'&pick\ up\ method\ prototype<Tab>'.esc_mapl.'nm           <C-C>:call C_ProtoPick("method")<CR>'
	exe ahead.'&insert\ prototype(s)<Tab>'.esc_mapl.'ni        :call C_ProtoInsert()<CR>'
	exe ihead.'&insert\ prototype(s)<Tab>'.esc_mapl.'ni   <C-C>:call C_ProtoInsert()<CR>'
	exe ahead.'&clear\ prototype(s)<Tab>'.esc_mapl.'nc         :call C_ProtoClear()<CR>'
	exe ihead.'&clear\ prototype(s)<Tab>'.esc_mapl.'nc 	 <C-C>:call C_ProtoClear()<CR>'
	exe ahead.'&show\ prototype(s)<Tab>'.esc_mapl.'ns		      :call C_ProtoShow()<CR>'
	exe ihead.'&show\ prototype(s)<Tab>'.esc_mapl.'ns		 <C-C>:call C_ProtoShow()<CR>'

	exe ahead.'-SEP2-									     :'
	"
	" templates: edit and reload templates, styles
	call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'do_specials', 'specials_menu', 'Snippets' )
	"
	"===============================================================================================
	"----- Menu : Run ---------------------------------------------------------   {{{2
	"===============================================================================================
	"
	let	ahead	= 'anoremenu <silent> '.s:MenuRun.'.'
	let	vhead	= 'vnoremenu <silent> '.s:MenuRun.'.'
	let	ihead	= 'inoremenu <silent> '.s:MenuRun.'.'
	"
	exe ahead.'save\ and\ &compile<Tab>'.esc_mapl.'rc\ \ \<A-F9\>         :call C_Compile()<CR>:call C_HlMessage()<CR>'
	exe ihead.'save\ and\ &compile<Tab>'.esc_mapl.'rc\ \ \<A-F9\>    <C-C>:call C_Compile()<CR>:call C_HlMessage()<CR>'
	exe ahead.'&link<Tab>'.esc_mapl.'rl\ \ \ \ \<F9\>                     :call C_Link()<CR>:call C_HlMessage()<CR>'
	exe ihead.'&link<Tab>'.esc_mapl.'rl\ \ \ \ \<F9\>                <C-C>:call C_Link()<CR>:call C_HlMessage()<CR>'
	exe ahead.'&run<Tab>'.esc_mapl.'rr\ \ \<C-F9\>                        :call C_Run()<CR>'
	exe ihead.'&run<Tab>'.esc_mapl.'rr\ \ \<C-F9\>                   <C-C>:call C_Run()<CR>'
	exe ahead.'executable\ to\ run<Tab>'.esc_mapl.'re                     :call <SID>ExeToRun()<CR>'
	exe ihead.'executable\ to\ run<Tab>'.esc_mapl.'re                <C-C>:call <SID>ExeToRun()<CR>'
	exe 'anoremenu '.s:MenuRun.'.cmd\.\ line\ &arg\.<Tab>'.esc_mapl.'ra\ \ \<S-F9\>         :CCmdlineArgs<Space>'
	exe 'inoremenu '.s:MenuRun.'.cmd\.\ line\ &arg\.<Tab>'.esc_mapl.'ra\ \ \<S-F9\>    <C-C>:CCmdlineArgs<Space>'
	exe ahead.'run\ &debugger<Tab>'.esc_mapl.'rd                           :call <SID>Debugger()<CR>'
	exe ihead.'run\ &debugger<Tab>'.esc_mapl.'rd                      <C-C>:call <SID>Debugger()<CR>'
	"
	exe ahead.'-SEP1-                                                      :'
	"
	if s:C_SplintIsExecutable==1
		exe ahead.'s&plint<Tab>'.esc_mapl.'rp                                :call C_SplintCheck()<CR>:call C_HlMessage()<CR>'
		exe ihead.'s&plint<Tab>'.esc_mapl.'rp                           <C-C>:call C_SplintCheck()<CR>:call C_HlMessage()<CR>'
		exe ahead.'cmd\.\ line\ arg\.\ for\ spl&int<Tab>'.esc_mapl.'rpa      :call C_SplintArguments()<CR>'
		exe ihead.'cmd\.\ line\ arg\.\ for\ spl&int<Tab>'.esc_mapl.'rpa <C-C>:call C_SplintArguments()<CR>'
		exe ahead.'-SEP-SPLINT-                                              :'
	endif
	"
	if s:C_CppcheckIsExecutable==1
		exe ahead.'cppcheck<Tab>'.esc_mapl.'rcc                            :call C_CppcheckCheck()<CR>:call C_HlMessage()<CR>'
		exe ihead.'cppcheck<Tab>'.esc_mapl.'rcc                       <C-C>:call C_CppcheckCheck()<CR>:call C_HlMessage()<CR>'

		call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'sub_menu', 'Run'.'.cppcheck\ severity<TAB>'.esc_mapl.'rccs' )

		for level in s:CppcheckSeverity
			exe ahead.'cppcheck\ severity.&'.level.'   :call C_GetCppcheckSeverity("'.level.'")<CR>'
		endfor
		exe ahead.'-SEP-CPPCHECK-   :'
	endif
	"
	if s:C_CodeCheckIsExecutable==1
		exe ahead.'CodeChec&k<Tab>'.esc_mapl.'rk                                :call C_CodeCheck()<CR>:call C_HlMessage()<CR>'
		exe ihead.'CodeChec&k<Tab>'.esc_mapl.'rk                           <C-C>:call C_CodeCheck()<CR>:call C_HlMessage()<CR>'
		exe ahead.'cmd\.\ line\ arg\.\ for\ Cod&eCheck<Tab>'.esc_mapl.'rka      :call C_CodeCheckArguments()<CR>'
		exe ihead.'cmd\.\ line\ arg\.\ for\ Cod&eCheck<Tab>'.esc_mapl.'rka <C-C>:call C_CodeCheckArguments()<CR>'
		exe ahead.'-SEP-CODECHECK-                                              :'
	endif
	"
	exe ahead.'in&dent<Tab>'.esc_mapl.'ri                                  :call C_Indent()<CR>'
	exe ihead.'in&dent<Tab>'.esc_mapl.'ri                             <C-C>:call C_Indent()<CR>'
	if	s:MSWIN
		exe ahead.'&hardcopy\ to\ printer<Tab>'.esc_mapl.'rh                 :call C_Hardcopy()<CR>'
		exe ihead.'&hardcopy\ to\ printer<Tab>'.esc_mapl.'rh            <C-C>:call C_Hardcopy()<CR>'
		exe vhead.'&hardcopy\ to\ printer<Tab>'.esc_mapl.'rh                 :call C_Hardcopy()<CR>'
	else
		exe ahead.'&hardcopy\ to\ FILENAME\.ps<Tab>'.esc_mapl.'rh            :call C_Hardcopy()<CR>'
		exe ihead.'&hardcopy\ to\ FILENAME\.ps<Tab>'.esc_mapl.'rh       <C-C>:call C_Hardcopy()<CR>'
		exe vhead.'&hardcopy\ to\ FILENAME\.ps<Tab>'.esc_mapl.'rh            :call C_Hardcopy()<CR>'
	endif
	exe ihead.'-SEP4-                                            :'

	exe ahead.'&settings<Tab>'.esc_mapl.'rs                                :call C_Settings(0)<CR>'
	exe ihead.'&settings<Tab>'.esc_mapl.'rs                           <C-C>:call C_Settings(0)<CR>'
	exe ihead.'-SEP5-                                            :'

	if !s:MSWIN
		exe ahead.'&xterm\ size<Tab>'.esc_mapl.'rx                           :call C_XtermSize()<CR>'
		exe ihead.'&xterm\ size<Tab>'.esc_mapl.'rx                      <C-C>:call C_XtermSize()<CR>'
	endif
	if s:C_OutputGvim == "vim"
		exe ahead.'&output:\ '.s:Output[0].'<Tab>'.esc_mapl.'ro           :call C_Toggle_Gvim_Xterm()<CR>'
		exe ihead.'&output:\ '.s:Output[0].'<Tab>'.esc_mapl.'ro      <C-C>:call C_Toggle_Gvim_Xterm()<CR>'
	else
		if s:C_OutputGvim == "buffer"
			exe ahead.'&output:\ '.s:Output[1].'<Tab>'.esc_mapl.'ro         :call C_Toggle_Gvim_Xterm()<CR>'
			exe ihead.'&output:\ '.s:Output[1].'<Tab>'.esc_mapl.'ro    <C-C>:call C_Toggle_Gvim_Xterm()<CR>'
		else
			exe ahead.'&output:\ '.s:Output[2].'<Tab>'.esc_mapl.'ro         :call C_Toggle_Gvim_Xterm()<CR>'
			exe ihead.'&output:\ '.s:Output[2].'<Tab>'.esc_mapl.'ro    <C-C>:call C_Toggle_Gvim_Xterm()<CR>'
		endif
	endif
	"
	"===============================================================================================
	"----- Menu : Tools -----------------------------------------------------   {{{2
	"===============================================================================================
	"
	if s:C_UseToolbox == 'yes' && mmtoolbox#tools#Property ( s:C_Toolbox, 'empty-menu' ) == 0
		call mmtoolbox#tools#AddMenus ( s:C_Toolbox, s:C_RootMenu.'&Tool\ Box' )
	endif
	"
	"===============================================================================================
	"----- Menu : Help --------------------------------------------------------   {{{2
	"===============================================================================================
	"
	let	ahead	= 'anoremenu <silent> '.s:C_RootMenu.'Help.'
	let	vhead	= 'vnoremenu <silent> '.s:C_RootMenu.'Help.'
	let	ihead	= 'inoremenu <silent> '.s:C_RootMenu.'Help.'
	"
	exe ahead.'show\ &manual<Tab>'.esc_mapl.'hm   		       :call C_Help("m")<CR>'
	exe ihead.'show\ &manual<Tab>'.esc_mapl.'hm 		    <C-C>:call C_Help("m")<CR>'
	exe ahead.'-SEP1-                              :'
	exe ahead.'&help\ (C-Support)<Tab>'.esc_mapl.'hp         :call C_HelpCsupport()<CR>'
	exe ihead.'&help\ (C-Support)<Tab>'.esc_mapl.'hp    <C-C>:call C_HelpCsupport()<CR>'
	"
	"===============================================================================================
	"----- Menu : C-Comments --------------------------------------------------   {{{2
	"===============================================================================================
	"
	exe "amenu          ".MenuComments.'.-SEP12-                                       :'
	exe "amenu <silent> ".MenuComments.'.\/*\ &xxx\ *\/\ \ <->\ \ \/\/\ xxx<Tab>'.esc_mapl.'cx   :call C_CommentToggle()<CR>'
	exe "vmenu <silent> ".MenuComments.'.\/*\ &xxx\ *\/\ \ <->\ \ \/\/\ xxx<Tab>'.esc_mapl.'cx   :call C_CommentToggle()<CR>'
	"
	"===============================================================================================
	"----- Menu : C-Doxygen ---------------------------------------------------   {{{2
	"===============================================================================================
	"
	if err_dox == '' && MenuDoxygen != ''
		let	MenuDoxygen	= s:C_RootMenu.MenuDoxygen
		"
		let [ bam_map, err_dox ] = mmtemplates#core#Resource ( g:C_Templates, 'get', 'property', 'Doxygen::BriefAM::Map' )
		"
		if err_dox == '' && bam_map != ''
			let bam_map = esc_mapl.mmtemplates#core#EscapeMenu( bam_map, 'right' )
		else
			let bam_map = esc_mapl.'dba'
		endif
		"
		exe "amenu          ".MenuDoxygen.'.-SEP-brief-                              :'
		exe "amenu <silent> ".MenuDoxygen.'.brief,\ &after\ member<Tab>'.bam_map.'   :call C_EndOfLineComment("doxygen")<CR>'
		exe "vmenu <silent> ".MenuDoxygen.'.brief,\ &after\ member<Tab>'.bam_map.'   :call C_EndOfLineComment("doxygen")<CR>'
	endif
	"
	"===============================================================================================
	"----- Menu : C-Idioms ----------------------------------------------------   {{{2
	"===============================================================================================
	"
	call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'sub_menu', '&Idioms' )
	let	MenuIdioms	= s:C_RootMenu.'&Idioms.'
	"
	exe "amenu ".MenuIdioms.'-SEP1-                                    :'
	exe "amenu ".MenuIdioms.'for(x=&0;\ x<n;\ x\+=1)<Tab>'.esc_mapl.'i0          :call C_CodeFor("up"    )<CR>'
	exe "vmenu ".MenuIdioms.'for(x=&0;\ x<n;\ x\+=1)<Tab>'.esc_mapl.'i0          :call C_CodeFor("up","v")<CR>'
	exe "imenu ".MenuIdioms.'for(x=&0;\ x<n;\ x\+=1)<Tab>'.esc_mapl.'i0     <Esc>:call C_CodeFor("up"    )<CR>'
	exe "amenu ".MenuIdioms.'for(x=&n-1;\ x>=0;\ x\-=1)<Tab>'.esc_mapl.'in       :call C_CodeFor("down"    )<CR>'
	exe "vmenu ".MenuIdioms.'for(x=&n-1;\ x>=0;\ x\-=1)<Tab>'.esc_mapl.'in       :call C_CodeFor("down","v")<CR>'
	exe "imenu ".MenuIdioms.'for(x=&n-1;\ x>=0;\ x\-=1)<Tab>'.esc_mapl.'in  <Esc>:call C_CodeFor("down"    )<CR>'
	"
	"===============================================================================================
	"----- Menu : C-Preprocessor ----------------------------------------------   {{{2
	"===============================================================================================
	"
	call mmtemplates#core#CreateMenus ( 'g:C_Templates', s:C_RootMenu, 'sub_menu', '&Preprocessor' )
	let	MenuPreprocessor	= s:C_RootMenu.'&Preprocessor.'
	"
	exe "amenu          ".MenuPreprocessor.'-SEP2-                                  :'
	exe "amenu          ".MenuPreprocessor.'#if\ &0\ #endif<Tab>'.esc_mapl.'pi0               :call C_PPIf0("a")<CR>2ji'
	exe "imenu          ".MenuPreprocessor.'#if\ &0\ #endif<Tab>'.esc_mapl.'pi0          <Esc>:call C_PPIf0("a")<CR>2ji'
	exe "vmenu          ".MenuPreprocessor.'#if\ &0\ #endif<Tab>'.esc_mapl.'pi0          <Esc>:call C_PPIf0("v")<CR>'
	exe "amenu <silent> ".MenuPreprocessor.'&remove\ #if\ 0\ #endif<Tab>'.esc_mapl.'pr0       :call C_PPIf0Remove()<CR>'
	exe "imenu <silent> ".MenuPreprocessor.'&remove\ #if\ 0\ #endif<Tab>'.esc_mapl.'pr0  <Esc>:call C_PPIf0Remove()<CR>'

	" }}}2
	"===============================================================================================

endfunction    " ----------  end of function  s:InitMenus  ----------

"------------------------------------------------------------------------------
"  C_SaveGlobalOption    {{{1
"  param 1 : option name
"  param 2 : characters to be escaped (optional)
"------------------------------------------------------------------------------
function! s:C_SaveGlobalOption ( option, ... )
	exe 'let escaped =&'.a:option
	if a:0 == 0
		let escaped	= escape( escaped, ' |"\' )
	else
		let escaped	= escape( escaped, ' |"\'.a:1 )
	endif
	let s:C_saved_global_option[a:option]	= escaped
endfunction    " ----------  end of function C_SaveGlobalOption  ----------
"
"------------------------------------------------------------------------------
"  C_RestoreGlobalOption    {{{1
"------------------------------------------------------------------------------
function! s:C_RestoreGlobalOption ( option )
	exe ':set '.a:option.'='.s:C_saved_global_option[a:option]
endfunction    " ----------  end of function C_RestoreGlobalOption  ----------
"
"------------------------------------------------------------------------------
"  C_Input: Input after a highlighted prompt     {{{1
"           3. argument : optional completion
"------------------------------------------------------------------------------
function! C_Input ( promp, text, ... )
	echohl Search																					" highlight prompt
	call inputsave()																			" preserve typeahead
	if a:0 == 0 || empty(a:1)
		let retval	=input( a:promp, a:text )
	else
		let retval	=input( a:promp, a:text, a:1 )
	endif
	call inputrestore()																		" restore typeahead
	echohl None																						" reset highlighting
	let retval  = substitute( retval, '^\s\+', "", "" )		" remove leading whitespaces
	let retval  = substitute( retval, '\s\+$', "", "" )		" remove trailing whitespaces
	return retval
endfunction    " ----------  end of function C_Input ----------
"
"------------------------------------------------------------------------------
"  C_AdjustLineEndComm: adjust line-end comments     {{{1
"------------------------------------------------------------------------------
function! C_AdjustLineEndComm ( ) range
	"
	" comment character (for use in regular expression)
	let cc = '\%(/\*\|//\)'                       " start of C or C++ comment
	"
	" patterns to ignore when adjusting line-end comments (maybe incomplete):
	" - double-quoted strings, includes \n \" \\ ...
	let align_regex = '"\%(\\.\|[^"]\)*"'
	"
	" local position
	if !exists( 'b:C_LineEndCommentColumn' )
		let b:C_LineEndCommentColumn = s:C_LineEndCommColDefault
	endif
	let correct_idx = b:C_LineEndCommentColumn
	"
	" === plug-in specific code ends here                 ===
	" === the behavior is governed by the variables above ===
	"
	" save the cursor position
	let save_cursor = getpos('.')
	"
	for line in range( a:firstline, a:lastline )
		silent exe ':'.line
		"
		let linetxt = getline('.')
		"
		" "pure" comment line left unchanged
		if match ( linetxt, '^\s*'.cc ) == 0
			"echo 'line '.line.': "pure" comment'
			continue
		endif
		"
		let b_idx1 = 1 + match ( linetxt, '\s*'.cc.'.*$', 0 )
		let b_idx2 = 1 + match ( linetxt,       cc.'.*$', 0 )
		"
		" not found?
		if b_idx1 == 0
			"echo 'line '.line.': no end-of-line comment'
			continue
		endif
		"
		" walk through ignored patterns
		let idx_start = 0
		"
		while 1
			let this_start = match ( linetxt, align_regex, idx_start )
			"
			if this_start == -1
				break
			else
				let idx_start = matchend ( linetxt, align_regex, idx_start )
				"echo 'line '.line.': ignoring >>>'.strpart(linetxt,this_start,idx_start-this_start).'<<<'
			endif
		endwhile
		"
		let b_idx1 = 1 + match ( linetxt, '\s*'.cc.'.*$', idx_start )
		let b_idx2 = 1 + match ( linetxt,       cc.'.*$', idx_start )
		"
		" not found?
		if b_idx1 == 0
			"echo 'line '.line.': no end-of-line comment'
			continue
		endif
		"
		call cursor ( line, b_idx2 )
		let v_idx2 = virtcol('.')
		"
		" do b_idx1 last, so the cursor is in the right position for substitute below
		call cursor ( line, b_idx1 )
		let v_idx1 = virtcol('.')
		"
		" already at right position?
		if ( v_idx2 == correct_idx )
			"echo 'line '.line.': already at right position'
			continue
		endif
		" ... or line too long?
		if ( v_idx1 >  correct_idx )
			"echo 'line '.line.': line too long'
			continue
		endif
		"
		" substitute all whitespaces behind the cursor (regex '\%#') and the next character,
		" to ensure the match is at least one character long
		silent exe 'substitute/\%#\s*\(\S\)/'.repeat( ' ', correct_idx - v_idx1 ).'\1/'
		"echo 'line '.line.': adjusted'
		"
	endfor
	"
	" restore the cursor position
	call setpos ( '.', save_cursor )
	"
endfunction		" ---------- end of function  C_AdjustLineEndComm  ----------
"
"------------------------------------------------------------------------------
"  C_GetLineEndCommCol: get line-end comment position    {{{1
"------------------------------------------------------------------------------
function! C_GetLineEndCommCol ()
	let actcol	= virtcol(".")
	if actcol+1 == virtcol("$")
		let	b:C_LineEndCommentColumn	= ''
		while match( b:C_LineEndCommentColumn, '^\s*\d\+\s*$' ) < 0
			let b:C_LineEndCommentColumn = C_Input( 'start line-end comment at virtual column : ', actcol, '' )
		endwhile
	else
		let	b:C_LineEndCommentColumn	= virtcol(".")
	endif
  echomsg "line end comments will start at column  ".b:C_LineEndCommentColumn
endfunction		" ---------- end of function  C_GetLineEndCommCol  ----------
"
"------------------------------------------------------------------------------
"  C_EndOfLineComment: single line-end comment    {{{1
"------------------------------------------------------------------------------
function! C_EndOfLineComment ( ... ) range
	"
	if !exists("b:C_LineEndCommentColumn")
		let	b:C_LineEndCommentColumn	= s:C_LineEndCommColDefault
	endif
	"
	" which template?
	let template = 'Comments.end-of-line-comment'
	"
	if a:0 > 0 && a:1 == 'doxygen'
		let template = 'Doxygen.brief, after member'
	endif
	"
	" trim whitespaces
	exe a:firstline.','.a:lastline.'s/\s*$//'
	"
	" do lines
	for line in range( a:lastline, a:firstline, -1 )
		silent exe ":".line
		if getline(line) !~ '^\s*$'
			let linelength	= virtcol( [line, "$"] ) - 1
			let	diff				= 1
			if linelength < b:C_LineEndCommentColumn
				let diff	= b:C_LineEndCommentColumn -1 -linelength
			endif
			exe "normal!	".diff."A "
			call mmtemplates#core#InsertTemplate(g:C_Templates, template)
		endif
	endfor
endfunction		" ---------- end of function  C_EndOfLineComment  ----------
"
"----------------------------------------------------------------------
"  C_CodeToCommentC : Code -> Comment   {{{1
"----------------------------------------------------------------------
function! C_CodeToCommentC ( ) range
	silent exe ':'.a:firstline.','.a:lastline."s/^/ \* /"
	silent exe ":".a:firstline."s'^ '\/'"
	silent exe ":".a:lastline
	silent put = ' */'
endfunction    " ----------  end of function  C_CodeToCommentC  ----------
"
"----------------------------------------------------------------------
"  C_CodeToCommentCpp : Code -> Comment   {{{1
"----------------------------------------------------------------------
function! C_CodeToCommentCpp ( ) range
	silent exe a:firstline.','.a:lastline.":s#^#//#"
endfunction    " ----------  end of function  C_CodeToCommentCpp  ----------
"
"----------------------------------------------------------------------
"  C_StartMultilineComment : Comment -> Code   {{{1
"----------------------------------------------------------------------
let s:C_StartMultilineComment	= '^\s*\/\*[\*! ]\='

function! C_RemoveCComment( start, end )

	if a:end-a:start<1
		return 0										" lines removed
	endif
	"
	" Is the C-comment complete ? Get length.
	"
	let check				= getline(	a:start ) =~ s:C_StartMultilineComment
	let	linenumber	= a:start+1
	while linenumber < a:end && getline(	linenumber ) !~ '^\s*\*\/'
		let check				= check && getline(	linenumber ) =~ '^\s*\*[ ]\='
		let linenumber	= linenumber+1
	endwhile
	let check = check && getline(	linenumber ) =~ '^\s*\*\/'
	"
	" remove a complete comment
	"
	if check
		exe "silent :".a:start.'   s/'.s:C_StartMultilineComment.'//'
		let	linenumber1	= a:start+1
		while linenumber1 < linenumber
			exe "silent :".linenumber1.' s/^\s*\*[ ]\=//'
			let linenumber1	= linenumber1+1
		endwhile
		exe "silent :".linenumber1.'   s/^\s*\*\///'
	endif

	return linenumber-a:start+1			" lines removed
endfunction    " ----------  end of function  C_RemoveCComment  ----------
"
"----------------------------------------------------------------------
"  C_CommentToCode : Comment -> Code       {{{1
"----------------------------------------------------------------------
function! C_CommentToCode( ) range

	let	removed	= 0
	"
	let	linenumber	= a:firstline
	while linenumber <= a:lastline
		" Do we have a C++ comment ?
		if getline(	linenumber ) =~ '^\s*//'
			exe "silent :".linenumber.' s#^\s*//##'
			let	removed    = 1
		endif
		" Do we have a C   comment ?
		if removed == 0 && getline(	linenumber ) =~ s:C_StartMultilineComment
			let removed = C_RemoveCComment( linenumber, a:lastline )
		endif

		if removed!=0
			let linenumber = linenumber+removed
			let	removed    = 0
		else
			let linenumber = linenumber+1
		endif
	endwhile
endfunction    " ----------  end of function  C_CommentToCode  ----------
"
"----------------------------------------------------------------------
"  C_CommentCToCpp : C Comment -> C++ Comment       {{{1
"  Changes the first comment in case of multiple C comments:
"    xxxx;               /* 1 */ /* 2 */
"    xxxx;               // 1 // 2
"----------------------------------------------------------------------
function! C_CommentToggle () range
	let	LineEndCommentC		= '\/\*\(.*\)\*\/'
	let	LineEndCommentCpp	= '\/\/\(.*\)$'
	"
	for linenumber in range( a:firstline, a:lastline )
		let line			= getline(linenumber)
		" ----------  C => C++  ----------
		if match( line, LineEndCommentC ) >= 0
			let line = substitute( line, '\/\*\s*\(.\{-}\)\s*\*\/', '\/\/ \1', '' )
			call setline( linenumber, line )
			continue
		endif
		" ----------  C++ => C  ----------
		if match( line, LineEndCommentCpp ) >= 0
			let	line	= substitute( line, '\/\/\s*\(.*\)\s*$', '/* \1 */', '' )
			call setline( linenumber, line )
		endif
	endfor
endfunction    " ----------  end of function C_CommentToggle  ----------
"
"===  FUNCTION  ================================================================
"          NAME:  C_NonCCommentToggle     {{{1
"   DESCRIPTION:  toggle comment
"===============================================================================
function! C_NonCCommentToggle ( ) range
	let	comment=1									" 
	for line in range( a:firstline, a:lastline )
		if match( getline(line), '^\V'.s:C_NonCComment ) == -1					" no comment 
			let comment = 0
			break
		endif
	endfor

	if comment == 0
			exe a:firstline.','.a:lastline."s/^/".s:C_NonCComment."/"
	else
			exe a:firstline.','.a:lastline."s/^".s:C_NonCComment."//"
	endif

endfunction    " ----------  end of function C_NonCCommentToggle ----------
"
"=====================================================================================
"----- Menu : Statements -----------------------------------------------------------
"=====================================================================================
"
"------------------------------------------------------------------------------
"  C_PPIf0 : #if 0 .. #endif        {{{1
"------------------------------------------------------------------------------
function! C_PPIf0 (mode)
	"
	let	s:C_If0_Counter	= 0
	let	save_line					= line(".")
	let	actual_line				= 0
	"
	" search for the maximum option number (if any)
	"
	normal! gg
	while actual_line < search( s:C_If0_Txt."\\d\\+" )
		let actual_line	= line(".")
	 	let actual_opt  = matchstr( getline(actual_line), s:C_If0_Txt."\\d\\+" )
		let actual_opt  = strpart( actual_opt, strlen(s:C_If0_Txt),strlen(actual_opt)-strlen(s:C_If0_Txt))
		if s:C_If0_Counter < actual_opt
			let	s:C_If0_Counter = actual_opt
		endif
	endwhile
	let	s:C_If0_Counter = s:C_If0_Counter+1
	silent exe ":".save_line
	"
	if a:mode=='a'
		let zz=    "\n#if  0     ".s:C_Com1." ----- #if 0 : ".s:C_If0_Txt.s:C_If0_Counter." ----- ".s:C_Com2."\n"
		let zz= zz."\n#endif     ".s:C_Com1." ----- #if 0 : ".s:C_If0_Txt.s:C_If0_Counter." ----- ".s:C_Com2."\n\n"
		put =zz
		normal! 4k
	endif

	if a:mode=='v'
		let	pos1	= line("'<")
		let	pos2	= line("'>")
		let zz=      "#endif     ".s:C_Com1." ----- #if 0 : ".s:C_If0_Txt.s:C_If0_Counter." ----- ".s:C_Com2."\n\n"
		exe ":".pos2."put =zz"
		let zz=    "\n#if  0     ".s:C_Com1." ----- #if 0 : ".s:C_If0_Txt.s:C_If0_Counter." ----- ".s:C_Com2."\n"
		exe ":".pos1."put! =zz"
		"
		if  &foldenable && foldclosed(".")
			normal! zv
		endif
	endif

endfunction    " ----------  end of function C_PPIf0 ----------
"
"------------------------------------------------------------------------------
"  C_PPIf0Remove : remove  #if 0 .. #endif        {{{1
"------------------------------------------------------------------------------
function! C_PPIf0Remove ()
	"
	" cursor on fold: open fold first
	if  &foldenable && foldclosed(".")
		normal! zv
	endif
	"
	let frstline	= searchpair( '^\s*#if\s\+0', '', '^\s*#endif\>.\+\<If0Label_', 'bn' )
  if frstline<=0
		echohl WarningMsg | echo 'no  #if 0 ... #endif  found or cursor not inside such a directive'| echohl None
    return
  endif
	let lastline	= searchpair( '^\s*#if\s\+0', '', '^\s*#endif\>.\+\<If0Label_', 'n' )
	if lastline<=0
		echohl WarningMsg | echo 'no  #if 0 ... #endif  found or cursor not inside such a directive'| echohl None
		return
	endif
  let actualnumber1  = matchstr( getline(frstline), s:C_If0_Txt."\\d\\+" )
  let actualnumber2  = matchstr( getline(lastline), s:C_If0_Txt."\\d\\+" )
	if actualnumber1 != actualnumber2
    echohl WarningMsg | echo 'lines '.frstline.', '.lastline.': comment tags do not match'| echohl None
		return
	endif

  silent exe ':'.lastline.','.lastline.'d'
	silent exe ':'.frstline.','.frstline.'d'

endfunction    " ----------  end of function C_PPIf0Remove ----------

"------------------------------------------------------------------------------
"  C_CodeSnippet : read / edit code snippet       {{{1
"------------------------------------------------------------------------------
function! C_CodeSnippet(mode)

	if isdirectory(s:C_CodeSnippets)
		if has("browsefilter") && exists( "b:browsefilter" )
 			let browsefilter_save	= b:browsefilter
			let b:browsefilter 		= "*"
		endif
		"
		" read snippet file, put content below current line and indent
		"
		if a:mode == "r"
			if has("browse") && s:C_GuiSnippetBrowser == 'gui'
				let	l:snippetfile=browse(0,"read a code snippet",s:C_CodeSnippets,"*.*")
			else
				let	l:snippetfile=input("read snippet ", s:C_CodeSnippets, "file" )
			endif
			if filereadable(l:snippetfile)
				let	linesread= line("$")
				let l:old_cpoptions	= &cpoptions " Prevent the alternate buffer from being set to this files
				setlocal cpoptions-=a
				:execute "read ".l:snippetfile
				let &cpoptions	= l:old_cpoptions		" restore previous options
				let	linesread= line("$")-linesread-1
				if linesread>=0 && match( l:snippetfile, '\.\(ni\|noindent\)$' ) < 0
				endif
			endif
			if line(".")==2 && getline(1)=~"^$"
				silent exe ":1,1d"
			endif
		endif
		"
		" update current buffer / split window / edit snippet file
		"
		if a:mode == "e"
			if has("browse") && s:C_GuiSnippetBrowser == 'gui'
				let	l:snippetfile	= browse(1,"edit a code snippet",s:C_CodeSnippets,"")
			else
				let	l:snippetfile=input("edit snippet ", s:C_CodeSnippets, "file" )
			endif
			if !empty(l:snippetfile)
				:execute "update! | split | edit ".l:snippetfile
			endif
		endif
    "
    " update current buffer / split window / view snippet file
    "
    if a:mode == "view"
			if has("gui_running") && s:C_GuiSnippetBrowser == 'gui'
				let l:snippetfile=browse(0,"view a code snippet",s:C_CodeSnippets,"")
			else
				let	l:snippetfile=input("view snippet ", s:C_CodeSnippets, "file" )
			endif
      if !empty(l:snippetfile)
        :execute "update! | split | view ".l:snippetfile
      endif
    endif
		"
		" write whole buffer into snippet file
		"
		if a:mode == "w" || a:mode == "wv"
			if has("browse") && s:C_GuiSnippetBrowser == 'gui'
				let	l:snippetfile	= browse(1,"write a code snippet",s:C_CodeSnippets,"")
			else
				let	l:snippetfile=input("write snippet ", s:C_CodeSnippets, "file" )
			endif
			if !empty(l:snippetfile)
				if filereadable(l:snippetfile)
					if confirm("File ".l:snippetfile." exists ! Overwrite ? ", "&Cancel\n&No\n&Yes") != 3
						return
					endif
				endif
				if a:mode == "w"
					:execute ":write! ".l:snippetfile
				else
					:execute ":*write! ".l:snippetfile
				endif
			endif
		endif

		if has("browsefilter") && exists( "b:browsefilter" )
			let b:browsefilter	= browsefilter_save
		endif
		"
	else
		echo "code snippet directory ".s:C_CodeSnippets." does not exist (please create it)"
	endif
endfunction    " ----------  end of function C_CodeSnippets  ----------
"
"------------------------------------------------------------------------------
"  C_help : builtin completion    {{{1
"------------------------------------------------------------------------------
function!	C_ForTypeComplete ( ArgLead, CmdLine, CursorPos )
	"
	" show all types
	if empty(a:ArgLead)
		return s:C_ForTypes
	endif
	"
	" show types beginning with a:ArgLead
	let	expansions	= []
	for item in s:C_ForTypes
		if match( item, '\<'.a:ArgLead.'\s*\w*' ) == 0
			call add( expansions, item )
		endif
	endfor
	return	expansions
endfunction    " ----------  end of function C_ForTypeComplete  ----------
"
"------------------------------------------------------------------------------
"  C_CodeFor : for (idiom)       {{{1
"------------------------------------------------------------------------------
function! C_CodeFor( direction, ... ) range
	"
	let updown	= ( a:direction == 'up' ? 'INCR.' : 'DECR.' )
	let	string	= C_Input( '[TYPE (expand)] VARIABLE [START [END ['.updown.']]] : ', '',
									\				'customlist,C_ForTypeComplete' )
	if empty(string)
		return
	endif
	"
	let string	= substitute( string, '\s\+', ' ', 'g' )
	let nextindex			= -1
	let loopvar_type	= ''
	for item in sort( copy( s:C_ForTypes ) )
		let nextindex	= matchend( string, '^'.item )
		if nextindex > 0
			let loopvar_type	= item
			let	string				= strpart( string, nextindex )
		endif
	endfor
	if !empty(loopvar_type)
		let loopvar_type	.= ' '
		if empty(string)
			let	string	= C_Input( 'VARIABLE [START [END ['.updown.']]] : ', '' )
			if empty(string)
				return
			endif
		endif
	endif
	let part	= split( string )

	if len( part ) 	> 4
    echohl WarningMsg | echomsg "for loop construction : to many arguments " | echohl None
		return
	endif

	let missing	= 0
	while len(part) < 4
		let part	= part + ['']
		let missing	= missing+1
	endwhile

	let [ loopvar, startval, endval, incval ]	= part

	if empty(incval)
		let incval	= '1'
	endif

	if a:direction == 'up'
		if empty(endval)
			let endval	= 'n'
		endif
		if empty(startval)
			let startval	= '0'
		endif
		let txt_init = loopvar_type.loopvar.' = '.startval
		let txt_cond = loopvar.' < '.endval
		let txt_incr = loopvar.' += '.incval
	else
		if empty(endval)
			let endval	= '0'
		endif
		if empty(startval)
			let startval	= 'n-1'
		endif
		let txt_init = loopvar_type.loopvar.' = '.startval
		let txt_cond = loopvar.' >= '.endval
		let txt_incr = loopvar.' -= '.incval
	endif
	"
	if a:0 == 0
		call mmtemplates#core#InsertTemplate ( g:C_Templates, 'Statements.for block',
					\ '|INIT|', txt_init, '|CONDITION|', txt_cond, '|INCREMENT|', txt_incr,
					\ 'range', a:firstline, a:lastline )
	elseif a:0 == 1 && a:1 == 'v'
		call mmtemplates#core#InsertTemplate ( g:C_Templates, 'Statements.for block',
					\ '|INIT|', txt_init, '|CONDITION|', txt_cond, '|INCREMENT|', txt_incr,
					\ 'range', a:firstline, a:lastline, 'v' )
	else
    echohl WarningMsg | echomsg "for loop construction : unknown argument ".a:1 | echohl None
	endif
	"
endfunction    " ----------  end of function C_CodeFor ----------
"
"------------------------------------------------------------------------------
"  Handle prototypes       {{{1
"------------------------------------------------------------------------------
"
let s:C_Prototype        = []
let s:C_PrototypeShow    = []
let s:C_PrototypeCounter = 0
let s:C_CComment         = '\/\*.\{-}\*\/\s*'		" C comment with trailing whitespaces
																								"  '.\{-}'  any character, non-greedy
let s:C_CppComment       = '\/\/.*$'						" C++ comment
"
"------------------------------------------------------------------------------
"  C_ProtoPick: pick up a method prototype (normal/visual)       {{{1
"  type : 'function', 'method'
"------------------------------------------------------------------------------
function! C_ProtoPick( type ) range
	"
	" remove C/C++-comments, leading and trailing whitespaces, squeeze whitespaces
	"
	let prototyp   = ''
	for linenumber in range( a:firstline, a:lastline )
		let newline			= getline(linenumber)
		let newline 	  = substitute( newline, s:C_CppComment, "", "" ) " remove C++ comment
		let prototyp		= prototyp." ".newline
	endfor
	"
	let prototyp  = substitute( prototyp, '^\s\+', "", "" )					" remove leading whitespaces
	let prototyp  = substitute( prototyp, s:C_CComment, "", "g" )		" remove (multiline) C comments
	let prototyp  = substitute( prototyp, '\s\+', " ", "g" )				" squeeze whitespaces
	let prototyp  = substitute( prototyp, '\s\+$', "", "" )					" remove trailing whitespaces
	"
	"-------------------------------------------------------------------------------
	" prototype for  methods
	"-------------------------------------------------------------------------------
	if a:type == 'method'
		"
		" remove template keyword
		"
		let	template_param	= '\s*\w\+\s\+\w\+\s*'
		let	template_params	= template_param.'\(,'.template_param.'\)*'
		let prototyp  = substitute( prototyp, '^template\s*<'.template_params.'>\s*', "", "" )
		"
		let idx     = stridx( prototyp, '(' )								    		" start of the parameter list
		let head    = strpart( prototyp, 0, idx )
		let parlist = strpart( prototyp, idx )
		"
		" remove the scope resolution operator
		"
		let	template_id	= '\h\w*\s*\(<[^>]\+>\)\?\s*::\s*'
		let	rgx2				= '\('.template_id.'\)*\([~]\?\h\w*\|operator.\+\)\s*$'
		let idx 				= match( head, rgx2 )								    		" start of the function name
		let returntype	= strpart( head, 0, idx )
		let fctname	  	= strpart( head, idx )

		let resret	= matchstr( returntype, '\('.template_id.'\)*'.template_id )
		let resret	= substitute( resret, '\s\+', '', 'g' )

		let resfct	= matchstr( fctname   , '\('.template_id.'\)*'.template_id )
		let resfct	= substitute( resfct, '\s\+', '', 'g' )

		if  !empty(resret) && match( resfct, resret.'$' ) >= 0
			"-------------------------------------------------------------------------------
			" remove scope resolution from the return type (keep 'std::')
			"-------------------------------------------------------------------------------
			let returntype	= substitute( returntype, '<\s*\w\+\s*>', '', 'g' )
			let returntype 	= substitute( returntype, '\<std\s*::', 'std##', 'g' )	" remove the scope res. operator
			let returntype 	= substitute( returntype, '\<\h\w*\s*::', '', 'g' )			" remove the scope res. operator
			let returntype 	= substitute( returntype, '\<std##', 'std::', 'g' )			" remove the scope res. operator
		endif

		let fctname		  = substitute( fctname, '<[^>]\+>', '', 'g' )
		let fctname   	= substitute( fctname, '\<std\s*::', 'std##', 'g' )	" remove the scope res. operator
		let fctname   	= substitute( fctname, '\<\h\w*\s*::', '', 'g' )		" remove the scope res. operator
		let fctname   	= substitute( fctname, '\<std##', 'std::', 'g' )		" remove the scope res. operator

		let	prototyp	= returntype.fctname.parlist
		"
		if empty(fctname) || empty(parlist)
			echon 'No prototype saved. Wrong selection ?'
			return
		endif
	endif
	"
	" remove trailing parts of the function body; add semicolon
	"
	let prototyp	= substitute( prototyp, '\s*{.*$', "", "" )
	let prototyp	= prototyp.";\n"

	"
	" bookkeeping
	"
	let s:C_PrototypeCounter += 1
	let s:C_Prototype        += [prototyp]
	let s:C_PrototypeShow    += ["(".s:C_PrototypeCounter.") ".bufname("%")." #  ".prototyp]
	"
	echon	s:C_PrototypeCounter.' prototype'
	if s:C_PrototypeCounter > 1
		echon	's'
	endif
	"
endfunction    " ---------  end of function C_ProtoPick ----------
"
"------------------------------------------------------------------------------
"  C_ProtoInsert : insert       {{{1
"------------------------------------------------------------------------------
function! C_ProtoInsert ()
	"
	" use internal formatting to avoid conficts when using == below
	let	equalprg_save	= &equalprg
	set equalprg=
	"
	if s:C_PrototypeCounter > 0
		for protytype in s:C_Prototype
			put =protytype
		endfor
		let	lines	= s:C_PrototypeCounter	- 1
		silent exe "normal! =".lines."-"
		call C_ProtoClear()
	else
		echo "currently no prototypes available"
	endif
	"
	" restore formatter programm
	let &equalprg	= equalprg_save
	"
endfunction    " ---------  end of function C_ProtoInsert  ----------
"
"------------------------------------------------------------------------------
"  C_ProtoClear : clear       {{{1
"------------------------------------------------------------------------------
function! C_ProtoClear ()
	if s:C_PrototypeCounter > 0
		let s:C_Prototype        = []
		let s:C_PrototypeShow    = []
		if s:C_PrototypeCounter == 1
			echo	s:C_PrototypeCounter.' prototype deleted'
		else
			echo	s:C_PrototypeCounter.' prototypes deleted'
		endif
		let s:C_PrototypeCounter = 0
	else
		echo "currently no prototypes available"
	endif
endfunction    " ---------  end of function C_ProtoClear  ----------
"
"------------------------------------------------------------------------------
"  C_ProtoShow : show       {{{1
"------------------------------------------------------------------------------
function! C_ProtoShow ()
	if s:C_PrototypeCounter > 0
		for protytype in s:C_PrototypeShow
			echo protytype
		endfor
	else
		echo "currently no prototypes available"
	endif
endfunction    " ---------  end of function C_ProtoShow  ----------

"------------------------------------------------------------------------------
"  C_Compile : C_Compile       {{{1
"------------------------------------------------------------------------------
"  The standard make program 'make' called by vim is set to the C or C++ compiler
"  and reset after the compilation  (setlocal makeprg=... ).
"  The errorfile created by the compiler will now be read by gvim and
"  the commands cl, cp, cn, ... can be used.
"------------------------------------------------------------------------------
let s:LastShellReturnCode	= 0			" for compile / link / run only

function! C_Compile ()

	let s:C_HlMessage = ""
	exe	":cclose"
	let	Sou		= expand("%:p")											" name of the file in the current buffer
	let	Obj		= expand("%:p:r").s:C_ObjExtension	" name of the object
	let SouEsc= escape( Sou, s:C_FilenameEscChar )
	let ObjEsc= escape( Obj, s:C_FilenameEscChar )
	if s:MSWIN
		let	SouEsc	= '"'.SouEsc.'"'
		let	ObjEsc	= '"'.ObjEsc.'"'
	endif
	let	compilerflags	= ''

	" update : write source file if necessary
	exe	":update"

	" compilation if object does not exist or object exists and is older then the source
	if !filereadable(Obj) || (filereadable(Obj) && (getftime(Obj) < getftime(Sou)))
		" &makeprg can be a string containing blanks
		call s:C_SaveGlobalOption('makeprg')
		if expand("%:e") == s:C_CExtension
			exe		"setlocal makeprg=".g:C_CCompiler
			let	compilerflags	= g:C_CFlags
		else
			exe		"setlocal makeprg=".g:C_CplusCompiler
			let	compilerflags	= g:C_CplusCFlags 
		endif
		"
		" COMPILATION
		"
		let v:statusmsg = ''
		let	s:LastShellReturnCode	= 0
		exe		"make ".compilerflags." ".SouEsc." -o ".ObjEsc
		if empty(v:statusmsg)
			let s:C_HlMessage = "'".Obj."' : compilation successful"
		endif
		if v:shell_error != 0
			let	s:LastShellReturnCode	= v:statusmsg
		endif
		call s:C_RestoreGlobalOption('makeprg')
		"
		" open error window if necessary
		:redraw!
		exe	":botright cwindow"
	else
		let s:C_HlMessage = " '".Obj."' is up to date "
	endif

endfunction    " ----------  end of function C_Compile ----------

"===  FUNCTION  ================================================================
"          NAME:  C_CheckForMain
"   DESCRIPTION:  check if current buffer contains a main function
"    PARAMETERS:  
"       RETURNS:  0 : no main function
"===============================================================================
function! C_CheckForMain ()
	return  search( '^\(\s*int\s\+\)\=\s*main', "cnw" )
endfunction    " ----------  end of function C_CheckForMain  ----------
"
"------------------------------------------------------------------------------
"  C_Link : C_Link       {{{1
"------------------------------------------------------------------------------
"  The standard make program which is used by gvim is set to the compiler
"  (for linking) and reset after linking.
"
"  calls: C_Compile
"------------------------------------------------------------------------------
function! C_Link ()

	let s:C_HlMessage = ""
	let	Sou		= expand("%:p")						       		" name of the file (full path)
	let	Exe		= expand("%:p:r").s:C_ExeExtension	" name of the executable
	let SouEsc= escape( Sou, s:C_FilenameEscChar )
	let ExeEsc= escape( Exe, s:C_FilenameEscChar )
	if s:MSWIN
		let	ExeEsc	= '"'.ExeEsc.'"'
	endif

	if C_CheckForMain() == 0
		let s:C_HlMessage = "no main function in '".Sou."'"
		return
	endif

	" no linkage if: executable exists and source exists and executable newer then source
	if    filereadable(Exe)      &&
				\ filereadable(Sou)    &&
				\ (getftime(Exe)  >= getftime(Sou))
		let s:C_HlMessage = " '".Exe."' is up to date "
		return
	endif

	let	linkerflags	= g:C_LFlags 

	call s:C_SaveGlobalOption('makeprg')
	if expand("%:e") == s:C_CExtension
		exe		"setlocal makeprg=".g:C_CCompiler
		let	linkerflags	= g:C_LFlags
	else
		exe		"setlocal makeprg=".g:C_CplusCompiler
		let	linkerflags	= g:C_CplusLFlags 
	endif
	let	s:LastShellReturnCode	= 0
	let v:statusmsg = ''
	if &filetype == "c" 
		silent exe "make ".linkerflags." -o ".ExeEsc." ".SouEsc." ".g:C_Libs
	else
		silent exe "make ".linkerflags." -o ".ExeEsc." ".SouEsc." ".g:C_CplusLibs
	endif
	if v:shell_error != 0
		let	s:LastShellReturnCode	= v:shell_error
	endif
	call s:C_RestoreGlobalOption('makeprg')
	"
	if empty(v:statusmsg)
		let s:C_HlMessage = "'".Exe."' : linking successful"
		" open error window if necessary
		:redraw!
		exe	":botright cwindow"
	else
		exe ":botright copen"
	endif
	"		
endfunction    " ----------  end of function C_Link ----------
"
"------------------------------------------------------------------------------
"  C_Run : 	C_Run       {{{1
"  calls: C_Link
"------------------------------------------------------------------------------
"
let s:C_OutputBufferName   = "C-Output"
let s:C_OutputBufferNumber = -1
let s:C_RunMsg1						 ="' does not exist or is not executable or source older then executable"
let s:C_RunMsg2						 ="' does not exist or is not executable"
"
function! C_Run ()
"
	let s:C_HlMessage = ""
	let Sou  					= expand("%:p")												" name of the source file
	let Exe  					= expand("%:p:r").s:C_ExeExtension		" name of the executable
	let ExeEsc  			= escape( Exe, s:C_FilenameEscChar )	" name of the executable, escaped
	let Quote					= ''
	if s:MSWIN
		let Quote					= '"'
	endif
	"
	let l:arguments     = exists("b:C_CmdLineArgs") ? b:C_CmdLineArgs : ''
	"
	let	l:currentbuffer	= bufname("%")
	"
	"==============================================================================
	"  run : run from the vim command line
	"==============================================================================
	if s:C_OutputGvim == "vim"
		"
		if s:C_ExecutableToRun !~ "^\s*$"
			call C_HlMessage( "executable : '".s:C_ExecutableToRun."'" )
			exe		'!'.Quote.s:C_ExecutableToRun.Quote.' '.l:arguments
		else

			silent call C_Link()
			if s:LastShellReturnCode == 0
				" clear the last linking message if any"
				let s:C_HlMessage = ""
				call C_HlMessage()
			endif
			"
			if	executable(Exe) && getftime(Exe) >=  getftime(Sou)
				exe		"!".Quote.ExeEsc.Quote." ".l:arguments
			else
				echomsg "file '".Exe.s:C_RunMsg1
			endif
		endif

	endif
	"
	"==============================================================================
	"  run : redirect output to an output buffer
	"==============================================================================
	if s:C_OutputGvim == "buffer"
		let	l:currentbuffernr	= bufnr("%")
		"
		if s:C_ExecutableToRun =~ "^\s*$"
			call C_Link()
		endif
		if l:currentbuffer ==  bufname("%")
			"
			"
			if bufloaded(s:C_OutputBufferName) != 0 && bufwinnr(s:C_OutputBufferNumber)!=-1
				exe bufwinnr(s:C_OutputBufferNumber) . "wincmd w"
				" buffer number may have changed, e.g. after a 'save as'
				if bufnr("%") != s:C_OutputBufferNumber
					let s:C_OutputBufferNumber	= bufnr(s:C_OutputBufferName)
					exe ":bn ".s:C_OutputBufferNumber
				endif
			else
				silent exe ":new ".s:C_OutputBufferName
				let s:C_OutputBufferNumber=bufnr("%")
				setlocal buftype=nofile
				setlocal noswapfile
				setlocal syntax=none
				setlocal bufhidden=delete
				setlocal tabstop=8
			endif
			"
			" run programm
			"
			setlocal	modifiable

			if s:C_ExecutableToRun !~ "^\s*$"
				call C_HlMessage( "executable : '".s:C_ExecutableToRun."'" )
				let realexe	= s:C_ExecutableToRun
			elseif executable(Exe) && getftime(Exe) >= getftime(Sou)
				let realexe	= ExeEsc
			else
				setlocal	nomodifiable
				:close
				echomsg "file '".Exe.s:C_RunMsg1
				return
			endif

			exe		'%!'.s:stdbuf.Quote.realexe.Quote.' '.l:arguments
			if v:shell_error
				call append( line('$'), "program '".realexe."' terminated with error ".v:shell_error )
			endif
			setlocal	nomodifiable
			"
			if winheight(winnr()) >= line("$")
				exe bufwinnr(l:currentbuffernr) . "wincmd w"
			endif
			"
		endif
	endif
	"
	"==============================================================================
	"  run : run in a detached xterm  (not available for MS Windows)
	"==============================================================================
	if s:C_OutputGvim == "xterm"
		"
		if s:C_ExecutableToRun !~ "^\s*$"
			if s:MSWIN
				exe		'!'.Quote.s:C_ExecutableToRun.Quote.' '.l:arguments
			else
				silent exe '!'.s:Xterm_Executable.' -title '.s:C_ExecutableToRun.' '.g:Xterm_Options.' -e '.s:C_Wrapper.' '.s:C_ExecutableToRun.' '.l:arguments.' &'
				:redraw!
				call C_HlMessage( "executable : '".s:C_ExecutableToRun."'" )
			endif
		else

			silent call C_Link()
			"
			if	executable(Exe) && getftime(Exe) >= getftime(Sou)
				if s:MSWIN
					exe		"!".Quote.ExeEsc.Quote." ".l:arguments
				else
					silent exe '!'.s:Xterm_Executable.' -title '.ExeEsc.' '.g:Xterm_Options.' -e '.s:C_Wrapper.' '.ExeEsc.' '.l:arguments.' &'
					:redraw!
				endif
			else
				echomsg "file '".Exe.s:C_RunMsg1
			endif
		endif
	endif

endfunction    " ----------  end of function C_Run ----------
"
"------------------------------------------------------------------------------
"  C_Arguments : Arguments for the executable       {{{1
"------------------------------------------------------------------------------
function! C_Arguments ( ... )
	let	b:C_CmdLineArgs= join( a:000 )
endfunction    " ----------  end of function C_Arguments ----------
"
"----------------------------------------------------------------------
"  C_Toggle_Gvim_Xterm : change output destination       {{{1
"----------------------------------------------------------------------
function! C_Toggle_Gvim_Xterm ()
	"
	" get the mapleader (correctly escaped)
	let [ esc_mapl, err ] = mmtemplates#core#Resource ( g:C_Templates, 'escaped_mapleader' )
	"
	if s:C_OutputGvim == "vim"
		exe "aunmenu  <silent>  ".s:MenuRun.'.&output:\ '.s:Output[0]
		exe "amenu    <silent>  ".s:MenuRun.'.&output:\ '.s:Output[1].'<Tab>'.esc_mapl.'ro        :call C_Toggle_Gvim_Xterm()<CR>'
		exe "imenu    <silent>  ".s:MenuRun.'.&output:\ '.s:Output[1].'<Tab>'.esc_mapl.'ro   <C-C>:call C_Toggle_Gvim_Xterm()<CR>'
		let	s:C_OutputGvim	= "buffer"
	else
		if s:C_OutputGvim == "buffer"
			exe "aunmenu  <silent>  ".s:MenuRun.'.&output:\ '.s:Output[1]
			exe "amenu    <silent>  ".s:MenuRun.'.&output:\ '.s:Output[2].'<Tab>'.esc_mapl.'ro      :call C_Toggle_Gvim_Xterm()<CR>'
			exe "imenu    <silent>  ".s:MenuRun.'.&output:\ '.s:Output[2].'<Tab>'.esc_mapl.'ro <C-C>:call C_Toggle_Gvim_Xterm()<CR>'
			let	s:C_OutputGvim	= "xterm"
		else
			" ---------- output : xterm -> gvim
			exe "aunmenu  <silent>  ".s:MenuRun.'.&output:\ '.s:Output[2]
			exe "amenu    <silent>  ".s:MenuRun.'.&output:\ '.s:Output[0].'<Tab>'.esc_mapl.'ro      :call C_Toggle_Gvim_Xterm()<CR>'
			exe "imenu    <silent>  ".s:MenuRun.'.&output:\ '.s:Output[0].'<Tab>'.esc_mapl.'ro <C-C>:call C_Toggle_Gvim_Xterm()<CR>'
			let	s:C_OutputGvim	= "vim"
		endif
	endif
	echomsg "output destination is '".s:C_OutputGvim."'"
endfunction    " ----------  end of function C_Toggle_Gvim_Xterm ----------
"
"------------------------------------------------------------------------------
"  C_XtermSize : xterm geometry       {{{1
"------------------------------------------------------------------------------
function! C_XtermSize ()
	let regex	= '-geometry\s\+\d\+x\d\+'
	let geom	= matchstr( g:Xterm_Options, regex )
	let geom	= matchstr( geom, '\d\+x\d\+' )
	let geom	= substitute( geom, 'x', ' ', "" )
	let	answer= C_Input("   xterm size (COLUMNS LINES) : ", geom )
	while match(answer, '^\s*\d\+\s\+\d\+\s*$' ) < 0
		let	answer= C_Input(" + xterm size (COLUMNS LINES) : ", geom )
	endwhile
	let answer  = substitute( answer, '\s\+', "x", "" )						" replace inner whitespaces
	let g:Xterm_Options	= substitute( g:Xterm_Options, regex, "-geometry ".answer , "" )
endfunction    " ----------  end of function C_XtermSize ----------

"-------------------------------------------------------------------------------
" s:ExeToRun : Choose an executable to run.   {{{1
"-------------------------------------------------------------------------------
function! s:ExeToRun ()
	let s:C_ExecutableToRun = s:UserInput( 'executable to run [tab compl.]: ', '', 'file' )
	if s:C_ExecutableToRun !~ "^\s*$"
		if s:MSWIN
			let s:C_ExecutableToRun = substitute(s:C_ExecutableToRun, '\\ ', ' ', 'g' )
		endif
		let s:C_ExecutableToRun = escape( fnamemodify( s:C_ExecutableToRun, ':p' ), s:C_FilenameEscChar )
	endif
endfunction    " ----------  end of function s:ExeToRun ----------

"-------------------------------------------------------------------------------
" s:Debugger : Start a debugger   {{{1
"-------------------------------------------------------------------------------
function! s:Debugger ()

	silent exe 'update'
	if s:C_ExecutableToRun == ''
		call s:ExeToRun()
	endif
	let l:arguments = exists("b:C_CmdLineArgs") ? " ".b:C_CmdLineArgs : ""

  if  s:MSWIN
    let l:arguments = substitute( l:arguments, '^\s\+', ' ', '' )
    let l:arguments = substitute( l:arguments, '\s\+', "\" \"", 'g')
  endif
  "
  " debugger is 'gdb'
  "
  if g:C_Debugger == "gdb"
    if  s:MSWIN
      exe '!gdb  "'.s:C_ExecutableToRun.l:arguments.'"'
    else
      if has("gui_running") || &term == "xterm"
				silent exe "!".s:Xterm_Executable." ".g:Xterm_Options.' -e gdb ' . s:C_ExecutableToRun.l:arguments.' &'
      else
        silent exe '!clear; gdb ' . s:C_ExecutableToRun.l:arguments
      endif
    endif
  endif
  "
  if v:windowid != 0
    "
    " grapical debugger is 'kdbg', uses a PerlTk interface
    "
    if g:C_Debugger == "kdbg"
      if  s:MSWIN
				exe '!kdbg "'.s:C_ExecutableToRun.l:arguments.'"'
      else
        silent exe '!kdbg  '.s:C_ExecutableToRun.l:arguments.' &'
      endif
    endif
    "
    " debugger is 'ddd'  (not available for MS Windows); graphical front-end for GDB
    "
    if g:C_Debugger == "ddd" && !s:MSWIN
      if !executable("ddd")
        echohl WarningMsg
        echo 'ddd does not exist or is not executable!'
        echohl None
        return
      else
        silent exe '!ddd '.s:C_ExecutableToRun.l:arguments.' &'
      endif
    endif
    "
  endif
  "
	redraw!
endfunction   " ---------- end of function s:Debugger ----------

"------------------------------------------------------------------------------
"  C_SplintArguments : splint command line arguments       {{{1
"------------------------------------------------------------------------------
function! C_SplintArguments ()
	if s:C_SplintIsExecutable==0
		let s:C_HlMessage = ' Splint is not executable or not installed! '
	else
		let	prompt	= 'Splint command line arguments for "'.expand("%").'" : '
		if exists("b:C_SplintCmdLineArgs")
			let	b:C_SplintCmdLineArgs= C_Input( prompt, b:C_SplintCmdLineArgs )
		else
			let	b:C_SplintCmdLineArgs= C_Input( prompt , "" )
		endif
	endif
endfunction    " ----------  end of function C_SplintArguments ----------
"
"------------------------------------------------------------------------------
"  C_SplintCheck : run splint(1)        {{{1
"------------------------------------------------------------------------------
function! C_SplintCheck ()
	if s:C_SplintIsExecutable==0
		let s:C_HlMessage = ' Splint is not executable or not installed! '
		return
	endif
	let	l:currentbuffer=bufname("%")
	if &filetype != "c" && &filetype != "cpp"
		let s:C_HlMessage = ' "'.l:currentbuffer.'" seems not to be a C/C++ file '
		return
	endif
	let s:C_HlMessage = ""
	exe	":cclose"
	silent exe	":update"
	call s:C_SaveGlobalOption('makeprg')
	" Windows seems to need this:
	if	s:MSWIN
		:compiler splint
	endif
	:setlocal makeprg=splint
	"
	let l:arguments  = exists("b:C_SplintCmdLineArgs") ? b:C_SplintCmdLineArgs : ' '
	silent exe	"make ".l:arguments." ".escape(l:currentbuffer,s:C_FilenameEscChar)
	call s:C_RestoreGlobalOption('makeprg')
	exe	":botright cwindow"
	"
	" message in case of success
	"
	if l:currentbuffer == bufname("%")
		let s:C_HlMessage = " Splint --- no warnings for : ".l:currentbuffer
	endif
endfunction    " ----------  end of function C_SplintCheck ----------
"
"------------------------------------------------------------------------------
"  C_CppcheckCheck : run cppcheck(1)        {{{1
"------------------------------------------------------------------------------
function! C_CppcheckCheck ()
	if s:C_CppcheckIsExecutable==0
		let s:C_HlMessage = ' Cppcheck is not executable or not installed! '
		return
	endif
	let	l:currentbuffer=bufname("%")
	if &filetype != "c" && &filetype != "cpp"
		let s:C_HlMessage = ' "'.l:currentbuffer.'" seems not to be a C/C++ file '
		return
	endif
	let s:C_HlMessage = ""
	exe	":cclose"
	silent exe	":update"
	call s:C_SaveGlobalOption('makeprg')
	"
	call s:C_SaveGlobalOption('errorformat')
	setlocal errorformat=[%f:%l]:%m
	" Windows seems to need this:
	if	s:MSWIN
		:compiler cppcheck
	endif
	:setlocal makeprg=cppcheck
	"
	silent exe	"make --enable=".s:C_CppcheckSeverity.' '.escape(l:currentbuffer,s:C_FilenameEscChar)
	call s:C_RestoreGlobalOption('makeprg')
	exe	":botright cwindow"
	"
	" message in case of success
	"
	if l:currentbuffer == bufname("%")
		let s:C_HlMessage = " Cppcheck --- no warnings for : ".l:currentbuffer
	endif
endfunction    " ----------  end of function C_CppcheckCheck ----------

"===  FUNCTION  ================================================================
"          NAME:  C_CppcheckSeverityList     {{{1
"   DESCRIPTION:  cppcheck severity : callback function for completion
"    PARAMETERS:  ArgLead - 
"                 CmdLine - 
"                 CursorPos - 
"       RETURNS:  
"===============================================================================
function!	C_CppcheckSeverityList ( ArgLead, CmdLine, CursorPos )
	return filter( copy( s:CppcheckSeverity ), 'v:val =~ "\\<'.a:ArgLead.'\\w*"' )
endfunction    " ----------  end of function C_CppcheckSeverityList  ----------

"===  FUNCTION  ================================================================
"          NAME:  C_GetCppcheckSeverity     {{{1
"   DESCRIPTION:  cppcheck severity : used in command definition
"    PARAMETERS:  severity - cppcheck severity
"       RETURNS:  
"===============================================================================
function! C_GetCppcheckSeverity ( severity )
	let	sev	= a:severity
	let sev	= substitute( sev, '^\s\+', '', '' )  	     			" remove leading whitespaces
	let sev	= substitute( sev, '\s\+$', '', '' )	       			" remove trailing whitespaces
	"
	if index( s:CppcheckSeverity, tolower(sev) ) >= 0
		let s:C_CppcheckSeverity = sev
		echomsg "cppcheck severity is set to '".s:C_CppcheckSeverity."'"
	else
		let s:C_CppcheckSeverity = 'all'			                        " the default
		echomsg "wrong argument '".a:severity."' / severity is set to '".s:C_CppcheckSeverity."'"
	endif
	"
endfunction    " ----------  end of function C_GetCppcheckSeverity  ----------
"
"===  FUNCTION  ================================================================
"          NAME:  C_CppcheckSeverityInput
"   DESCRIPTION:  read cppcheck severity from the command line
"    PARAMETERS:  -
"       RETURNS:  
"===============================================================================
function! C_CppcheckSeverityInput ()
		let retval = input( "cppcheck severity  (current = '".s:C_CppcheckSeverity."' / tab exp.): ", '', 'customlist,C_CppcheckSeverityList' )
		redraw!
		call C_GetCppcheckSeverity( retval )
	return
endfunction    " ----------  end of function C_CppcheckSeverityInput  ----------
"
"------------------------------------------------------------------------------
"  C_CodeCheckArguments : CodeCheck command line arguments       {{{1
"------------------------------------------------------------------------------
function! C_CodeCheckArguments ()
	if s:C_CodeCheckIsExecutable==0
		let s:C_HlMessage = ' CodeCheck is not executable or not installed! '
	else
		let	prompt	= 'CodeCheck command line arguments for "'.expand("%").'" : '
		if exists("b:C_CodeCheckCmdLineArgs")
			let	b:C_CodeCheckCmdLineArgs= C_Input( prompt, b:C_CodeCheckCmdLineArgs )
		else
			let	b:C_CodeCheckCmdLineArgs= C_Input( prompt , s:C_CodeCheckOptions )
		endif
	endif
endfunction    " ----------  end of function C_CodeCheckArguments ----------
"
"------------------------------------------------------------------------------
"  C_CodeCheck : run CodeCheck       {{{1
"------------------------------------------------------------------------------
function! C_CodeCheck ()
	if s:C_CodeCheckIsExecutable==0
		let s:C_HlMessage = ' CodeCheck is not executable or not installed! '
		return
	endif
	let	l:currentbuffer=bufname("%")
	if &filetype != "c" && &filetype != "cpp"
		let s:C_HlMessage = ' "'.l:currentbuffer.'" seems not to be a C/C++ file '
		return
	endif
	let s:C_HlMessage = ""
	exe	":cclose"
	silent exe	":update"
	call s:C_SaveGlobalOption('makeprg')
	exe	"setlocal makeprg=".s:C_CodeCheckExeName
	"
	" match the splint error messages (quickfix commands)
	" ignore any lines that didn't match one of the patterns
	"
	call s:C_SaveGlobalOption('errorformat')
	setlocal errorformat=%f(%l)%m
	"
	let l:arguments  = exists("b:C_CodeCheckCmdLineArgs") ? b:C_CodeCheckCmdLineArgs : ""
	if empty( l:arguments )
		let l:arguments	=	s:C_CodeCheckOptions
	endif
	exe	":make ".l:arguments." ".escape( l:currentbuffer, s:C_FilenameEscChar )
	call s:C_RestoreGlobalOption('errorformat')
	call s:C_RestoreGlobalOption('makeprg')
	exe	":botright cwindow"
	"
	" message in case of success
	"
	if l:currentbuffer == bufname("%")
		let s:C_HlMessage = " CodeCheck --- no warnings for : ".l:currentbuffer
	endif
endfunction    " ----------  end of function C_CodeCheck ----------
"
"------------------------------------------------------------------------------
"  C_Indent : run indent(1)       {{{1
"------------------------------------------------------------------------------
"
function! C_Indent ( )
	if s:C_IndentIsExecutable == 0
		echomsg 'indent is not executable or not installed!'
		return
	endif
	let	l:currentbuffer=expand("%:p")
	if &filetype != "c" && &filetype != "cpp"
		echomsg '"'.l:currentbuffer.'" seems not to be a C/C++ file '
		return
	endif
	if C_Input("indent whole file [y/n/Esc] : ", "y" ) != "y"
		return
	endif
	:update

	exe	":cclose"
	if s:MSWIN
		silent exe ":%!indent "
	else
		silent exe ":%!indent 2> ".s:C_IndentErrorLog
		redraw!
		call s:C_SaveGlobalOption('errorformat')
		if getfsize( s:C_IndentErrorLog ) > 0
			exe ':edit! '.s:C_IndentErrorLog
			let errorlogbuffer	= bufnr("%")
			exe ':%s/^indent: Standard input/indent: '.escape( l:currentbuffer, '/' ).'/'
			setlocal errorformat=indent:\ %f:%l:%m
			:cbuffer
			exe ':bdelete! '.errorlogbuffer
			exe	':botright cwindow'
		else
			echomsg 'File "'.l:currentbuffer.'" reformatted.'
		endif
		call s:C_RestoreGlobalOption('errorformat')
	endif

endfunction    " ----------  end of function C_Indent ----------
"
"------------------------------------------------------------------------------
"  C_HlMessage : indent message     {{{1
"------------------------------------------------------------------------------
function! C_HlMessage ( ... )
	redraw!
	echohl Search
	if a:0 == 0
		echo s:C_HlMessage
	else
		echo a:1
	endif
	echohl None
endfunction    " ----------  end of function C_HlMessage ----------

"-------------------------------------------------------------------------------
" C_Settings : Print the settings.   {{{1
"-------------------------------------------------------------------------------
function! C_Settings ( verbose )
	"
	if     s:MSWIN | let sys_name = 'Windows'
	elseif s:UNIX  | let sys_name = 'UN*X'
	else           | let sys_name = 'unknown' | endif
	"
	let	txt = " C/C++-Support settings\n\n"
	" template settings: macros, style, ...
	if exists ( 'g:C_Templates' )
		let txt .= '                   author :  "'.mmtemplates#core#ExpandText( g:C_Templates, '|AUTHOR|'       )."\"\n"
		let txt .= '                authorref :  "'.mmtemplates#core#ExpandText( g:C_Templates, '|AUTHORREF|'    )."\"\n"
		let txt .= '                    email :  "'.mmtemplates#core#ExpandText( g:C_Templates, '|EMAIL|'        )."\"\n"
		let txt .= '             organization :  "'.mmtemplates#core#ExpandText( g:C_Templates, '|ORGANIZATION|' )."\"\n"
		let txt .= '         copyright holder :  "'.mmtemplates#core#ExpandText( g:C_Templates, '|COPYRIGHT|'    )."\"\n"
		let txt .= '                  license :  "'.mmtemplates#core#ExpandText( g:C_Templates, '|LICENSE|'      )."\"\n"
		let txt .= '                  project :  "'.mmtemplates#core#ExpandText( g:C_Templates, '|PROJECT|'     )."\"\n"
		let txt .= '           template style :  "'.mmtemplates#core#Resource ( g:C_Templates, "style" )[0]."\"\n\n"
	else
		let txt .= "                templates :  -not loaded-\n\n"
	endif
	" plug-in installation
	let txt .= '      plugin installation :  '.g:C_Installation.' on '.sys_name."\n"
	" toolbox
	if s:C_UseToolbox == 'yes'
		let toollist = mmtoolbox#tools#GetList ( s:C_Toolbox )
		if empty ( toollist )
			let txt .= "            using toolbox :  -no tools-\n"
		else
			let sep  = "\n"."                             "
			let txt .=      "            using toolbox :  "
						\ .join ( toollist, sep )."\n"
		endif
	endif
	let txt .= "\n"
	" templates, snippets
	if exists ( 'g:C_Templates' )
		let [ templist, msg ] = mmtemplates#core#Resource ( g:C_Templates, 'template_list' )
		let sep  = "\n"."                             "
		let txt .=      "           template files :  "
					\ .join ( templist, sep )."\n"
	else
		let txt .= "           template files :  -not loaded-\n"
	endif
	let txt .=
				\  '       code snippets dir. :  '.s:C_CodeSnippets."\n"
	" ----- dictionaries ------------------------
	if !empty(g:C_Dictionary_File)
		let ausgabe= &dictionary
		let ausgabe= substitute( ausgabe, ",", ",\n                             ", "g" )
		let txt = txt."       dictionary file(s) :  ".ausgabe."\n"
	endif
	" ----- map leader, menus, file headers -----
	if a:verbose >= 1
		let	txt .= "\n"
					\ .'                mapleader :  "'.g:C_MapLeader."\"\n"
					\ .'     load menus / delayed :  "'.s:C_LoadMenus.'" / "'.s:C_CreateMenusDelayed."\"\n"
					\ .'       insert file header :  "'.s:C_InsertFileHeader."\"\n"
	endif
	let txt .= "\n"
	" ----- extension, flags, executables -------
	let txt = txt.'         C file extension :  "'.s:C_CExtension.'"  (everything else is C++)'."\n"
	let txt = txt.'    extension for objects :  "'.s:C_ObjExtension."\"\n"
	let txt = txt.'extension for executables :  "'.s:C_ExeExtension."\"\n"
	let txt = txt.'       compiler flags (C) :  "'.g:C_CFlags."\"\n"
	let txt = txt.'         linker flags (C) :  "'.g:C_LFlags."\"\n"
	let txt = txt.'            libraries (C) :  "'.g:C_Libs."\"\n"
	let txt = txt.'     compiler flags (C++) :  "'.g:C_CplusCFlags."\"\n"
	let txt = txt.'       linker flags (C++) :  "'.g:C_CplusLFlags."\"\n"
	let txt = txt.'          libraries (C++) :  "'.g:C_CplusLibs."\"\n"
	let txt = txt.'         C / C++ compiler :  "'.g:C_CCompiler.'" / "'.g:C_CplusCompiler."\"\n"
	let txt = txt.'                 debugger :  "'.g:C_Debugger."\"\n"
	let txt = txt.'             exec. to run :  "'.s:C_ExecutableToRun."\"\n"
	" ----- output ------------------------------
	if a:verbose >= 1
		let txt = txt."\n"
		let txt = txt."            output method :  ".s:C_OutputGvim."\n"
	endif
	if !s:MSWIN && a:verbose >= 1
		let txt = txt.'         xterm executable :  '.s:Xterm_Executable."\n"
		let txt = txt.'            xterm options :  '.g:Xterm_Options."\n"
	endif
	" ----- splint ------------------------------
	if s:C_SplintIsExecutable==1
		if exists("b:C_SplintCmdLineArgs")
			let ausgabe = b:C_SplintCmdLineArgs
		else
			let ausgabe = ""
		endif
		let txt = txt."\n"
		let txt = txt."        splint options(s) :  ".ausgabe."\n"
	endif
	" ----- cppcheck ------------------------------
	if s:C_CppcheckIsExecutable==1
		let txt = txt."\n"
		let txt = txt."        cppcheck severity :  ".s:C_CppcheckSeverity."\n"
	endif
	" ----- code check --------------------------
	if s:C_CodeCheckIsExecutable==1
		if exists("b:C_CodeCheckCmdLineArgs")
			let ausgabe = b:C_CodeCheckCmdLineArgs
		else
			let ausgabe = s:C_CodeCheckOptions
		endif
		let txt = txt."\n"
		let txt = txt."CodeCheck (TM) options(s) :  ".ausgabe."\n"
	endif
	let	txt = txt."__________________________________________________________________________\n"
	let	txt = txt." C/C++-Support, Version ".g:C_Version." / Wolfgang Mehner / wolfgang-mehner@web.de\n\n"
	"
	if a:verbose == 2
		split CSupport_Settings.txt
		put = txt
	else
		echo txt
	endif
endfunction    " ----------  end of function C_Settings ----------
"
"------------------------------------------------------------------------------
"  C_Hardcopy : hardcopy     {{{1
"    MSWIN : a printer dialog is displayed
"    other : print PostScript to file
"------------------------------------------------------------------------------
function! C_Hardcopy () range
  let outfile = expand("%")
  if empty(outfile)
		let s:C_HlMessage = 'Buffer has no name.'
		call C_HlMessage()
  endif
	let outdir	= getcwd()
	if filewritable(outdir) != 2
		let outdir	= $HOME
	endif
	if  !s:MSWIN
		let outdir	= outdir.'/'
	endif
  let old_printheader=&printheader
  exe  ':set printheader='.s:C_Printheader
  " ----- normal mode ----------------
  if a:firstline == a:lastline
    silent exe  'hardcopy > '.outdir.outfile.'.ps'
    if  !s:MSWIN
      echo 'file "'.outfile.'" printed to "'.outdir.outfile.'.ps"'
    endif
  endif
  " ----- visual mode / range ----------------
  if a:firstline < a:lastline
    silent exe  a:firstline.','.a:lastline."hardcopy > ".outdir.outfile.".ps"
    if  !s:MSWIN
      echo 'file "'.outfile.'" (lines '.a:firstline.'-'.a:lastline.') printed to "'.outdir.outfile.'.ps"'
    endif
  endif
  exe  ':set printheader='.escape( old_printheader, ' %' )
endfunction   " ---------- end of function  C_Hardcopy  ----------
"
"------------------------------------------------------------------------------
"  C_HelpCsupport : help csupport     {{{1
"------------------------------------------------------------------------------
function! C_HelpCsupport ()
	try
		:help csupport
	catch
		exe ':helptags '.s:plugin_dir.'/doc'
		:help csupport
	endtry
endfunction    " ----------  end of function C_HelpCsupport ----------
"
"------------------------------------------------------------------------------
"  C_Help : lookup word under the cursor or ask    {{{1
"------------------------------------------------------------------------------
"
let s:C_DocBufferName       = "C_HELP"
let s:C_DocHelpBufferNumber = -1
"
function! C_Help( type )

	let cuc		= getline(".")[col(".") - 1]		" character under the cursor
	let	item	= expand("<cword>")							" word under the cursor
	if empty(cuc) || empty(item) || match( item, cuc ) == -1
		let	item=C_Input('name of the manual page : ', '' )
	endif

	if empty(item)
		return
	endif
	"------------------------------------------------------------------------------
	"  replace buffer content with bash help text
	"------------------------------------------------------------------------------
	"
	" jump to an already open bash help window or create one
	"
	if bufloaded(s:C_DocBufferName) != 0 && bufwinnr(s:C_DocHelpBufferNumber) != -1
		exe bufwinnr(s:C_DocHelpBufferNumber) . "wincmd w"
		" buffer number may have changed, e.g. after a 'save as'
		if bufnr("%") != s:C_DocHelpBufferNumber
			let s:C_DocHelpBufferNumber=bufnr(s:C_OutputBufferName)
			exe ":bn ".s:C_DocHelpBufferNumber
		endif
	else
		exe ":new ".s:C_DocBufferName
		let s:C_DocHelpBufferNumber=bufnr("%")
		setlocal buftype=nofile
		setlocal noswapfile
		setlocal bufhidden=delete
		setlocal syntax=OFF

		 noremap  <buffer>  <silent>  <S-F1>        :call C_Help("m")<CR>
		inoremap  <buffer>  <silent>  <S-F1>   <C-C>:call C_Help("m")<CR>
	endif
	setlocal	modifiable
	"
	if a:type == 'm' 
		"
		" Is there more than one manual ?
		"
		let manpages	= system( s:C_Man.' -k '.item )
		if v:shell_error
			echomsg	"Shell command '".s:C_Man." -k ".item."' failed."
			:close
			return
		endif
		let	catalogs	= split( manpages, '\n', )
		let	manual		= {}
		"
		" Select manuals where the name exactly matches
		"
		for line in catalogs
			if line =~ '^'.item.'\s\+(' 
				let	itempart	= split( line, '\s\+' )
				let	catalog		= itempart[1][1:-2]
				if match( catalog, '.p$' ) == -1
					let	manual[catalog]	= catalog
				endif
			endif
		endfor
		"
		" Build a selection list if there are more than one manual
		"
		let	catalog	= ""
		if len(keys(manual)) > 1
			for key in keys(manual)
				echo ' '.item.'  '.key
			endfor
			let defaultcatalog	= ''
			if has_key( manual, '3' )
				let defaultcatalog	= '3'
			else
				if has_key( manual, '2' )
					let defaultcatalog	= '2'
				endif
			endif
			let	catalog	= input( 'select manual section (<Enter> cancels) : ', defaultcatalog )
			if ! has_key( manual, catalog )
				:close
				:redraw
				echomsg	"no appropriate manual section '".catalog."'"
				return
			endif
		endif

		" :WORKAROUND:05.04.2016 21:05:WM: setting the filetype changes the global tabstop,
		" handle this manually
		let ts_save = &g:tabstop

		set filetype=man

		let &g:tabstop = ts_save

		" get the width of the newly opened window
		" and set the width of man's output accordingly
		let win_w = winwidth( winnr() )
		if s:UNIX && win_w > 0
			silent exe ":%! MANWIDTH=".win_w." ".s:C_Man." ".catalog." ".item
		else
			silent exe ":%!".s:C_Man." ".catalog." ".item
		endif

		if s:MSWIN
			call s:C_RemoveSpecialCharacters()
		endif
	endif

	setlocal nomodifiable
endfunction		" ---------- end of function  C_Help  ----------
"
"------------------------------------------------------------------------------
"  C_RemoveSpecialCharacters   {{{1
"  remove <backspace><any character> in CYGWIN man(1) output
"  remove           _<any character> in CYGWIN man(1) output
"------------------------------------------------------------------------------
"
function! s:C_RemoveSpecialCharacters ( )
	let	patternunderline	= '_\%x08'
	let	patternbold				= '\%x08.'
	setlocal modifiable
	if search(patternunderline) != 0
		silent exe ':%s/'.patternunderline.'//g'
	endif
	if search(patternbold) != 0
		silent exe ':%s/'.patternbold.'//g'
	endif
	setlocal nomodifiable
	silent normal! gg
endfunction		" ---------- end of function  s:C_RemoveSpecialCharacters   ----------
"
"------------------------------------------------------------------------------
"  C_CreateGuiMenus     {{{1
"------------------------------------------------------------------------------
function! C_CreateGuiMenus ()
	if s:C_MenusVisible == 'no'
		aunmenu <silent> &Tools.Load\ C\ Support
		amenu   <silent> 40.1000 &Tools.-SEP100- :
		amenu   <silent> 40.1030 &Tools.Unload\ C\ Support <C-C>:call C_RemoveGuiMenus()<CR>
		call s:RereadTemplates()
		call s:InitMenus()
		let  s:C_MenusVisible = 'yes'
	endif
endfunction    " ----------  end of function C_CreateGuiMenus  ----------

"------------------------------------------------------------------------------
"  === Templates API ===   {{{1
"------------------------------------------------------------------------------
"
"------------------------------------------------------------------------------
"  C_SetMapLeader   {{{2
"------------------------------------------------------------------------------
function! C_SetMapLeader ()
	if exists ( 'g:C_MapLeader' )
		call mmtemplates#core#SetMapleader ( g:C_MapLeader )
	endif
endfunction    " ----------  end of function C_SetMapLeader  ----------
"
"------------------------------------------------------------------------------
"  C_ResetMapLeader   {{{2
"------------------------------------------------------------------------------
function! C_ResetMapLeader ()
	if exists ( 'g:C_MapLeader' )
		call mmtemplates#core#ResetMapleader ()
	endif
endfunction    " ----------  end of function C_ResetMapLeader  ----------
" }}}2

"-------------------------------------------------------------------------------
" s:RereadTemplates : Reload the templates.   {{{1
"-------------------------------------------------------------------------------
function! s:RereadTemplates ()

	"-------------------------------------------------------------------------------
	" SETUP TEMPLATE LIBRARY
	"-------------------------------------------------------------------------------
	let g:C_Templates = mmtemplates#core#NewLibrary ( 'api_version', '1.0' )
	"
	" mapleader
	if empty ( g:C_MapLeader )
		call mmtemplates#core#Resource ( g:C_Templates, 'set', 'property', 'Templates::Mapleader', '\' )
	else
		call mmtemplates#core#Resource ( g:C_Templates, 'set', 'property', 'Templates::Mapleader', g:C_MapLeader )
	endif
	"
	" some metainfo
	call mmtemplates#core#Resource ( g:C_Templates, 'set', 'property', 'Templates::Wizard::PluginName',   'C' )
	call mmtemplates#core#Resource ( g:C_Templates, 'set', 'property', 'Templates::Wizard::FiletypeName', 'C' )
	call mmtemplates#core#Resource ( g:C_Templates, 'set', 'property', 'Templates::Wizard::FileCustomNoPersonal',   s:plugin_dir.'/c-support/rc/custom.templates' )
	call mmtemplates#core#Resource ( g:C_Templates, 'set', 'property', 'Templates::Wizard::FileCustomWithPersonal', s:plugin_dir.'/c-support/rc/custom_with_personal.templates' )
	call mmtemplates#core#Resource ( g:C_Templates, 'set', 'property', 'Templates::Wizard::FilePersonal',           s:plugin_dir.'/c-support/rc/personal.templates' )
	call mmtemplates#core#Resource ( g:C_Templates, 'set', 'property', 'Templates::Wizard::CustomFileVariable',     'g:C_CustomTemplateFile' )
	"
	" maps: special operations
	call mmtemplates#core#Resource ( g:C_Templates, 'set', 'property', 'Templates::RereadTemplates::Map', 'ntr' )
	call mmtemplates#core#Resource ( g:C_Templates, 'set', 'property', 'Templates::ChooseStyle::Map',     'nts' )
	call mmtemplates#core#Resource ( g:C_Templates, 'set', 'property', 'Templates::SetupWizard::Map',     'ntw' )
	"
	" syntax: comments
	call mmtemplates#core#ChangeSyntax ( g:C_Templates, 'comment', '§' )

	" property: file skeletons
	call mmtemplates#core#Resource ( g:C_Templates, 'add', 'property', 'C::FileSkeleton::Header',   'Comments.file description header' )
	call mmtemplates#core#Resource ( g:C_Templates, 'add', 'property', 'C::FileSkeleton::Source',   'Comments.file description impl' )
	call mmtemplates#core#Resource ( g:C_Templates, 'add', 'property', 'Cpp::FileSkeleton::Header', 'Comments.file description header' )
	call mmtemplates#core#Resource ( g:C_Templates, 'add', 'property', 'Cpp::FileSkeleton::Source', 'Comments.file description impl' )

	" property: Doxygen menu
	call mmtemplates#core#Resource ( g:C_Templates, 'add', 'property', 'Doxygen::BriefAM::Menu', '' )
	call mmtemplates#core#Resource ( g:C_Templates, 'add', 'property', 'Doxygen::BriefAM::Map', '' )
	"
	"-------------------------------------------------------------------------------
	" load template library
	"-------------------------------------------------------------------------------

	" global templates (global installation only)
	if g:C_Installation == 'system'
		call mmtemplates#core#ReadTemplates ( g:C_Templates, 'load', s:C_GlobalTemplateFile,
					\ 'name', 'global', 'map', 'ntg' )
	endif

	" local templates (optional for global installation)
	if g:C_Installation == 'system'
		call mmtemplates#core#ReadTemplates ( g:C_Templates, 'load', s:C_LocalTemplateFile,
					\ 'name', 'local', 'map', 'ntl', 'optional', 'hidden' )
	else
		call mmtemplates#core#ReadTemplates ( g:C_Templates, 'load', s:C_LocalTemplateFile,
					\ 'name', 'local', 'map', 'ntl' )
	endif

	" additional templates (optional)
	if ! empty ( s:C_AdditionalTemplates )
		call mmtemplates#core#AddCustomTemplateFiles ( g:C_Templates, s:C_AdditionalTemplates, "C's additional templates" )
	endif

	" personal templates (shared across template libraries) (optional, existence of file checked by template engine)
	call mmtemplates#core#ReadTemplates ( g:C_Templates, 'personalization',
				\ 'name', 'personal', 'map', 'ntp' )

	" custom templates (optional, existence of file checked by template engine)
	call mmtemplates#core#ReadTemplates ( g:C_Templates, 'load', s:C_CustomTemplateFile,
				\ 'name', 'custom', 'map', 'ntc', 'optional' )

	"-------------------------------------------------------------------------------
	" further setup
	"-------------------------------------------------------------------------------
	"
	" get the jump tags
	let s:C_TemplateJumpTarget = mmtemplates#core#Resource ( g:C_Templates, "jumptag" )[0]
	"
endfunction    " ----------  end of function s:RereadTemplates  ----------

"-------------------------------------------------------------------------------
" s:CheckTemplatePersonalization : Check whether the name, .. has been set.   {{{1
"-------------------------------------------------------------------------------

let s:DoneCheckTemplatePersonalization = 0

function! s:CheckTemplatePersonalization ()

	" check whether the templates are personalized
	if s:DoneCheckTemplatePersonalization
				\ || mmtemplates#core#ExpandText ( g:C_Templates, '|AUTHOR|' ) != 'YOUR NAME'
				\ || s:C_InsertFileHeader != 'yes'
		return
	endif

	let s:DoneCheckTemplatePersonalization = 1

	let maplead = mmtemplates#core#Resource ( g:C_Templates, 'get', 'property', 'Templates::Mapleader' )[0]

	redraw
	call s:ImportantMsg ( 'The personal details are not set in the template library. Use the map "'.maplead.'ntw".' )

endfunction    " ----------  end of function s:CheckTemplatePersonalization  ----------

"-------------------------------------------------------------------------------
" s:CheckAndRereadTemplates : Make sure the templates are loaded.   {{{1
"-------------------------------------------------------------------------------
function! s:CheckAndRereadTemplates ()
	if ! exists ( 'g:C_Templates' )
		call s:RereadTemplates()
	endif
endfunction    " ----------  end of function s:CheckAndRereadTemplates  ----------

"-------------------------------------------------------------------------------
" s:InsertFileHeader : Insert a file header.   {{{1
"-------------------------------------------------------------------------------
function! s:InsertFileHeader ()
	call s:CheckAndRereadTemplates()

	" prevent insertion for a file generated from a link error
	if isdirectory(expand('%:p:h')) && s:C_InsertFileHeader == 'yes'
		let ft = &filetype == 'cpp' ? 'Cpp' : 'C'

		if index( s:C_SourceCodeExtensionsList, expand('%:e') ) >= 0
			let templ_s = mmtemplates#core#Resource ( g:C_Templates, 'get', 'property', ft.'::FileSkeleton::Source' )[0]
		else
			let templ_s = mmtemplates#core#Resource ( g:C_Templates, 'get', 'property', ft.'::FileSkeleton::Header' )[0]
		endif

		" insert templates in reverse order, always above the first line
		" the last one to insert (the first in the list), will determine the
		" placement of the cursor
		let templ_l = split ( templ_s, ';' )
		for i in range ( len(templ_l)-1, 0, -1 )
			exe 1
			if -1 != match ( templ_l[i], '^\s\+$' )
				put! =''
			else
				call mmtemplates#core#InsertTemplate ( g:C_Templates, templ_l[i], 'placement', 'above' )
			endif
		endfor
		if len(templ_l) > 0
			set modified
		endif
	endif
endfunction    " ----------  end of function s:InsertFileHeader  ----------

"------------------------------------------------------------------------------
"  C_ToolMenu     {{{1
"------------------------------------------------------------------------------
function! C_ToolMenu ()
	amenu   <silent> 40.1000 &Tools.-SEP100- :
	amenu   <silent> 40.1030 &Tools.Load\ C\ Support      :call C_CreateGuiMenus()<CR>
	imenu   <silent> 40.1030 &Tools.Load\ C\ Support <C-C>:call C_CreateGuiMenus()<CR>
endfunction    " ----------  end of function C_ToolMenu  ----------

"------------------------------------------------------------------------------
"  C_RemoveGuiMenus     {{{1
"------------------------------------------------------------------------------
function! C_RemoveGuiMenus ()
	if s:C_MenusVisible == 'yes'
		exe "aunmenu <silent> ".s:C_RootMenu
		"
		aunmenu <silent> &Tools.Unload\ C\ Support
		call C_ToolMenu()
		"
		let s:C_MenusVisible = 'no'
	endif
endfunction    " ----------  end of function C_RemoveGuiMenus  ----------

"------------------------------------------------------------------------------
"  C_HighlightJumpTargets   {{{1
"------------------------------------------------------------------------------
function! C_HighlightJumpTargets ()
	if s:C_Ctrl_j == 'on'
		exe 'match Search /'.s:C_TemplateJumpTarget.'/'
	endif
endfunction    " ----------  end of function C_HighlightJumpTargets  ----------

"------------------------------------------------------------------------------
"  C_JumpCtrlJ     {{{1
"------------------------------------------------------------------------------
function! C_JumpCtrlJ ()
  let match	= search( s:C_TemplateJumpTarget, 'c' )
	if match > 0
		" remove the target
		call setline( match, substitute( getline('.'), s:C_TemplateJumpTarget, '', '' ) )
	else
		" try to jump behind parenthesis or strings in the current line 
		if match( getline(".")[col(".") - 1], "[\]})\"'`]"  ) != 0
			call search( "[\]})\"'`]", '', line(".") )
		endif
		normal! l
	endif
	return ''
endfunction    " ----------  end of function C_JumpCtrlJ  ----------

"===  FUNCTION  ================================================================
"          NAME:  CreateAdditionalMaps     {{{1
"   DESCRIPTION:  create additional maps
"    PARAMETERS:  -
"       RETURNS:  
"===============================================================================
function! s:CreateAdditionalMaps ()
	"
	"-------------------------------------------------------------------------------
	" settings - local leader
	"-------------------------------------------------------------------------------
	if ! empty ( g:C_MapLeader )
		if exists ( 'g:maplocalleader' )
			let ll_save = g:maplocalleader
		endif
		let g:maplocalleader = g:C_MapLeader
	endif    
	"
	" ---------- C/C++ dictionary -----------------------------------
	" This will enable keyword completion for C and C++
	" using Vim's dictionary feature |i_CTRL-X_CTRL-K|.
	" Set the new dictionaries in front of the existing ones
	" 
	if exists("g:C_Dictionary_File")
		silent! exe 'setlocal dictionary+='.g:C_Dictionary_File
	endif    
	"
	"-------------------------------------------------------------------------------
	" USER DEFINED COMMANDS
	"-------------------------------------------------------------------------------
	"
	command! -nargs=1 -complete=customlist,C_CppcheckSeverityList  CppcheckSeverity   call C_GetCppcheckSeverity (<f-args>)
	"
	" ---------- commands : run -------------------------------------
  command! -nargs=* -complete=file CCmdlineArgs     call C_Arguments(<q-args>)
	"
	" ---------- F-key mappings  ------------------------------------
	"
	"   Alt-F9   write buffer and compile
	"       F9   compile and link
	"  Ctrl-F9   run executable
	" Shift-F9   command line arguments
	"
	noremap  <buffer>  <silent>  <A-F9>       :call C_Compile()<CR>:call C_HlMessage()<CR>
	inoremap <buffer>  <silent>  <A-F9>  <C-C>:call C_Compile()<CR>:call C_HlMessage()<CR>
	"
	noremap  <buffer>  <silent>    <F9>       :call C_Link()<CR>:call C_HlMessage()<CR>
	inoremap <buffer>  <silent>    <F9>  <C-C>:call C_Link()<CR>:call C_HlMessage()<CR>
	"
	noremap  <buffer>  <silent>  <C-F9>       :call C_Run()<CR>
	inoremap <buffer>  <silent>  <C-F9>  <C-C>:call C_Run()<CR>
	"
	noremap  <buffer>            <S-F9>       :CCmdlineArgs<Space>
	inoremap <buffer>            <S-F9>  <C-C>:CCmdlineArgs<Space>
	"

	" ---------- KEY MAPPINGS : MENU ENTRIES -------------------------------------
	" ---------- comments menu  ------------------------------------------------
	"
	 noremap   <buffer>  <silent>  <LocalLeader>cl         :call C_EndOfLineComment()<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>cl    <Esc>:call C_EndOfLineComment()<CR>
	"
	nnoremap   <buffer>  <silent>  <LocalLeader>cj         :call C_AdjustLineEndComm()<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>cj         :call C_AdjustLineEndComm()<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>cj    <Esc>:call C_AdjustLineEndComm()<CR>a
	"
	noremap    <buffer>  <silent>  <LocalLeader>cs         :call C_GetLineEndCommCol()<CR>

	noremap    <buffer>  <silent>  <LocalLeader>c*         :call C_CodeToCommentC()<CR>:nohlsearch<CR>j
	vnoremap   <buffer>  <silent>  <LocalLeader>c*         :call C_CodeToCommentC()<CR>:nohlsearch<CR>j
	inoremap   <buffer>  <silent>  <LocalLeader>c*    <Esc>:call C_CodeToCommentC()<CR>:nohlsearch<CR>j

	noremap    <buffer>  <silent>  <LocalLeader>cc         :call C_CodeToCommentCpp()<CR>:nohlsearch<CR>j
	vnoremap   <buffer>  <silent>  <LocalLeader>cc         :call C_CodeToCommentCpp()<CR>:nohlsearch<CR>j
	inoremap   <buffer>  <silent>  <LocalLeader>cc    <Esc>:call C_CodeToCommentCpp()<CR>:nohlsearch<CR>j
	noremap    <buffer>  <silent>  <LocalLeader>co         :call C_CommentToCode()<CR>:nohlsearch<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>co         :call C_CommentToCode()<CR>:nohlsearch<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>co    <Esc>:call C_CommentToCode()<CR>:nohlsearch<CR>
	" 
	 noremap   <buffer>  <silent>  <LocalLeader>cn         :call C_NonCCommentToggle( )<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>cn         :call C_NonCCommentToggle( )<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>cn    <Esc>:call C_NonCCommentToggle( )<CR>
	" 
	 noremap   <buffer>  <silent>  <LocalLeader>cx         :call C_CommentToggle( )<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>cx         :call C_CommentToggle( )<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>cx    <Esc>:call C_CommentToggle( )<CR>
	" 
	" ---------- Doxygen menu  ---------------------------------------------------
	"
	let [ bam_map, err ] = mmtemplates#core#Resource ( g:C_Templates, 'get', 'property', 'Doxygen::BriefAM::Map' )
	"
	if err == '' && bam_map != ''
		silent exe ' noremap   <buffer>  <silent>  <LocalLeader>'.bam_map.'         :call C_EndOfLineComment("doxygen")<CR>'
		silent exe 'inoremap   <buffer>  <silent>  <LocalLeader>'.bam_map.'    <Esc>:call C_EndOfLineComment("doxygen")<CR>'
	endif
	"
	" ---------- statements menu  ------------------------------------------------
	"
	" ---------- preprocessor menu  ----------------------------------------------
	"
	noremap    <buffer>  <silent>  <LocalLeader>pi0       :call C_PPIf0("a")<CR>2ji
	inoremap   <buffer>  <silent>  <LocalLeader>pi0  <Esc>:call C_PPIf0("a")<CR>2ji
	vnoremap   <buffer>  <silent>  <LocalLeader>pi0  <Esc>:call C_PPIf0("v")<CR>

	noremap    <buffer>  <silent>  <LocalLeader>pr0       :call C_PPIf0Remove()<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>pr0  <Esc>:call C_PPIf0Remove()<CR>
	"
	" ---------- idioms menu  ----------------------------------------------------
	"
	noremap    <buffer>  <silent>  <LocalLeader>i0         :call C_CodeFor("up"    )<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>i0         :call C_CodeFor("up","v")<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>i0    <Esc>:call C_CodeFor("up"    )<CR>
	noremap    <buffer>  <silent>  <LocalLeader>in         :call C_CodeFor("down"    )<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>in         :call C_CodeFor("down","v")<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>in    <Esc>:call C_CodeFor("down"    )<CR>
	"
	" ---------- snippet menu : snippets -----------------------------------------
	"
	noremap    <buffer>  <silent>  <LocalLeader>nr         :call C_CodeSnippet("r")<CR>
	noremap    <buffer>  <silent>  <LocalLeader>nv         :call C_CodeSnippet("view")<CR>
	noremap    <buffer>  <silent>  <LocalLeader>nw         :call C_CodeSnippet("w")<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>nw    <Esc>:call C_CodeSnippet("wv")<CR>
	noremap    <buffer>  <silent>  <LocalLeader>ne         :call C_CodeSnippet("e")<CR>
	"
	inoremap   <buffer>  <silent>  <LocalLeader>nr    <Esc>:call C_CodeSnippet("r")<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>nv    <Esc>:call C_CodeSnippet("view")<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>nw    <Esc>:call C_CodeSnippet("w")<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>ne    <Esc>:call C_CodeSnippet("e")<CR>
	"
	" ---------- snippet menu : prototypes ---------------------------------------
	"
	noremap    <buffer>  <silent>  <LocalLeader>np        :call C_ProtoPick("function")<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>np        :call C_ProtoPick("function")<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>np   <Esc>:call C_ProtoPick("function")<CR>
	"                                                                                 
	noremap    <buffer>  <silent>  <LocalLeader>nf        :call C_ProtoPick("function")<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>nf        :call C_ProtoPick("function")<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>nf   <Esc>:call C_ProtoPick("function")<CR>
	"
	noremap    <buffer>  <silent>  <LocalLeader>nm        :call C_ProtoPick("method")<CR>
	vnoremap   <buffer>  <silent>  <LocalLeader>nm        :call C_ProtoPick("method")<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>nm   <Esc>:call C_ProtoPick("method")<CR>
	"
	noremap    <buffer>  <silent>  <LocalLeader>ni         :call C_ProtoInsert()<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>ni    <Esc>:call C_ProtoInsert()<CR>
	"
	noremap    <buffer>  <silent>  <LocalLeader>nc         :call C_ProtoClear()<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>nc    <Esc>:call C_ProtoClear()<CR>
	"
	noremap    <buffer>  <silent>  <LocalLeader>ns         :call C_ProtoShow()<CR>
	inoremap   <buffer>  <silent>  <LocalLeader>ns    <Esc>:call C_ProtoShow()<CR>
	"
	" ---------- C++ menu ----------------------------------------------------
	"
	" ---------- run menu --------------------------------------------------------
	"
	noremap  <buffer>  <silent>  <LocalLeader>rc         :call C_Compile()<CR>:call C_HlMessage()<CR>
	inoremap <buffer>  <silent>  <LocalLeader>rc    <C-C>:call C_Compile()<CR>:call C_HlMessage()<CR>
	noremap  <buffer>  <silent>  <LocalLeader>rl         :call C_Link()<CR>:call C_HlMessage()<CR>
	inoremap <buffer>  <silent>  <LocalLeader>rl    <C-C>:call C_Link()<CR>:call C_HlMessage()<CR>
	noremap  <buffer>  <silent>  <LocalLeader>rr         :call C_Run()<CR>
	inoremap <buffer>  <silent>  <LocalLeader>rr    <C-C>:call C_Run()<CR>
	noremap  <buffer>  <silent>  <LocalLeader>re         :call <SID>ExeToRun()<CR>
	inoremap <buffer>  <silent>  <LocalLeader>re    <C-C>:call <SID>ExeToRun()<CR>
	noremap  <buffer>            <LocalLeader>ra         :CCmdlineArgs<Space>
	inoremap <buffer>            <LocalLeader>ra    <C-C>:CCmdlineArgs<Space>
	noremap  <buffer>  <silent>  <LocalLeader>rd         :call <SID>Debugger()<CR>
	inoremap <buffer>  <silent>  <LocalLeader>rd    <C-C>:call <SID>Debugger()<CR>
	noremap  <buffer>  <silent>  <LocalLeader>rp         :call C_SplintCheck()<CR>:call C_HlMessage()<CR>
	inoremap <buffer>  <silent>  <LocalLeader>rp    <C-C>:call C_SplintCheck()<CR>:call C_HlMessage()<CR>
	noremap  <buffer>  <silent>  <LocalLeader>rpa        :call C_SplintArguments()<CR>
	inoremap <buffer>  <silent>  <LocalLeader>rpa   <C-C>:call C_SplintArguments()<CR>
	noremap  <buffer>  <silent>  <LocalLeader>rcc        :call C_CppcheckCheck()<CR>:call C_HlMessage()<CR>
	inoremap <buffer>  <silent>  <LocalLeader>rcc   <C-C>:call C_CppcheckCheck()<CR>:call C_HlMessage()<CR>
	noremap  <buffer>  <silent>  <LocalLeader>rccs       :call C_CppcheckSeverityInput()<CR>
	inoremap <buffer>  <silent>  <LocalLeader>rccs  <C-C>:call C_CppcheckSeverityInput()<CR>

	noremap  <buffer>  <silent>  <LocalLeader>ri         :call C_Indent()<CR>
	inoremap <buffer>  <silent>  <LocalLeader>ri    <C-C>:call C_Indent()<CR>
	noremap  <buffer>  <silent>  <LocalLeader>rh         :call C_Hardcopy()<CR>
	inoremap <buffer>  <silent>  <LocalLeader>rh    <C-C>:call C_Hardcopy()<CR>
	vnoremap <buffer>  <silent>  <LocalLeader>rh         :call C_Hardcopy()<CR>
	noremap  <buffer>  <silent>  <LocalLeader>rs         :call C_Settings(0)<CR>
	inoremap <buffer>  <silent>  <LocalLeader>rs    <C-C>:call C_Settings(0)<CR>
	"
	if has("unix")
		noremap  <buffer>  <silent>  <LocalLeader>rx       :call C_XtermSize()<CR>
		inoremap <buffer>  <silent>  <LocalLeader>rx  <C-C>:call C_XtermSize()<CR>
	endif
	noremap  <buffer>  <silent>  <LocalLeader>ro         :call C_Toggle_Gvim_Xterm()<CR>
	inoremap <buffer>  <silent>  <LocalLeader>ro    <C-C>:call C_Toggle_Gvim_Xterm()<CR>
	"
	" Abraxas CodeCheck (R)
	"
	if s:C_CodeCheckIsExecutable==1
		noremap  <buffer>  <silent>  <LocalLeader>rk       :call C_CodeCheck()<CR>:call C_HlMessage()<CR>
		inoremap <buffer>  <silent>  <LocalLeader>rk  <C-C>:call C_CodeCheck()<CR>:call C_HlMessage()<CR>
		noremap  <buffer>  <silent>  <LocalLeader>rka      :call C_CodeCheckArguments()<CR>
		inoremap <buffer>  <silent>  <LocalLeader>rka <C-C>:call C_CodeCheckArguments()<CR>
	endif
	" ---------- plugin help -----------------------------------------------------
	"
	noremap  <buffer>  <silent>  <LocalLeader>hp         :call C_HelpCsupport()<CR>
	inoremap <buffer>  <silent>  <LocalLeader>hp    <C-C>:call C_HelpCsupport()<CR>
	noremap  <buffer>  <silent>  <LocalLeader>hm         :call C_Help("m")<CR>
	inoremap <buffer>  <silent>  <LocalLeader>hm    <C-C>:call C_Help("m")<CR>
	"
	" ---------- tool box --------------------------------------------------------
	"
	if s:C_UseToolbox == 'yes'
		call mmtoolbox#tools#AddMaps ( s:C_Toolbox )
	endif
	"
	"-------------------------------------------------------------------------------
	" settings - reset local leader
	"-------------------------------------------------------------------------------
	if ! empty ( g:C_MapLeader )
		if exists ( 'll_save' )
			let g:maplocalleader = ll_save
		else
			unlet g:maplocalleader
		endif
	endif
	"
	"-------------------------------------------------------------------------------
	" templates
	"-------------------------------------------------------------------------------
	if s:C_Ctrl_j == 'on'
		nnoremap  <buffer>  <silent>  <C-j>       i<C-R>=C_JumpCtrlJ()<CR>
		inoremap  <buffer>  <silent>  <C-j>  <C-G>u<C-R>=C_JumpCtrlJ()<CR>
	endif
	"
	" ----------------------------------------------------------------------------
	"
	call mmtemplates#core#CreateMaps ( 'g:C_Templates', g:C_MapLeader, 'do_special_maps', 'do_del_opt_map' )
	"
endfunction    " ----------  end of function s:CreateAdditionalMaps  ----------

"-------------------------------------------------------------------------------
" s:Initialize : Initialize templates, menus, and maps.   {{{1
"-------------------------------------------------------------------------------
function! s:Initialize ( ftype )
	if ! exists( 'g:C_Templates' ) |
		if s:C_LoadMenus == 'yes' | call C_CreateGuiMenus()
		else                      | call s:RereadTemplates()
		endif |
	endif |
	call s:CreateAdditionalMaps()
	call s:CheckTemplatePersonalization()
endfunction    " ----------  end of function s:Initialize  ----------

"-------------------------------------------------------------------------------
" === Setup: Templates, toolbox and menus ===   {{{1
"-------------------------------------------------------------------------------

"------------------------------------------------------------------------------
"  setup the toolbox   {{{2
"------------------------------------------------------------------------------
"
if s:C_UseToolbox == 'yes'
	"
	let s:C_Toolbox = mmtoolbox#tools#NewToolbox ( 'C' )
	call mmtoolbox#tools#Property ( s:C_Toolbox, 'mapleader', g:C_MapLeader )
	"
	call mmtoolbox#tools#Load ( s:C_Toolbox, s:C_ToolboxDir )
	"
	" debugging only:
	"call mmtoolbox#tools#Info ( s:C_Toolbox )
	"
endif

"------------------------------------------------------------------------------
"  show / hide the C-Support menus   {{{2
"------------------------------------------------------------------------------

call C_ToolMenu()

if s:C_LoadMenus == 'yes' && s:C_CreateMenusDelayed == 'no'
	call C_CreateGuiMenus()
endif

"------------------------------------------------------------------------------
"  lazy initialization / automated header insertion   {{{2
"
"			Vim always adds the {cmd} after existing autocommands,
"			so that the autocommands execute in the order in which
"			they were given. The order matters!
"------------------------------------------------------------------------------
if has("autocmd")
	augroup CSupport

	" adjust header filetype:
	" *.h has filetype 'cpp' by default, this can be changed to 'c'
	if s:C_TypeOfH=='c'
		autocmd BufNewFile,BufEnter  *.h  set filetype=c | " COMMENT: g:C_TypeOfH == 'c'
	endif

	" create menus and maps
	autocmd FileType c    call s:Initialize('c')
	autocmd FileType cpp  call s:Initialize('cpp')

	" insert file header
	if !exists( 'g:C_Styles' )
		" template styles are the default settings
		autocmd BufNewFile *  if &filetype == 'c'   && expand("%:e") !~ 'ii\?' | call s:InsertFileHeader() | endif
		autocmd BufNewFile *  if &filetype == 'cpp' && expand("%:e") !~ 'ii\?' | call s:InsertFileHeader() | endif
	else
		" template styles are related to file extensions
		for [ pattern, stl ] in items( g:C_Styles )
			exe "autocmd BufNewFile,BufReadPost ".pattern." call mmtemplates#core#ChooseStyle ( g:C_Templates, '".stl."')"
			exe "autocmd BufNewFile             ".pattern." call s:InsertFileHeader()"
		endfor
	endif

	" highlight jump targets after opening file
	exe 'autocmd BufReadPost *.'.join( s:C_SourceCodeExtensionsList, '\|*.' )
				\     .' call C_HighlightJumpTargets()'

	augroup END
endif " has("autocmd")
" }}}2
"-------------------------------------------------------------------------------

" }}}1
"-------------------------------------------------------------------------------

"=====================================================================================
" vim: tabstop=2 shiftwidth=2 foldmethod=marker
