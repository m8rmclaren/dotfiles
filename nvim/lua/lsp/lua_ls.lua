-- TODO can't get this style of config working
return {
    cmd = { "lua-language-server" },
    filetypes = "lua",
    settings = {
        Lua = {
            diagnostics = {
                -- tell the language server to recognize the `vim` global
                globals = { "vim" },
            },
        },
    }
}
