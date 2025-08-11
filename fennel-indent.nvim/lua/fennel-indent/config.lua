local config = {
  semantic_alignment = { ["if"] = true, ["when"] = true }
}

local M = {}

function M.get()
  return config
end

function M.set(opts)
  config = vim.tbl_deep_extend('force', config, opts or {})
end

function M.get_semantic_alignment()
  return config.semantic_alignment
end

return M