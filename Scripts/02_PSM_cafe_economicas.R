# ==============================================================================
# Script 02b: Propensity Score Matching - CAFÉ (VARIÁVEIS ECONÔMICAS)
# Objetivo: Estimar efeito causal das IGs de café em variáveis econômicas
# Metodologia: PSM (Nearest Neighbor + Caliper)
# Expansão: Adiciona VA Setorial e Participação Agropecuária como outcomes
# ==============================================================================

.libPaths(c("~/R/library", .libPaths()))

rm(list = ls())

# Pacotes
library(dplyr)
library(MatchIt)    # PSM
library(cobalt)     # Balanceamento
library(lmtest)
library(sandwich)

setwd("/mnt/c/Users/Trovao/Desktop/Artigo - Economia Regional")

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║   PSM - INDICAÇÕES GEOGRÁFICAS CAFÉ (VARIÁVEIS ECONÔMICAS)    ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# ==============================================================================
# 1. CARREGAR BASE INTEGRADA
# ==============================================================================

cat("1. Carregando base de dados...\n")
base <- read.csv("Resultados/base_cafe_psm.csv")

cat("  ✓ Observações:", nrow(base), "\n")
cat("  ✓ Tratados (com IG Café):", sum(base$IG_Cafe), "\n")
cat("  ✓ Controles (sem IG):", sum(base$IG_Cafe == 0), "\n\n")

# Remover observações com NA nas covariáveis principais
base_completa <- base %>%
  filter(!is.na(IFDM), !is.na(PIB_Percapita), !is.na(Part_Agro))

cat("  ✓ Após remover NAs:", nrow(base_completa), "observações\n")
cat("    - Tratados:", sum(base_completa$IG_Cafe), "\n")
cat("    - Controles:", sum(base_completa$IG_Cafe == 0), "\n\n")

# ==============================================================================
# 2. ESPECIFICAR MODELO DE PROPENSITY SCORE
# ==============================================================================

cat("2. Estimando Propensity Score (Modelo Logit)...\n\n")

# Fórmula do matching
# Incluir covariáveis que influenciam tanto o tratamento quanto o resultado

formula_ps <- IG_Cafe ~ PIB_Percapita + Part_Agro +
                        VA_Agropecuaria + VA_Industria + VA_Servicos +
                        IFDM_Educacao + IFDM_Saude

cat("  Covariáveis no modelo:\n")
cat("    - PIB per capita\n")
cat("    - Participação da agropecuária (%)\n")
cat("    - Valor Adicionado: Agropecuária, Indústria, Serviços\n")
cat("    - IFDM Educação e Saúde (pré-tratamento)\n\n")

# ==============================================================================
# 3. ESTIMAR PSM
# ==============================================================================

cat("3. Realizando Matching (Nearest Neighbor)...\n\n")

# Estimar PSM
m_out <- matchit(
  formula_ps,
  data = base_completa,
  method = "nearest",     # Nearest neighbor
  distance = "logit",     # Propensity score via logit
  ratio = 3,              # 3 controles para cada tratado
  replace = TRUE,         # Com reposição
  caliper = 0.01,         # Caliper de 0.01
  std.caliper = TRUE      # Caliper em desvios-padrão
)

# Sumário do matching
cat("═══════════════════════════════════════════════════════════\n")
cat("                    RESUMO DO MATCHING\n")
cat("═══════════════════════════════════════════════════════════\n\n")
summary(m_out)

# ==============================================================================
# 4. EXTRAIR DADOS PAREADOS
# ==============================================================================

cat("\n\n4. Extraindo dados pareados...\n")

# Obter base matched
base_matched <- match.data(m_out)

cat("  ✓ Observações pareadas:", nrow(base_matched), "\n")
cat("  ✓ Tratados:", sum(base_matched$IG_Cafe), "\n")
cat("  ✓ Controles pareados:", sum(base_matched$IG_Cafe == 0), "\n\n")

# ==============================================================================
# 5. ESTIMAR ATT - TODAS AS VARIÁVEIS ECONÔMICAS
# ==============================================================================

cat("5. Estimando Average Treatment Effect on Treated (ATT)...\n\n")

# VARIÁVEIS DE RESULTADO EXPANDIDAS
# Incluindo todas as variáveis econômicas disponíveis
resultados <- c(
  # IFDM (para comparação)
  "IFDM", "IFDM_Emprego", "IFDM_Educacao", "IFDM_Saude",

  # VARIÁVEIS ECONÔMICAS
  "PIB_Percapita",          # PIB per capita (R$)
  "PIB_Total",              # PIB total (R$ milhares)
  "VA_Agropecuaria",        # VA Agropecuária (R$ milhares)
  "VA_Industria",           # VA Indústria (R$ milhares)
  "VA_Servicos",            # VA Serviços (R$ milhares)
  "Part_Agro"               # Participação Agropecuária (%)
)

cat("  Variáveis de resultado:\n")
cat("    - IFDM (Geral, Emprego, Educação, Saúde)\n")
cat("    - PIB per capita e PIB Total\n")
cat("    - Valor Adicionado Setorial (Agro, Indústria, Serviços)\n")
cat("    - Participação da Agropecuária no PIB\n\n")

# Calcular ATT para cada variável
att_results <- data.frame(
  Variavel = character(),
  ATT = numeric(),
  SE = numeric(),
  t_stat = numeric(),
  p_value = numeric(),
  stringsAsFactors = FALSE
)

