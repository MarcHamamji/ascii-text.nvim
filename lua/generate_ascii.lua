local Job = require("plenary.job")

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

return generate_ascii
