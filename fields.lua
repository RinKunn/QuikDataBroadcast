
MARKET_CLASS_CODES = {'TQCB', 'TQOB'}
RPS_CLASS_CODES = {'PTOB', 'PSOB', 'PSEO', 'PTOD', 'PSEU'}

BOND_MAIN_INFO = 
{
	{'isincode',		'STRING', 'isin'},
	{'code',			'STRING', 'код бумаги'},
	{'shortname',       'STRING', 'краткое название бумаги'},
	{'longname',        'STRING', 'полное название бумаги'},
	{'regnumber',       'STRING', 'Регистрац номер'},
	{'sectypestatic',   'STRING', 'Тип инструмента'},
	{'secsubtypestatic','STRING', 'Подтип инструмента'},
	{'tradingstatus',	'STRING', 'состояние сессии'},
	{'listlevel', 	    'INT', 'листинг'},
	{'lotsize',         'INT', 'размер лота'},
	{'sec_face_unit',	'STRING', 'валюта номинала'},
	{'issuesize',		'NUMERIC', 'объем обращения'},
	{'mat_date',		'STRING', 'дата погашения'},
	{'days_to_mat_date','INT', 'число дней до погашения'},
	
	{'sec_face_value',	'NUMERIC', 'непогашенный номинал бумаги'},
	{'accruedint',		'NUMERIC', 'накопленный купонный доход'},
	{'couponvalue',		'NUMERIC', 'размер купона в валюте номинала'},
	{'nextcoupon',		'STRING', 'дата выплаты купона'},
	{'couponperiod',	'INT', 'длительность купона в днях'},
	
	{'buybackdate',		'STRING', 'дата оферты, если есть'},
	{'settledate',		'STRING', 'дата расчетов по бумаге'},
	{'trade_date_code',	'STRING', 'дата торгов'}
}

QUOTES_PARAMS = 
{
	{'bid',				'NUMERIC', 'спрос'},
	{'offer',			'NUMERIC', 'предложение'},
	{'duration',        'NUMERIC', 'дюрация'},
	{'class_code',		'STRING', 'код класса'}
}

TRADES_PARAMS = 
{
	{'time',			'STRING',  'Время последней сделки'},
	{'last',			'NUMERIC', 'Цена последней сделки'},
	{'yield',			'NUMERIC', 'Доходность последней сделки'},
	{'numtrades',		'NUMERIC', 'количество сделок за сегодня'},
	{'voltoday',		'NUMERIC', 'оборот в бумагах'},
	{'valtoday',		'NUMERIC', 'оборот в деньгах'}
}


-- MARKET_CODES_RUB = {'TQCB', 'TQOB'}
-- MARKET_CODES_EURUSD = {'TQOD', 'TQOE'}
-- RPS_CODES_RUB = {'PTOB', 'PSOB'}
-- RPS_CODES_EUR = {'PSEO'}
-- RPS_CODES_USD = {'PTOD', 'PSEU'}




