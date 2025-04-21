# Create systemd service for quota tracking
cat > /etc/systemd/system/internet-quota-track.service << EOF
[Unit]
Description=Track Internet Time Quota
After=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/bin/internet-quota.sh track
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for quota reset
cat > /etc/systemd/system/internet-quota-reset.service << EOF
[Unit]
Description=Reset Internet Time Quota
After=network.target

[Service]
Type=oneshot
User=root
Group=root
ExecStart=/usr/local/bin/internet-quota.sh reset

[Install]
WantedBy=multi-user.target
EOF

# Create systemd timer for quota reset
cat > /etc/systemd/system/internet-quota-reset.timer << EOF
[Unit]
Description=Reset Internet Time Quota Timer

[Timer]
OnCalendar=*-*-* ${QUOTA_RESET_TIME}
Persistent=true

[Install]
WantedBy=timers.target
EOF 