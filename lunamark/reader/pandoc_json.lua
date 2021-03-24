local json = require("json")
local util = require("lunamark.util")

local M = {}

function M.new(writer, options)
  options = options or {}

  parse_pandoc =
    function(inp)
      local result = { writer.start_document(), "output goes here", writer.stop_document() }
      return util.rope_to_string(result), writer.get_metadata()
    end

  return parse_pandoc
end

return M
