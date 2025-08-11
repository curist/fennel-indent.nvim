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

return M