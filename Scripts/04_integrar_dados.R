# ==============================================================================
# Script 04: Integração de Dados
# Objetivo: Criar base única com IGs + IFDM + PIB + covariáveis
# ==============================================================================

rm(list = ls())

library(readxl)
library(dplyr)
library(tidyr)
library(stringr)

setwd("C:/Users/Trovao/Desktop/Artigo - Economia Regional")

cat("\n=== INTEGRAÇÃO DE DADOS PARA PSM ===\n\n")

# ==============================================================================
# 1. CARREGAR DADOS
# ==============================================================================

cat("1. Carregando dados...\n")

# IGs
igs <- read_excel("Dados/IGs_Brasil_INPI_x_DataSebrae.xlsx")
cat("  ✓ IGs carregadas:", nrow(igs), "registros\n")

# IFDM
ifdm <- read_excel("Dados/IFDM_2013_2023_painel_tratado.xlsx")
cat("  ✓ IFDM carregado:", nrow(ifdm), "observações\n")

# PIB
pib <- read_excel("Dados/PIB_Municipal_2002_2023_painel_IG.xlsx")
cat("  ✓ PIB carregado:", nrow(pib), "observações\n")

# ==============================================================================
# 2. PREPARAR DADOS DE IGs
# ==============================================================================

cat("\n2. Preparando dados de IGs...\n")

# Identificar colunas (AJUSTAR conforme estrutura real!)
# Assumindo que há colunas: cod_municipio, nome_municipio, produto, ano_registro

# Criar variável de tratamento
igs_tratamento <- igs %>%
  mutate(
    # Classificar produto
    Produto_Categoria = case_when(
      str_detect(tolower(Produto), "café|coffee") ~ "Café",
      str_detect(tolower(Produto), "vinho|wine|espumante") ~ "Vinho",
      str_detect(tolower(Produto), "queijo") ~ "Queijo",
      str_detect(tolower(Produto), "cachaça") ~ "Cachaça",
      str_detect(tolower(Produto), "mel") ~ "Mel",
      str_detect(tolower(Produto), "fruta|banana|laranja") ~ "Frutas",
      TRUE ~ "Outros"
    ),
    # Variável de tratamento
    IG_Cafe = ifelse(Produto_Categoria == "Café", 1, 0),
    IG_Vinho = ifelse(Produto_Categoria == "Vinho", 1, 0),
    IG_Agricola = ifelse(Produto_Categoria %in% c("Café", "Vinho", "Queijo",
                                                    "Cachaça", "Mel", "Frutas"), 1, 0)
  )

# Resumir por município
igs_municipio <- igs_tratamento %>%
  group_by(cod_municipio) %>%  # AJUSTAR nome da coluna!
  summarise(
    IG_Cafe = max(IG_Cafe),
    IG_Vinho = max(IG_Vinho),
    IG_Agricola = max(IG_Agricola),
    N_IGs = n(),
    Ano_Primeira_IG = min(Ano_Registro, na.rm = TRUE)  # AJUSTAR!
  )

cat("  ✓ Municípios com IG Café:", sum(igs_municipio$IG_Cafe), "\n")
cat("  ✓ Municípios com IG Vinho:", sum(igs_municipio$IG_Vinho), "\n")
cat("  ✓ Municípios com IG Agrícola:", sum(igs_municipio$IG_Agricola), "\n")

# ==============================================================================
# 3. INTEGRAR COM IFDM (variável de resultado)
# ==============================================================================

cat("\n3. Integrando com IFDM...\n")

# Pegar anos mais recentes (2018, 2019, 2020) para análise cross-section
# Ou fazer painel completo se quiser

ifdm_recente <- ifdm %>%
  filter(Ano >= 2018) %>%  # AJUSTAR conforme disponibilidade
  group_by(cod_municipio) %>%  # AJUSTAR nome!
  summarise(
    IFDM = mean(IFDM, na.rm = TRUE),
    IFDM_Emprego = mean(IFDM_Emprego, na.rm = TRUE),  # AJUSTAR nomes!
    IFDM_Educacao = mean(IFDM_Educacao, na.rm = TRUE),
    IFDM_Saude = mean(IFDM_Saude, na.rm = TRUE)
  )

cat("  ✓ Municípios no IFDM:", nrow(ifdm_recente), "\n")

# ==============================================================================
# 4. INTEGRAR COM PIB (covariável + resultado)
# ==============================================================================

cat("\n4. Integrando com PIB...\n")

