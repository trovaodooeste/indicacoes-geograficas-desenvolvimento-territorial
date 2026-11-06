# ==============================================================================
# Script 06: DiD com Variáveis Econômicas - VERSÃO SIMPLIFICADA
# Objetivo: DiD para PIB e VA Setorial usando dados já integrados
# Data: 08/06/2026
# ==============================================================================

.libPaths(c("~/R/library", .libPaths()))

rm(list = ls())

library(readxl)
library(dplyr)
library(tidyr)
library(ggplot2)
library(lmtest)
library(sandwich)
library(stringr)

setwd("/mnt/c/Users/Trovao/Desktop/Artigo - Economia Regional")

cat("\n╔═════════════════════════════════════════════════════════════════╗\n")
cat("║           DiD - VARIÁVEIS ECONÔMICAS (Versão Simplificada)     ║\n")
cat("╚═════════════════════════════════════════════════════════════════╝\n\n")

# ==============================================================================
# 1. CARREGAR DADOS JÁ INTEGRADOS
# ==============================================================================

cat("1. Carregando dados (IFDM + PIB já integrados)...\n")

# Municípios pareados
base_matched <- read.csv("Resultados/base_cafe_matched.csv")
cod_pareados <- unique(base_matched$cod_municipio)

cat("  ✓ Municípios pareados (PSM):", length(cod_pareados), "\n")

# IFDM (já tem ig_ano_concessao!)
ifdm <- read_excel("Dados/IFDM_2013_2023_painel_tratado.xlsx",
                   sheet = "Painel IFDM 2013-2023") %>%
  filter(cod_municipio %in% cod_pareados)

# PIB
pib <- read_excel("Dados/PIB_Municipal_2002_2023_painel_IG.xlsx",
                  sheet = "Painel 2002-2023") %>%
  mutate(cod_municipio = floor(cod_municipio / 10)) %>%
  filter(cod_municipio %in% cod_pareados) %>%
  select(cod_municipio, ano,
         pib_total = pib_r1000,
         pib_pc = pib_percapita,
         va_agro = vab_agropecuaria_r1000,
         va_ind = vab_industria_r1000,
         va_serv = vab_servicos_r1000)

# Join
painel <- ifdm %>%
  left_join(pib, by = c("cod_municipio", "ano"))

cat("  ✓ Painel criado:", nrow(painel), "observações\n")
cat("  ✓ Anos:", paste(sort(unique(painel$ano)), collapse=", "), "\n")
cat("  ✓ Municípios:", n_distinct(painel$cod_municipio), "\n\n")

# ==============================================================================
# 2. PREPARAR VARIÁVEIS DO TRATAMENTO
# ==============================================================================

cat("2. Preparando variáveis de tratamento...\n")

# Filtrar apenas café
painel_cafe <- painel %>%
  filter(is.na(ig_nome) | grepl("Café|Coffee|Conilon", ig_nome, ignore.case = TRUE))

# Criar variáveis de tratamento
painel_cafe <- painel_cafe %>%
  mutate(
    # Tratado = tem IG de café
    tratado = !is.na(ig_ano_concessao) & tem_ig == 1,

    # Pós-tratamento = ano >= ano de concessão
    pos_tratamento = tratado & (ano >= ig_ano_concessao),

    # Tempo relativo
    tempo_relativo = ifelse(tratado, ano - ig_ano_concessao, NA),

    # Log transformações (lidar com outliers)
    log_pib_pc = log(pib_pc + 1),
    log_pib_total = log(pib_total + 1),
    log_va_agro = log(va_agro + 1),
    log_va_ind = log(va_ind + 1),
    log_va_serv = log(va_serv + 1),

    # Participação setorial
    part_agro = (va_agro / pib_total) * 100,
    part_ind = (va_ind / pib_total) * 100,
    part_serv = (va_serv / pib_total) * 100
  )

