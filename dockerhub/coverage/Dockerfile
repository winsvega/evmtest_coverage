FROM winsvega/retesteth:latest as retesteth
FROM winsvega/evmone-coverage:latest

COPY printhint.sh /printhint.sh
COPY entrypoint.sh /entrypoint.sh
COPY --from=retesteth /usr/bin/retesteth /usr/bin 
COPY check.sh /check.sh

RUN chmod +x /entrypoint.sh
RUN chmod +x /check.sh
ENTRYPOINT ["/entrypoint.sh"]
