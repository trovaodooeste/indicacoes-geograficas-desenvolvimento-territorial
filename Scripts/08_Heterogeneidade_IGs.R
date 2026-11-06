# ==============================================================================
# Script 08: Análise de Heterogeneidade - IGs Específicas
# Objetivo: Testar se efeito varia entre IGs grandes vs pequenas
# Data: 09/06/2026
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

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║         ANÁLISE DE HETEROGENEIDADE - IGs ESPECÍFICAS          ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

# ==============================================================================
# 1. CARREGAR PAINEL COM ANOS DE CONCESSÃO
# ==============================================================================

cat("1. Carregando painel completo...\n")

# Municípios com anos de concessão
anos_ig <- read.csv("Resultados/Municipios_Anos_Concessao.csv")

# Painel IFDM + PIB
painel <- read.csv("Resultados/painel_cafe_economicas_final.csv")

cat("  ✓ Painel carregado:", nrow(painel), "observações\n")
cat("  ✓ Municípios com IG:", n_distinct(anos_ig$cod_municipio), "\n\n")

# ==============================================================================
# 2. CLASSIFICAR IGs POR TAMANHO
# ==============================================================================

cat("2. Classificando IGs por tamanho...\n\n")

# Contar municípios por IG
igs_tamanho <- anos_ig %>%
  group_by(nome_ig_extraido) %>%
  summarise(
    n_municipios = n(),
    ano_concessao = first(ano_concessao)
  ) %>%
  arrange(desc(n_municipios))

cat("  IGs por número de municípios:\n")
print(igs_tamanho, n = 30)
cat("\n")

# Classificar IGs
# Grandes: ≥10 municípios
# Pequenas: <10 municípios

igs_grandes <- igs_tamanho %>%
  filter(n_municipios >= 10) %>%
  pull(nome_ig_extraido)

cat("  IGs GRANDES (≥10 municípios):\n")
for(ig in igs_grandes) {
  n <- igs_tamanho$n_municipios[igs_tamanho$nome_ig_extraido == ig]
  cat("    -", ig, ":", n, "municípios\n")
}
cat("\n")

# Adicionar classificação ao painel de municípios
anos_ig <- anos_ig %>%
  mutate(
    ig_grande = ifelse(nome_ig_extraido %in% igs_grandes, 1, 0)
  )

# Join com painel
painel <- painel %>%
  left_join(
    anos_ig %>% select(cod_municipio, nome_ig_extraido, ig_grande),
    by = "cod_municipio"
  )

# ==============================================================================
# 3. DiD COM HETEROGENEIDADE - IFDM
# ==============================================================================

cat("3. Estimando DiD com heterogeneidade...\n\n")

# Preparar variáveis
painel <- painel %>%
  mutate(
    mun_f = as.factor(cod_municipio),
    ano_f = as.factor(ano),

    # Tratamento específico por tamanho de IG
    pos_trat_grande = pos_tratamento & ig_grande == 1,
    pos_trat_pequena = pos_tratamento & (ig_grande == 0 | is.na(ig_grande))
  )

# Modelo com interação
cat("  Modelo 1: DiD com interação (IG Grande vs Pequena)\n")
cat("  -------------------------------------------------------\n")

modelo_het <- lm(ifdm_geral ~ pos_trat_grande + pos_trat_pequena + mun_f + ano_f,
                 data = painel)

vcov_het <- vcovCL(modelo_het, cluster = painel$cod_municipio)
coef_het <- coeftest(modelo_het, vcov = vcov_het)

# Extrair coeficientes
if("pos_trat_grandeTRUE" %in% rownames(coef_het)) {
  att_grande <- coef_het["pos_trat_grandeTRUE", "Estimate"]
  se_grande <- coef_het["pos_trat_grandeTRUE", "Std. Error"]
  p_grande <- coef_het["pos_trat_grandeTRUE", "Pr(>|t|)"]

  cat("    ATT (IGs Grandes):", sprintf("%.5f", att_grande), "\n")
  cat("    SE:              ", sprintf("%.5f", se_grande), "\n")
  cat("    p-valor:         ", sprintf("%.4f", p_grande), "\n")
  cat("    IC 95%:          [", sprintf("%.5f", att_grande - 1.96*se_grande),
      ",", sprintf("%.5f", att_grande + 1.96*se_grande), "]\n\n")
}

if("pos_trat_pequenaTRUE" %in% rownames(coef_het)) {
  att_pequena <- coef_het["pos_trat_pequenaTRUE", "Estimate"]
  se_pequena <- coef_het["pos_trat_pequenaTRUE", "Std. Error"]
  p_pequena <- coef_het["pos_trat_pequenaTRUE", "Pr(>|t|)"]

  cat("    ATT (IGs Pequenas):", sprintf("%.5f", att_pequena), "\n")
  cat("    SE:                ", sprintf("%.5f", se_pequena), "\n")
  cat("    p-valor:           ", sprintf("%.4f", p_pequena), "\n")
  cat("    IC 95%:            [", sprintf("%.5f", att_pequena - 1.96*se_pequena),
      ",", sprintf("%.5f", att_pequena + 1.96*se_pequena), "]\n\n")
}

