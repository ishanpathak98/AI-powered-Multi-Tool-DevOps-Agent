# AI-powered-Multi-Tool-DevOps-Agent
An AI-powered multi-tool DevOps agent that automates infrastructure monitoring, anomaly detection, root cause analysis, and remediation.
The agent will handle two main workflows:

1️⃣ CPU Spike Detection & Analysis Agent
Using Prometheus Node Exporter on an AWS EC2 instance:
Continuously monitor CPU usage.


Detect CPU spikes exceeding defined thresholds.


Retrieve relevant logs for the incident window.


Analyze logs using an LLM to identify potential root causes (e.g., memory leaks, infinite loops).



2️⃣ Auto Remediation Agent
Upon validated detection:
Automatically restart the failing container/service on the instance.


Verify system stability post-remediation.


Notify users via Slack/email with a clear incident summary and action taken.
