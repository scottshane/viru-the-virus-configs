local utils = require('utils')
local lsp_utils = require('lsp-setup/utils')

-- setup lsp keymaps
local function setup_lsp_keymaps(_, bufnr)
    -- NOTE(vir): now using fzf-lua
    utils.map("n", "<leader>uS", vim.lsp.buf.references, {silent = true}, bufnr)
    utils.map('n', '<leader>r', vim.lsp.buf.rename, {silent = true}, bufnr)
    utils.map('n', 'K', vim.lsp.buf.hover, {silent = true}, bufnr)
end

-- setup diagnostic keymaps
local function setup_diagnostics_keymaps(_, bufnr)
    utils.map('n', '[e', function() vim.diagnostic.goto_prev({ float = true }) end, {silent = true}, bufnr)
    utils.map('n', ']e', function() vim.diagnostic.goto_next({ float = true }) end, {silent = true}, bufnr)
    utils.map('n', '<leader>e', function() lsp_utils.toggle_diagnostics_list(false) end, {silent = true}, bufnr)
    utils.map('n', '<leader>E', function() lsp_utils.toggle_diagnostics_list(true) end, {silent=true}, bufnr)
end

-- setup auto format
local function setup_formatting_keymaps(client, bufnr)
    if client.server_capabilities.documentFormattingProvider then
        utils.map('n', '<c-f>', function() vim.lsp.buf.format({async=true}) end, {silent = true}, bufnr)
    end

    if client.server_capabilities.documentRangeFormattingProvider then
        utils.map('v', '<c-f>', '<esc><cmd>lua vim.lsp.buf.range_formatting()<cr>', {silent = true}, bufnr)
    end
end

-- setup independent keymaps
local function setup_independent_keymaps(client, bufnr)
    if client.name == 'clangd' then
        utils.map('n', '<f9>', '<cmd>ClangdSwitchSourceHeader<cr>', {}, bufnr)
    elseif client.name == 'pyright' then
        utils.map('n', '<f9>', '<cmd>PyrightOrganizeImports<cr>', {}, bufnr)
    end
end

-- setup buffer options
local function setup_options()
    vim.opt_local.omnifunc = 'v:lua.vim.lsp.omnifunc'
    vim.opt_local.formatoptions = "cqnjlr"
end

-- setup buffer autocommands
local function setup_autocmds(client, bufnr)
    vim.api.nvim_create_augroup('LspPopups', { clear = false })
    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = 'LspPopups' })
    vim.api.nvim_create_autocmd('CursorHold', { group = 'LspPopups', callback = vim.diagnostic.open_float, buffer = bufnr })

    if client.server_capabilities.documentHighlightProvider then
        local group = vim.api.nvim_create_augroup('LspHighlights', { clear = false })
        vim.api.nvim_clear_autocmds({ buffer = bufnr, group = group })

        vim.api.nvim_create_autocmd('CursorHold', { group = group, callback = vim.lsp.buf.document_highlight, buffer = bufnr })
        vim.api.nvim_create_autocmd('CursorMoved', { group = group, callback = vim.lsp.buf.clear_references, buffer = bufnr })
    end

    if client.server_capabilities.documentSymbolProvider then
        local group = vim.api.nvim_create_augroup('LspStates', { clear = false })
		vim.api.nvim_clear_autocmds({ buffer = bufnr, group = group })

        vim.api.nvim_create_autocmd({'InsertLeave', 'BufEnter', 'CursorHold'}, { group = group, callback = lsp_utils.update_tags, buffer = bufnr })
        vim.api.nvim_create_autocmd({'CursorHold', 'CursorMoved'}, { group = group, callback = lsp_utils.update_context, buffer = bufnr })
        vim.api.nvim_create_autocmd('BufDelete', { group = group, callback = function() lsp_utils.clear_buffer_tags(bufnr) end, buffer = bufnr })

        -- first-call
        lsp_utils.update_tags()
    end
end

-- setup buffer highlights
local function setup_highlights()
end

return {
    setup_lsp_keymaps = setup_lsp_keymaps,
    setup_diagnostics_keymaps = setup_diagnostics_keymaps,
    setup_formatting_keymaps = setup_formatting_keymaps,
    setup_independent_keymaps = setup_independent_keymaps,

    setup_options = setup_options,
    setup_autocmds = setup_autocmds,
    setup_highlights = setup_highlights
}
