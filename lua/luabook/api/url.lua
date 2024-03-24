local M = {}

local function char_to_hex(c)
    local result = ""
    for i = 1, #c do
        result = result .. string.format("%%%02X", string.byte(c, i))
    end
    return result
end

function M.encode(data)
    if data then
        return data:gsub("([^%w _.~-])", char_to_hex):gsub(" ", "+")
    end
end

function M.encode_query(query)
    local output = {}

    for k, v in pairs(query) do
        table.insert(output, M.encode(k) .. "=" .. M.encode(v))
    end

    return table.concat(output, "&")
end

return M
