from pynq import Overlay
from pynq import GPIO
from pynq import MMIO
from pynq import allocate
import pynq.lib.dma
from time import sleep
import numpy as np

Darwin = Overlay("./pynq/design_1_wrapper.bit")
BASE_ADDRESS = 0x43C00000
ADDRESS_RANGE = 0xFFFF

def Darwin_rst():
    tik = GPIO(GPIO.get_gpio_pin(2), 'out')
    rst = GPIO(GPIO.get_gpio_pin(3), 'out')
    tik.write(0)
    rst.write(0)
    sleep(0.1)
    rst.write(1)

def Darwin_tik():
    tik = GPIO(GPIO.get_gpio_pin(2), 'out')
    tik.write(1)
    sleep(0.1)
    tik.write(0)

def swap_hex_halves(hex_string):
    # 将十六进制字符串分割为长度为4的片段，并交换每个片段的前两位和后两位
    swapped_hex = ''.join(hex_string[i:i+4][2:] + hex_string[i:i+4][:2] for i in range(0, len(hex_string), 4))
    return swapped_hex

def set_direction(d):
    if d == 'E':
        mmio.write(0x0, 0x0)
    elif d == 'S' :
        mmio.write(0x0, 0x1)
    elif d == 'W' :
        mmio.write(0x0, 0x2)
    elif d == 'N' :
        mmio.write(0x0, 0x3)
    else :
        mmio.write(0x0, 0x2) #default west
        
def send_data(input_file):
    with open(input_file, 'r') as file:
        lines = file.readlines()
        hex_content = ''.join(line.strip() for line in lines)
        swapped_hex_content = swap_hex_halves(hex_content)

        #input_buffer = allocate(shape=(1024,), dtype='u4')
        input_buffer = xlnk.cma_array(shape=(1024,), dtype=np.uint32)
        for i in range(0, len(swapped_hex_content), 8) :
            print(swapped_hex_content[i:i+8])
            input_buffer[i] = swapped_hex_content[i:i+8]

        dma.sendchannel.transfer(input_buffer)
        dma.sendchannel.wait()

        del input_buffer

def receive_data():
    receive_length = mmio.read(12)
    output_buffer = allocate(shape=(receive_length*2,), dtype=np.uint32)
    dma.recvchannel.transfer(output_buffer)
    dma.recvchannel.wait()
    
    for i in(0, receive_length/2):
        print(output_buffer[i])

    del output_buffer

def receive_data_all():
    receive_length = mmio.read(12)
    print("receive_length = {}".format(receive_length))
   
    output_buffer = xlnk.cma_array(shape=(receive_length//2,), dtype=np.uint32)
    dma.recvchannel.transfer(output_buffer)
    dma.recvchannel.wait()
    for i in range(receive_length//2) :
        print(hex(output_buffer[0]))
    del output_buffer




print("Darwin reset ...")
Darwin_rst()
mmio = MMIO(BASE_ADDRESS, ADDRESS_RANGE) #mapping

set_direction('W') 

dma = Darwin.axi_dma
input_file = "./test_file/input.txt"
send_data(input_file)
receive_data()




8040 0020
4080 2000