# Teste de diferença
if(exists("att_grande") && exists("att_pequena")) {
  dif <- att_grande - att_pequena
  se_dif <- sqrt(se_grande^2 + se_pequena^2)
  t_dif <- dif / se_dif
  p_dif <- 2 * pt(-abs(t_dif), df = nrow(painel) - 2)

  cat("    TESTE DE DIFERENÇA (Grande - Pequena):\n")
  cat("    Diferença:  ", sprintf("%.5f", dif), "\n")
  cat("    SE:         ", sprintf("%.5f", se_dif), "\n")
  cat("    t-stat:     ", sprintf("%.3f", t_dif), "\n")
  cat("    p-valor:    ", sprintf("%.4f", p_dif), "\n")

  if(p_dif < 0.10) {
    cat("    ✓ DIFERENÇA SIGNIFICATIVA entre IGs grandes e pequenas!\n\n")
  } else {
    cat("    ✗ Diferença NÃO significativa (p > 0.10)\n\n")
  }
}

# ==============================================================================
# 4. ANÁLISE POR IG ESPECÍFICA (TOP 3)
# ==============================================================================

cat("4. Análise por IG específica (TOP 3 maiores)...\n\n")

# Top 3 IGs
top3_igs <- igs_tamanho %>%
  head(3) %>%
  pull(nome_ig_extraido)

resultados_igs <- data.frame()

for(ig_nome in top3_igs) {

  cat("  Analisando:", ig_nome, "\n")

  # Filtrar painel para esta IG vs controles
  painel_ig <- painel %>%
    filter(
      # Controles OU municípios desta IG específica
      is.na(nome_ig_extraido) | nome_ig_extraido == ig_nome
    ) %>%
    mutate(
      tratado_ig = !is.na(nome_ig_extraido) & nome_ig_extraido == ig_nome,
      pos_trat_ig = tratado_ig & pos_tratamento
    )

  if(nrow(painel_ig) < 100) {
    cat("    ⚠ Poucos dados, pulando...\n\n")
    next
  }

  # Estimar DiD
  tryCatch({
    modelo_ig <- lm(ifdm_geral ~ pos_trat_ig + as.factor(cod_municipio) + as.factor(ano),
                    data = painel_ig)

    vcov_ig <- vcovCL(modelo_ig, cluster = painel_ig$cod_municipio)
    coef_ig <- coeftest(modelo_ig, vcov = vcov_ig)

    if("pos_trat_igTRUE" %in% rownames(coef_ig)) {
      att <- coef_ig["pos_trat_igTRUE", "Estimate"]
      se <- coef_ig["pos_trat_igTRUE", "Std. Error"]
      p <- coef_ig["pos_trat_igTRUE", "Pr(>|t|)"]

      cat("    ATT:     ", sprintf("%.5f", att), "\n")
      cat("    p-valor: ", sprintf("%.4f", p), "\n")

      sig <- ifelse(p < 0.10, "Sim*", "Não")
      cat("    Sig.:    ", sig, "\n\n")

      resultados_igs <- rbind(resultados_igs, data.frame(
        IG = ig_nome,
        N_Municipios = igs_tamanho$n_municipios[igs_tamanho$nome_ig_extraido == ig_nome],
        ATT = att,
        SE = se,
        p_valor = p,
        IC_Inf = att - 1.96*se,
        IC_Sup = att + 1.96*se,
        Significativo = sig
      ))
    }
  }, error = function(e) {
    cat("    ✗ Erro:", e$message, "\n\n")
  })
}