# Verificar
cat("  ✓ Tratados:", sum(painel_cafe$tratado[!duplicated(painel_cafe$cod_municipio)]), "municípios\n")
cat("  ✓ Controles:", sum(!painel_cafe$tratado[!duplicated(painel_cafe$cod_municipio)]), "municípios\n")
cat("  ✓ Obs pós-tratamento:", sum(painel_cafe$pos_tratamento, na.rm=TRUE), "\n\n")

# ==============================================================================
# 3. DiD - MÚLTIPLOS OUTCOMES
# ==============================================================================

cat("3. Estimando DiD para múltiplos outcomes...\n\n")

# Preparar efeitos fixos
painel_cafe$mun_f <- as.factor(painel_cafe$cod_municipio)
painel_cafe$ano_f <- as.factor(painel_cafe$ano)

# Lista de outcomes
outcomes <- list(
  # IFDM (para comparação)
  list(var = "ifdm_geral", nome = "IFDM Geral", tipo = "IFDM"),
  list(var = "ifdm_emprego_renda", nome = "IFDM Emprego", tipo = "IFDM"),

  # PIB
  list(var = "log_pib_pc", nome = "log(PIB per capita)", tipo = "PIB"),
  list(var = "log_pib_total", nome = "log(PIB Total)", tipo = "PIB"),

  # VA Setorial (nível)
  list(var = "va_agro", nome = "VA Agropecuária (R$ mil)", tipo = "VA_nivel"),
  list(var = "va_ind", nome = "VA Indústria (R$ mil)", tipo = "VA_nivel"),
  list(var = "va_serv", nome = "VA Serviços (R$ mil)", tipo = "VA_nivel"),

  # VA Setorial (log)
  list(var = "log_va_agro", nome = "log(VA Agropecuária)", tipo = "VA_log"),
  list(var = "log_va_ind", nome = "log(VA Indústria)", tipo = "VA_log"),
  list(var = "log_va_serv", nome = "log(VA Serviços)", tipo = "VA_log"),

  # Participação setorial
  list(var = "part_agro", nome = "Participação Agropecuária (%)", tipo = "Estrutura"),
  list(var = "part_ind", nome = "Participação Indústria (%)", tipo = "Estrutura"),
  list(var = "part_serv", nome = "Participação Serviços (%)", tipo = "Estrutura")
)

# Estimar DiD para cada outcome
resultados_did <- data.frame()

for(i in 1:length(outcomes)) {
  outcome <- outcomes[[i]]
  var <- outcome$var
  nome <- outcome$nome
  tipo <- outcome$tipo

  cat("  [", i, "/", length(outcomes), "] Estimando:", nome, "\n")

  # Filtrar NAs
  painel_var <- painel_cafe %>%
    filter(!is.na(.data[[var]]), !is.na(pos_tratamento))

  if(nrow(painel_var) < 100) {
    cat("      ⚠ Poucos dados, pulando...\n")
    next
  }

  # Estimar modelo
  formula_did <- as.formula(paste(var, "~ pos_tratamento + mun_f + ano_f"))

  tryCatch({
    modelo <- lm(formula_did, data = painel_var)

    # Erros clusterizados
    vcov_cl <- vcovCL(modelo, cluster = painel_var$cod_municipio)
    coef_rob <- coeftest(modelo, vcov = vcov_cl)

    # Verificar se coeficiente existe
    if("pos_tratamento" %in% rownames(coef_rob)) {
      att <- coef_rob["pos_tratamento", "Estimate"]
      se <- coef_rob["pos_tratamento", "Std. Error"]
      t_stat <- coef_rob["pos_tratamento", "t value"]
      p_val <- coef_rob["pos_tratamento", "Pr(>|t|)"]

      # Guardar
      resultados_did <- rbind(resultados_did, data.frame(
        Tipo = tipo,
        Variavel = nome,
        ATT = att,
        SE = se,
        t_stat = t_stat,
        p_value = p_val,
        N_obs = nrow(painel_var),
        N_tratados = sum(painel_var$tratado),
        N_controles = sum(!painel_var$tratado),
        stringsAsFactors = FALSE
      ))

      cat("      ✓ ATT =", sprintf("%.5f", att), "| SE =", sprintf("%.5f", se),
          "| p =", sprintf("%.3f", p_val), "\n")
    } else {
      cat("      ✗ Coeficiente 'pos_tratamento' não encontrado\n")
    }

  }, error = function(e) {
    cat("      ✗ Erro:", e$message, "\n")
  })
}

