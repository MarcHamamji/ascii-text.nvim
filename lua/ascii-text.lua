local pickers = require('telescope.pickers')
local previewers = require('telescope.previewers')
local finders = require('telescope.finders')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local conf = require('telescope.config').values

local Job = require('plenary.job')

local generate_ascii = require('generate_ascii')

local M = {}

local fonts = {}
local default_opts = {}

M.setup = function(opts)
  default_opts = opts or {}
  local job = Job:new({
    command = 'figlist',
    on_exit = function(result, return_val)
      if return_val ~= 0 then
        error('`figlist` could not run successfully')
      end
      local output = result:result()
      local i = 4
      while output[i] ~= "Figlet control files in this directory:" do
        fonts[#fonts + 1] = output[i]
        i = i + 1
      end
    end,
  })
  job:start()
end

M.open = function(opts)
  local text = vim.fn.input("Text: ")

  local picker = pickers.new({}, {
    prompt_title = "ASCII Text",
    finder = finders.new_table {
      results = fonts
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local font = action_state.get_selected_entry()[1]
        local settings = opts or default_opts
        settings.font = font
        generate_ascii(text, settings, function(output)
          vim.schedule(function()
            vim.api.nvim_put(output, "", false, true)
          end)
        end)
      end)
      return true
    end,
    layout_config = {
      preview_width = 0.7,
    },
    previewer = previewers.new({
      preview_fn = function(_, entry, status)
        local bufnr = vim.api.nvim_win_get_buf(status.preview_win)
        vim.api.nvim_win_set_option(status.preview_win, 'wrap', false)
        local settings = opts or default_opts
        settings.font = entry[1]
        generate_ascii(text, settings, function(output)
          vim.schedule(function()
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, output)
          end)
        end)
      end
    }),
  })
  picker:find()
end

return M
