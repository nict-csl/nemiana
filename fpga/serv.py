import socket
import re
import time
import sys
from pynq import Overlay
from pynq import MMIO
import numpy as np
from pynq import allocate # 利用可能な領域を確保するメソッドを利用可能にする

port_num = 5678

base = Overlay("./design_1.bit")
dma = base.axi_dma_0 # AXI DMA を操作するハンドラ
mmio0 = MMIO(base_addr = base.ip_dict['axi_gpio_0']['phys_addr'], length = 0x1000, debug = True)
mmio1 = MMIO(base_addr = base.ip_dict['axi_gpio_1']['phys_addr'], length = 0x1000, debug = True)


input_buffer  = allocate(shape=(512,), dtype=np.uint32)  # Numpy の配列からデータ受け渡し用の領域を確保
output_buffer = allocate(shape=(65536,), dtype=np.uint32) # Numpy の配列からデータ受け渡し用の領域を確保

CPU_RESET         = (1<<0)
RESTORE_MODE      = (1<<1)
UPDATE_REGISTER   = (1<<6)
UPDATE_PC         = (1<<7)
TRACE_FAULT       = (1<<13)
FIFO_START        = (1<<8)
FIFO_RESET        = (1<<9)
CPU_RESUME        = (1<<14)
UPDATE_FROM_DMA   = ((1<<15)|(1<<16))

p_state   = re.compile('GET /state HTTP/1.1')
p_trace   = re.compile('GET /trace HTTP/1.1')
p_write   = re.compile('POST /write HTTP/1.1')
p_resume  = re.compile('GET /resume HTTP/1.1')
p_reset   = re.compile('GET /reset HTTP/1.1')
p_init    = re.compile('GET /init HTTP/1.1')
p_exit    = re.compile('GET /exit HTTP/1.1')

attr_name_list=['state2_3','state2_2','state2_1','state2_0','fifo_enable','fifo_full','fifo_empty','start_flag','last_flag','valid_flag','m_tready','fifo_full2','fifo_empty2','cnt','stall_flag','aaa','iana_stall_requested_from_instruction']
attr_name_list.reverse()

def init():
    base = Overlay("./design_1.bit")
    dma = base.axi_dma_0 # AXI DMA を操作するハンドラ
    mmio0 = MMIO(base_addr = base.ip_dict['axi_gpio_0']['phys_addr'], length = 0x1000, debug = True)
    mmio1 = MMIO(base_addr = base.ip_dict['axi_gpio_1']['phys_addr'], length = 0x1000, debug = True)


def print_status(msg):
    status = mmio1.read(0)

    print(msg)
    i=0;
    for name in attr_name_list:
        if (status & (1<<i)) == 0:
            print(name,":",0)
        else:
            print(name,":",1)
        i = i + 1
    print
    
def get_trace():
    for i in range (len(output_buffer)):
        output_buffer[i] = 0xF0F0F0F0
    res="";

    status = mmio1.read(0)
    if (status & (1<<4))!=0:
        return ""
    
    mmio0.write(0, FIFO_START|TRACE_FAULT)
    time.sleep(0.1)
    i = 0
    while True:
        try:
            print_status("transfer ")
            rtn = dma.recvchannel.transfer(output_buffer)
            print ("transfer:", rtn);
            print_status("wait ")
            rtn = dma.recvchannel.wait()
            print ("recvchannel:", rtn);
            print_status("done ")
            mmio0.write(0, TRACE_FAULT)
            break;
        except RuntimeError:
            print("DMA no started")
            print_status("Exception ")
            time.sleep(0.1)
            mmio0.write(0, TRACE_FAULT)
            time.sleep(0.1)
            print_status("FIFO RESET ")
            mmio0.write(0, FIFO_START|TRACE_FAULT)
            time.sleep(0.1)
            print_status("FIFO RESTERT ")
        if i>10 :
            print ("Time out")
            sys.exit()
        i = i+1
            
    res = ""
    for i in range (2, int(len(output_buffer)/4)-1) :
        res = res + "attr2:"
        for j in range (4) :
            if(j==3) :
                res = res + "{0:08X}\n".format(output_buffer[i*4 + j])
            else:
                res = res + "{0:08X},".format(output_buffer[i*4 + j])
    return res