# Adicionar significância
resultados_did$Significancia <- case_when(
  resultados_did$p_value < 0.01 ~ "***",
  resultados_did$p_value < 0.05 ~ "**",
  resultados_did$p_value < 0.10 ~ "*",
  TRUE ~ ""
)

# IC 95%
resultados_did$IC_Inferior <- resultados_did$ATT - 1.96 * resultados_did$SE
resultados_did$IC_Superior <- resultados_did$ATT + 1.96 * resultados_did$SE

# ==============================================================================
# 4. APRESENTAR RESULTADOS
# ==============================================================================

cat("\n\n╔═════════════════════════════════════════════════════════════════╗\n")
cat("║                    DiD - RESULTADOS COMPLETOS                   ║\n")
cat("╚═════════════════════════════════════════════════════════════════╝\n\n")

cat("═══════════════════════════════════════════════════════════════════\n")
cat("A. INDICADORES DE DESENVOLVIMENTO (IFDM)\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

ifdm_results <- resultados_did %>% filter(Tipo == "IFDM")
if(nrow(ifdm_results) > 0) {
  print(ifdm_results[, c("Variavel", "ATT", "SE", "p_value", "Significancia")],
        row.names = FALSE)
}

cat("\n\n═══════════════════════════════════════════════════════════════════\n")
cat("B. PIB E RENDA\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

pib_results <- resultados_did %>% filter(Tipo == "PIB")
if(nrow(pib_results) > 0) {
  pib_results$Var_Percentual <- (exp(pib_results$ATT) - 1) * 100
  print(pib_results[, c("Variavel", "ATT", "Var_Percentual", "SE", "p_value", "Significancia")],
        row.names = FALSE)
  cat("\n  Nota: Var_Percentual = variação % (exp(coef) - 1)\n")
}

cat("\n\n═══════════════════════════════════════════════════════════════════\n")
cat("C. VALOR ADICIONADO SETORIAL (log)\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

va_log_results <- resultados_did %>% filter(Tipo == "VA_log")
if(nrow(va_log_results) > 0) {
  va_log_results$Var_Percentual <- (exp(va_log_results$ATT) - 1) * 100
  print(va_log_results[, c("Variavel", "ATT", "Var_Percentual", "SE", "p_value", "Significancia")],
        row.names = FALSE)
  cat("\n  Nota: Var_Percentual = variação % (exp(coef) - 1)\n")
}

cat("\n\n═══════════════════════════════════════════════════════════════════\n")
cat("D. PARTICIPAÇÃO SETORIAL\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

estrut_results <- resultados_did %>% filter(Tipo == "Estrutura")
if(nrow(estrut_results) > 0) {
  print(estrut_results[, c("Variavel", "ATT", "SE", "p_value", "Significancia")],
        row.names = FALSE)
  cat("\n  Nota: ATT em pontos percentuais\n")
}

cat("\n\nSignificância: *** p<0.01, ** p<0.05, * p<0.10\n")

# ==============================================================================
# 5. SALVAR RESULTADOS
# ==============================================================================

cat("\n\n4. Salvando resultados...\n")

write.csv(resultados_did,
          "Resultados/DiD_Economicas_Resultados.csv",
          row.names = FALSE)

write.csv(painel_cafe,
          "Resultados/painel_cafe_economicas.csv",
          row.names = FALSE)

cat("  ✓ DiD_Economicas_Resultados.csv\n")
cat("  ✓ painel_cafe_economicas.csv\n")

cat("\n\n✓ DiD COM VARIÁVEIS ECONÔMICAS - CONCLUÍDO!\n")
cat("\nPRÓXIMOS PASSOS:\n")
cat("  1. Revisar resultados em DiD_Economicas_Resultados.csv\n")
cat("  2. Criar Event Study para variáveis econômicas\n")
cat("  3. Comparar PSM vs DiD\n\n")
