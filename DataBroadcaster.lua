----------------------------------------------------------------------------------------
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

message("Detected Quik version: ".. quikVersion .." and using cpath: "..package.cpath  , 0)

----------------------------------------------------------------------------------------
local socket = require ("libs.socket")
local json = require ("libs.dkjson")
local deque = require ("libs.deque")
require ("libs.loggingfile")

local logger = logging.file(getScriptPath().."\\logs\\".."%s.log", "%Y-%m-%d", "%date|%level: %message\n")

local is_started = false
local is_connected = false
local is_quik_connected = false

local callback_host = '127.0.0.1'
local callback_port = 9090
--local callback_port = 34131
--local callback_host = '82.148.31.138'    -- old ip address
--local callback_host = '46.242.5.83'        -- new ip address

local callback_client

local queue = nil
local BOOST_PROCC_TIME = 10
local NORM_PROCC_TIME = 100

local buffer_dir = getScriptPath().."\\buffer";
local buffer_fname = buffer_dir.."\\"..tostring(os.date('%Y%m%d'))..".txt"
local InitDate = os.date("%Y-%m-%d %X")
GLOBAL_NUMBER = 0
local message_sended_count = 0

function main()
	while is_started do
		if is_quik_connected or queue:length() > 0 then
			-- если нет соединени€ с сервером Quik, то данные не поступают
			-- скрипт закрывает соединение с удаленным сервером
			-- если queue не пуст, то перед его закрытием скрипт отправл€ет все данные с очереди
			if not ensure_connected(callback_host, callback_port) then
				AddQueueToCache(buffer_fname)
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
				sleep(NORM_PROCC_TIME)
			end
		else
			closeSocket()
		end
	end
	if queue:length() > 0 then
		logger:info("Queue isn't empty: %d", queue:length())
		AddQueueToCache()
	else
		logger:info("Queue is empty")
	end
end

function ensure_connected(host, port)
	if host == nil or port == nil then return end
    if not callback_client then
		message("Trying to connecting to server: "..host..":"..port)
		logger:warn("Trying to connecting to server: "..host..":"..port)
		callback_client = socket.connect(host, port)
		if callback_client then
			if not CacheIsEmpty() then
				LoadQueueFromCache()
			end
			message("Connected to server: "..host..":"..port)
			logger:info("Connected to server: "..host..":"..port)
			logger:info("---------")
			is_connected = true
			pcall(callback_client.settimeout, callback_client, 1000, 't')
		end
    end
	return callback_client ~= nil
end

---------------------------
-----------Functions-------

function HandleMessage(msg_json)
	local res, err = sendCallback(msg_json)
	if not res == true then
		AddToCache(msg_json)
		logger:warn(string.format("Can't send data to remote server: %s", err))
	end
end


function AddToCache(msg_json)
	AppendToFile(buffer_fname, msg_json)
end

function AppendToFile(fname, msg_json)
	local file = io.open(fname, "a+")
	file:write(msg_json.."\n")
	io.close(file)
end

