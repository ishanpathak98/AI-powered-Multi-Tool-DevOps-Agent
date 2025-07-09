# 🤖 DevOps AI Agent – Ishan Pathak

An AI-powered multi-tool DevOps Agent that automates infrastructure monitoring, anomaly detection, root cause analysis, and auto-remediation — designed using AWS, Terraform, Prometheus, Python, and LLMs (OpenAI/Ollama).

---

## 📌 Project Overview

This agent handles two core workflows:

### 1️⃣ CPU Spike Detection & Analysis
- Continuously monitors CPU usage using Prometheus Node Exporter.
- Detects spikes (e.g., >80% for 2+ minutes).
- Retrieves logs during anomaly window.
- Analyzes logs using LLM (OpenAI or Ollama) to identify root causes (e.g., memory leaks, infinite loops).

### 2️⃣ Auto Remediation & Notification
- If confident, restarts the affected container or service.
- Verifies system health post-remediation.
- Notifies via Slack/email with a detailed incident summary and actions taken.

---

## ⚙️ Tech Stack

| Layer | Tools Used |
|------|------------|
| 🧱 Infrastructure | AWS EC2 (Free Tier), Terraform |
| 🔍 Monitoring | Prometheus, Node Exporter |
| 📜 Log Collection | File-based logs or Loki (optional) |
| 🧠 AI Analysis | OpenAI API or Ollama (local LLM) |
| 🔁 Remediation | Docker, systemctl |
| 📩 Notifications | Slack Webhook, SMTP (optional) |
| 🧠 Orchestration | LangChain or Custom Python Agent |
| 🖥️ Frontend (Optional) | Streamlit |

---

## 📁 Project Structure

DevOpsAgent-IshanPathak/
├── terraform/ # Terraform IaC for AWS Infra
│ ├── main.tf
│ ├── variables.tf
│ ├── outputs.tf
│ └── user_data.sh
├── agents/ # Python agent modules
│ ├── monitor.py # CPU Monitoring tool
│ ├── analyzer.py # Log analysis using LLM
│ ├── remediator.py # Auto-remediation logic
│ └── notifier.py # Slack/email notifications
├── logs/ # Sample synthetic logs
├── frontend/ # Optional Streamlit dashboard
├── tests/ # Test scenarios and scripts
├── requirements.txt
├── run_agent.py # Main orchestrator
└── README.md



---

## 🏗️ Deployment Phases

### Phase 1: Infrastructure Setup (Terraform)
- Deploy EC2 (Ubuntu 22.04 t2.micro) with Docker, Prometheus Node Exporter, Python.
- Set up security groups, IAM roles, and basic monitoring stack.

### Phase 2: Monitoring Agent
- Prometheus fetches CPU metrics from Node Exporter.
- Python script polls Prometheus API to detect CPU spikes.

### Phase 3: Log Analysis Agent
- Logs retrieved from `/var/log/syslog` or `docker logs`.
- Sent to OpenAI or Ollama with a custom prompt.
- Root cause returned and parsed.

### Phase 4: Auto Remediation Agent
- If LLM suggests a fix with high confidence:
  - Restart Docker container or service.
  - Recheck CPU to confirm fix.
- Logs the fix taken.

### Phase 5: Notification Agent
- Sends Slack/email with:
  - Spike details
  - Root cause analysis
  - Action taken

---

## ✅ Bonus Features

- Extend to monitor **memory**, **disk**, and **network** spikes.
- **CI/CD Integration** via GitHub Actions monitoring.
- **Incident Archive** in SQLite or ChromaDB.
- **Auto Post-Mortems** using GDocs/Notion API.
- **Predictive Analysis** using Prophet/ARIMA for CPU trends.

---

## 🧪 Testing Scenarios

| Scenario | Validation |
|----------|------------|
| CPU Spike | Simulate via `while true; do :; done` |
| Log Analysis | Inject synthetic errors (e.g., OOM, infinite loop) |
| Auto Remediation | Kill container and validate restart |
| Notification | Confirm Slack/email alerts with summary |

---

## 📽️ Demo Video (Coming Soon)

A video walkthrough showcasing:
- CPU spike detection
- Log analysis using LLM
- Auto-remediation
- Notification summary

⏳ Duration: Under 15 mins

---

## 🙌 Acknowledgements

- Inspired by best practices in DevOps automation and AIOps
- Built using open-source tools: Prometheus, LangChain, Docker, OpenAI, Streamlit, etc.

---

## 📄 License

This project is open-source and licensed under the MIT License.

