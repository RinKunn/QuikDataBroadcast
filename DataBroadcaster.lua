----------------------------------------------------------------------------------------
function is_quik()
    if getScriptPath then return true else return false end
end

quikVersion = nil
script_path = "."

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
package.path = package.path .. ";" .. script_path .. "\\?.lua;" .. script_path .. "\\?.luac"..";"..".\\?.lua;"..".\\?.luac"
package.cpath = package.cpath .. ";" .. script_path .. libPath .. '?.dll'..";".. '.' .. libPath .. '?.dll'



----------------------------------------------------------------------------------------
require ("libs.loggingfile")
require ("quikcallbacks")
require ("utils")
require ("config")
local deque = require ("libs.deque")

logger = logging.file(getScriptPath().."\\logs\\".."%s.log", "%Y-%m-%d", "%date|%level: %message\n")

is_started = false
is_quik_connected = false

queue = nil


message_sended_count = 0
quote_id = 0



function main()
	while is_started do
		if is_quik_connected or queue:length() > 0 then
			-- если нет соединения с сервером Quik, то данные не поступают
			-- скрипт закрывает соединение с удаленным сервером
			-- если queue не пуст, то перед его закрытием скрипт отправляет все данные с очереди
			if not ensureConnected(CALLBACK_HOST, CALLBACK_PORT) then
				addQueueToCache(buffer_fname)
			else
				local msg = queue:pop_left()
				if msg ~= nil then 
					HandleMessage(msg)
					message_sended_count = message_sended_count + 1
				end
				message(string.format('queue(%d)', queue:length()))
			end
			
			if queue:length() >= 10 then
				sleep(BOOST_PROCC_TIME)
			else
				sleep(DEFAULT_PROCC_TIME)
			end
		else
			closeSocket()
		end
	end
	
	if queue:length() > 0 then
		logger:info("Queue isn't empty: %d", queue:length())
		addQueueToCache()
	else
		logger:info("Queue is empty")
	end
end


function HandleMessage(msg_json)
	local res, err = sendCallback(msg_json)
	if not res == true then
		addToCache(msg_json)
		logger:warn(string.format("Can't send data to remote server: %s", err))
	end
end