FROM ghcr.io/anomalyco/opencode:latest

# Como a imagem original usa Alpine, mudamos para o root para instalar a compatibilidade
USER root

# Instala o libc6-compat que resolve o problema do TUI e do linkador dinâmico
RUN apk add --no-cache libc6-compat gcompat

# Devolve a execução para o comando padrão do opencode
ENTRYPOINT ["opencode"]
