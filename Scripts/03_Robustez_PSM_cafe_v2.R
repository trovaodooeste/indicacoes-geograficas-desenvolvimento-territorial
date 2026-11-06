# ==============================================================================
# Script 03: Análise de Robustez - PSM CAFÉ (Versão Simplificada)
# Objetivo: Testar sensibilidade a diferentes calipers e ratios
# ==============================================================================

.libPaths(c("~/R/library", .libPaths()))

rm(list = ls())

library(dplyr)
library(MatchIt)
library(lmtest)
library(sandwich)

setwd("/mnt/c/Users/Trovao/Desktop/Artigo - Economia Regional")

cat("\n╔═══════════════════════════════════════════════════════════╗\n")
cat("║         ANÁLISE DE ROBUSTEZ - PSM CAFÉ                    ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

# ==============================================================================
# 1. CARREGAR BASE
# ==============================================================================

cat("1. Carregando base de dados...\n")
base <- read.csv("Resultados/base_cafe_psm.csv") %>%
  filter(!is.na(IFDM), !is.na(PIB_Percapita), !is.na(Part_Agro))

cat("  ✓ Observações:", nrow(base), "\n")
cat("  ✓ Tratados:", sum(base$IG_Cafe), "\n")
cat("  ✓ Controles:", sum(base$IG_Cafe == 0), "\n\n")

# ==============================================================================
# 2. FÓRMULA BASE
# ==============================================================================

formula_ps <- IG_Cafe ~ PIB_Percapita + Part_Agro +
                        VA_Agropecuaria + VA_Industria + VA_Servicos +
                        IFDM_Educacao + IFDM_Saude

# ==============================================================================
# 3. TESTAR DIFERENTES ESPECIFICAÇÕES
# ==============================================================================

resultados <- list()

# Especificação 1: Baseline (nossa análise original)
cat("2. Especificação 1: BASELINE (Caliper=0.01, Ratio=3:1, Replace=TRUE)\n")
m1 <- matchit(formula_ps, data = base, method = "nearest",
              distance = "logit", ratio = 3, replace = TRUE,
              caliper = 0.01, std.caliper = TRUE)
d1 <- match.data(m1, drop.unmatched = TRUE)
resultados[[1]] <- list(
  nome = "Baseline",
  caliper = 0.01,
  ratio = 3,
  replace = TRUE,
  n_trat = sum(d1$IG_Cafe == 1),
  n_ctrl = sum(d1$IG_Cafe == 0),
  att_ifdm = coef(lm(IFDM ~ IG_Cafe, data = d1, weights = weights))["IG_Cafe"],
  se_ifdm = coeftest(lm(IFDM ~ IG_Cafe, data = d1, weights = weights),
                     vcov = vcovHC(lm(IFDM ~ IG_Cafe, data = d1, weights = weights), type = "HC1"))["IG_Cafe", "Std. Error"],
  att_pib = coef(lm(PIB_Percapita ~ IG_Cafe, data = d1, weights = weights))["IG_Cafe"]
)
cat("  ✓ ATT IFDM:", sprintf("%.5f", resultados[[1]]$att_ifdm), "\n\n")

# Especificação 2: Caliper mais restritivo
cat("3. Especificação 2: Caliper=0.005 (mais restritivo)\n")
m2 <- matchit(formula_ps, data = base, method = "nearest",
              distance = "logit", ratio = 3, replace = TRUE,
              caliper = 0.005, std.caliper = TRUE)
d2 <- match.data(m2, drop.unmatched = TRUE)
resultados[[2]] <- list(
  nome = "Caliper 0.005",
  caliper = 0.005,
  ratio = 3,
  replace = TRUE,
  n_trat = sum(d2$IG_Cafe == 1),
  n_ctrl = sum(d2$IG_Cafe == 0),
  att_ifdm = coef(lm(IFDM ~ IG_Cafe, data = d2, weights = weights))["IG_Cafe"],
  se_ifdm = coeftest(lm(IFDM ~ IG_Cafe, data = d2, weights = weights),
                     vcov = vcovHC(lm(IFDM ~ IG_Cafe, data = d2, weights = weights), type = "HC1"))["IG_Cafe", "Std. Error"],
  att_pib = coef(lm(PIB_Percapita ~ IG_Cafe, data = d2, weights = weights))["IG_Cafe"]
)
cat("  ✓ ATT IFDM:", sprintf("%.5f", resultados[[2]]$att_ifdm), "\n\n")

# Especificação 3: Caliper mais permissivo
cat("4. Especificação 3: Caliper=0.02 (mais permissivo)\n")
m3 <- matchit(formula_ps, data = base, method = "nearest",
              distance = "logit", ratio = 3, replace = TRUE,
              caliper = 0.02, std.caliper = TRUE)
d3 <- match.data(m3, drop.unmatched = TRUE)
resultados[[3]] <- list(
  nome = "Caliper 0.02",
  caliper = 0.02,
  ratio = 3,
  replace = TRUE,
  n_trat = sum(d3$IG_Cafe == 1),
  n_ctrl = sum(d3$IG_Cafe == 0),
  att_ifdm = coef(lm(IFDM ~ IG_Cafe, data = d3, weights = weights))["IG_Cafe"],
  se_ifdm = coeftest(lm(IFDM ~ IG_Cafe, data = d3, weights = weights),
                     vcov = vcovHC(lm(IFDM ~ IG_Cafe, data = d3, weights = weights), type = "HC1"))["IG_Cafe", "Std. Error"],
  att_pib = coef(lm(PIB_Percapita ~ IG_Cafe, data = d3, weights = weights))["IG_Cafe"]
)
cat("  ✓ ATT IFDM:", sprintf("%.5f", resultados[[3]]$att_ifdm), "\n\n")

# Especificação 4: Caliper ainda mais permissivo
cat("5. Especificação 4: Caliper=0.05\n")
m4 <- matchit(formula_ps, data = base, method = "nearest",
              distance = "logit", ratio = 3, replace = TRUE,
              caliper = 0.05, std.caliper = TRUE)
d4 <- match.data(m4, drop.unmatched = TRUE)
resultados[[4]] <- list(
  nome = "Caliper 0.05",
  caliper = 0.05,
  ratio = 3,
  replace = TRUE,
  n_trat = sum(d4$IG_Cafe == 1),
  n_ctrl = sum(d4$IG_Cafe == 0),
  att_ifdm = coef(lm(IFDM ~ IG_Cafe, data = d4, weights = weights))["IG_Cafe"],
  se_ifdm = coeftest(lm(IFDM ~ IG_Cafe, data = d4, weights = weights),
                     vcov = vcovHC(lm(IFDM ~ IG_Cafe, data = d4, weights = weights), type = "HC1"))["IG_Cafe", "Std. Error"],
  att_pib = coef(lm(PIB_Percapita ~ IG_Cafe, data = d4, weights = weights))["IG_Cafe"]
)
cat("  ✓ ATT IFDM:", sprintf("%.5f", resultados[[4]]$att_ifdm), "\n\n")

# Especificação 5: Ratio 1:1
cat("6. Especificação 5: Ratio=1:1 (menos controles)\n")
m5 <- matchit(formula_ps, data = base, method = "nearest",
              distance = "logit", ratio = 1, replace = TRUE,
              caliper = 0.01, std.caliper = TRUE)
d5 <- match.data(m5, drop.unmatched = TRUE)
resultados[[5]] <- list(
  nome = "Ratio 1:1",
  caliper = 0.01,
  ratio = 1,
  replace = TRUE,
  n_trat = sum(d5$IG_Cafe == 1),
  n_ctrl = sum(d5$IG_Cafe == 0),
  att_ifdm = coef(lm(IFDM ~ IG_Cafe, data = d5, weights = weights))["IG_Cafe"],
  se_ifdm = coeftest(lm(IFDM ~ IG_Cafe, data = d5, weights = weights),
                     vcov = vcovHC(lm(IFDM ~ IG_Cafe, data = d5, weights = weights), type = "HC1"))["IG_Cafe", "Std. Error"],
  att_pib = coef(lm(PIB_Percapita ~ IG_Cafe, data = d5, weights = weights))["IG_Cafe"]
)
cat("  ✓ ATT IFDM:", sprintf("%.5f", resultados[[5]]$att_ifdm), "\n\n")

# Especificação 6: Ratio 5:1
cat("7. Especificação 6: Ratio=5:1 (mais controles)\n")
m6 <- matchit(formula_ps, data = base, method = "nearest",
              distance = "logit", ratio = 5, replace = TRUE,
              caliper = 0.01, std.caliper = TRUE)
d6 <- match.data(m6, drop.unmatched = TRUE)
resultados[[6]] <- list(
  nome = "Ratio 5:1",
  caliper = 0.01,
  ratio = 5,
  replace = TRUE,
  n_trat = sum(d6$IG_Cafe == 1),
  n_ctrl = sum(d6$IG_Cafe == 0),
  att_ifdm = coef(lm(IFDM ~ IG_Cafe, data = d6, weights = weights))["IG_Cafe"],
  se_ifdm = coeftest(lm(IFDM ~ IG_Cafe, data = d6, weights = weights),
                     vcov = vcovHC(lm(IFDM ~ IG_Cafe, data = d6, weights = weights), type = "HC1"))["IG_Cafe", "Std. Error"],
  att_pib = coef(lm(PIB_Percapita ~ IG_Cafe, data = d6, weights = weights))["IG_Cafe"]
)
cat("  ✓ ATT IFDM:", sprintf("%.5f", resultados[[6]]$att_ifdm), "\n\n")

# Especificação 7: Sem reposição
cat("8. Especificação 7: Replace=FALSE (sem reposição)\n")
m7 <- matchit(formula_ps, data = base, method = "nearest",
              distance = "logit", ratio = 3, replace = FALSE,
              caliper = 0.01, std.caliper = TRUE)
d7 <- match.data(m7, drop.unmatched = TRUE)
resultados[[7]] <- list(
  nome = "Sem reposição",
  caliper = 0.01,
  ratio = 3,
  replace = FALSE,
  n_trat = sum(d7$IG_Cafe == 1),
  n_ctrl = sum(d7$IG_Cafe == 0),
  att_ifdm = coef(lm(IFDM ~ IG_Cafe, data = d7, weights = weights))["IG_Cafe"],
  se_ifdm = coeftest(lm(IFDM ~ IG_Cafe, data = d7, weights = weights),
                     vcov = vcovHC(lm(IFDM ~ IG_Cafe, data = d7, weights = weights), type = "HC1"))["IG_Cafe", "Std. Error"],
  att_pib = coef(lm(PIB_Percapita ~ IG_Cafe, data = d7, weights = weights))["IG_Cafe"]
)
cat("  ✓ ATT IFDM:", sprintf("%.5f", resultados[[7]]$att_ifdm), "\n\n")

# Especificação 8: Modelo parcimonioso (sem VA setoriais)
cat("9. Especificação 8: Modelo Parcimonioso (sem VA setoriais)\n")
formula_parc <- IG_Cafe ~ PIB_Percapita + Part_Agro + IFDM_Educacao + IFDM_Saude
m8 <- matchit(formula_parc, data = base, method = "nearest",
              distance = "logit", ratio = 3, replace = TRUE,
              caliper = 0.01, std.caliper = TRUE)
d8 <- match.data(m8, drop.unmatched = TRUE)
resultados[[8]] <- list(
  nome = "Modelo Parcimonioso",
  caliper = 0.01,
  ratio = 3,
  replace = TRUE,
  n_trat = sum(d8$IG_Cafe == 1),
  n_ctrl = sum(d8$IG_Cafe == 0),
  att_ifdm = coef(lm(IFDM ~ IG_Cafe, data = d8, weights = weights))["IG_Cafe"],
  se_ifdm = coeftest(lm(IFDM ~ IG_Cafe, data = d8, weights = weights),
                     vcov = vcovHC(lm(IFDM ~ IG_Cafe, data = d8, weights = weights), type = "HC1"))["IG_Cafe", "Std. Error"],
  att_pib = coef(lm(PIB_Percapita ~ IG_Cafe, data = d8, weights = weights))["IG_Cafe"]
)
cat("  ✓ ATT IFDM:", sprintf("%.5f", resultados[[8]]$att_ifdm), "\n\n")

# ==============================================================================
# 4. RESUMIR RESULTADOS
# ==============================================================================

cat("╔═══════════════════════════════════════════════════════════╗\n")
cat("║              RESUMO DA ANÁLISE DE ROBUSTEZ                ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

# Criar dataframe
df_results <- data.frame(
  Especificacao = sapply(resultados, function(x) x$nome),
  Caliper = sapply(resultados, function(x) x$caliper),
  Ratio = sapply(resultados, function(x) x$ratio),
  Replace = sapply(resultados, function(x) x$replace),
  N_Tratados = sapply(resultados, function(x) x$n_trat),
  N_Controles = sapply(resultados, function(x) x$n_ctrl),
  ATT_IFDM = sapply(resultados, function(x) x$att_ifdm),
  SE_IFDM = sapply(resultados, function(x) x$se_ifdm),
  ATT_PIB = sapply(resultados, function(x) x$att_pib)
)

# Calcular IC e p-value
df_results$IC_Inf_IFDM <- df_results$ATT_IFDM - 1.96 * df_results$SE_IFDM
df_results$IC_Sup_IFDM <- df_results$ATT_IFDM + 1.96 * df_results$SE_IFDM
df_results$p_value <- 2 * (1 - pnorm(abs(df_results$ATT_IFDM / df_results$SE_IFDM)))
df_results$Significativo <- ifelse(df_results$p_value < 0.10, "Sim", "Não")

print(df_results[, c("Especificacao", "N_Tratados", "N_Controles",
                     "ATT_IFDM", "IC_Inf_IFDM", "IC_Sup_IFDM",
                     "p_value", "Significativo")], row.names = FALSE)

cat("\n\nESTATÍSTICAS RESUMO:\n")
cat("  Média ATT IFDM:", sprintf("%.5f", mean(df_results$ATT_IFDM)), "\n")
cat("  Mediana ATT IFDM:", sprintf("%.5f", median(df_results$ATT_IFDM)), "\n")
cat("  Min ATT IFDM:", sprintf("%.5f", min(df_results$ATT_IFDM)), "\n")
cat("  Max ATT IFDM:", sprintf("%.5f", max(df_results$ATT_IFDM)), "\n")
cat("  Desvio ATT IFDM:", sprintf("%.5f", sd(df_results$ATT_IFDM)), "\n\n")

cat("  Significativos (p<0.10):", sum(df_results$p_value < 0.10), "/", nrow(df_results), "\n")
cat("  Positivos:", sum(df_results$ATT_IFDM > 0), "/", nrow(df_results), "\n\n")

# Salvar
write.csv(df_results, "Resultados/Robustez_PSM_Cafe.csv", row.names = FALSE)

cat("✓ Resultados salvos: Resultados/Robustez_PSM_Cafe.csv\n\n")

cat("╔═══════════════════════════════════════════════════════════╗\n")
cat("║                      CONCLUSÃO                            ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

if(sum(df_results$p_value < 0.10) == 0) {
  cat("✓ RESULTADO ROBUSTO: Nenhuma especificação encontrou efeito significativo.\n")
  cat("  A conclusão de 'sem efeito causal' é ROBUSTA às diferentes especificações.\n\n")
} else {
  cat("⚠️ Efeito significativo em", sum(df_results$p_value < 0.10), "de", nrow(df_results), "especificações.\n")
  cat("  Resultados podem ser sensíveis à especificação.\n\n")
}

cat("✓ ANÁLISE DE ROBUSTEZ CONCLUÍDA!\n\n")
