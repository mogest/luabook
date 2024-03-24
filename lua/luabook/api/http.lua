local Job = require("plenary.job")
local URL = require("luabook.api.url")

local M = {}

local function curl(args, request_body, opts)
    table.insert(args, "-i")
    table.insert(args, "-s")

    if opts.insecure then
        table.insert(args, "-k")
    end

    if opts and opts.auth then
        if opts.auth.username or opts.auth.password then
            table.insert(args, "-u")
            table.insert(args, opts.auth.username .. ":" .. opts.auth.password)
        elseif opts.auth.bearer then
            table.insert(args, "--oauth2-bearer")
            table.insert(args, opts.auth.bearer)
        elseif opts.auth.token_type == "Bearer" and opts.auth.access_token then
            table.insert(args, "--oauth2-bearer")
            table.insert(args, opts.auth.access_token)
        else
            error("auth table specified with an unknown type, must contain username and password or bearer")
        end
    end

    if opts and opts.headers then
        for k, v in pairs(opts.headers) do
            table.insert(args, "-H")
            table.insert(args, k .. ": " .. v)
        end
    end

    local output, code = Job:new({
        command = "curl",
        args = args,
        writer = request_body,
    }):sync()

    if code ~= 0 then
        error(string.format("curl execution failed with code %s: %s", code, table.concat(output, "\n")))
    end

    local response = {}

    local headers = {}
    local body = {}
    local is_header = true

    local status = string.gmatch(output[1], "([^ ]+)")
    response.version = status()
    response.status_code = status()
    response.success = response.status_code:match("^2") ~= nil

    for index = 2, #output do
        local line = output[index]

        if is_header then
            if line == "" then
                is_header = false
            else
                string.gsub(line, "(.-):%s*(.+)", function(k, v)
                    headers[k:lower()] = v
                end)
            end
        else
            table.insert(body, line)
        end

        index = index + 1
    end

    response.full_output_table = output
    response.headers = headers
    response.body_table = body

    if headers["content-type"] then
        response.type = headers["content-type"]:match("([^;]+)")
    else
        response.type = "text/plain"
    end

    if response.type == "application/json" then
        response.decoded = function()
            return vim.fn.json_decode(table.concat(response.body_table, "\n"))
        end
    end

    return response
end

function M.request(method, url, opts)
    local args = { "-X", method, "--url", url }
    local body

    opts = opts or {}

    if method == "GET" or method == "HEAD" then
        body = nil
    elseif opts.json then
        table.insert(args, "-H")
        table.insert(args, "Content-Type: application/json")
        table.insert(args, "--json")
        table.insert(args, "@-")
        body = vim.fn.json_encode(opts.json)
    elseif opts.urlencoded then
        table.insert(args, "-H")
        table.insert(args, "Content-Type: application/x-www-form-urlencoded")
        table.insert(args, "--data")
        table.insert(args, "@-")
        body = URL.encode_query(opts.urlencoded)
    elseif opts.data then
        table.insert(args, "--data-binary")
        table.insert(args, "@-")
        body = opts.data
    else
        error("Specify either json, urlencoded, or data")
    end

    return curl(args, body, opts)
end

function M.get(url, opts)
    return M.request("GET", url, opts)
end

function M.head(url, opts)
    return M.request("HEAD", url, opts)
end

function M.post(url, opts)
    return M.request("POST", url, opts)
end

function M.put(url, opts)
    return M.request("PUT", url, opts)
end

function M.patch(url, opts)
    return M.request("PATCH", url, opts)
end

function M.delete(url, opts)
    return M.request("DELETE", url, opts)
end

function M.inspect(response, opts)
    opts = opts or {}

    if opts.jq then
        local output
        local code
        local jqargs = {}

        if type(opts.jq) == "string" then
            jqargs = { opts.jq }
        end

        output, code = Job:new({
            command = "jq",
            args = jqargs,
            writer = response.body_table,
        }):sync()

        if code ~= 0 then
            error(string.format("jq execution failed with code %s: %s", code, table.concat(output, "\n")))
        end

        return output, "application/json"
    end

    if opts.headers then
        return response.full_output_table, response.type
    end

    return response.body_table, response.type
end

return M
