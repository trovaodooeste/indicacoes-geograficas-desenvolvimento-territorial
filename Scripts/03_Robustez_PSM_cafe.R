# ==============================================================================
# Script 03: Análise de Robustez - PSM CAFÉ
# Objetivo: Testar sensibilidade dos resultados a diferentes especificações
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
# 2. FUNÇÃO PARA ESTIMAR ATT
# ==============================================================================

estimar_att <- function(matched_data, var) {
  formula_att <- as.formula(paste(var, "~ IG_Cafe"))
  modelo <- lm(formula_att, data = matched_data, weights = weights)
  se_robust <- coeftest(modelo, vcov = vcovHC(modelo, type = "HC1"))

  att <- coef(modelo)["IG_Cafe"]
  se <- se_robust["IG_Cafe", "Std. Error"]
  p_val <- se_robust["IG_Cafe", "Pr(>|t|)"]

  return(c(ATT = att, SE = se, p_value = p_val))
}

# ==============================================================================
# 3. ESPECIFICAÇÕES A TESTAR
# ==============================================================================

cat("2. Definindo especificações...\n\n")

# Fórmulas
formula_completa <- IG_Cafe ~ PIB_Percapita + Part_Agro +
                              VA_Agropecuaria + VA_Industria + VA_Servicos +
                              IFDM_Educacao + IFDM_Saude

formula_parcimoniosa <- IG_Cafe ~ PIB_Percapita + Part_Agro +
                                  IFDM_Educacao + IFDM_Saude

# Criar grid de especificações
especificacoes <- expand.grid(
  caliper = c(0.005, 0.01, 0.02, 0.05),
  ratio = c(1, 2, 3, 5),
  replace = c(TRUE, FALSE),
  formula_nome = c("Completa", "Parcimoniosa"),
  stringsAsFactors = FALSE
)

cat("  ✓", nrow(especificacoes), "especificações a testar\n\n")

# ==============================================================================
# 4. RODAR TODAS AS ESPECIFICAÇÕES
# ==============================================================================

cat("3. Rodando análise de robustez...\n\n")

resultados_robustez <- data.frame()

for(i in 1:nrow(especificacoes)) {

  spec <- especificacoes[i, ]

  cat(sprintf("  [%d/%d] Caliper=%.3f, Ratio=%d:1, Replace=%s, Formula=%s\n",
              i, nrow(especificacoes), spec$caliper, spec$ratio,
              spec$replace, spec$formula_nome))

  # Selecionar fórmula
  formula_ps <- if(spec$formula_nome == "Completa") formula_completa else formula_parcimoniosa

  # Tentar fazer matching
  tryCatch({
    m_out <- matchit(
      formula_ps,
      data = base,
      method = "nearest",
      distance = "logit",
      ratio = spec$ratio,
      replace = spec$replace,
      caliper = spec$caliper,
      std.caliper = TRUE
    )

    # Extrair dados pareados
    base_matched <- match.data(m_out)

    # Calcular ATT para IFDM e PIB
    att_ifdm <- estimar_att(base_matched, "IFDM")
    att_pib <- estimar_att(base_matched, "PIB_Percapita")

    # Guardar resultados
    resultado <- data.frame(
      Caliper = spec$caliper,
      Ratio = spec$ratio,
      Replace = spec$replace,
      Formula = spec$formula_nome,
      N_Tratados = sum(base_matched$IG_Cafe == 1),
      N_Controles = sum(base_matched$IG_Cafe == 0),
      N_Total = nrow(base_matched),
      ATT_IFDM = att_ifdm["ATT"],
      SE_IFDM = att_ifdm["SE"],
      p_IFDM = att_ifdm["p_value"],
      ATT_PIB = att_pib["ATT"],
      SE_PIB = att_pib["SE"],
      p_PIB = att_pib["p_value"]
    )

    resultados_robustez <- rbind(resultados_robustez, resultado)

  }, error = function(e) {
    cat("    ⚠️ ERRO:", e$message, "\n")
  })
}

