local Sandbox = require("luabook.sandbox")
local api = require("luabook.api")

local M = {}

local function process(bufnr, start, env)
    local content = vim.api.nvim_buf_get_lines(bufnr, start, -1, false)

    local count = #content

    if count == 0 then
        return
    end

    local index = 1

    while index <= count do
        if content[index] == "```" then
            index = index + 1
            break
        end
        index = index + 1
    end

    local code = ""
    local insertAt = -1
    local deleteTo = -1

    while index <= count do
        if content[index] == "```" then
            index = index + 1
            insertAt = index
            deleteTo = index

            if index <= count and content[index]:match("^### Output") then
                index = index + 1
                while index <= count do
                    local line = content[index]
                    if line ~= "" and line:sub(1, 2) ~= "  " then
                        break
                    end
                    index = index + 1
                end
                deleteTo = index
            end

            break
        end

        code = code .. content[index] .. "\n"
        index = index + 1
    end

    if code == "" then
        return
    end

    local output
    local output_type
    local f, err = load(code, nil, "t", env)

    local lines = { "### Output", "  " }
    local i = 3

    if f == nil then
        output = err
        output_type = "error"
        lines[i] = "  Error compiling code:"
        lines[i + 1] = "  "
        i = i + 2
    else
        local success
        success, output, output_type = pcall(f)
        if not success then
            lines[i] = "  Error running code:"
            lines[i + 1] = "  "
            i = i + 2
            output_type = "error"
        end
    end

    if output ~= nil then
        if output_type then
            lines[1] = "### Output (" .. output_type .. ")"
        end

        if type(output) == "table" then
            for _, v in ipairs(output) do
                lines[i] = "    " .. tostring(v)
                i = i + 1
            end
            lines[i] = ""
        else
            for line in tostring(output):gmatch("([^\n]*)\n?") do
                lines[i] = "    " .. line
                i = i + 1
            end
        end
    end

    if insertAt ~= -1 then
        insertAt = start + insertAt - 1
        deleteTo = start + deleteTo - 1
    end

    vim.api.nvim_buf_set_lines(bufnr, insertAt, deleteTo, false, lines)

    return start + index - (deleteTo - insertAt) + #lines - 1
end

function M.start()
    local bufnr = 0
    local start = 0

    local env = Sandbox.new()
    env.lb = api

    while true do
        local next = process(bufnr, start, env)
        if next == nil then
            break
        end
        start = next
    end
end

return M
