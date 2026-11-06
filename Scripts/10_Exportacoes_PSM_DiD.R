# ==============================================================================
# Script 10: PSM + DiD — Exportações de Café por Município
# Objetivo: Estimar efeito das IGs de café nas exportações municipais
#           Responde à sugestão do professor (variáveis de exportação)
# Pré-requisito: Scripts 01_integrar_dados_cafe.R e 02_PSM_cafe.R
# Data: 17/06/2026
# ==============================================================================

.libPaths(c("~/R/library", .libPaths()))
rm(list = ls())

library(readxl)
library(dplyr)
library(lmtest)
library(sandwich)

setwd("C:/Users/Trovao/Desktop/Artigo - Economia Regional")

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║       PSM + DiD — EXPORTAÇÕES DE CAFÉ POR MUNICÍPIO           ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

# ==============================================================================
# 1. CARREGAR TABELA DE MUNICÍPIOS DO COMEXSTAT → IBGE
# ==============================================================================

cat("1. Carregando correspondência ComexStat → IBGE...\n")

# A aba "UF_MUN" da tabela auxiliar faz o de-para dos códigos
tryCatch({
  tab_aux_sheets <- excel_sheets("Dados/ComexStat_Raw/TABELAS_AUXILIARES.xlsx")
  cat("   Abas disponíveis:", paste(tab_aux_sheets, collapse = ", "), "\n")

  # Identificar a aba com dados de municípios
  aba_mun <- tab_aux_sheets[grepl("MUN|mun|municipio|cidade|city", tab_aux_sheets, ignore.case = TRUE)][1]

  if(!is.na(aba_mun)) {
    mun_ref <- read_excel("Dados/ComexStat_Raw/TABELAS_AUXILIARES.xlsx", sheet = aba_mun)
    cat("   Aba usada:", aba_mun, "—", nrow(mun_ref), "municípios\n")
    cat("   Colunas:", paste(names(mun_ref), collapse = ", "), "\n\n")
  } else {
    cat("   Aba de municípios não encontrada. Listando todas as abas:\n")
    for (s in tab_aux_sheets) {
      df_temp <- read_excel("Dados/ComexStat_Raw/TABELAS_AUXILIARES.xlsx", sheet = s, n_max = 3)
      cat("    Aba", s, ":", paste(names(df_temp), collapse = ", "), "\n")
    }
    mun_ref <- NULL
  }
}, error = function(e) {
  cat("   Erro ao ler TABELAS_AUXILIARES.xlsx:", e$message, "\n\n")
  mun_ref <<- NULL
})

# ==============================================================================
# 2. CARREGAR DADOS DE EXPORTAÇÃO DE CAFÉ
# ==============================================================================

cat("2. Carregando dados de exportação de café (ComexStat)...\n")

exportacoes <- read.csv2(
  "Dados/ComexStat_Cafe_Municipios.csv",
  sep = ";",
  header = TRUE,
  stringsAsFactors = FALSE
)

# Garantir tipos numéricos
exportacoes <- exportacoes %>%
  mutate(
    CO_ANO = as.integer(CO_ANO),
    CO_MUN = as.character(CO_MUN),
    KG_LIQUIDO_TOTAL = as.numeric(KG_LIQUIDO_TOTAL),
    VL_FOB_USD_TOTAL = as.numeric(VL_FOB_USD_TOTAL)
  )

cat("   Observações:", nrow(exportacoes), "\n")
cat("   Anos:", paste(sort(unique(exportacoes$CO_ANO)), collapse = ", "), "\n")
cat("   Municípios únicos:", n_distinct(exportacoes$CO_MUN), "\n\n")

# Calcular preço médio (USD/kg) — variável usada por Medeiros et al. 2021
exportacoes <- exportacoes %>%
  mutate(
    preco_medio_usd_kg = ifelse(KG_LIQUIDO_TOTAL > 0,
                                VL_FOB_USD_TOTAL / KG_LIQUIDO_TOTAL,
                                NA_real_),
    log_exportacoes_usd = log(VL_FOB_USD_TOTAL + 1),
    log_kg_exportado = log(KG_LIQUIDO_TOTAL + 1)
  ) %>%
  rename(ano = CO_ANO, cod_comexstat = CO_MUN)

# ==============================================================================
# 3. CONVERTER CÓDIGO COMEXSTAT → CÓDIGO IBGE (6 DÍGITOS)
# ==============================================================================

cat("3. Convertendo código ComexStat para código IBGE (6 dígitos)...\n\n")

# O ComexStat usa o código IBGE de 7 dígitos (CO_MUN_GEO = código c/ dígito verificador)
# Nossa base usa o código IBGE de 6 dígitos (sem dígito verificador)
# Conversão: cod_ibge_6dig = as.integer(CO_MUN_7dig) %/% 10
#
# Verificação: Anagé (BA) cod_municipio=290120 → ComexStat 2901205 → 2901205%/%10 = 290120 ✓

