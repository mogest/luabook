# Luabook

Luabook is a Neovim plugin that lets you write Lua in a file mixed with other markdown text, and execute it with
the results appearing in the file.

It also includes an HTTP library for easy connection to APIs.

## Alpha software

Luabook is functional but at the start of its journey.  Please don't rely on it for mission critical work just at
the moment.  The `lb` API may completely change based upon feedback so consider it unstable.

## Installation

With your favourite plugin manager:

Using lazy
```
{
  'mogest/luabook',
  dependencies = { 'nvim-lua/plenary.nvim' }
}
```

Using packer
```
use {
  'mogest/luabook',
  requires = { { 'nvim-lua/plenary.nvim' } }
}
```

Using vim-plug
```
Plug 'nvim-lua/plenary.nvim'
Plug 'mogest/luabook'
```

If you want to use the HTTP library, make sure you've got the `curl` and `jq` binaries installed on your system.

## Usage

Create a file, preferably one that ends with `.luabook` to get formatting but this is optional.

Add a Lua code block in between triple backticks that returns a value:

````
```
  return 1 + 2
```
````

Run `:Luabook` and the code will be executed, with the result being placed inline.

````
```
  return 1 + 2
```
### Output

    3
````

## Samples

There are no samples yet :)  But will be one day...

## Lua

Luabook will display whatever is `return`ed from the code block.  Use the `inspect` function to print tables.

If a second value is returned, it's expected to be a string that indicates the first value's MIME type.

Global variables defined within a code block are available in the blocks below it.  Variables defined with `local`
will be local to the code block.

### Sandbox

Luabook runs Lua in a sandbox to protect you from malicious scripts.  That means some functions in Lua's standard
library are not available, such as the file commands.  The `vim` global variable is also not available.

However Luabook replaces the file functions with safe versions; see below for details.

## Luabook extensions

Luabook provides useful functions under the `lb` global variable.

### Storage

#### `lb.store.read(key)`

Reads and returns the data stored in the store named `key`.  Data is stored as JSON so can be any data type
represented by JSON.  If the key is not found, it will return `nil`.

#### `lb.store.write(key, data)`

Writes the `data` in the store named `key`.  Data is stored as JSON so can be any data type represented by JSON.

#### `lb.store.cache(key, function() -> data)`

Reads and returns the data stored in the store named `key`, but if `key` does not exist, run the supplied function
and store the data in `key` instead, returning the function's result.

#### `lb.store.cache_with_expiry(key, function() -> (data, expires_in_seconds))`

Reads and returns the data stored in the store named `key`, but if `key` does not exist or is expired, run the
supplied function and cache the result.  The function must return the data and an expiry time in seconds from now.  

```lua
local value, expires_in, cached_flag = lb.store.cache_with_expiry("weather_data", function()
  local response = lb.http.get("https://weather.example/api/current.json")

  if not response.success then
    return nil, 0
  end

  -- Cache the response for one hour
  return response.decoded(), 3600
end)

return "Weather is: " .. inspect(value) .. "\n" ..
    "This expires in " .. inspect(expires_in) .. " seconds.\n" ..
    "This data came from the cache? " .. inspect(cached_flag)
```

### HTTP

#### Requests

 * `lb.http.get(url, opts)`
 * `lb.http.head(url, opts)`
 * `lb.http.post(url, opts)`
 * `lb.http.put(url, opts)`
 * `lb.http.patch(url, opts)`
 * `lb.http.delete(url, opts)`
 * `lb.http.request(method, url, opts)`

Makes an HTTP request to `url`.  POST/PUT/PATCH/DELETE requests must include an option that specifies a body for
the request.

| Table key | Description |
| --------- | ----------- |
| json      | Body data: encodes the value with JSON and adds a `Content-Type: application/json' header |
| urlencoded | Body data: encodes the value, which must be a table, with URL encoding, and adds a `Content-Type: application/x-www-form-encoded` header |
| data      | Body data: treat the value as the raw binary body |
| headers   | Takes a table of key/values and adds these as headers to the request |
| auth      | `{username = "", password = ""}` will include a Basic Authorization header<br>`{bearer = ""}` will include a Bearer Authorization header<br>`{token_type = "Bearer", access_token = "XYZ"}` will include XYZ as a Bearer Authorization header |
| insecure  | If set `true`, will allow connections to HTTPS servers where the certificate is not valid.  Defaults to `false`. |

Returns a response table which looks like this:

```
{
    version = "HTTP/1.1",
    status_code = "200",
    success = true,
    headers = { ["content-type"] = "application/json; charset=utf-8" },
    type = "application/json",
    body_table = { "123" },
    decoded = function() end,
}
```

 * `success` is true for any 2xx status code, and false otherwise.
 * `body_table` is a table of the body, with each line an element in the ordered table.
 * `decoded` is only included for json responses.  When called, it will return a JSON-decoded representation of the
body.

#### `lb.http.inspect(response, opts)`

Returns a textual representation of the HTTP response.  `opts` is a table.

 * `{jq = true}` will run the body through the jq application.  `{jq = ".results[4]"}` will pass the filter string to
jq and return the fifth element of the `results` value.
 * `{headers = true}` will return the HTTP response headers along with the body in the output.

### Encoding

#### `lb.url.encode(data)`

URL-encodes the string `data` and returns the result.

#### `lb.url.encode_query(query)`

URL-encodes the query contained in the table `query` and returns a string.

```
> lb.url.encode_query({first = "one", second = "two!"})
"first=one&second=two%21"
```

### OAuth 2

#### `lb.oauth2.request_token_with_client_credentials(url, client_id, client_secret, opts)`

Makes an OAuth 2 request for a token with client credentials.  The `url` is the endpoint (typically a URL with
the path `/oauth2/token`).

`opts` is a table.  If `{ cache = "auth" }` is specified, the access token will be cached in the store using
`"auth"` as the key for the lifetime of the access token.

## Contributing

Luabook is early in its development, and welcomes PRs.  If you're thinking about writing something big, consider
discussing in an issue first.
