local json = require("json")
local util = require("lunamark.util")

local M = {}

function M.new(writer, options)
  local options = options or {}

  local parsers -- we fill this later

  local function parse_block(block) return parsers[block.t](block.c) end

  -- concat is an optional argument
  local function parse_blocks(blocks, concat)
    local outputs = {}
    local length = #blocks
    for i,block in ipairs(blocks) do
      table.insert(outputs, parse_block(block))
      if concat and i < length then table.insert(outputs, concat) end
    end
    return outputs -- , concat
  end

  parsers = {
    Str = function(c) return c end,
    Space = function(c) return writer.space end,
    Para = function(c) return writer.paragraph(parse_blocks(c)) end,
    Emph = function(c) return writer.emphasis(parse_blocks(c)) end,
    Strong = function(c) return writer.strong(parse_blocks(c)) end,

    Header = function(c)
      -- TODO handle attributes
      return writer.header(parse_blocks(c[3]), c[1])
    end,
  }

  local function parse_table(json_table)
    return parse_blocks(json_table.blocks, writer.interblocksep)
  end

  parse_pandoc =
    function(inp)
      local json_table = json.decode(inp)
      local result = { writer.start_document(), parse_table(json_table), writer.stop_document() }
      return util.rope_to_string(result), writer.get_metadata()
    end

  return parse_pandoc
end

return M
