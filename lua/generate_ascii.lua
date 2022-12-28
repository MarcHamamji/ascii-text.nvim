local Job = require("plenary.job")

local flags = {
  font = {
    default = 'standard',
    prefix = '-f',
    custom = true,
  },
  output_width = {
    default = 80,
    prefix = '-w',
    custom = true,
  },
  spacing = {
    prefix = nil,
    default = 'smushing',
    options = {
      smushing = '-s',
      kerning = '-k',
      ['full-width'] = '-W',
    },
  },
  justification = {
    prefix = nil,
    default = 'auto',
    options = {
      left = '-l',
      center = '-c',
      right = '-r',
      auto = '-x',
    },
  },
}

local generate_arg = function(key, value)
  local flag = flags[key]
  local arg = {}

  if flag.prefix ~= nil then
    table.insert(arg, flag.prefix)
  end

  if flag.custom then
    if value == nil then
      table.insert(arg, flag.default)
    else
      table.insert(arg, value)
    end
  else
    if value == nil then
      table.insert(arg, flag.options[flag.default])
    else
      table.insert(arg, flag.options[value])
    end
  end

  return arg
end

local generate_args = function(options, text)
  local args = {}
  for key, _ in pairs(flags) do
    for _, flag in pairs(generate_arg(key, options[key])) do
      table.insert(args, flag)
    end
  end
  table.insert(args, text)
  return args
end

local generate_ascii = function(text, options, callback)
  -- print('GOT OPTIONS', vim.inspect(options))
  print('Command: figlet ' .. table.concat(generate_args(options, text), ' '))
  local job = Job:new({
    command = 'figlet',
    args = generate_args(options, text),
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

return generate_ascii