exportacoes <- exportacoes %>%
  mutate(
    cod_municipio = as.integer(as.numeric(cod_comexstat)) %/% 10L
  )

cat("   Conversão aplicada: CO_MUN (7 dig) %/% 10 → cod_municipio (6 dig)\n")
cat("   Exemplo: 2901205 → 290120 (Anagé, BA)\n")
cat("   Municípios únicos após conversão:", n_distinct(exportacoes$cod_municipio), "\n\n")

# ==============================================================================
# 4. INTEGRAR EXPORTAÇÕES AO PAINEL EXISTENTE
# ==============================================================================

cat("4. Integrando exportações ao painel existente...\n")

# Usar o painel já construído com PSM (tratados + controles)
painel_base <- read.csv("Resultados/painel_cafe_economicas_final.csv")
cat("   Painel base:", nrow(painel_base), "obs |",
    n_distinct(painel_base$cod_municipio), "municípios\n")

# Pesos do PSM
pesos_psm <- read.csv("Resultados/base_cafe_matched.csv") %>%
  select(cod_municipio, weights) %>%
  distinct()

# Integrar exportações (zeros para municípios sem exportação)
painel_completo <- painel_base %>%
  left_join(
    exportacoes %>%
      select(cod_municipio, ano, KG_LIQUIDO_TOTAL, VL_FOB_USD_TOTAL,
             preco_medio_usd_kg, log_exportacoes_usd, log_kg_exportado),
    by = c("cod_municipio", "ano")
  ) %>%
  left_join(pesos_psm, by = "cod_municipio") %>%
  mutate(
    # Municípios sem registro de exportação = zero
    KG_LIQUIDO_TOTAL    = replace(KG_LIQUIDO_TOTAL,    is.na(KG_LIQUIDO_TOTAL),    0),
    VL_FOB_USD_TOTAL    = replace(VL_FOB_USD_TOTAL,    is.na(VL_FOB_USD_TOTAL),    0),
    log_exportacoes_usd = replace(log_exportacoes_usd, is.na(log_exportacoes_usd), 0),
    log_kg_exportado    = replace(log_kg_exportado,    is.na(log_kg_exportado),    0),
    # Identificador de tratado/controle
    IG_Cafe = tratado
  )

cat("   Municípios com exportação > 0 em algum ano:",
    n_distinct(painel_completo$cod_municipio[painel_completo$VL_FOB_USD_TOTAL > 0]), "\n")
cat("   Tratados com exportação > 0 em algum ano:",
    n_distinct(painel_completo$cod_municipio[painel_completo$VL_FOB_USD_TOTAL > 0 &
                                               painel_completo$tratado == TRUE]), "\n\n")

# ==============================================================================
# 5. PSM — CROSS-SECTION (IGUAL A MEDEIROS ET AL. 2021)
# ==============================================================================

cat("5. PSM Cross-Section (replicando abordagem de Medeiros et al.)...\n\n")

# Medeiros et al. usaram ano específico para cada outcome
# Exportações: 2019 (último ano disponível no estudo deles)
# Preço médio: também 2019

# Nós vamos usar 2018 como pós-tratamento (5 anos após 2013, antes da pandemia)
ano_psm <- 2018

dados_psm <- painel_completo %>%
  filter(ano == ano_psm) %>%
  filter(!is.na(IG_Cafe))

cat("   Ano de resultado PSM:", ano_psm, "\n")
cat("   Tratados:", sum(dados_psm$IG_Cafe, na.rm = TRUE), "\n")
cat("   Controles:", sum(!dados_psm$IG_Cafe, na.rm = TRUE), "\n\n")

# Função para calcular ATT com pesos do matching
calcular_att_psm <- function(dados, variavel) {
  if(!variavel %in% names(dados)) return(NULL)
  if(all(is.na(dados[[variavel]]))) return(NULL)

  formula <- as.formula(paste(variavel, "~ IG_Cafe"))
  tryCatch({
    modelo <- lm(formula, data = dados, weights = dados$weights)
    vcov_r <- vcovHC(modelo, type = "HC1")
    coef_r <- coeftest(modelo, vcov = vcov_r)

    media_ctrl <- mean(dados[[variavel]][!dados$IG_Cafe], na.rm = TRUE)
    att <- coef_r["IG_CafeTRUE", "Estimate"]

    data.frame(
      Metodo = "PSM",
      Variavel = variavel,
      ATT = att,
      SE = coef_r["IG_CafeTRUE", "Std. Error"],
      p_value = coef_r["IG_CafeTRUE", "Pr(>|t|)"],
      Media_Controle = media_ctrl,
      Efeito_Pct = att / abs(media_ctrl) * 100,
      IC_Inf = att - 1.96 * coef_r["IG_CafeTRUE", "Std. Error"],
      IC_Sup = att + 1.96 * coef_r["IG_CafeTRUE", "Std. Error"],
      Sig = case_when(
        coef_r["IG_CafeTRUE", "Pr(>|t|)"] < 0.01 ~ "***",
        coef_r["IG_CafeTRUE", "Pr(>|t|)"] < 0.05 ~ "**",
        coef_r["IG_CafeTRUE", "Pr(>|t|)"] < 0.10 ~ "*",
        TRUE ~ ""
      )
    )
  }, error = function(e) NULL)
}