for(var in resultados) {
  if(var %in% names(base_matched)) {
    # Regressão com pesos do matching
    formula_att <- as.formula(paste(var, "~ IG_Cafe"))

    modelo <- lm(formula_att,
                 data = base_matched,
                 weights = weights)

    # Erros robustos
    se_robust <- coeftest(modelo, vcov = vcovHC(modelo, type = "HC1"))

    # Extrair ATT
    att <- coef(modelo)["IG_Cafe"]
    se <- se_robust["IG_Cafe", "Std. Error"]
    t_stat <- se_robust["IG_Cafe", "t value"]
    p_val <- se_robust["IG_Cafe", "Pr(>|t|)"]

    # Adicionar aos resultados
    att_results <- rbind(att_results, data.frame(
      Variavel = var,
      ATT = att,
      SE = se,
      t_stat = t_stat,
      p_value = p_val
    ))
  }
}

# Adicionar significância
att_results$Significancia <- case_when(
  att_results$p_value < 0.01 ~ "***",
  att_results$p_value < 0.05 ~ "**",
  att_results$p_value < 0.10 ~ "*",
  TRUE ~ ""
)

# Adicionar intervalo de confiança 95%
att_results$IC_Inferior <- att_results$ATT - 1.96 * att_results$SE
att_results$IC_Superior <- att_results$ATT + 1.96 * att_results$SE

# ==============================================================================
# 6. APRESENTAR RESULTADOS
# ==============================================================================

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║         RESULTADOS - EFEITO DAS IGs DE CAFÉ (COMPLETO)        ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

cat("═══════════════════════════════════════════════════════════════════\n")
cat("A. INDICADORES DE DESENVOLVIMENTO (IFDM)\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

ifdm_results <- att_results %>%
  filter(grepl("IFDM", Variavel))

print(ifdm_results[, c("Variavel", "ATT", "SE", "IC_Inferior", "IC_Superior",
                       "p_value", "Significancia")], row.names = FALSE)

cat("\n\n═══════════════════════════════════════════════════════════════════\n")
cat("B. INDICADORES ECONÔMICOS\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

econ_results <- att_results %>%
  filter(!grepl("IFDM", Variavel))

print(econ_results[, c("Variavel", "ATT", "SE", "IC_Inferior", "IC_Superior",
                       "p_value", "Significancia")], row.names = FALSE)

cat("\n\nSignificância: *** p<0.01, ** p<0.05, * p<0.10\n")

# ==============================================================================
# 7. ANÁLISE ADICIONAL: EFEITO PERCENTUAL
# ==============================================================================

cat("\n\n6. Calculando efeitos percentuais...\n\n")

# Calcular médias dos controles
medias_controle <- base_matched %>%
  filter(IG_Cafe == 0) %>%
  summarise(across(all_of(resultados), ~mean(.x, na.rm = TRUE)))

# Adicionar efeito percentual
att_results$Media_Controle <- NA
att_results$Efeito_Percentual <- NA

for(i in 1:nrow(att_results)) {
  var <- att_results$Variavel[i]
  if(var %in% names(medias_controle)) {
    media <- medias_controle[[var]]
    att_results$Media_Controle[i] <- media
    if(media != 0) {
      att_results$Efeito_Percentual[i] <- (att_results$ATT[i] / media) * 100
    }
  }
}

cat("═══════════════════════════════════════════════════════════════════\n")
cat("EFEITOS PERCENTUAIS\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

efeito_pct <- att_results %>%
  select(Variavel, ATT, Media_Controle, Efeito_Percentual, p_value, Significancia) %>%
  mutate(Efeito_Percentual = round(Efeito_Percentual, 2))

print(efeito_pct, row.names = FALSE)

# ==============================================================================
# 8. SALVAR RESULTADOS
# ==============================================================================

cat("\n\n7. Salvando resultados...\n")

# Salvar tabela de ATT expandida
write.csv(att_results,
          "Resultados/ATT_Cafe_Economicas.csv",
          row.names = FALSE)

# Relatório completo
sink("Resultados/relatorio_PSM_Cafe_Economicas.txt")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("   RELATÓRIO PSM - IGs DE CAFÉ (VARIÁVEIS ECONÔMICAS)\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")
cat("Data:", format(Sys.Date(), "%d/%m/%Y"), "\n\n")
cat("AMOSTRA:\n")
cat("  Total de municípios:", nrow(base_completa), "\n")
cat("  Municípios com IG Café:", sum(base_completa$IG_Cafe), "\n")
cat("  Municípios pareados:", nrow(base_matched), "\n\n")
cat("ESPECIFICAÇÃO DO MATCHING:\n")
cat("  Método: Nearest Neighbor\n")
cat("  Ratio: 3:1 (com reposição)\n")
cat("  Caliper: 0.01\n")
cat("  Distance: Logit\n\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("RESULTADOS - INDICADORES DE DESENVOLVIMENTO (IFDM)\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")
print(ifdm_results[, c("Variavel", "ATT", "SE", "IC_Inferior", "IC_Superior",
                       "p_value", "Significancia")], row.names = FALSE)
cat("\n\n═══════════════════════════════════════════════════════════════════\n")
cat("RESULTADOS - INDICADORES ECONÔMICOS\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")
print(econ_results[, c("Variavel", "ATT", "SE", "IC_Inferior", "IC_Superior",
                       "p_value", "Significancia")], row.names = FALSE)
cat("\n\n═══════════════════════════════════════════════════════════════════\n")
cat("EFEITOS PERCENTUAIS\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")
print(efeito_pct, row.names = FALSE)
cat("\n═══════════════════════════════════════════════════════════════════\n")
sink()

cat("  ✓ Resultados salvos em Resultados/ATT_Cafe_Economicas.csv\n")
cat("  ✓ Relatório salvo em Resultados/relatorio_PSM_Cafe_Economicas.txt\n")

cat("\n\n✓ ANÁLISE PSM (VARIÁVEIS ECONÔMICAS) - CONCLUÍDA!\n\n")
