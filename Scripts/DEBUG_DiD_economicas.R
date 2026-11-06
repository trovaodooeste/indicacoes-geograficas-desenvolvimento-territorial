# ==============================================================================
# DEBUG: DiD com Variáveis Econômicas
# Objetivo: Identificar problema na integração IFDM + PIB
# ==============================================================================

.libPaths(c("~/R/library", .libPaths()))

rm(list = ls())

library(readxl)
library(dplyr)
library(tidyr)
library(stringr)

setwd("/mnt/c/Users/Trovao/Desktop/Artigo - Economia Regional")

cat("\n=== DEBUG: DiD com Variáveis Econômicas ===\n\n")

# ==============================================================================
# 1. CARREGAR MUNICÍPIOS PAREADOS
# ==============================================================================

cat("1. Carregando municípios pareados...\n")
base_matched <- read.csv("Resultados/base_cafe_matched.csv")
cod_pareados <- unique(base_matched$cod_municipio)
cat("  ✓ Municípios pareados:", length(cod_pareados), "\n")
cat("  ✓ Tratados:", sum(base_matched$IG_Cafe), "\n")
cat("  ✓ Controles:", sum(base_matched$IG_Cafe == 0), "\n\n")

# ==============================================================================
# 2. CARREGAR IFDM (PAINEL)
# ==============================================================================

cat("2. Carregando IFDM (painel)...\n")
ifdm <- read_excel("Dados/IFDM_2013_2023_painel_tratado.xlsx",
                   sheet = "Painel IFDM 2013-2023") %>%
  filter(cod_municipio %in% cod_pareados)

cat("  ✓ Observações IFDM:", nrow(ifdm), "\n")
cat("  ✓ Anos:", paste(sort(unique(ifdm$ano)), collapse=", "), "\n")
cat("  ✓ Municípios únicos:", n_distinct(ifdm$cod_municipio), "\n")
cat("  ✓ Colunas IFDM:", paste(names(ifdm), collapse=", "), "\n\n")

# ==============================================================================
# 3. CARREGAR PIB (PAINEL)
# ==============================================================================

cat("3. Carregando PIB (painel)...\n")
pib_raw <- read_excel("Dados/PIB_Municipal_2002_2023_painel_IG.xlsx",
                      sheet = "Painel 2002-2023")

cat("  Colunas PIB (raw):\n")
print(names(pib_raw))
cat("\n")

# Padronizar código
pib <- pib_raw %>%
  mutate(cod_municipio = floor(cod_municipio / 10)) %>%
  filter(cod_municipio %in% cod_pareados)

cat("  ✓ Observações PIB:", nrow(pib), "\n")
cat("  ✓ Anos:", paste(sort(unique(pib$ano)), collapse=", "), "\n")
cat("  ✓ Municípios únicos:", n_distinct(pib$cod_municipio), "\n\n")

# Verificar sobreposição IFDM x PIB
cat("4. Verificando sobreposição IFDM x PIB...\n")

anos_ifdm <- sort(unique(ifdm$ano))
anos_pib <- sort(unique(pib$ano))
anos_comuns <- intersect(anos_ifdm, anos_pib)

cat("  Anos IFDM:", paste(anos_ifdm, collapse=", "), "\n")
cat("  Anos PIB:", paste(anos_pib, collapse=", "), "\n")
cat("  Anos em comum:", paste(anos_comuns, collapse=", "), "\n\n")

mun_ifdm <- unique(ifdm$cod_municipio)
mun_pib <- unique(pib$cod_municipio)
mun_comuns <- intersect(mun_ifdm, mun_pib)

cat("  Municípios IFDM:", length(mun_ifdm), "\n")
cat("  Municípios PIB:", length(mun_pib), "\n")
cat("  Municípios em comum:", length(mun_comuns), "\n\n")

# ==============================================================================
# 5. TESTAR JOIN
# ==============================================================================

cat("5. Testando join IFDM + PIB...\n")

# Selecionar apenas colunas necessárias do PIB
pib_clean <- pib %>%
  select(cod_municipio, ano,
         pib_r1000, pib_percapita,
         vab_agropecuaria_r1000, vab_industria_r1000, vab_servicos_r1000)

# Renomear para evitar conflitos
pib_clean <- pib_clean %>%
  rename(
    pib_total = pib_r1000,
    pib_pc = pib_percapita,
    va_agro = vab_agropecuaria_r1000,
    va_ind = vab_industria_r1000,
    va_serv = vab_servicos_r1000
  )

cat("  Colunas PIB limpas:", paste(names(pib_clean), collapse=", "), "\n\n")

# Join
painel <- ifdm %>%
  left_join(pib_clean, by = c("cod_municipio", "ano"))

cat("  ✓ Painel após join:", nrow(painel), "obs\n")
cat("  ✓ NAs em pib_pc:", sum(is.na(painel$pib_pc)), "\n")
cat("  ✓ NAs em pib_total:", sum(is.na(painel$pib_total)), "\n")
cat("  ✓ NAs em va_agro:", sum(is.na(painel$va_agro)), "\n\n")

# ==============================================================================
# 6. VERIFICAR ESTRUTURA FINAL
# ==============================================================================

cat("6. Verificando estrutura final do painel...\n")

# Verificar observações por município
obs_por_mun <- painel %>%
  group_by(cod_municipio) %>%
  summarise(
    n_obs = n(),
    anos = paste(sort(unique(ano)), collapse=","),
    tem_pib = sum(!is.na(pib_pc))
  )

cat("\n  Amostra de municípios:\n")
print(head(obs_por_mun, 10))

cat("\n  Resumo:\n")
cat("    Min obs/município:", min(obs_por_mun$n_obs), "\n")
cat("    Max obs/município:", max(obs_por_mun$n_obs), "\n")
cat("    Média obs/município:", round(mean(obs_por_mun$n_obs), 1), "\n")
cat("    Municípios com PIB completo:", sum(obs_por_mun$tem_pib == obs_por_mun$n_obs), "\n")
cat("    Municípios com PIB parcial:", sum(obs_por_mun$tem_pib > 0 & obs_por_mun$tem_pib < obs_por_mun$n_obs), "\n")
cat("    Municípios SEM PIB:", sum(obs_por_mun$tem_pib == 0), "\n\n")

# ==============================================================================
# 7. SALVAR DIAGNÓSTICO
# ==============================================================================

cat("7. Salvando diagnóstico...\n")
write.csv(painel, "Resultados/DEBUG_painel_ifdm_pib.csv", row.names = FALSE)
write.csv(obs_por_mun, "Resultados/DEBUG_obs_por_municipio.csv", row.names = FALSE)

cat("  ✓ DEBUG_painel_ifdm_pib.csv\n")
cat("  ✓ DEBUG_obs_por_municipio.csv\n\n")

cat("✓ DIAGNÓSTICO COMPLETO!\n\n")

cat("RESUMO:\n")
cat("  - Painel tem", nrow(painel), "observações\n")
cat("  - Anos disponíveis:", paste(anos_comuns, collapse=", "), "\n")
cat("  - Municípios com dados completos PIB+IFDM:", sum(obs_por_mun$tem_pib == obs_por_mun$n_obs), "\n")
cat("\nPRÓXIMO PASSO: Adicionar anos de concessão IG e criar variável pos_tratamento\n")
