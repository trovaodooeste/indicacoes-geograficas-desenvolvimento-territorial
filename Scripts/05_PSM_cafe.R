# ==============================================================================
# Script 05: Propensity Score Matching - CAFÉ
# Objetivo: Estimar efeito causal das IGs de café no desenvolvimento territorial
# Metodologia: PSM (Nearest Neighbor + Caliper)
# ==============================================================================

rm(list = ls())

# Pacotes
library(readxl)
library(dplyr)
library(MatchIt)    # PSM
library(cobalt)     # Balanceamento
library(lmtest)
library(sandwich)

setwd("C:/Users/Trovao/Desktop/Artigo - Economia Regional")

cat("\n╔═══════════════════════════════════════════════════════════╗\n")
cat("║   PROPENSITY SCORE MATCHING - INDICAÇÕES GEOGRÁFICAS CAFÉ  ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

# ==============================================================================
# 1. CARREGAR BASE INTEGRADA
# ==============================================================================

cat("1. Carregando base de dados...\n")
base <- read.csv("Resultados/base_cafe_psm.csv")

cat("  ✓ Observações:", nrow(base), "\n")
cat("  ✓ Tratados (com IG Café):", sum(base$IG_Cafe), "\n")
cat("  ✓ Controles (sem IG):", sum(base$IG_Cafe == 0), "\n\n")

# ==============================================================================
# 2. ESPECIFICAR MODELO DE PROPENSITY SCORE
# ==============================================================================

cat("2. Estimando Propensity Score (Modelo Logit)...\n\n")

# Fórmula do matching
# Incluir covariáveis que influenciam tanto o tratamento quanto o resultado
formula_ps <- IG_Cafe ~ Part_Agro + PIB_Percapita + Populacao +
                        Producao_Cafe + N_Estabelecimentos_Cafe +
                        Idade_Media_Produtores + Escolaridade_Baixa

# NOTA: Ajustar variáveis conforme disponibilidade nos dados!

# Estimar PSM
m_out <- matchit(
  formula_ps,
  data = base,
  method = "nearest",     # Nearest neighbor
  distance = "logit",     # Propensity score via logit
  ratio = 3,              # 3 controles para cada tratado
  replace = TRUE,         # Com reposição
  caliper = 0.01,         # Caliper de 0.01
  std.caliper = TRUE      # Caliper em desvios-padrão
)

# Sumário do matching
cat("\n=== RESUMO DO MATCHING ===\n")
summary(m_out)

# ==============================================================================
# 3. DIAGNÓSTICO DE BALANCEAMENTO
# ==============================================================================

cat("\n\n3. Testando balanceamento das covariáveis...\n\n")

# Sumário de balanceamento
bal_tab <- bal.tab(m_out, un = TRUE, thresholds = c(m = 0.1))
print(bal_tab)

# Gráfico de Love Plot
png("Resultados/PSM_Cafe_LovePlot.png", width = 800, height = 600)
love.plot(m_out,
          threshold = 0.1,
          title = "Balanceamento das Covariáveis - Café")
dev.off()
cat("\n  ✓ Gráfico salvo: Resultados/PSM_Cafe_LovePlot.png\n")

# Teste de Kolmogorov-Smirnov
cat("\n=== TESTE KOLMOGOROV-SMIRNOV ===\n")
ks_test <- ks.test(
  base$propensity_score[base$IG_Cafe == 1],
  base$propensity_score[base$IG_Cafe == 0]
)
print(ks_test)

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
# 5. ESTIMAR EFEITO MÉDIO DO TRATAMENTO (ATT)
# ==============================================================================

cat("5. Estimando Average Treatment Effect on Treated (ATT)...\n\n")

# Variáveis de resultado
resultados <- c("IFDM", "IFDM_Emprego", "IFDM_Educacao", "IFDM_Saude",
                "PIB_Percapita", "Emprego_Total", "Emprego_Turismo",
                "Exportacoes", "Exodo_Rural")

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

cat("\n╔═══════════════════════════════════════════════════════════╗\n")
cat("║              RESULTADOS - EFEITO DAS IGs DE CAFÉ          ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

print(att_results, row.names = FALSE)

cat("\nSignificância: *** p<0.01, ** p<0.05, * p<0.10\n")

# ==============================================================================
# 6. SALVAR RESULTADOS
# ==============================================================================

cat("\n\n6. Salvando resultados...\n")

# Salvar tabela de ATT
write.csv(att_results,
          "Resultados/ATT_Cafe.csv",
          row.names = FALSE)

# Salvar base matched
write.csv(base_matched,
          "Resultados/base_cafe_matched.csv",
          row.names = FALSE)

# Relatório completo
sink("Resultados/relatorio_PSM_Cafe.txt")
cat("═══════════════════════════════════════════════════════════\n")
cat("   RELATÓRIO PSM - INDICAÇÕES GEOGRÁFICAS DE CAFÉ\n")
cat("═══════════════════════════════════════════════════════════\n\n")
cat("Data:", format(Sys.Date(), "%d/%m/%Y"), "\n\n")
cat("AMOSTRA:\n")
cat("  Total de municípios:", nrow(base), "\n")
cat("  Municípios com IG Café:", sum(base$IG_Cafe), "\n")
cat("  Municípios pareados:", nrow(base_matched), "\n\n")
cat("ESPECIFICAÇÃO DO MATCHING:\n")
cat("  Método: Nearest Neighbor\n")
cat("  Ratio: 3:1 (com reposição)\n")
cat("  Caliper: 0.01\n")
cat("  Distance: Logit\n\n")
cat("RESULTADOS (ATT):\n")
print(att_results, row.names = FALSE)
cat("\n═══════════════════════════════════════════════════════════\n")
sink()

cat("  ✓ Resultados salvos em Resultados/\n")
cat("\n\n✓ ANÁLISE PSM - CAFÉ CONCLUÍDA COM SUCESSO!\n")
cat("\nPróximos passos:\n")
cat("  1. Revisar balanceamento das covariáveis (LovePlot)\n")
cat("  2. Analisar ATT (ATT_Cafe.csv)\n")
cat("  3. Executar 06_PSM_vinho.R\n\n")
