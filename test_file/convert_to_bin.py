def swap_hex_halves(hex_string):
    # 将十六进制字符串分割为长度为4的片段，并交换每个片段的前两位和后两位
    swapped_hex = ''.join(hex_string[i:i+4][2:] + hex_string[i:i+4][:2] for i in range(0, len(hex_string), 4))
    return swapped_hex

def text_to_binary(input_file, output_file):
    try:
        with open(input_file, 'r') as file:
            lines = file.readlines()  # 逐行读取文件内容
            hex_content = ''.join(line.strip() for line in lines)  # 合并所有行的内容
            
            swapped_hex_content = swap_hex_halves(hex_content)

            # 将交换后的十六进制数据转换为二进制数据
            binary_content = bytes.fromhex(swapped_hex_content)

            # 将二进制数据写入文件
            with open(output_file, 'wb') as bin_file:
                bin_file.write(binary_content)
            fileline = file.readline()
                    

    except FileNotFoundError:
        print(f"文件 '{input_file}' 未找到。")

def read_binary_file(file_name):
    try:
        with open(file_name, 'rb') as file:
            content = file.read()
            hex_content = content.hex()
            print(hex_content)
    except FileNotFoundError:
        print(f"文件 '{file_name}' 未找到。")

input_file_name = 'nc3.txt'  # 你的文本文件名
output_file_name = 'nc3.bin'  # 要保存的二进制文件名

text_to_binary(input_file_name, output_file_name)
read_binary_file(output_file_name)

