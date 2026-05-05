import paramiko
from scp import SCPClient
import os
import sys
import traceback

def deploy():
    host = "187.124.218.24"
    user = "root"
    password = "Hosi.Academy@2026"
    remote_path = "/opt/lms-prod"
    local_archive = r"C:\lms-prod\web_build.tar.gz"

    if not os.path.exists(local_archive):
        print(f"Error: Local archive {local_archive} not found!")
        return

    print(f"Connecting to {host}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(host, username=user, password=password, timeout=30)
        print("Connected successfully!")

        # Step 1: Add local public key
        print("Authorizing local SSH key...")
        pub_key_path = os.path.expanduser("~/.ssh/id_rsa.pub")
        if os.path.exists(pub_key_path):
            with open(pub_key_path, "r") as f:
                pub_key = f.read().strip()
            ssh.exec_command(f"mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '{pub_key}' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys")
            print("SSH key authorized!")

        # Step 2: Upload archive
        print(f"Uploading {local_archive} to {remote_path}...")
        def progress(filename, size, sent):
            sys.stdout.write(f"\rProgress: {sent}/{size} bytes ({(sent/size)*100:.1f}%)")
            sys.stdout.flush()

        with SCPClient(ssh.get_transport(), progress=progress) as scp:
            scp.put(local_archive, remote_path + "/web_build.tar.gz")
        print("\nUpload complete!")

        # Step 3: Run remote commands
        commands = [
            f"cd {remote_path}",
            "echo 'Stopping existing frontend container...'",
            "docker stop lms-prod-frontend-1 2>/dev/null || true",
            "docker rm lms-prod-frontend-1 2>/dev/null || true",
            "echo 'Clearing old files...'",
            "rm -rf frontend/prebuilt_web",
            "mkdir -p frontend/prebuilt_web",
            "echo 'Extracting new build...'",
            "tar -xzf web_build.tar.gz -C frontend/prebuilt_web/",
            "rm web_build.tar.gz",
            "echo 'Setting permissions...'",
            "chmod -R 755 frontend/prebuilt_web/",
            "echo 'Starting new frontend container...'",
            f"docker run -d --name lms-prod-frontend-1 --network lms-prod_lms_network -p 7000:80 -v {remote_path}/frontend/prebuilt_web:/usr/share/nginx/html:ro nginx:alpine",
            "echo 'Updating backend code...'",
            "git pull origin master || echo 'Git pull failed, continuing...'",
            "echo 'Rebuilding backend services...'",
            "docker compose build --no-cache backend celery celery-2 celery-beat socketio flower",
            "echo 'Running migrations...'",
            "docker compose run --rm backend python manage.py migrate",
            "echo 'Starting services...'",
            "docker compose up -d",
            "echo 'Cleaning up old images...'",
            "docker system prune -f",
            "echo 'Restarting Nginx...'",
            "docker restart lms_nginx 2>/dev/null || echo 'Nginx container not found'"
        ]

        # Join commands with semicolon instead of && to continue on individual failures
        full_cmd = "; ".join(commands)
        print("Executing remote deployment commands...")
        stdin, stdout, stderr = ssh.exec_command(full_cmd)
        
        # Read output in real-time
        while not stdout.channel.exit_status_ready():
            if stdout.channel.recv_ready():
                line = stdout.channel.recv(1024).decode(errors='replace')
                sys.stdout.write(line)
                sys.stdout.flush()
        
        print("\nDeployment finished!")

    except Exception as e:
        print(f"\nAn error occurred: {e}")
        traceback.print_exc()
    finally:
        ssh.close()

if __name__ == "__main__":
    deploy()
