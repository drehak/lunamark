local json = require("rxi-json-lua")
local util = require("lunamark.util")

local M = {}

function M.new(writer, options)
  local options = options or {}

  local parsers -- we fill this later

  local function parse_block(block)
    if block.t == nil then
      util.err("field \"t\" missing in block table - is it a block?")
    end
    -- print(block.t)
    local parser = parsers[block.t]
    if parser == nil then
      util.err("unknown block type '" .. block.t .. "'")
    end
    return parser(block.c)
  end

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
    Plain = function(c) return writer.plain(parse_blocks(c)) end,
    Para = function(c) return writer.paragraph(parse_blocks(c)) end,
    Emph = function(c) return writer.emphasis(parse_blocks(c)) end,
    Strong = function(c) return writer.strong(parse_blocks(c)) end,

    Header = function(c)
      -- TODO handle attributes
      return writer.header(parse_blocks(c[3]), c[1])
    end,

    BulletList = function(c)
      local blocks = {}
      for i,inner in ipairs(c) do
        table.insert(blocks, parse_blocks(inner))
      end
      return writer.bulletlist(blocks)
    end,

    OrderedList = function(c)
      local blocks = {}
      local tight = false
      local startnum = c[1][1]

      for i,inner in ipairs(c[2]) do
        table.insert(blocks, parse_blocks(inner))
      end
      return writer.orderedlist(blocks, tight, startnum)
    end,

    Code = function(c) return writer.code(c[2]) end,
    CodeBlock = function(c)
      local info = ""
      if c[1][2][1] then info = c[1][2][1] end
      return writer.fenced_code(c[2], info)
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
