import base64
import subprocess
subprocess.call("curl -XPOST https://www.hackthebox.eu/api/invite/generate", shell=True)
print('\n')
api = str(input("see the line =, copy it any paste here:\n==> ")) 
print('\n') #This steing will produce a new line
dec = str(base64.standard_b64decode(api)) 
print("[+]==> " + dec.replace('b', ''))
print('\n')
print("The format of the code is AAAA-BBBB-CCCC-DDDD-EEEE paste it in webiste") 
print('\n')