cat("\n  ✓ Robustez concluída!\n\n")

# ==============================================================================
# 5. ANALISAR RESULTADOS
# ==============================================================================

cat("╔═══════════════════════════════════════════════════════════╗\n")
cat("║              RESUMO DA ANÁLISE DE ROBUSTEZ                ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

# Adicionar significância
resultados_robustez <- resultados_robustez %>%
  mutate(
    Sig_IFDM = case_when(
      p_IFDM < 0.01 ~ "***",
      p_IFDM < 0.05 ~ "**",
      p_IFDM < 0.10 ~ "*",
      TRUE ~ ""
    ),
    Sig_PIB = case_when(
      p_PIB < 0.01 ~ "***",
      p_PIB < 0.05 ~ "**",
      p_PIB < 0.10 ~ "*",
      TRUE ~ ""
    )
  )

# Mostrar todas as especificações
cat("TODAS AS ESPECIFICAÇÕES:\n\n")
print(resultados_robustez[, c("Caliper", "Ratio", "Replace", "Formula",
                               "N_Tratados", "N_Controles",
                               "ATT_IFDM", "p_IFDM", "Sig_IFDM")],
      row.names = FALSE)

cat("\n\n")

# Estatísticas resumo
cat("═══════════════════════════════════════════════════════════\n")
cat("ESTATÍSTICAS RESUMO - ATT IFDM\n")
cat("═══════════════════════════════════════════════════════════\n\n")

cat("Mínimo:  ", sprintf("%.5f", min(resultados_robustez$ATT_IFDM)), "\n")
cat("Máximo:  ", sprintf("%.5f", max(resultados_robustez$ATT_IFDM)), "\n")
cat("Média:   ", sprintf("%.5f", mean(resultados_robustez$ATT_IFDM)), "\n")
cat("Mediana: ", sprintf("%.5f", median(resultados_robustez$ATT_IFDM)), "\n")
cat("Desvio:  ", sprintf("%.5f", sd(resultados_robustez$ATT_IFDM)), "\n\n")

cat("Resultados significativos (p<0.10):",
    sum(resultados_robustez$p_IFDM < 0.10), "/", nrow(resultados_robustez), "\n")
cat("Resultados positivos:",
    sum(resultados_robustez$ATT_IFDM > 0), "/", nrow(resultados_robustez), "\n\n")

cat("═══════════════════════════════════════════════════════════\n")
cat("ESTATÍSTICAS RESUMO - ATT PIB PER CAPITA\n")
cat("═══════════════════════════════════════════════════════════\n\n")

cat("Mínimo:  ", sprintf("R$ %.2f", min(resultados_robustez$ATT_PIB)), "\n")
cat("Máximo:  ", sprintf("R$ %.2f", max(resultados_robustez$ATT_PIB)), "\n")
cat("Média:   ", sprintf("R$ %.2f", mean(resultados_robustez$ATT_PIB)), "\n")
cat("Mediana: ", sprintf("R$ %.2f", median(resultados_robustez$ATT_PIB)), "\n")
cat("Desvio:  ", sprintf("R$ %.2f", sd(resultados_robustez$ATT_PIB)), "\n\n")

cat("Resultados significativos (p<0.10):",
    sum(resultados_robustez$p_PIB < 0.10), "/", nrow(resultados_robustez), "\n")
cat("Resultados positivos:",
    sum(resultados_robustez$ATT_PIB > 0), "/", nrow(resultados_robustez), "\n\n")

# ==============================================================================
# 6. GRÁFICOS DE SENSIBILIDADE
# ==============================================================================

cat("4. Gerando gráficos de sensibilidade...\n")

# Preparar para gráfico
library(ggplot2)

resultados_robustez$Spec_Label <- paste0("C=", resultados_robustez$Caliper,
                                         " R=", resultados_robustez$Ratio,
                                         ifelse(resultados_robustez$Replace, " (Rep)", " (No)"),
                                         " ", resultados_robustez$Formula)

# Gráfico 1: ATT IFDM por especificação
p1 <- ggplot(resultados_robustez, aes(x = reorder(Spec_Label, ATT_IFDM), y = ATT_IFDM)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = ATT_IFDM - 1.96*SE_IFDM,
                    ymax = ATT_IFDM + 1.96*SE_IFDM), width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  coord_flip() +
  labs(title = "Robustez: ATT no IFDM por Especificação",
       subtitle = "Intervalo de confiança 95%",
       x = "Especificação",
       y = "ATT IFDM") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 6))

