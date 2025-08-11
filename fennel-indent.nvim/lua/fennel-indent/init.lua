local M = {}

function M.setup(opts)
  require("fennel-indent.config").set(opts)
end

function M.indentexpr()
  return require("fennel-indent.indentexpr")(vim.v.lnum)
end

return M