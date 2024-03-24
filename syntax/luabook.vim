if exists("b:current_syntax")
  finish
endif

runtime! syntax/markdown.vim
unlet! b:current_syntax

syntax include @luabookCode syntax/lua.vim
unlet! b:current_syntax
syntax include @luabookJson syntax/json.vim
unlet! b:current_syntax
syntax include @luabookHtml syntax/html.vim
unlet! b:current_syntax

syntax region luabookCodeHi matchgroup=luabookDelimiter start="^```$" end="^```$" keepend contains=@luabookCode
syntax region luabookJsonHi matchgroup=luabookDelimiter start="^### Output (application/json)" matchgroup=NONE end="^$" keepend contains=@luabookJson
syntax region luabookHtmlHi matchgroup=luabookDelimiter start="^### Output (text/html)" matchgroup=NONE end="^$" keepend contains=@luabookHtml
syntax region luabookErrorHi matchgroup=luabookDelimiter start="^### Output (error)" matchgroup=NONE end="^$" keepend

highlight def link luabookDelimiter Special
highlight def link luabookErrorHi ErrorMsg
