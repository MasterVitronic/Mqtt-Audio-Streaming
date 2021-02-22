local utils = {}
utils.__index = utils;

--@see https://stackoverflow.com/questions/41783274/how-to-clear-stdout-line-in-lua
stdout, out = '', nil
function utils:iop(str)
	io.output():setvbuf("no")
	io.output():setvbuf("line")
	io.write(('\b \b'):rep(#stdout))  -- erase old line
	io.write(str)                     -- write new line
	io.flush()
	stdout = str
end

--@see http://lua-users.org/wiki/SimpleRound
function utils:round(val, decimal)
  if (decimal) then
    return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
  else
    return math.floor(val+0.5)
  end
end

return utils