variaveis_exportacao <- c(
  "VL_FOB_USD_TOTAL",     # Valor exportado (USD) — principal
  "KG_LIQUIDO_TOTAL",     # Volume exportado (kg)
  "preco_medio_usd_kg",   # Preço médio (USD/kg) — Medeiros: +0.78**
  "log_exportacoes_usd",  # Log do valor exportado
  "log_kg_exportado"      # Log do volume exportado
)

resultados_psm <- do.call(rbind, lapply(variaveis_exportacao, function(v) {
  calcular_att_psm(dados_psm, v)
}))

# ==============================================================================
# 6. DiD — PAINEL COMPLETO
# ==============================================================================

cat("6. DiD com efeitos fixos (painel 2013-2023)...\n\n")

calcular_att_did <- function(dados, variavel) {
  if(!variavel %in% names(dados)) return(NULL)

  dados_mod <- dados %>%
    filter(!is.na(!!sym(variavel)), !is.na(pos_tratamento)) %>%
    mutate(mun_f = as.factor(cod_municipio), ano_f = as.factor(ano))

  formula <- as.formula(paste(variavel, "~ pos_tratamento + mun_f + ano_f"))
  tryCatch({
    modelo <- lm(formula, data = dados_mod)
    vcov_r <- vcovCL(modelo, cluster = dados_mod$cod_municipio)
    coef_r <- coeftest(modelo, vcov = vcov_r)

    att <- coef_r["pos_tratamentoTRUE", "Estimate"]
    se  <- coef_r["pos_tratamentoTRUE", "Std. Error"]
    pv  <- coef_r["pos_tratamentoTRUE", "Pr(>|t|)"]

    data.frame(
      Metodo = "DiD",
      Variavel = variavel,
      ATT = att, SE = se, p_value = pv,
      Media_Controle = mean(dados_mod[[variavel]][!dados_mod$pos_tratamento], na.rm = TRUE),
      Efeito_Pct = att / abs(mean(dados_mod[[variavel]][!dados_mod$pos_tratamento], na.rm = TRUE)) * 100,
      IC_Inf = att - 1.96 * se,
      IC_Sup = att + 1.96 * se,
      Sig = case_when(pv < 0.01 ~ "***", pv < 0.05 ~ "**", pv < 0.10 ~ "*", TRUE ~ "")
    )
  }, error = function(e) NULL)
}

resultados_did <- do.call(rbind, lapply(variaveis_exportacao, function(v) {
  calcular_att_did(painel_completo, v)
}))

# ==============================================================================
# 7. APRESENTAR RESULTADOS
# ==============================================================================

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║              RESULTADOS — EXPORTAÇÕES DE CAFÉ                 ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("═══ PSM Cross-Section (ano", ano_psm, ") ═══════════════════════════\n\n")
if(!is.null(resultados_psm)) {
  print(resultados_psm %>% select(Variavel, ATT, SE, p_value, Efeito_Pct, Sig),
        row.names = FALSE, digits = 4)
}

cat("\n═══ DiD com Efeitos Fixos (2013-2023) ══════════════════════════\n\n")
if(!is.null(resultados_did)) {
  print(resultados_did %>% select(Variavel, ATT, SE, p_value, Efeito_Pct, Sig),
        row.names = FALSE, digits = 4)
}

cat("\n─── Medeiros et al. (2021) para comparação: ─────────────────────\n")
cat("  Exportações (USD): +2.866.133 (não sig.)\n")
cat("  Preço médio (USD/kg): +0.78** (p<0.05)\n\n")

# ==============================================================================
# 8. SALVAR RESULTADOS
# ==============================================================================

cat("8. Salvando...\n")

resultados_todos <- rbind(resultados_psm, resultados_did)
if(!is.null(resultados_todos)) {
  write.csv(resultados_todos, "Resultados/ATT_Cafe_Exportacoes.csv", row.names = FALSE)
  cat("   ✓ Resultados/ATT_Cafe_Exportacoes.csv\n")
}

write.csv(painel_completo, "Resultados/painel_cafe_exportacoes.csv", row.names = FALSE)
cat("   ✓ Resultados/painel_cafe_exportacoes.csv\n\n")

cat("✓ Script concluído!\n\n")
