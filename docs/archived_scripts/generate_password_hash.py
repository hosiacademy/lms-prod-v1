import hashlib
import os
import base64

def make_password(password, salt=None, iterations=1000000):
    if salt is None:
        salt = os.urandom(16).hex()
    
    password_bytes = password.encode('utf-8')
    salt_bytes = salt.encode('utf-8')
    
    # PBKDF2-HMAC-SHA256
    dk = hashlib.pbkdf2_hmac('sha256', password_bytes, salt_bytes, iterations)
    hash_value = base64.b64encode(dk).decode('ascii')
    
    return f'pbkdf2_sha256${iterations}${salt}${hash_value}'

# Generate password hash for 'teststudent'
hashed = make_password('teststudent')
print(hashed)
