local json = require("rxi-json-lua")
local util = require("lunamark.util")

local M = {}

M.list_number_styles = {
  Decimal = 1,
  LowerRoman = 2,
  UpperRoman = 3,
  LowerAlpha = 4,
  -- NOTE: Pandoc doesn't recognize upper alpha ordered lists as lists
  UpperAlpha = 5,
}

M.list_number_delims = {
  Period = 1,
  OneParen = 2,
  TwoParens = 3,
}

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
      -- NOTE: writers don't handle number styles and delims yet
      local number_style_str = c[1][2].t
      local number_style = M.list_number_styles[number_style_str]
      if number_style == nil then
        util.err("unknown list number style '" .. number_style_str .. "'")
      end
      local number_delim_str = c[1][3].t
      local number_delim = M.list_number_delims[number_delim_str]
      if number_delim == nil then
        util.err("unknown list number delim '" .. number_delim_str .. "'")
      end

      for i,inner in ipairs(c[2]) do
        table.insert(blocks, parse_blocks(inner))
      end
    return writer.orderedlist(blocks, tight, startnum)
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