def cpu_write(str):
    print ("cpu_write:", str)

    input_buffer[0] = 0xDEADBEEF
    input_buffer[1] = 0xDEADBEEF
    input_buffer[2] = 0xDEADBEEF
    input_buffer[3] = 0xDEADBEEF
    input_buffer[4] = 0xDEADBEEF
    input_buffer[5] = 0xDEADBEEF
    input_buffer[6] = 0xDEADBEEF
    input_buffer[7] = 0xFFFFFFFF
    i=8
    while(i<16) :
        input_buffer[i] = 0
        i = i + 1

    datalist = str.splitlines()
    for s in datalist:
        print ("cpu_write s:", s)
        if re.search(r'[a-fA-F0-9]+\s+[a-fA-F0-9]+', s):
            print ("s=",s)
            d = s.split()
            if len(d) >= 2 :
                addr = int(d[0],16)
                data = int(d[1],16)
                print ("addr={:08X},data={:08X}".format(addr,data))
                input_buffer[i    ] = addr
                input_buffer[i + 1] = data
                i = i + 2
    print ("transfer")
    dma.sendchannel.transfer(input_buffer)
    print ("wait")
    dma.sendchannel.wait()
    print ("end")
    print ("wait update", file=sys.stderr);
    mmio0.write(0, TRACE_FAULT|RESTORE_MODE|UPDATE_FROM_DMA)
    time.sleep(0.1)
    mmio0.write(0, TRACE_FAULT)
    return "write success"

def cpu_resume():
    mmio0.write(0, CPU_RESUME|TRACE_FAULT)
    mmio0.write(0, TRACE_FAULT)
    return "cpu resumed"
    
def get_state():
    return "GPIO: {:08X}".format(mmio1.read(0))

def task(sock) :
    cmd = sock.recv(4096).decode()
    print(cmd)
    sendline=""
    exit_flag=False
    if p_state.match(cmd) :
        state = get_state()
        sendline = ("HTTP/1.0 200 OK\r\n\r\nstate {:1}".format(state)).encode('utf-8');
    elif p_trace.match(cmd) :
        data = "HTTP/1.0 200 OK\r\n\r\n";
        data = data + get_trace();
        sendline = data.encode('utf-8');
    elif p_write.match(cmd) :
        data = "HTTP/1.0 200 OK\r\n\r\n";
        data = data + cpu_write(cmd);
        data = data + cpu_write(cmd);
        data = data + cpu_write(cmd);
        sendline = data.encode('utf-8');
    elif p_resume.match(cmd) :
        data = "HTTP/1.0 200 OK\r\n\r\n";
        data = data + cpu_resume()
        sendline = data.encode('utf-8');
    elif p_reset.match(cmd) :
        reset()
        data = "HTTP/1.0 200 OK\r\n\r\n";
        data = data + "cpu reset\r\n";
        sendline = data.encode('utf-8');
    elif p_init.match(cmd) :
        init()
        reset()
        data = "HTTP/1.0 200 OK\r\n\r\n";
        data = data + "cpu initialized\r\n";
        sendline = data.encode('utf-8');
    elif p_exit.match(cmd) :
        data = "HTTP/1.0 200 OK\r\n\r\n";
        data = data + "This server will be exit.\r\n";
        sendline = data.encode('utf-8');
        exit_flag=True
    else:
        sendline = "HTTP/1.0 200 OK\r\n\r\nHello world!".encode('utf-8');
    sock.send(sendline)
    sock.close()
    if exit_flag:
        exit()

def reset() :
    time.sleep(0.01)
    mmio0.write(0, 1| FIFO_RESET)
    time.sleep(0.01)
    mmio0.write(0, 1| TRACE_FAULT)
    mmio0.write(0, TRACE_FAULT)
    time.sleep(0.01)
    

def main_loop() :    
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind((socket.gethostname(), port_num))
    s.listen(5)
    while True:
        clients,address=s.accept()
        task(clients)

if len(sys.argv)>2:
    port_num = int(sys.argv[1])
    
reset()
main_loop()
