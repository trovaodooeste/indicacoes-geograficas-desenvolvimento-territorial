# ==============================================================================
# Script 06: DiD com Variáveis Econômicas - VERSÃO FINAL
# Objetivo: DiD para PIB e VA Setorial usando anos EXATOS de concessão
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

setwd("/mnt/c/Users/Trovao/Desktop/Artigo - Economia Regional")

cat("\n╔═════════════════════════════════════════════════════════════════╗\n")
cat("║           DiD - VARIÁVEIS ECONÔMICAS (Anos Exatos - FINAL)     ║\n")
cat("╚═════════════════════════════════════════════════════════════════╝\n\n")

# ==============================================================================
# 1. CARREGAR MUNICÍPIOS PAREADOS + ANOS DE CONCESSÃO
# ==============================================================================

cat("1. Carregando municípios pareados e anos de concessão...\n")

# Municípios pareados
base_matched <- read.csv("Resultados/base_cafe_matched.csv")
cod_pareados <- unique(base_matched$cod_municipio)

# Anos de concessão (criado pelo script anterior)
anos_ig <- read.csv("Resultados/Municipios_Anos_Concessao.csv")

cat("  ✓ Municípios pareados:", length(cod_pareados), "\n")
cat("  ✓ Municípios com IG café:", nrow(anos_ig), "\n\n")

# ==============================================================================
# 2. CARREGAR PAINEL IFDM + PIB
# ==============================================================================

cat("2. Carregando painel IFDM + PIB...\n")

# IFDM
ifdm <- read_excel("Dados/IFDM_2013_2023_painel_tratado.xlsx",
                   sheet = "Painel IFDM 2013-2023") %>%
  filter(cod_municipio %in% cod_pareados) %>%
  select(cod_municipio, municipio, uf, ano, starts_with("ifdm"))

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
  left_join(pib, by = c("cod_municipio", "ano")) %>%
  # Join com anos IG
  left_join(anos_ig %>% select(cod_municipio, ano_concessao),
            by = "cod_municipio")

cat("  ✓ Painel criado:", nrow(painel), "observações\n")
cat("  ✓ Anos:", paste(sort(unique(painel$ano)), collapse=", "), "\n\n")

# ==============================================================================
# 3. PREPARAR VARIÁVEIS DE TRATAMENTO
# ==============================================================================

cat("3. Preparando variáveis de tratamento...\n")

painel <- painel %>%
  mutate(
    # Tratado = tem ano de concessão
    tratado = !is.na(ano_concessao),

    # Pós-tratamento
    pos_tratamento = tratado & (ano >= ano_concessao),

    # Tempo relativo
    tempo_relativo = ifelse(tratado, ano - ano_concessao, NA),

    # Log transformações
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

cat("  ✓ Tratados:", sum(painel$tratado[!duplicated(painel$cod_municipio)]), "municípios\n")
cat("  ✓ Controles:", sum(!painel$tratado[!duplicated(painel$cod_municipio)]), "municípios\n")
cat("  ✓ Obs pós-tratamento:", sum(painel$pos_tratamento, na.rm=TRUE), "\n\n")

# ==============================================================================
# 4. DiD - MÚLTIPLOS OUTCOMES
# ==============================================================================

cat("4. Estimando DiD para múltiplos outcomes...\n\n")

# Preparar efeitos fixos
painel$mun_f <- as.factor(painel$cod_municipio)
painel$ano_f <- as.factor(painel$ano)

# Lista de outcomes
outcomes <- list(
  # IFDM (para comparação)
  list(var = "ifdm_geral", nome = "IFDM Geral", tipo = "IFDM"),
  list(var = "ifdm_emprego_renda", nome = "IFDM Emprego", tipo = "IFDM"),

  # PIB (log)
  list(var = "log_pib_pc", nome = "log(PIB per capita)", tipo = "PIB"),
  list(var = "log_pib_total", nome = "log(PIB Total)", tipo = "PIB"),

  # VA Setorial (log)
  list(var = "log_va_agro", nome = "log(VA Agropecuária)", tipo = "VA"),
  list(var = "log_va_ind", nome = "log(VA Indústria)", tipo = "VA"),
  list(var = "log_va_serv", nome = "log(VA Serviços)", tipo = "VA"),

  # Participação setorial
  list(var = "part_agro", nome = "Participação Agropecuária (%)", tipo = "Estrutura"),
  list(var = "part_ind", nome = "Participação Indústria (%)", tipo = "Estrutura"),
  list(var = "part_serv", nome = "Participação Serviços (%)", tipo = "Estrutura")
)

# Estimar DiD
resultados_did <- data.frame()

for(i in 1:length(outcomes)) {
  outcome <- outcomes[[i]]
  var <- outcome$var
  nome <- outcome$nome
  tipo <- outcome$tipo

  cat("  [", i, "/", length(outcomes), "] Estimando:", nome, "\n")

  # Filtrar NAs
  painel_var <- painel %>%
    filter(!is.na(.data[[var]]))

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

    # Extrair coeficientes
    if("pos_tratamentoTRUE" %in% rownames(coef_rob)) {
      # Coeficiente é "pos_tratamentoTRUE" (variável lógica)
      att <- coef_rob["pos_tratamentoTRUE", "Estimate"]
      se <- coef_rob["pos_tratamentoTRUE", "Std. Error"]
      t_stat <- coef_rob["pos_tratamentoTRUE", "t value"]
      p_val <- coef_rob["pos_tratamentoTRUE", "Pr(>|t|)"]

      # Guardar
      resultados_did <- rbind(resultados_did, data.frame(
        Tipo = tipo,
        Variavel = nome,
        ATT = att,
        SE = se,
        t_stat = t_stat,
        p_value = p_val,
        N_obs = nrow(painel_var),
        stringsAsFactors = FALSE
      ))

      cat("      ✓ ATT =", sprintf("%.5f", att), "| p =", sprintf("%.3f", p_val), "\n")

    } else {
      cat("      ✗ Coeficiente não encontrado. Nomes disponíveis:\n")
      cat("        ", paste(head(rownames(coef_rob), 10), collapse=", "), "\n")
    }

  }, error = function(e) {
    cat("      ✗ Erro:", e$message, "\n")
  })
}

