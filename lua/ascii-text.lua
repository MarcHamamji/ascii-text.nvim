local pickers = require('telescope.pickers')
local previewers = require('telescope.previewers')
local finders = require('telescope.finders')
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require('telescope.config').values

local Job = require('plenary.job')

local M = {}

local fonts = {}

M.setup = function()
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
  job:sync()
end

local generate_ascii = function(text, font, callback)
  local job = Job:new({
    command = 'figlet',
    args = { '-f', font, text },
    on_exit = function(result, return_val)
      if return_val ~= 0 then
        error('`figlet` could not run successfully')
      end
      local output = result:result()
      callback(output)
    end,
  })
  job:start()
end

M.open = function()
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
        generate_ascii(text, font, function(output)
          vim.schedule(function ()
            vim.api.nvim_put(output, "", false, true)
          end)
        end)
      end)
      return true
    end,
    previewer = previewers.new({
      preview_fn = function(_, entry, status)
        local bufnr = vim.api.nvim_win_get_buf(status.preview_win)
        generate_ascii(text, entry[1], function(output)
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
