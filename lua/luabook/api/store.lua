local url = require("luabook.api.url")

local M = {}

local mkdir_called = false

local function file_for_key(key)
    if type(key) ~= "string" or key == "" then
        error("key must be a non-empty string")
    end

    local buffer_name = vim.api.nvim_buf_get_name(0)
    if buffer_name == "" then
        error("Buffer must have a name before luabook files can be accessed")
    end

    local path = vim.fn.stdpath("data") .. "/luabook"

    if not mkdir_called then
        vim.fn.mkdir(path, "p")
        mkdir_called = true
    end

    return string.format("%s/data,%s,%s", path, url.encode(buffer_name), url.encode(key))
end

function M.write(key, data)
    vim.fn.writefile({ vim.fn.json_encode(data) }, file_for_key(key))
    return data
end

function M.read(key)
    local path = file_for_key(key)

    local success, data = pcall(function()
        return vim.fn.readfile(path)
    end)

    if not success or data == nil or #data == 0 then
        return
    end

    return vim.fn.json_decode(data[1])
end

function M.cache(key, fn)
    return M.read(key) or M.write(key, fn())
end

function M.cache_with_expiry(key, fn)
    local value = M.read(key)
    local now = os.time()

    if value and value.expires_at and value.expires_at > now then
        return value.data, value.expires_at - now, true
    end

    local data, expires_in = fn()

    if not expires_in or type(expires_in) ~= "number" then
        error("function must return a second value that is the expiry time in seconds")
    end

    if expires_in > 0 then
        M.write(key, { data = data, expires_at = now + expires_in })
    end

    return data, expires_in, false
end

return M
