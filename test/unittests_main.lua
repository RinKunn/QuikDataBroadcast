function getScriptPath() return io.popen("cd"):read('*l') end
getInfoParam = function(prm) 
	if prm == "VERSION" then 
		return "8.7" 
	else 
		error('Not applied for param: '..prm)
	end 
end

local function myget_parent_dir(str)
   local fpat = "\\"
   local last_end = #str-1
   local s, e, cap = str:find(fpat, last_end)
   while last_end >= 1 do
      if e ~= nil then
         return str:sub(1, e - 1)
      end
      last_end = last_end-1
      s, e, cap = str:find(fpat, last_end)
   end
   return nil
end

local script_path = getScriptPath()
local base_path = myget_parent_dir(script_path)
local socketcore_path = base_path.."\\clibs64\\53_MD\\"
local libs_path = base_path.."\\libs\\"
local testlibs_path = script_path.."\\libs\\"

package.path = package.path .. ";"..base_path.."\\?.lua;"..base_path.."\\?.luac;"..".\\?.lua;"..".\\?.luac;"..libs_path.."?.lua;"..testlibs_path.."?.lua"
package.cpath = package.cpath..";"..socketcore_path..'?.dll;' ..'.'..socketcore_path..'?.dll;'..testlibs_path.."?.lua"
-----------------------------------------

require ('DataBroadcaster')
local lu = require('luaunit')
local copas = require('copas')
local timer = require('copas.timer')
local mockagne = require('mockagne')
local when = mockagne.when
local any = mockagne.any
local verify = mockagne.verify

--- redefine global function ---
isConnected = function() return 1 end
--message = function(msg) print(msg) end
message = function(msg) end
sleep = function (...) return coroutine.yield() end
socket = mockagne.getMock()


