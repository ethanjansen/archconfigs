-- load defaults i.e lua_lsp
local configs = require("nvchad.configs.lspconfig")

-- Servers
local servers = {
  html = {},
  cssls = {},
  marksman = {},
  bashls = {},
  denols = {},
  jsonls = {},
  yamlls = {},
  clangd = {}, 

  pylsp = {
    settings = {
      pylsp = {
        plugins = {
          pycodestyle = {
            maxLineLength = 150,
          },
          flake8 = {
            maxLineLength = 150,
          },
        },
      },
    },
  },

  texlab = {
    settings = {
      texlab = {
        auxDirectory = ".",
        bibtexFormatter = "texlab",
        build = {
          args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
          executable = "latexmk",
          forwardSearchAfter = false,
          onSave = false,
        },
        chktex = {
          onEdit = false,
          onOpenAndSave = false,
        },
        diagnosticsDelay = 300,
        formatterLineLength = 80,
        forwardSearch = {
          args = {}
        },
        latexFormatter = "latexindent",
          latexindent = {
            modifyLineBreaks = false
          },
        },
      },
    },
}


-- lsps with default config
for name, opts in pairs(servers) do
  opts.on_attach = configs.on_attach
  opts.on_init = configs.on_init
  opts.capabilities = configs.capabilities

  require("lspconfig")[name].setup(opts)
end

-- configuring single server, example: typescript
-- lspconfig.ts_ls.setup {
--   on_attach = nvlsp.on_attach,
--   on_init = nvlsp.on_init,
--   capabilities = nvlsp.capabilities,
-- }
