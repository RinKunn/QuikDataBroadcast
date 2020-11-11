from datetime import datetime
import socket
import json

local_host = '127.0.0.1'
local_port = 9090

remote_host = '82.148.31.138'
remote_port = 9090

def socket_server(s_host, s_port):

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((s_host, s_port))
        s.listen()
        print('Server running at %s:%s'%(s_host, s_port))
        while True:
            conn, addr = s.accept()
            with conn:
                print('Connected by', addr)
                while True:
                    bpackage = conn.recv(2048)
                    if not bpackage:
                        break
                    try:
                        #handle_package(bpackage)
                        print_handle_package(bpackage)
                    except Exception as ex:
                        print(ex, data)


def handle_clean_bpackage(bpackage):
    package = bpackage.decode('cp1251')
    data_collection = package.split('\n')[:-1]
    for data in data_collection:
        jsondata = json.loads(data)
        print(jsondata)


def package_clean(bpackage):
    if (bpackage[-1:] == b'\n' and bpackage[:1] == b'{'):
        return True
    return False


partial_packages = b''

def handle_package(bpackage):
    global partial_packages
    if (package_clean(bpackage)):
        handle_clean_bpackage(bpackage)
    else:
        print ('---get partial package!')
        partial_packages += bpackage
        if (package_clean(partial_packages)):
            handle_clean_bpackage(partial_packages)
            print ('---partial packages successful concatenated ')
            partial_packages = b''

def print_handle_package(bpackage):
    package = bpackage.decode('cp1251')
    print (package)

socket_server(local_host, local_port)