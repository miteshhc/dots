---@diagnostic disable: undefined-global           -- undefined global vim
local lspconfig = require 'lspconfig'
local configs = require 'lspconfig.configs'

require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = { 'pyright', 'clangd', 'gopls', 'rust_analyzer' },
})

-- -----------------------
-- Custom lsp
-- -----------------------
if not configs.qml6_lsp then
    configs.qml6_lsp = {
        default_config = {
            autostart = false,
            cmd = {'qmlls6'},
            filetypes = {'qml'},
            root_dir = function(fname)
                return lspconfig.util.find_git_ancestor(fname) or vim.fn.getcwd()
            end,
            settings = {},
        },
    }
end

-- -----------------------
-- Rust
-- -----------------------
lspconfig.rust_analyzer.setup({
    autostart = false,
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_dir = function(fname)
        local cargo_crate_dir = lspconfig.util.root_pattern 'Cargo.toml'(fname)
        local cmd = 'cargo metadata --no-deps --format-version 1'
        if cargo_crate_dir ~= nil then
            cmd = cmd .. ' --manifest-path ' .. lspconfig.util.path.join(cargo_crate_dir, 'Cargo.toml')
        end
        local cargo_metadata = vim.fn.system(cmd)
        local cargo_workspace_dir = nil
        if vim.v.shell_error == 0 then
            cargo_workspace_dir = vim.fn.json_decode(cargo_metadata)['workspace_root']
        end
        return cargo_workspace_dir
        or cargo_crate_dir
        or lspconfig.util.root_pattern 'rust-project.json'(fname)
        or lspconfig.util.find_git_ancestor(fname)
    end,
    settings = {
        ["rust-analyzer"] = {}
    }
})

-- -----------------------
-- Completions
-- -----------------------
local cmp = require('cmp')

cmp.setup({
    sources = {
        {name = 'path'},
        {name = 'nvim_lsp'},
        {name = 'nvim_lua'},
        {name = 'buffer', keyword_length = 2},
    },

    mapping = cmp.mapping.preset.insert({
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<C-Space>'] = cmp.mapping.complete(),

        -- Better mapping
        ['<C-n>'] = function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end,
        ['<C-p>'] = function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end
    }),

    vim.diagnostic.config({
        virtual_text = {
            prefix = '▎',-- Could be '●', '▎', 'x'
        },
        signs = true,
        severity_sort = false,
    }),

    window = {
        -- completion = cmp.config.window.bordered({
        --     winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
        -- }),
        -- documentation = cmp.config.window.bordered({
        --     winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
        -- }),
    },
    experimental = {
        ghost_text = true,
    }
})

-- -----------------------
-- Setup lsp servers
-- -----------------------
local on_attach = require('plugins.lsp_opts').on_attach

require('mason-lspconfig').setup_handlers({
    function(server)
        local opts = {
            autostart = false,
            on_attach = on_attach
        }
        lspconfig[server].setup(opts)
    end,
})
