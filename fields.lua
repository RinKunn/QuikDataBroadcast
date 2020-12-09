
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

BOND_REALTIME_PARAMS = 
{
	{'isincode',		'STRING', 'isin'},
	{'class_code',		'STRING', 'код класса'},
	{'code',			'STRING', 'код бумаги'},
	{'bid',				'NUMERIC', 'спрос'},
	{'offer',			'NUMERIC', 'предложение'},
	{'duration',        'NUMERIC', 'дюраци€'},
	{'time',			'STRING',  '¬рем€ последней сделки'},
	{'last',			'NUMERIC', '÷ена последней сделки'},
	{'yield',			'NUMERIC', 'ƒоходность последней сделки'},
	{'numtrades',		'NUMERIC', 'количество сделок за сегодн€'},
	{'voltoday',		'NUMERIC', 'оборот в бумагах'},
	{'valtoday',		'NUMERIC', 'оборот в деньгах'}
}

BOND_REALTIME_RPS_PARAMS = 
{
	{'isincode',		'STRING', 'isin'},
	{'class_code',		'STRING', 'код класса'},
	{'code',			'STRING', 'код бумаги'},
	{'time',			'STRING',  '¬рем€ последней сделки'},
	{'last',			'NUMERIC', '÷ена последней сделки'},
	{'yield',			'NUMERIC', 'ƒоходность последней сделки'},
	{'numtrades',		'NUMERIC', 'количество сделок за сегодн€'},
	{'voltoday',		'NUMERIC', 'оборот в бумагах'},
	{'valtoday',		'NUMERIC', 'оборот в деньгах'}
}

BOND_REALTIME_CHANGECHECK_PARAMS = 
{
	{'bid',				'NUMERIC', 'спрос'},
	{'offer',			'NUMERIC', 'предложение'},
	{'duration',        'NUMERIC', 'дюраци€'},
	{'time',			'STRING',  '¬рем€ последней сделки'}
}

-- MARKET_CODES_RUB = {'TQCB', 'TQOB'}
-- MARKET_CODES_EURUSD = {'TQOD', 'TQOE'}
-- RPS_CODES_RUB = {'PTOB', 'PSOB'}
-- RPS_CODES_EUR = {'PSEO'}
-- RPS_CODES_USD = {'PTOD', 'PSEU'}