function AddQueueToCache()
	if queue:length() == 0 then return end
	local msg_list = queue:extract_data()
	local file = io.open(buffer_fname, "a+")
	for i, msg_json in ipairs(msg_list) do
		file:write(msg_json.."\n")
	end
	io.close(file)
	logger:debug("Added %d messages to local cache", #msg_list)
end

function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

function LoadQueueFromCache()
	logger:info('Loading data from cache...')
	local rlines = {}
	for line in io.lines(buffer_fname) do
		rlines[#rlines + 1] = line
	end
	os.remove(buffer_fname)
	logger:info('Loaded %d messages from local cache', #rlines)
	queue:push_right_datas(rlines)
end

function CacheIsEmpty()
	return not file_exists(buffer_fname)
end

function PrintConfigsToLog()
	logger:info("-------------------------")
	logger:info("Parameters:")
	logger:info("host=%s, port=%s", callback_host, callback_port)
	logger:info("Normal delay=%d ms, Boost delay=%d ms,", NORM_PROCC_TIME, BOOST_PROCC_TIME)
	logger:info("Cache path=%s", buffer_fname)
	if CacheIsEmpty() then 
		logger:info("Cache file is empty")
	else
		logger:info("Cache file has datas")
	end
	logger:info("Connection with Quik's DataServer: %s", NumberToBool(isConnected()))
	logger:info("-------------------------")
end
---------------------------


------------------------------------------------------
----------------------- CALBACKS----------------------

-- ѕри запуске скрипта
function OnInit()
	is_quik_connected = NumberToBool(isConnected())
	PrintConfigsToLog()
	if queue == nil then 
		queue = deque.new()
		logger:info("Queue is initialized")
	end
	is_started = true
end

-- ѕри остановке скрипта
function OnStop(s)
	message("Script Stopped")
	logger:info("Script Stopped")
	is_started = false
	closeSocket()
    return 1000
end

-- ѕри соединении с сервером Quik
function OnConnected()
	logger:info('Connetion with Quik Server is established')
	is_quik_connected = true
end


-- ѕри разрыве соединении с сервером Quik
function OnDisconnected()
	is_quik_connected = false
	logger:info("Connection lost with Quik Server!")
end



function OnParam(class_code, sec_code)
	if arrayContain(MARKET_CLASS_CODES, class_code) == false then return end
	GLOBAL_NUMBER = GLOBAL_NUMBER + 1
	local dat = {}
	dat = getSecurityQuotesInfo(class_code, sec_code)
	dat.msg_type = 'OnParam'
	dat.id = GLOBAL_NUMBER
	queue:push_right(string.format('%d:%s', dat.id, to_json(dat)))
end



function OnClose()
   logger:info("QuikApp is closing...")
   closeSocket()
end

----------------------------
function NumberToBool(num)
	if num == 1 then return true end
	return false
end
function arrayContain(tbl, val)
	for ind=1, #tbl, 1 do
		if tbl[ind] == val then return true end
	end
	return false
end

function closeSocket()
	if is_connected then
		logger:info("Closing socket with %s:%s...", host, port)
		is_connected = false
		logger:info("ќтправлено %d сообщений", message_sended_count)
		if callback_client then
			pcall(callback_client.close, callback_client)
			callback_client = nil
		end
	end
end


function sendCallback(msg_json)
    if is_connected and callback_client then
        local status, res = pcall(callback_client.send, callback_client, msg_json..'\n')
        if status and res then
            return true
        else
			logger:warn("Connection lost with server: "..callback_host..":"..callback_port)
			message("Connection lost with server: "..callback_host..":"..callback_port)
            closeSocket()
            return nil, res
        end
	else
		return false
    end
end

function to_json(msg)
    local status, str= pcall(json.encode, msg, { indent = false }) -- dkjson
    if status then
        return str
    else
        error(str)
    end
end

function timemsec()
    local st, res = pcall(socket.gettime)
    if st then
        return (res) * 1000
    else
        error("unexpected error in timemsec")
    end
end


function getSecurityQuotesInfo(class, sec)
	local p={}
	p['datetime'] = tostring(os.date('%Y-%m-%dT%X'))
	p = setValues(class, sec, BOND_MAIN_INFO, p)
	p = setValues(class, sec, QUOTES_PARAMS, p)
	p['market_trades'] = setValues(class, sec, TRADES_PARAMS)
	p['rps_trades'] = setRPSValues(RPS_CLASS_CODES, sec, TRADES_PARAMS)
	return p
end


function setValues(class_code, sec_code, prms, input_p)
	local p = input_p or {}
	for ind=1, #prms, 1 do
		local prm_code = prms[ind][1]
		local prm_type = prms[ind][2]
		local loc = getParamEx(class_code, sec_code, prm_code)
		if loc ~= nil then
			if prm_type == 'NUMERIC' or prm_type == 'INT' then
				p[prm_code] = tonumber(loc.param_value)
			else
				if isempty(loc.param_image) then
					p[prm_code] = json.null
				else
					p[prm_code] = loc.param_image
				end
			end
		end
	end
	return p
end

function isempty(s)
  return s == nil or s == ''
end

--[[ 
	for 'string' parameters from 'prms' - get max value over all 'classcodes'
	for 'number' parameters from 'prms' - get sum of values over all 'classcodes'
]]

function setRPSValues(classcodes, sec_code, prms)
	-- loop by params collection
	local p = {}
	for p_ind=1, #prms, 1 do
		local prm_code = prms[p_ind][1]
		local prm_type = prms[p_ind][2]
		
		if prm_type == 'STRING' then
			local max_str = ''
			-- loop by RPS class_codes
			for i, class_code in ipairs(classcodes) do
				if getSecurityInfo(class_code, sec_code) then
					local prm_val = getParamEx(class_code, sec_code, prm_code)
					if prm_val ~= nil then
						max_str = math.max(max_str, prm_val.param_image)
					end
				end
			end
			if isempty(max_str) then
				p[prm_code] = json.null
			else
				p[prm_code] = max_str
			end
		else
			local sum = 0
			for i, class_code in ipairs(classcodes) do
				if getSecurityInfo(class_code, sec_code) then
					local prm_val = getParamEx(class_code, sec_code, prm_code)
					if prm_val ~= nil then
						sum = sum + prm_val.param_value
					end
				end
			end
			p[prm_code] = sum
		end
	end
	return p
end


MARKET_CLASS_CODES = {'TQCB', 'TQOB'}
RPS_CLASS_CODES = {'PTOB', 'PSOB', 'PSEO', 'PTOD', 'PSEU'}

BOND_MAIN_INFO = 
{
	{'isincode',		'STRING', 'isin'},
	{'code',			'STRING', 'код бумаги'},
	{'shortname',       'STRING', 'краткое название бумаги'},
	{'longname',        'STRING', 'полное название бумаги'},
	{'regnumber',       'STRING', '–егистрац номер'},
	{'sectypestatic',   'STRING', '“ип инструмента'},
	{'secsubtypestatic','STRING', 'ѕодтип инструмента'},
	{'tradingstatus',	'STRING', 'состо€ние сессии'},
	{'listlevel', 	    'INT', 'листинг'},
	{'lotsize',         'INT', 'размер лота'},
	{'sec_face_unit',	'STRING', 'валюта номинала'},
	{'issuesize',		'NUMERIC', 'объем обращени€'},
	{'mat_date',		'STRING', 'дата погашени€'},
	{'days_to_mat_date','INT', 'число дней до погашени€'},
	
	{'sec_face_value',	'NUMERIC', 'непогашенный номинал бумаги'},
	{'accruedint',		'NUMERIC', 'накопленный купонный доход'},
	{'couponvalue',		'NUMERIC', 'размер купона в валюте номинала'},
	{'nextcoupon',		'STRING', 'дата выплаты купона'},
	{'couponperiod',	'INT', 'длительность купона в дн€х'},
	
	{'buybackdate',		'STRING', 'дата оферты, если есть'},
	{'settledate',		'STRING', 'дата расчетов по бумаге'},
	{'trade_date_code',	'STRING', 'дата торгов'}
}

QUOTES_PARAMS = 
{
	{'bid',				'NUMERIC', 'спрос'},
	{'offer',			'NUMERIC', 'предложение'},
	{'duration',        'NUMERIC', 'дюраци€'},
	{'class_code',		'STRING', 'код класса'}
}

TRADES_PARAMS = 
{
	{'time',			'STRING',  '¬рем€ последней сделки'},
	{'last',			'NUMERIC', '÷ена последней сделки'},
	{'yield',			'NUMERIC', 'ƒоходность последней сделки'},
	{'numtrades',		'NUMERIC', 'количество сделок за сегодн€'},
	{'voltoday',		'NUMERIC', 'оборот в бумагах'},
	{'valtoday',		'NUMERIC', 'оборот в деньгах'}
}


-- MARKET_CODES_RUB = {'TQCB', 'TQOB'}
-- MARKET_CODES_EURUSD = {'TQOD', 'TQOE'}
-- RPS_CODES_RUB = {'PTOB', 'PSOB'}
-- RPS_CODES_EUR = {'PSEO'}
-- RPS_CODES_USD = {'PTOD', 'PSEU'}




