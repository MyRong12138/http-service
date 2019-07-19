local typedefs = require "kong.db.schema.typedefs"

return {
  name = "http-service",
  fields = {
    { consumer=typedefs.no_consumer },
    { config = {
        type = "record",
        fields = {
          { get_role_http_addr = typedefs.url({ required = true }) },
          { get_api_http_addr = typedefs.url({ required = true }) },
    }, }, },
  },
}