TestMain = {}
	function TestMain:setUp()
		self.logfile = getScriptPath().."\\logs\\"..os.date("%Y-%m-%d")..".log"
		local conv = function()
				if not self.server_running then return nil end
				return { send = function(...) return self.server_running, self.server_running end}
			end
		when(socket.connect('127.0.0.1', 9090)).thenAnswerFn(conv)
		OnInit()
	end
	
	function TestMain:tearDown()
		if is_started then
			OnStop()
		end
		is_started = false
		is_connected = false
		msg_sended_amount = 0
		os.remove(self.logfile)
		os.remove(cache.filepath)
		queue = nil
		cache = nil
		receiver = nil
	end
	
	
	function TestMain:test_beforeRunning_logPrinted()
		lu.assertTrue(is_started)
		lu.assertTrue(is_connected)
		lu.assertTrue(file_exists(self.logfile))
		lu.assertNotNil(queue)
		lu.assertNotNil(cache)
		lu.assertNotNil(receiver)
		lu.assertTrue(queue:is_empty())
		lu.assertTrue(cache:is_empty())
		lu.assertFalse(receiver.is_connected)
	end
	
	function TestMain:test_OnStop_shutdownWork()
		local mr = coroutine.create(main)
		local resumeres = coroutine.resume(mr)
		lu.assertTrue(resumeres)
		lu.assertEquals(coroutine.status(mr), 'suspended')
		lu.assertTrue(is_started)
		lu.assertTrue(is_connected)
		
		OnStop()
		
		resumeres = coroutine.resume(mr)
		lu.assertTrue(resumeres)
		lu.assertEquals(coroutine.status(mr), 'dead')
		lu.assertFalse(is_started)
	end
	
	--[[ 
	@event: Начальная инициализация
	@condit: Quik disconnected, Remote connected, Cache is empty
	@result: Не соединяется с удаленным сервером
	]]
	function TestMain:testInit_cacheEmptySR_notConnectedToRemote()
		self.server_running = true
		is_connected = false
		lu.assertTrue(cache:is_empty())
		local mr = coroutine.create(main)
		
		coroutine.resume(mr)
		
		lu.assertFalse(receiver.is_connected)
		lu.assertTrue(queue:is_empty())
		
		OnStop()
		coroutine.resume(mr)
	end
	
	--[[ 
	@event: Начальная инициализация
	@condit: Quik disconnected, Remote connected, Cache has 2 data
	@result: Соединяется с удаленным сервером и отправляет 1 данные
	]]
	function TestMain:testInit_cacheHasDataSR_ConnectedToRemoteAndSend()
		file_append(cache.filepath, '{"id":1}\n{"id":2}\n')
		self.server_running = true
		is_connected = false
		lu.assertEquals(cache:length(), 2)
		local mr = coroutine.create(main)
		
		coroutine.resume(mr)
		
		lu.assertTrue(receiver.is_connected)
		lu.assertEquals(queue:length(), 1)
		lu.assertEquals(msg_sended_amount, 1)
		
		OnStop()
		coroutine.resume(mr)
	end
	
	
	--[[ 
	@event: Добавление данных в очередь
	@condit: Quik connected, Remote disconnected
	@result: Переносит все данные с очереди в кэш
	]]
	function TestMain:testAdd1DataToQueue_QCSS_added1ToCache()
		self.server_running = false
		is_connected = true
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		
		queue:push_right({id = 1})
		coroutine.resume(mr)
		
		local cacheLines = lines_from(cache.filepath)
		lu.assertTrue(queue:is_empty())
		lu.assertEquals(cache:length(), 1)
		lu.assertEquals(cacheLines[1], '{"id":1}')
		
		OnStop()
		coroutine.resume(mr)
	end
	
	--[[ 
	@event: Добавление данных в очередь
	@condit: Quik connected, Remote connected
	@result: Отправляет все данные с очереди на сервер
	]]
	function TestMain:testAdd1DataToQueue_QCSR_send1ToRemote()
		self.server_running = true
		is_connected = true
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		
		queue:push_right({id = 1})
		coroutine.resume(mr)
		
		lu.assertTrue(queue:is_empty())
		lu.assertTrue(cache:is_empty())
		lu.assertEquals(msg_sended_amount, 1)
		
		OnStop()
		coroutine.resume(mr)
	end
	
	--[[ 
	@event: Добавление данных в очередь при загрузке cache
	@condit: Quik connected, Remote connected
	@result: добавленный объект пересылается после cache
	
	-- function TestMain:testAddDataToQueue_cacheLoading_sendToRemoteAfterLoading()
		--TODO
	-- end
	]]
	
	
	------- QUIK CONNECTION EVENTS -------
	--[[ 
	@event: Разрыв связи с Quik'ом
	@condit: Remote connected, queue = 0
	@result: Закрывает соединение с сервером
	]]
	function TestMain:testOnDisconnected_SR_closeRemote()
		self.server_running = true
		is_connected = true
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		lu.assertTrue(receiver.is_connected)
		
		OnDisconnected()
		coroutine.resume(mr)
		
		lu.assertFalse(receiver.is_connected)
		OnStop()
		coroutine.resume(mr)
	end
	
	--[[ 
	@event: Разрыв связи с Quik'ом
	@condit: Remote disconnected, queue = 0
	@result: ничего не делает
	]]
	function TestMain:testOnDisconnected_SS_nothing()
		self.server_running = false
		is_connected = true
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		lu.assertFalse(receiver.is_connected)
		
		OnDisconnected()
		coroutine.resume(mr)
		
		lu.assertFalse(receiver.is_connected)
		OnStop()
		coroutine.resume(mr)
	end
	
	--[[ 
	@event: Разрыв связи с Quik'ом
	@condit: Remote connected, queue > 0
	@result: Отправляет все данные с очереди на сервер
	]]
	function TestMain:testOnDisconnected_queueHas1DataSR_send1ToRemote()
		self.server_running = true
		is_connected = true
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		
		queue:push_right({id = 1})
		OnDisconnected()
		coroutine.resume(mr)
		
		lu.assertEquals(msg_sended_amount, 1)
		lu.assertTrue(queue:is_empty())
		lu.assertTrue(cache:is_empty())
		
		OnStop()
		coroutine.resume(mr)
	end
	
	--[[
	@event: Разрыв связи с Quik'ом
	@condit: Remote disconnected, queue > 0
	@result: Переносит все данные с очереди в кэш
	]]
	function TestMain:testOnDisconnected_queueHas1DataSS_save1ToCache() 
		self.server_running = false
		is_connected = true
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		
		queue:push_right({id = 1})
		OnDisconnected()
		coroutine.resume(mr)
		
		lu.assertEquals(msg_sended_amount, 0)
		lu.assertTrue(queue:is_empty())
		lu.assertFalse(cache:is_empty())
		lu.assertEquals(cache:length(), 1)
		
		OnStop()
		coroutine.resume(mr)
	end
	

	--[[ 
	@event: Соединение с сервером Quik'а
	@condit: cache = 0, сервер не запущен
	@result: делает попытку подключения к Remote
	]]
	function TestMain:testOnConnected_SS_dontconnectToRemote()
		self.server_running = false
		is_connected = false
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		lu.assertFalse(receiver.is_connected)
		
		OnConnected()
		coroutine.resume(mr)
		
		lu.assertFalse(receiver.is_connected)
		lu.assertTrue(is_connected)
		
		OnStop()
		coroutine.resume(mr)
	end
	
	--[[ 
	@event: Соединение с сервером Quik'а
	@condit: cache = 0, сервер запущен
	@result: делает попытку подключения к Remote
	]]
	function TestMain:testOnConnected_SR_connectToRemote()
		self.server_running = true
		is_connected = false
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		lu.assertFalse(receiver.is_connected)
		
		OnConnected()
		coroutine.resume(mr)
		
		lu.assertTrue(receiver.is_connected)
		lu.assertTrue(is_connected)
		
		OnStop()
		coroutine.resume(mr)
	end
	
	--[[ 
	@event: Соединение с сервером Quik'а
	@condit: cache > 0, сервер не запущен
	@result: делает попытку подключения к Remote
	]]
	function TestMain:testOnConnected_cacheHas1DataSS_dontload1ToQueue()
		file_append(cache.filepath, '{"id": 1}\n')
		self.server_running = false
		is_connected = false
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		lu.assertFalse(cache:is_empty())
		lu.assertTrue(queue:is_empty())
		
		OnConnected()
		coroutine.resume(mr)
		
		lu.assertFalse(receiver.is_connected)
		lu.assertTrue(is_connected)
		lu.assertTrue(queue:is_empty())
		lu.assertFalse(cache:is_empty())
		lu.assertEquals(cache:length(), 1)
		OnStop()
		coroutine.resume(mr)
	end
	
	--[[ 
	@event: Соединение с сервером Quik'а
	@condit: cache > 0, сервер запущен
	@result: делает попытку подключения к Remote
	]]
	function TestMain:testOnConnected_cacheHas1DataSR_load1ToQueueAndSend()
		file_append(cache.filepath, '{"id": 1}\n')
		self.server_running = true
		is_connected = false
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		lu.assertTrue(cache:is_empty())
		lu.assertTrue(queue:is_empty())
		
		OnConnected()
		coroutine.resume(mr)
		
		lu.assertEquals(msg_sended_amount, 1)
		OnStop()
		coroutine.resume(mr)
	end
	
	------- REMOTE CONNECTION EVENT -------
	
	--[[ 
	@event: Cоединение с Remote сервером
	@condit: cache > 0, queue = 0
	@result: переносит данные из cache в queue
	]]
	function TestMain:testRemoteConnected_cacheHas1Data_load1ToQueueAndSend()
		file_append(cache.filepath, '{"id":1}\n')
		self.server_running = false
		is_connected = true
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		lu.assertTrue(queue:is_empty())
		lu.assertEquals(cache:length(), 1)
		
		self.server_running = true
		coroutine.resume(mr)
		
		lu.assertTrue(receiver.is_connected)
		lu.assertTrue(cache:is_empty())
		lu.assertTrue(queue:is_empty())
		lu.assertEquals(msg_sended_amount, 1)
		
		OnStop()
		coroutine.resume(mr)
	end
	
	--[[ 
	@event: Cоединение с Remote сервером 
	@condit: cache > 0, queue > 0
	@result: переносит данные из cache в queue и отправляет первую
	]]
	function TestMain:testRemoteConnected_cacheQueueHas2Data_load1ToQueueAnd2Send()
		file_append(cache.filepath, '{"id":1}\n')
		self.server_running = false
		is_connected = true
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		
		queue:push_right({id = 2})
		self.server_running = true
		coroutine.resume(mr)
		
		lu.assertTrue(receiver.is_connected)
		lu.assertTrue(cache:is_empty())
		lu.assertEquals(queue:length(), 1)
		lu.assertEquals(msg_sended_amount, 1)
		lu.assertEquals(queue:peek_left().id, 2)
		OnStop()
		coroutine.resume(mr)
	end
	
	--[[ 
	@event: Разрыв соединения с Remote сервером при отправке сообщения
	@condit: queue > 0
	@result: переносит данные из queue в cache
	]]
	function TestMain:testRemoteDisconnected_send1Data_save1ToCache()
		self.server_running = true
		is_connected = true
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		lu.assertTrue(receiver.is_connected)
		
		queue:push_right({st = 'send break and save to cache 1'})		
		self.server_running = false
		coroutine.resume(mr)
		
		lu.assertFalse(receiver.is_connected)
		lu.assertEquals(cache:length(), 1)
		lu.assertTrue(queue:is_empty())
		lu.assertEquals(msg_sended_amount, 0)
		
		OnStop()
		coroutine.resume(mr)
		lu.assertEquals(coroutine.status(mr), 'dead')
	end
	
	--[[ 
	@event: Разрыв соединения с Remote сервером при отправке сообщения
	@condit: queue = 2
	@result: переносит данные из queue в cache
	]]
	function TestMain:testRemoteDisconnected_queueHas2Data_save2ToCache()
		self.server_running = true
		is_connected = true
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		lu.assertTrue(receiver.is_connected)
		
		queue:push_right({st = 'send break and save to cache 1'})
		queue:push_right({st = 'saved to cache 2'})
		self.server_running = false
		coroutine.resume(mr)
		
		lu.assertFalse(receiver.is_connected)
		lu.assertEquals(cache:length(), 1)
		lu.assertEquals(queue:length(), 1)
		lu.assertEquals(msg_sended_amount, 0)
		
		OnStop()
		coroutine.resume(mr)
		lu.assertEquals(coroutine.status(mr), 'dead')
		lu.assertEquals(cache:length(), 2)
	end
	
	--[[ 
	@event: Cоединение с Remote сервером
	@condit: cache > 0, queue > 0 (перед соединением сервера Quik может занести новые данные)
	@result: переносит данные из cache в queue перед имеющимися данными
	]]
	function TestMain:testRemoteConnected_cacheQueue_loadToQueueBeforeExistData()
		file_append(cache.filepath, '{"id":1}\n')
		self.server_running = false
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		
		queue:push_right({id = 2})
		queue:push_right({id = 3})
		self.server_running = true
		coroutine.resume(mr)
		
		lu.assertEquals(msg_sended_amount, 1)
		lu.assertTrue(cache:is_empty())
		lu.assertEquals(queue:length(), 2)
		lu.assertEquals(queue:peek_left().id, 2)
		lu.assertEquals(queue:peek_right().id, 3)
		
		OnStop()
		coroutine.resume(mr)
		lu.assertEquals(cache:length(), 2)
	end

