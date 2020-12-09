
MARKET_CLASS_CODES = {'TQCB', 'TQOB'}
RPS_CLASS_CODES = {'PTOB', 'PSOB', 'PSEO', 'PTOD', 'PSEU'}

BOND_MAIN_INFO = 
{
	{'isincode',		'STRING', 'isin'},
	{'code',			'STRING', '��� ������'},
	{'shortname',       'STRING', '������� �������� ������'},
	{'longname',        'STRING', '������ �������� ������'},
	{'regnumber',       'STRING', '��������� �����'},
	{'sectypestatic',   'STRING', '��� �����������'},
	{'secsubtypestatic','STRING', '������ �����������'},
	{'tradingstatus',	'STRING', '��������� ������'},
	{'listlevel', 	    'INT', '�������'},
	{'lotsize',         'INT', '������ ����'},
	{'sec_face_unit',	'STRING', '������ ��������'},
	{'issuesize',		'NUMERIC', '����� ���������'},
	{'mat_date',		'STRING', '���� ���������'},
	{'days_to_mat_date','INT', '����� ���� �� ���������'},
	
	{'sec_face_value',	'NUMERIC', '������������ ������� ������'},
	{'accruedint',		'NUMERIC', '����������� �������� �����'},
	{'couponvalue',		'NUMERIC', '������ ������ � ������ ��������'},
	{'nextcoupon',		'STRING', '���� ������� ������'},
	{'couponperiod',	'INT', '������������ ������ � ����'},
	
	{'buybackdate',		'STRING', '���� ������, ���� ����'},
	{'settledate',		'STRING', '���� �������� �� ������'},
	{'trade_date_code',	'STRING', '���� ������'}
}

BOND_REALTIME_PARAMS = 
{
	{'isincode',		'STRING', 'isin'},
	{'class_code',		'STRING', '��� ������'},
	{'code',			'STRING', '��� ������'},
	{'bid',				'NUMERIC', '�����'},
	{'offer',			'NUMERIC', '�����������'},
	{'duration',        'NUMERIC', '�������'},
	{'time',			'STRING',  '����� ��������� ������'},
	{'last',			'NUMERIC', '���� ��������� ������'},
	{'yield',			'NUMERIC', '���������� ��������� ������'},
	{'numtrades',		'NUMERIC', '���������� ������ �� �������'},
	{'voltoday',		'NUMERIC', '������ � �������'},
	{'valtoday',		'NUMERIC', '������ � �������'}
}

BOND_REALTIME_RPS_PARAMS = 
{
	{'isincode',		'STRING', 'isin'},
	{'class_code',		'STRING', '��� ������'},
	{'code',			'STRING', '��� ������'},
	{'time',			'STRING',  '����� ��������� ������'},
	{'last',			'NUMERIC', '���� ��������� ������'},
	{'yield',			'NUMERIC', '���������� ��������� ������'},
	{'numtrades',		'NUMERIC', '���������� ������ �� �������'},
	{'voltoday',		'NUMERIC', '������ � �������'},
	{'valtoday',		'NUMERIC', '������ � �������'}
}

BOND_REALTIME_CHANGECHECK_PARAMS = 
{
	{'bid',				'NUMERIC', '�����'},
	{'offer',			'NUMERIC', '�����������'},
	{'duration',        'NUMERIC', '�������'},
	{'time',			'STRING',  '����� ��������� ������'}
}

-- MARKET_CODES_RUB = {'TQCB', 'TQOB'}
-- MARKET_CODES_EURUSD = {'TQOD', 'TQOE'}
-- RPS_CODES_RUB = {'PTOB', 'PSOB'}
-- RPS_CODES_EUR = {'PSEO'}
-- RPS_CODES_USD = {'PTOD', 'PSEU'}






