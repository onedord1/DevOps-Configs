    [SERVICE]
      Daemon Off
      Flush 5
      Log_Level {{ .Values.logLevel }}
      Parsers_File /fluent-bit/etc/parsers.conf
      Parsers_File /fluent-bit/etc/conf/custom_parsers.conf
      HTTP_Server On
      HTTP_Listen 0.0.0.0
      HTTP_Port {{ .Values.metricsPort }}
      Health_Check On
    [INPUT]
      Name tail
      Path /var/log/containers/json*.log
      Tag test
      Mem_Buf_Limit 10MB
      Refresh_Interval 5
      Parser docker_trimmed    [FILTER]
      Name parser
      Match test
      Key_Name log
      Parser json_parser
      Reserve_Data On
    [OUTPUT]
        Name es
        Match test
        Host 172.17.19.61
        Port 9200
        TLS On
        TLS.Verify Off
        Suppress_Type_Name On
        Index test
        Retry_Limit False
        HTTP_User elastic
        HTTP_Passwd Elast1cPass014413
        Replace_Dots On
