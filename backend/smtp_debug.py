import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
from decouple import Config, RepositoryEnv

# Load .env explicitly
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
env_path = os.path.join(BASE_DIR, '.env')
config = Config(RepositoryEnv(env_path))

def test_smtp_exchange():
    host = config('EMAIL_HOST')
    port = config('EMAIL_PORT', cast=int)
    user = config('EMAIL_HOST_USER')
    password = config('EMAIL_HOST_PASSWORD')
    use_tls = config('EMAIL_USE_TLS', cast=bool)
    recipient = 'hosimonorepo@gmail.com'

    print(f"Connecting to {host}:{port}...")
    
    msg = MIMEMultipart()
    msg['From'] = f"Hosi Academy <{user}>"
    msg['To'] = recipient
    msg['Subject'] = "SMTP Protocol Test"
    msg.attach(MIMEText("Testing the exact SMTP exchange protocol.", 'plain'))

    try:
        server = smtplib.SMTP(host, port, timeout=10)
        server.set_debuglevel(1) # This will show the full exchange!
        
        if use_tls:
            server.starttls()
            
        server.login(user, password)
        server.send_message(msg)
        server.quit()
        print("\n[SUCCESS] SMTP session completed.")
    except Exception as e:
        print(f"\n[ERROR] SMTP failed: {str(e)}")

if __name__ == "__main__":
    test_smtp_exchange()