local t = mockagne.getMock()
getParamEx = t.getParamEx

TestOnParam = {}
	function TestOnParam:setUp()
		when(t.getParamEx('TQOB', 'Bond1', 'class_code')).thenAnswer({param_image = 'TQOB'})
		when(t.getParamEx('TQOB', 'Bond1', 'code')).thenAnswer({param_image = 'Bond1'})
		when(t.getParamEx('TQOB', 'Bond1', 'bid')).thenAnswer({param_image = '101.5', param_value = 101.5})
		when(t.getParamEx('TQOB', 'Bond1', 'offer')).thenAnswer({param_image = '101.8', param_value = 101.8})
		when(t.getParamEx('TQOB', 'Bond1', 'time')).thenAnswer({param_image = '13:45:11', param_value = 11531})
		when(t.getParamEx('TQOB', 'Bond1', 'yield')).thenAnswer({param_image = '8.5', param_value = 8.5})
		OnInit()
	end
	
	function TestOnParam:tearDown()
		queue = nil
		bondsLastInfo = nil
		quote_id = 0
	end
	
	function TestOnParam:test_ClassCodeBond_updateAndAddQueue()
		OnParam('TQOB', 'Bond1')
		
		lu.assertNotNil(bondsLastInfo)
		lu.assertEquals(dictLen(bondsLastInfo), 1)
		lu.assertEquals(queue:length(), 1)
		lu.assertEquals(queue:peek_left().msg_type, 'info')
		lu.assertEquals(queue:peek_left().id, 1)
	end
	
	function TestOnParam:test_DontChangedTracingField_notUpdateNotAddQueue()
		OnParam('TQOB', 'Bond1')
		OnParam('TQOB', 'Bond1')
		
		lu.assertNotNil(bondsLastInfo)
		lu.assertEquals(dictLen(bondsLastInfo), 1)
		lu.assertEquals(bondsLastInfo['Bond1']['time'], '13:45:11')
		lu.assertEquals(queue:length(), 1)
	end
	
	function TestOnParam:test_ChangedTracingField_updateAndAddQueue()
		OnParam('TQOB', 'Bond1')
		lu.assertEquals(bondsLastInfo['Bond1']['time'], '13:45:11')
		when(t.getParamEx('TQOB', 'Bond1', 'time')).thenAnswer({param_image = '13:45:12', param_value = 11532})
		OnParam('TQOB', 'Bond1')
		
		lu.assertNotNil(bondsLastInfo)
		lu.assertEquals(dictLen(bondsLastInfo), 1)
		lu.assertEquals(queue:length(), 2)
		lu.assertEquals(bondsLastInfo['Bond1']['time'], '13:45:12')
	end
	
	function TestOnParam:test_ChangedAnotherFiled_notUpdateNotAddQueue()
		OnParam('TQOB', 'Bond1')
		when(t.getParamEx('TQOB', 'Bond1', 'yield')).thenAnswer({param_image = '9.0', param_value = 9.0})
		OnParam('TQOB', 'Bond1')
		
		lu.assertNotNil(bondsLastInfo)
		lu.assertEquals(dictLen(bondsLastInfo), 1)
		lu.assertEquals(queue:length(), 1)
	end
	
	function TestOnParam:test_ClassCodeWrong_notAdded()
		OnParam('TTTT', 'Bond1')
		
		lu.assertEquals(dictLen(bondsLastInfo), 0)
		lu.assertEquals(queue:length(), 0)
	end
	
	function TestOnParam:test_ClassCodeRPS_notUpdateAddQueue()
		when(t.getParamEx('PTOB', 'Bond2', 'class_code')).thenAnswer({param_image = 'PTOB'})
		when(t.getParamEx('PTOB', 'Bond2', 'code')).thenAnswer({param_image = 'Bond2'})
		OnParam('PTOB', 'Bond2')
		
		lu.assertEquals(dictLen(bondsLastInfo), 0)
		lu.assertEquals(queue:length(), 1)
		lu.assertEquals(queue:peek_left().msg_type, 'rpsinfo')
		lu.assertEquals(queue:peek_left().id, 1)
	end
	
	
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

function file_append(file, line)
	local f = io.open(file, "a+")
	f:write(line)
	f:close()
end


function lines_from(file)
  if not file_exists(file) then return {} end
  local flines = {}
  for line in io.lines(file) do 
    flines[#flines + 1] = line
  end
  return flines
end

function dictLen(tbl)
	local count = 0
	for i, v in pairs(tbl) do count = count + 1 end
	return count
end

local runner = lu.LuaUnit.new()
--runner:setOutputType("junit", "unit_test_results")
runner:runSuite()



