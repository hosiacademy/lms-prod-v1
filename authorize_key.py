import paramiko
import os

def authorize_key():
    host = "187.124.218.24"
    user = "root"
    password = "Hosi.Academy@2026"

    print(f"Connecting to {host} to authorize SSH key...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(host, username=user, password=password, timeout=30)
        print("Connected!")

        pub_key_path = os.path.expanduser("~/.ssh/id_rsa.pub")
        if os.path.exists(pub_key_path):
            with open(pub_key_path, "r") as f:
                pub_key = f.read().strip()
            
            # Use a more robust way to append the key
            cmd = f"mkdir -p ~/.ssh && chmod 700 ~/.ssh && grep -qF '{pub_key}' ~/.ssh/authorized_keys || echo '{pub_key}' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
            ssh.exec_command(cmd)
            print("SSH key authorized successfully!")
        else:
            print(f"Error: Public key {pub_key_path} not found!")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    authorize_key()
