----------------------------------------------------------------------------------------
function is_quik()
    if getScriptPath then return true else return false end
end

quikVersion = nil
script_path = "."
libs_path = "\\libs\\"

-- Loading suitable lua core lib for Quik
if is_quik() then
    script_path = getScriptPath()
    
	quikVersion = getInfoParam("VERSION")

	if quikVersion ~= nil then
		quikVersion = tonumber(quikVersion:match("%d+%.%d+"))
	end

	if quikVersion == nil then
		message("QUIK# cannot detect QUIK version", 3)
		return
	else
		libPath = "\\clibs"
	end
    
    -- MD dynamic, requires MSVCRT
    -- MT static, MSVCRT is linked statically with luasocket
    -- package.cpath contains info.exe working directory, which has MSVCRT, so MT should not be needed in theory, 
    -- but in one issue someone said it doesn't work on machines that do not have Visual Studio. 
    local linkage = "MD"
    
	if quikVersion >= 8.5 then
        libPath = libPath .. "64\\53_"..linkage.."\\"
	elseif quikVersion >= 8 then
        libPath = libPath .. "64\\5.1_"..linkage.."\\"
	else
		libPath = "\\clibs\\5.1_"..linkage.."\\"
	end
end

package.path = package.path..";" ..script_path.."\\?.lua;" ..script_path.."\\?.luac;"..".\\?.lua;"..".\\?.luac;"..script_path..libs_path.."?.lua"
package.cpath = package.cpath..";" .. script_path .. libPath .. '?.dll'..";".. '.' .. libPath .. '?.dll;'..script_path..libs_path.."?.lua"

----------------------------------------------------------------------------------------

local perf = {
	boost = {name = "Boost", sleeptime = 10},
	default = {name = "Default", sleeptime = 100},
	lazy = {name = "Lazy", sleeptime = 1000}
}

require ("loggingfile")
require ("quikcallbacks")
local json = require ("dkjson")
local lqueue = require ("deque")
local lcache = require ("qdbccache")
local lreceiver = require ("receiverapi")

logger = logging.file(getScriptPath().."\\logs\\".."%s.log", "%Y-%m-%d", "%date|%level: %message\n")

is_started = false
is_connected = false
msg_sended_amount = 0


local runmode = perf.lazy
queue = lqueue:new()
cache = lcache:create(getScriptPath().."\\cache\\")
receiver = lreceiver:create('127.0.0.1', 9090)

function main()
	logger:info("Running mode: %s, run every %d ms.", runmode.name, runmode.sleeptime)
	while is_started do
		-- ���� ��� ���������� � �������� Quik, �� ������ �� ���������
		-- ���� queue �� ����, �� ������ ���������� ��� ������ � �������
		-- � ����� ��������� ���������� � ��������� ��������
		logger:debug("Quik connected: %s, Server connected: %s, #queue: %d, sended: %d", is_connected, receiver.is_connected, queue:length(), msg_sended_amount)
		
		if is_connected or not queue:is_empty() then
			logger:debug("Queue has data or connection with Quik is not closed")
			-- �������� ���������� � ��������
			if not receiver.is_connected then
				logger:debug("Trying to connect to remote server...")
				if receiver:connect() then
					logger:info('Connected to remote server!')
					if not cache:isEmpty() then
						local collect, err_msg = cache:extractData()
						if collect == nil then error(err_msg) end
						logger:info('Loaded %d datas from cache', #collect)
						queue:push_right_some(collect)
					else
						logger:info("Cache is empty")
					end
				end
			end
			
			if not receiver.is_connected then
				logger:debug("Connection failed!")
				SaveQueueToCache()
			else
				local msg = queue:pop_left()
				if msg ~= nil then
					local res, err = receiver:sendStr(to_json(msg))
					if not res then
						-- �� ������� ��������� ������ �� ������
						logger:warn('Connection with server is lost! (%s)', receiver.is_connected)
						CloseConnection()
					else
						msg_sended_amount = msg_sended_amount + 1
					end
				end
			end
		else
			CloseConnection()
		end
		CheckMode()
		sleep(runmode.sleeptime)
	end
	
	-- ����� ��������� �������
	if not queue:is_empty() then
		logger:info("Before closing queue had data: %d", queue:length())
		SaveQueueToCache()
	else
		logger:info("Before closing queue was empty")
	end
end


function SaveQueueToCache()
	if queue:is_empty() then return end
	local data = queue:extract_data()
	cache:appendCollection(data)
	logger:info("To cache added %d data", #data)
end

function CloseConnection()
	if not receiver.is_connected then return end
	logger:info('Closing connection with remote server...')
	receiver:disconnect()
	logger:info('Connection closed!')
	logger:info('Before connection close %d datas were sent', msg_sended_amount)
	msg_sended_amount = 0
end

function to_json (obj)
    local status, str= pcall(json.encode, obj, { indent = false }) -- dkjson
    if status then
        return tostring(str)
    else
        error(str)
    end
end

function CheckMode()
	local old_mode = runmode
	if not receiver.is_connected then
		runmode = perf.lazy
	elseif queue:length() >= 100 then
		runmode = perf.boost
	elseif runmode ~= perf.default then
		runmode = perf.default
	end
	if old_mode ~= runmode then logger:debug("--Mode changed to %s", runmode.name) end
end