# Pegar anos recentes
pib_recente <- pib %>%
  filter(Ano >= 2018) %>%  # AJUSTAR!
  group_by(cod_municipio) %>%
  summarise(
    PIB_Total = mean(PIB_Total, na.rm = TRUE),  # AJUSTAR nomes!
    PIB_Percapita = mean(PIB_Percapita, na.rm = TRUE),
    VA_Agropecuaria = mean(VA_Agropecuaria, na.rm = TRUE),
    VA_Industria = mean(VA_Industria, na.rm = TRUE),
    VA_Servicos = mean(VA_Servicos, na.rm = TRUE),
    # Participação da agropecuária
    Part_Agro = (VA_Agropecuaria / PIB_Total) * 100
  )

cat("  ✓ Municípios no PIB:", nrow(pib_recente), "\n")

# ==============================================================================
# 5. JUNTAR TUDO
# ==============================================================================

cat("\n5. Criando base integrada...\n")

base_completa <- ifdm_recente %>%
  left_join(pib_recente, by = "cod_municipio") %>%
  left_join(igs_municipio, by = "cod_municipio") %>%
  mutate(
    # Preencher NAs de tratamento com 0 (não tem IG)
    IG_Cafe = ifelse(is.na(IG_Cafe), 0, IG_Cafe),
    IG_Vinho = ifelse(is.na(IG_Vinho), 0, IG_Vinho),
    IG_Agricola = ifelse(is.na(IG_Agricola), 0, IG_Agricola)
  )

cat("  ✓ Base completa:", nrow(base_completa), "municípios\n")
cat("  ✓ Variáveis:", ncol(base_completa), "\n\n")

# ==============================================================================
# 6. ESTATÍSTICAS DESCRITIVAS POR GRUPO
# ==============================================================================

cat("=== ESTATÍSTICAS DESCRITIVAS ===\n\n")

# Café
cat("MUNICÍPIOS COM IG CAFÉ:\n")
cafe_stats <- base_completa %>%
  filter(IG_Cafe == 1) %>%
  summarise(
    N = n(),
    IFDM_medio = mean(IFDM, na.rm = TRUE),
    PIB_PC_medio = mean(PIB_Percapita, na.rm = TRUE),
    Part_Agro_media = mean(Part_Agro, na.rm = TRUE)
  )
print(cafe_stats)

cat("\nMUNICÍPIOS SEM IG CAFÉ:\n")
sem_cafe_stats <- base_completa %>%
  filter(IG_Cafe == 0) %>%
  summarise(
    N = n(),
    IFDM_medio = mean(IFDM, na.rm = TRUE),
    PIB_PC_medio = mean(PIB_Percapita, na.rm = TRUE),
    Part_Agro_media = mean(Part_Agro, na.rm = TRUE)
  )
print(sem_cafe_stats)

# Vinho
cat("\n\nMUNICÍPIOS COM IG VINHO:\n")
vinho_stats <- base_completa %>%
  filter(IG_Vinho == 1) %>%
  summarise(
    N = n(),
    IFDM_medio = mean(IFDM, na.rm = TRUE),
    PIB_PC_medio = mean(PIB_Percapita, na.rm = TRUE),
    Part_Agro_media = mean(Part_Agro, na.rm = TRUE)
  )
print(vinho_stats)

# ==============================================================================
# 7. SALVAR BASE INTEGRADA
# ==============================================================================

cat("\n\n7. Salvando base integrada...\n")

write.csv(base_completa,
          "Resultados/base_integrada_psm.csv",
          row.names = FALSE,
          fileEncoding = "UTF-8")

# Salvar bases separadas para cada análise
base_cafe <- base_completa %>%
  select(cod_municipio, IG_Cafe, IFDM, PIB_Percapita, Part_Agro, everything())

base_vinho <- base_completa %>%
  select(cod_municipio, IG_Vinho, IFDM, PIB_Percapita, Part_Agro, everything())

base_agricola <- base_completa %>%
  select(cod_municipio, IG_Agricola, IFDM, PIB_Percapita, Part_Agro, everything())

write.csv(base_cafe, "Resultados/base_cafe_psm.csv", row.names = FALSE)
write.csv(base_vinho, "Resultados/base_vinho_psm.csv", row.names = FALSE)
write.csv(base_agricola, "Resultados/base_agricola_psm.csv", row.names = FALSE)

cat("  ✓ Arquivos salvos em Resultados/\n")
cat("\n\n✓ INTEGRAÇÃO CONCLUÍDA COM SUCESSO!\n")
cat("\nPróximo passo: Executar 05_PSM.R\n")