ggsave("Resultados/Robustez_ATT_IFDM.png", p1, width = 10, height = 12)

# Gráfico 2: ATT por Caliper
p2 <- ggplot(resultados_robustez, aes(x = factor(Caliper), y = ATT_IFDM)) +
  geom_boxplot() +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  labs(title = "ATT IFDM por Caliper",
       x = "Caliper",
       y = "ATT IFDM") +
  theme_minimal()

ggsave("Resultados/Robustez_Caliper.png", p2, width = 8, height = 6)

# Gráfico 3: ATT por Ratio
p3 <- ggplot(resultados_robustez, aes(x = factor(Ratio), y = ATT_IFDM)) +
  geom_boxplot() +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  labs(title = "ATT IFDM por Ratio",
       x = "Ratio (controles por tratado)",
       y = "ATT IFDM") +
  theme_minimal()

ggsave("Resultados/Robustez_Ratio.png", p3, width = 8, height = 6)

cat("  ✓ Gráficos salvos:\n")
cat("    - Resultados/Robustez_ATT_IFDM.png\n")
cat("    - Resultados/Robustez_Caliper.png\n")
cat("    - Resultados/Robustez_Ratio.png\n\n")

# ==============================================================================
# 7. SALVAR RESULTADOS
# ==============================================================================

cat("5. Salvando resultados...\n")

write.csv(resultados_robustez,
          "Resultados/Robustez_PSM_Cafe.csv",
          row.names = FALSE)

cat("  ✓ Tabela salva: Resultados/Robustez_PSM_Cafe.csv\n\n")

# ==============================================================================
# 8. CONCLUSÃO
# ==============================================================================

cat("╔═══════════════════════════════════════════════════════════╗\n")
cat("║                      CONCLUSÃO                            ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

# Verificar se resultados são robustos
ifdm_positivo_pct <- (sum(resultados_robustez$ATT_IFDM > 0) / nrow(resultados_robustez)) * 100
ifdm_sig_pct <- (sum(resultados_robustez$p_IFDM < 0.10) / nrow(resultados_robustez)) * 100

cat("ROBUSTEZ DOS RESULTADOS:\n\n")
cat("IFDM:\n")
cat("  - ATT positivo em", sprintf("%.1f%%", ifdm_positivo_pct), "das especificações\n")
cat("  - ATT significativo (p<0.10) em", sprintf("%.1f%%", ifdm_sig_pct), "das especificações\n")
cat("  - Média do ATT:", sprintf("%.5f", mean(resultados_robustez$ATT_IFDM)), "\n")

if(ifdm_sig_pct < 10) {
  cat("\n✓ RESULTADO ROBUSTO: Efeito NÃO significativo em quase todas as especificações\n")
  cat("  A conclusão de 'sem efeito causal' é ROBUSTA.\n\n")
} else if(ifdm_sig_pct > 50) {
  cat("\n⚠️ ATENÇÃO: Efeito significativo em mais de 50% das especificações\n")
  cat("  Resultados podem ser sensíveis à especificação.\n\n")
} else {
  cat("\n⚠️ RESULTADO MISTO: Efeito significativo em algumas especificações\n")
  cat("  Resultados são sensíveis à escolha do modelo.\n\n")
}

cat("✓ ANÁLISE DE ROBUSTEZ CONCLUÍDA COM SUCESSO!\n\n")
