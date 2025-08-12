-- Default configuration
local default_config = {
  semantic_alignment = {
    'if', 'and', 'or', '..', '->', '->>', '-?>', '-?>>',
    '%', '*', '+', '/', '-', '>=', '//', '<=', '^', '>', '<', '=', 'not=',
  }
}


-- Convert default semantic_alignment vector to set
local function vector_to_set(vec)
  local set = {}
  for _, key in ipairs(vec) do
    set[key] = true
  end
  return set
end

local config = {
  semantic_alignment = vector_to_set(default_config.semantic_alignment)
}

local M = {}

function M.get()
  return config
end

function M.set(opts)
  local merged_opts = vim.tbl_deep_extend('force', default_config, opts or {})

  -- Convert semantic_alignment vector to set format if needed
  if merged_opts.semantic_alignment and vim.tbl_islist(merged_opts.semantic_alignment) then
    merged_opts.semantic_alignment = vector_to_set(merged_opts.semantic_alignment)
  end

  config = merged_opts
end

function M.get_semantic_alignment()
  return config.semantic_alignment
end

return M

