local http = require("luabook.api.http")
local store = require("luabook.api.store")

local M = {}

local function request(url, client_id, client_secret)
	local response = http.post(url, {
		auth = {
			username = client_id,
			password = client_secret,
		},
		urlencoded = {
			grant_type = "client_credentials",
		},
	})

	if response.status_code ~= "200" then
		error(
			string.format(
				"Failed to get token with code %s, body %s",
				response.status_code,
				table.concat(response.body_table, "\n")
			)
		)
	end

	return response.decoded()
end

function M.request_token_with_client_credentials(url, client_id, client_secret, opts)
	if opts and opts.cache then
		local result, expires_in = store.cache_with_expiry(opts.cache, function()
			local result = request(url, client_id, client_secret)
			return result, result.expires_in
		end)

        result.expires_in = expires_in
		return result
	else
		return request(url, client_id, client_secret)
	end
end

return M
