# syntax=docker/dockerfile:1
FROM python:3.11-slim

# 安裝系統工具
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl git podman \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 安裝 ansible-navigator（ansible-core 作為 dependency 一併安裝）
RUN pip install --no-cache-dir ansible-navigator ansible-core

WORKDIR /app

# 安裝 Python 套件
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Clone Ansible repos（兩者皆為 public repo，不需要任何 token）
# CCChou/OpenShift-Automation：
#   - /app/automation       → Ansible playbook 執行入口（AUTOMATION_DIR）
#   - /root/OpenShift-Automation → Ansible roles 查找路徑（ansible.cfg roles_path）
RUN git clone https://github.com/CCChou/OpenShift-Automation.git /app/automation && \
    git clone https://github.com/CCChou/OpenShift-Automation.git /root/OpenShift-Automation

# 複製 backend 程式碼
# frontend/dist 不在此 image 內，main.py 的靜態 serve 會自動跳過
COPY . .

RUN mkdir -p /app/vars /app/logs

ENV SITE_VARS_PATH=/app/vars/site.yml
ENV LOG_DIR=/app/logs
ENV AUTOMATION_DIR=/app/automation
ENV IMAGESET_PATH=/app/automation/yaml/imageset-config.yaml

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:8000/api/health || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
