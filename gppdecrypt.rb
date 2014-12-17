require 'rubygems'

require 'openssl'

require 'base64'





encrypted_data = ARGV



def decrypt(encrypted_data)

padding = "=" * (4 - (encrypted_data.length % 4))

epassword = "#{encrypted_data}#{padding}"

decoded = Base64.decode64(epassword)



key = "\x4e\x99\x06\xe8\xfc\xb6\x6c\xc9\xfa\xf4\x93\x10\x62\x0f\xfe\xe8\xf4\x96\xe8\x06\xcc\x05\x79\x90\x20\x9b\x09\xa4\x33\xb6\x6c\x1b"

aes = OpenSSL::Cipher::Cipher.new("AES-256-CBC")

aes.decrypt

aes.key = key

plaintext = aes.update(decoded)

plaintext << aes.final

pass = plaintext.unpack('v*').pack('C*') # UNICODE conversion



return pass

end



blah = decrypt(encrypted_data)

puts blah
