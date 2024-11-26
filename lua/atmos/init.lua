-- Require Telescope
local telescope = require('telescope')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local builtin = require('telescope.builtin')

-- List Atmos stacks
local function atmos_list_stacks()
    local handle = io.popen('atmos list stacks')
    if not handle then
        error("Failed to execute command")
    end
    local result = handle:read("*a")
    handle:close()
    return result
end

-- List Atmos components
local function atmos_list_components()
    local handle = io.popen('atmos list components')
    if not handle then
        error("Failed to execute command")
    end
    local result = handle:read("*a")
    handle:close()
    -- Ensure results are trimmed and split correctly
    local components = vim.split(result, "\n", { trimempty = true })
    return components
end

-- Validate Atmos stacks
local function atmos_validate_stacks()
    local handle = io.popen('atmos validate stacks')
    if not handle then
        error("Failed to execute atmos validate stacks")
    end
    local result = handle:read("*a")
    handle:close()
    return result -- This should return 'result' not 'results'
end

-- Display results in a floating window
local function show_floating_window(contents)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(contents, "\n"))

    local width = vim.o.columns - 10
    local height = vim.o.lines - 10
    local opts = {
        relative = 'editor',
        width = width,
        height = height,
        col = 5,
        row = 5,
        style = 'minimal',
        border = 'single'
    }

    vim.api.nvim_open_win(buf, true, opts)
end

-- Display output in Telescope and handle selection
local function show_in_telescope(output, is_component)
    if not output or vim.tbl_isempty(output) then
        print("No results found.")
        return
    end
    pickers.new({}, {
        prompt_title = "Atmos List",
        finder = finders.new_table({
            results = output,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                if selection then
                    if is_component then
                        -- Strip everything after the first forward slash
                        local component_name = selection[1]:match("^[^/]+")
                        local path = vim.fn.getenv("ATMOS_BASE_PATH") .. "/components/terraform/" .. component_name
                        builtin.find_files({ cwd = path })
                    else
                        print("Selected stack: " .. selection[1])
                    end
                end
            end)
            return true
        end,
    }):find()
end

local function atmos_list_stacks_command()
    local output = atmos_list_stacks()
    output = vim.split(output, "\n", { trimempty = true }) -- Ensure output is split and trimmed
    show_in_telescope(output, false)
end

local function atmos_list_components_command()
    local output = atmos_list_components()
    show_in_telescope(output, true)
end

local function atmos_validate_stacks_command()
    local output = atmos_validate_stacks()
    show_floating_window(output)
end

-- Setup Atmos environment variables
local function setup_env(base_path, config_path)
    vim.fn.setenv("ATMOS_BASE_PATH", base_path)
    vim.fn.setenv("ATMOS_CLI_CONFIG_PATH", config_path)
end

-- Create Neovim commands
vim.api.nvim_create_user_command('AtmosListStacks', atmos_list_stacks_command, {})
vim.api.nvim_create_user_command('AtmosListComponents', atmos_list_components_command, {})
vim.api.nvim_create_user_command('AtmosValidateStacks', atmos_validate_stacks_command, {})

-- Setup function
local function setup(options)
    setup_env(options.base_path, options.config_path)
end

return {
    setup = setup,
    atmos_list_stacks_command = atmos_list_stacks_command,
    atmos_list_components_command = atmos_list_components_command,
    atmos_validate_stacks_command = atmos_validate_stacks_command -- Fix here, use the correct function
}