# ==============================================================================
# 5. APRESENTAR RESULTADOS
# ==============================================================================

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║              RESULTADOS - ANÁLISE DE HETEROGENEIDADE          ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("═══════════════════════════════════════════════════════════════════\n")
cat("MODELO 1: IGs GRANDES vs PEQUENAS\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

if(exists("att_grande") && exists("att_pequena")) {
  resultado_tamanho <- data.frame(
    Categoria = c("IGs Grandes (≥10 municípios)",
                  "IGs Pequenas (<10 municípios)",
                  "Diferença (Grande - Pequena)"),
    ATT = c(att_grande, att_pequena, dif),
    SE = c(se_grande, se_pequena, se_dif),
    p_valor = c(p_grande, p_pequena, p_dif),
    IC_Inf = c(att_grande - 1.96*se_grande,
               att_pequena - 1.96*se_pequena,
               dif - 1.96*se_dif),
    IC_Sup = c(att_grande + 1.96*se_grande,
               att_pequena + 1.96*se_pequena,
               dif + 1.96*se_dif)
  )

  print(resultado_tamanho, row.names = FALSE)
  cat("\n")
}

cat("\n═══════════════════════════════════════════════════════════════════\n")
cat("MODELO 2: IGs ESPECÍFICAS (TOP 3)\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

if(nrow(resultados_igs) > 0) {
  print(resultados_igs, row.names = FALSE)
  cat("\n* Significativo a 10%\n")
}

# ==============================================================================
# 6. GRÁFICO DE HETEROGENEIDADE
# ==============================================================================

cat("\n5. Gerando gráfico de heterogeneidade...\n")

if(nrow(resultados_igs) > 0) {

  # Adicionar resultado agregado
  resultado_geral <- data.frame(
    IG = "TODAS as IGs (agregado)",
    N_Municipios = sum(anos_ig$ig_grande == 1 | anos_ig$ig_grande == 0, na.rm = TRUE),
    ATT = 0.0088,  # Do DiD geral
    SE = 0.0051,
    p_valor = 0.081,
    IC_Inf = -0.001,
    IC_Sup = 0.019,
    Significativo = "Não"
  )

  resultados_plot <- rbind(resultado_geral, resultados_igs)
  resultados_plot$IG <- factor(resultados_plot$IG,
                                levels = rev(resultados_plot$IG))

  p_het <- ggplot(resultados_plot, aes(x = IG, y = ATT)) +
    geom_point(size = 3) +
    geom_errorbar(aes(ymin = IC_Inf, ymax = IC_Sup), width = 0.2) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
    coord_flip() +
    labs(title = "Heterogeneidade do Efeito das IGs de Café no IFDM",
         subtitle = "Análise por IG específica | DiD com efeitos fixos | IC 95%",
         x = "",
         y = "Efeito no IFDM (ATT)",
         caption = "Nota: Anos EXATOS de concessão | Erros padrão clusterizados por município") +
    theme_minimal() +
    theme(plot.caption = element_text(size = 8, hjust = 0))

  ggsave("Resultados/Heterogeneidade_IGs.png", p_het, width = 10, height = 6)
  cat("  ✓ Gráfico salvo em Resultados/Heterogeneidade_IGs.png\n\n")
}

# ==============================================================================
# 7. SALVAR RESULTADOS
# ==============================================================================

cat("6. Salvando resultados...\n")

if(exists("resultado_tamanho")) {
  write.csv(resultado_tamanho,
            "Resultados/Heterogeneidade_Tamanho.csv",
            row.names = FALSE)
  cat("  ✓ Heterogeneidade_Tamanho.csv\n")
}

if(nrow(resultados_igs) > 0) {
  write.csv(resultados_igs,
            "Resultados/Heterogeneidade_IGs_Especificas.csv",
            row.names = FALSE)
  cat("  ✓ Heterogeneidade_IGs_Especificas.csv\n")
}

# Relatório
sink("Resultados/Relatorio_Heterogeneidade.txt")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("         ANÁLISE DE HETEROGENEIDADE - IGs DE CAFÉ\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")
cat("Data:", format(Sys.Date(), "%d/%m/%Y"), "\n\n")

cat("OBJETIVO:\n")
cat("  Testar se o efeito das IGs varia entre:\n")
cat("  1. IGs grandes (≥10 municípios) vs pequenas (<10 municípios)\n")
cat("  2. IGs específicas (análise individual das TOP 3)\n\n")

cat("MÉTODO:\n")
cat("  - DiD com efeitos fixos (município + ano)\n")
cat("  - Erros padrão clusterizados por município\n")
cat("  - Anos EXATOS de concessão (tratamento escalonado)\n\n")

cat("═══════════════════════════════════════════════════════════════════\n")
cat("RESULTADOS - IGs GRANDES vs PEQUENAS\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

if(exists("resultado_tamanho")) {
  print(resultado_tamanho, row.names = FALSE)
}

cat("\n\n═══════════════════════════════════════════════════════════════════\n")
cat("RESULTADOS - IGs ESPECÍFICAS\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

if(nrow(resultados_igs) > 0) {
  print(resultados_igs, row.names = FALSE)
}

cat("\n\n═══════════════════════════════════════════════════════════════════\n")
cat("INTERPRETAÇÃO\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

if(exists("p_dif")) {
  if(p_dif < 0.10) {
    cat("✓ HÁ EVIDÊNCIA de heterogeneidade por tamanho de IG (p < 0.10)\n")
    cat("  → IGs maiores podem ter efeito diferente de IGs menores\n")
  } else {
    cat("✗ NÃO HÁ EVIDÊNCIA de heterogeneidade por tamanho de IG (p ≥ 0.10)\n")
    cat("  → Efeito parece ser homogêneo independente do tamanho da IG\n")
  }
}

cat("\n")
if(nrow(resultados_igs) > 0) {
  n_sig <- sum(resultados_igs$p_valor < 0.10)
  if(n_sig > 0) {
    cat("✓", n_sig, "de", nrow(resultados_igs), "IGs específicas mostram efeito significativo\n")
  } else {
    cat("✗ NENHUMA das", nrow(resultados_igs), "IGs específicas mostra efeito significativo\n")
    cat("  → Confirma resultado agregado: efeito nulo\n")
  }
}

cat("\n═══════════════════════════════════════════════════════════════════\n")
sink()

cat("\n✓ ANÁLISE DE HETEROGENEIDADE - CONCLUÍDA!\n\n")
