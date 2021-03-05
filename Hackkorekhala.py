import base64
import subprocess
subprocess.call("curl -XPOST https://www.hackthebox.eu/api/invite/generate", shell=True) #The command to get the encypted invite-code
print('\n')
api = str(input("see the line =, copy it any paste here:\n==> ")) #To store the encrypted in a value
print('\n') #This steing will produce a new line
dec = str(base64.standard_b64decode(api)) #The Decrypted
print("[+]==> " + dec.replace('b', '')) #replacing th extra charater with a space
print('\n')
print("The format of the code is AAAA-BBBB-CCCC-DDDD-EEEE paste it in webiste") #This is The format of the code
print('\n')
