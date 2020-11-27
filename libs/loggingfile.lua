-------------------------------------------------------------------------------
-- Saves logging information in a file
--
-- @author Thiago Costa Ponte (thiago@ideais.com.br)
--
-- @copyright 2004-2013 Kepler Project
--
-------------------------------------------------------------------------------

local logging = require"logging"

-- local lastFileNameDatePattern
-- local lastFileHandler
-- local openFileLogger = function (filename, datePattern)
	-- local filename = string.format(filename, os.date(datePattern))
	-- if (lastFileNameDatePattern ~= filename) then
		-- local f = io.open(filename, "a")
		-- if (f) then
			-- f:setvbuf ("line")
			-- lastFileNameDatePattern = filename
			-- lastFileHandler = f
			-- return f
		-- else
			-- return nil, string.format("file `%s' could not be opened for writing", filename)
		-- end
	-- else
		-- return lastFileHandler
	-- end
-- end

-- function logging.file(filename, datePattern, logPattern)
	-- if type(filename) ~= "string" then
		-- filename = "lualogging.log"
	-- end

	-- return logging.new( function(self, level, msg)
		-- local f, msg = openFileLogger(filename, datePattern)
		-- if not f then
			-- return nil, msg
		-- end
		-- local s = logging.prepareLogMsg(logPattern, os.date("%Y.%m.%d %X"), level, msg)
		-- f:write(s)
		-- return true
	-- end)
-- end
local createDirIfNotExists
local socket = require ("socket")

function logging.file(filename, datePattern, logPattern)
	if type(filename) ~= "string" then
		filename = "lualogging.log"
	end
	local filename = string.format(filename, os.date(datePattern))
	createDirIfNotExists(filename)
	return logging.new( function(self, level, msg)
		local fp, err = io.open(filename, "a")
		local ms = "."..string.format('%.3f',socket.gettime()):match("%.(%d+)")
		local str = logging.prepareLogMsg(logPattern, os.date("%Y.%m.%d %X")..ms, level, msg)
		fp:write(str)
		fp:close()
		--if level == "INFO" then message(msg) end
		return true
	end)
end

function createDirIfNotExists(filename)
	local fp, err = io.open(filename, "a")
	if fp == nil then 
		os.execute("mkdir logs")
		fp, err = io.open(filename, "a")
		if fp == nil then error(err) end
	end
	fp:close()
	os.remove(filename)
end


return logging.file