# Adicionar significância
if(nrow(resultados_did) > 0) {
  resultados_did$Significancia <- case_when(
    resultados_did$p_value < 0.01 ~ "***",
    resultados_did$p_value < 0.05 ~ "**",
    resultados_did$p_value < 0.10 ~ "*",
    TRUE ~ ""
  )

  # IC 95%
  resultados_did$IC_Inferior <- resultados_did$ATT - 1.96 * resultados_did$SE
  resultados_did$IC_Superior <- resultados_did$ATT + 1.96 * resultados_did$SE
}

# ==============================================================================
# 5. APRESENTAR RESULTADOS
# ==============================================================================

cat("\n\n╔═════════════════════════════════════════════════════════════════╗\n")
cat("║                    DiD - RESULTADOS COMPLETOS                   ║\n")
cat("╚═════════════════════════════════════════════════════════════════╝\n\n")

if(nrow(resultados_did) > 0) {

  cat("═══════════════════════════════════════════════════════════════════\n")
  cat("A. INDICADORES DE DESENVOLVIMENTO (IFDM)\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")

  ifdm_results <- resultados_did %>% filter(Tipo == "IFDM")
  if(nrow(ifdm_results) > 0) {
    print(ifdm_results[, c("Variavel", "ATT", "SE", "IC_Inferior", "IC_Superior",
                           "p_value", "Significancia")], row.names = FALSE)
  }

  cat("\n\n═══════════════════════════════════════════════════════════════════\n")
  cat("B. PIB E RENDA (log)\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")

  pib_results <- resultados_did %>% filter(Tipo == "PIB")
  if(nrow(pib_results) > 0) {
    pib_results$Var_Percentual <- (exp(pib_results$ATT) - 1) * 100
    print(pib_results[, c("Variavel", "ATT", "Var_Percentual", "SE", "p_value", "Significancia")],
          row.names = FALSE)
    cat("\n  Nota: Var_Percentual = (exp(coef) - 1) × 100\n")
  }

  cat("\n\n═══════════════════════════════════════════════════════════════════\n")
  cat("C. VALOR ADICIONADO SETORIAL (log)\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")

  va_results <- resultados_did %>% filter(Tipo == "VA")
  if(nrow(va_results) > 0) {
    va_results$Var_Percentual <- (exp(va_results$ATT) - 1) * 100
    print(va_results[, c("Variavel", "ATT", "Var_Percentual", "SE", "p_value", "Significancia")],
          row.names = FALSE)
    cat("\n  Nota: Var_Percentual = (exp(coef) - 1) × 100\n")
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

} else {
  cat("⚠️ NENHUM RESULTADO GERADO - Verificar dados de tratamento\n")
}

# ==============================================================================
# 6. SALVAR RESULTADOS
# ==============================================================================

cat("\n\n5. Salvando resultados...\n")

write.csv(resultados_did,
          "Resultados/DiD_Economicas_Final_Resultados.csv",
          row.names = FALSE)

write.csv(painel,
          "Resultados/painel_cafe_economicas_final.csv",
          row.names = FALSE)

cat("  ✓ DiD_Economicas_Final_Resultados.csv\n")
cat("  ✓ painel_cafe_economicas_final.csv\n")

cat("\n\n✓ DiD COM VARIÁVEIS ECONÔMICAS - CONCLUÍDO!\n\n")
