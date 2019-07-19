local BasePlugin = require "kong.plugins.base_plugin"
local HttpService = BasePlugin:extend()

local kong = kong
local url = require "socket.url"
local http = require "resty.http"

HttpService.PRIORITY = 1000
HttpService.VERSION="0.1.0"

function HttpService:new()
  HttpService.super.new(self, "http-service")
end
--获取请求路径信息
local function parse_url(host_url)
  local parsed_url

  parsed_url = url.parse(host_url)
  if not parsed_url.port then
    if parsed_url.scheme == "http" then
      parsed_url.port = 80
    elseif parsed_url.scheme == "https" then
      parsed_url.port = 443
    end
  end

  if not parsed_url.path then
    parsed_url.path = "/"
  end

  return parsed_url
end

--发送请求
local function send_payload(url,body)
  local getRequestUrl=parse_url(url)

  local host = getRequestUrl.host
  local port = tonumber(getRequestUrl.port)

  local httpc = http.new()
  httpc:set_timeout(60000)

  ok, err = httpc:connect(host, port)
  if not ok then
    return nil, "failed to connect to " .. host .. ":" .. tostring(port) .. ": " .. err
  end

  if getRequestUrl.scheme == "https" then
    local _, err = httpc:ssl_handshake(true, host, false)
    if err then
      return nil, "failed to do SSL handshake with " ..
                  host .. ":" .. tostring(port) .. ": " .. err
    end
  end

  local res, err = httpc:request({
    method = "POST",
    path = getRequestUrl.path,
    query = getRequestUrl.query,
    headers = {
      ["Host"] = getRequestUrl.host,
      ["Content-Type"] = "application/x-www-form-urlencoded",
      ["Authorization"] = getRequestUrl.userinfo and (
        "Basic " .. ngx_encode_base64(getRequestUrl.userinfo)
      ),
    },
    body = body,
  })
  if not res then
    return nil, "failed request to " .. host .. ":" .. tostring(port) .. ": " .. err
  end

  local response_body = res:read_body()
  local success = res.status == 200
  local err_msg

  if not success then
    err_msg = "request to " .. host .. ":" .. tostring(port) ..
              " returned status code " .. tostring(res.status) .. " and body " ..
              response_body
  end

  ok, err = httpc:set_keepalive(keepalive)
  if not ok then
    kong.log.err("failed keepalive for ", host, ":", tostring(port), ": ", err)
  end

  return response_body,err_msg

end

--解析json
function get_json(body)

  local cjson = require("cjson")
  local json=cjson.new()
  kong.log("解析json开始")
  local table = json.decode(body)

  if table ~= nil and next(table) ~= nil then
  kong.log("取得json"..tostring(table))
  end

  for k, v in pairs(table["RoleList"]) do
    --print(k .. " : " .. v)
  kong.log("\njson存储的值名为："..k.."\n值为："..tostring(v).."\n")
  end
end

function HttpService:access(conf)
  HttpService.super.access(self)
    --print(k .. " : " .. v)
  --kong.log("\nkong存储的值名为："..k.."\n值为："..tostring(v).."\n")
--return kong.response.exit(500, { message = tostring("nihao") })
  kong.log("两个网址分别为"..tostring(conf.get_role_http_addr).."\n"..tostring(conf.get_api_http_addr).."\n")
  local body,err=send_payload(conf.get_role_http_addr,"uid=1&tid=1")
  if type(err)=="nil" then
  kong.log("返回数据为"..tostring(body).."\n")
  else
  kong.log("返回错误信息为"..tostring(err).."\n")
  end

  get_json(body)

end

return HttpService
