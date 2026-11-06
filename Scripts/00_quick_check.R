# ==============================================================================
# SCRIPT RÁPIDO - Verificação Inicial dos Dados
# Execute este script PRIMEIRO para ver a estrutura dos arquivos
# ==============================================================================

library(readxl)

setwd("C:/Users/Trovao/Desktop/Artigo - Economia Regional")

cat("=== VERIFICAÇÃO RÁPIDA DOS DADOS ===\n\n")

# 1. IGs
cat("1. INDICAÇÕES GEOGRÁFICAS\n")
cat("Carregando...\n")
igs <- read_excel("Dados/IGs_Brasil_INPI_x_DataSebrae.xlsx")
cat("Linhas:", nrow(igs), "| Colunas:", ncol(igs), "\n")
cat("Colunas:", paste(names(igs), collapse = ", "), "\n")
cat("Primeiras 3 linhas:\n")
print(head(igs, 3))

cat("\n\n2. IFDM\n")
cat("Carregando...\n")
ifdm <- read_excel("Dados/IFDM_2013_2023_painel_tratado.xlsx")
cat("Linhas:", nrow(ifdm), "| Colunas:", ncol(ifdm), "\n")
cat("Colunas:", paste(names(ifdm), collapse = ", "), "\n")

cat("\n\n3. PIB MUNICIPAL\n")
cat("Carregando... (pode demorar 10-20s)\n")
pib <- read_excel("Dados/PIB_Municipal_2002_2023_painel_IG.xlsx")
cat("Linhas:", nrow(pib), "| Colunas:", ncol(pib), "\n")
cat("Colunas:", paste(names(pib), collapse = ", "), "\n")

cat("\n\n✓ PRONTO! Copie e cole toda essa saída aqui para mim.\n")
