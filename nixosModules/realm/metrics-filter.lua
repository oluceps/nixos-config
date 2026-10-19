-- allowed_paths is generated from the declared endpoints; no caller-selected backend.
local function decode(value)
  local out, i = {}, 1
  while i <= #value do
    local c = value:sub(i, i)
    if c == '%' then
      local hex = value:sub(i + 1, i + 2)
      if not hex:match('^%x%x$') then return nil end
      c, i = string.char(tonumber(hex, 16)), i + 2
    elseif c == '+' then
      c = ' '
    end
    if c == '\0' or c == '\r' or c == '\n' then return nil end
    out[#out + 1], i = c, i + 1
  end
  return table.concat(out)
end

function envoy_on_request(handle)
  local headers = handle:headers()
  local uri = headers:get(':path') or ''
  local path, query = uri:match('^([^?]*)%??(.*)$')
  local rule = allowed_paths[path]
  local function deny()
    handle:respond({ [':status'] = '403', ['content-type'] = 'text/plain' }, 'Forbidden\n')
  end
  if headers:get(':method') ~= 'GET' or not rule then deny(); return end
  if rule == true then
    if query ~= '' then deny() end
    return
  end
  local params = {}
  for pair in (query .. '&'):gmatch('(.-)&') do
    local key, value = pair:match('^([^=]+)=(.*)$')
    key, value = key and decode(key), value and decode(value)
    if not key or not value or params[key] or (key ~= 'module' and key ~= 'target') then
      deny(); return
    end
    params[key] = value
  end
  if not params.module or not params.target or not rule[params.module] or not rule[params.module][params.target] then
    deny()
  end
end
