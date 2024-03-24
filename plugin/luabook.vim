if exists("g:loaded_luabook")
    finish
endif
let g:loaded_luabook = 1

command Luabook lua require('luabook').start()
