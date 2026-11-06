# ==============================================================================
# Script 08b: Análise de Heterogeneidade - MÚLTIPLAS VARIÁVEIS
# Objetivo: Testar heterogeneidade para IFDM + PIB + VA Setorial
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
cat("║    ANÁLISE DE HETEROGENEIDADE - MÚLTIPLAS VARIÁVEIS           ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

# ==============================================================================
# 1. CARREGAR DADOS
# ==============================================================================

cat("1. Carregando dados...\n")

anos_ig <- read.csv("Resultados/Municipios_Anos_Concessao.csv")
painel <- read.csv("Resultados/painel_cafe_economicas_final.csv")

# Classificar IGs por tamanho
igs_tamanho <- anos_ig %>%
  group_by(nome_ig_extraido) %>%
  summarise(n_municipios = n()) %>%
  arrange(desc(n_municipios))

igs_grandes <- igs_tamanho %>%
  filter(n_municipios >= 10) %>%
  pull(nome_ig_extraido)

anos_ig <- anos_ig %>%
  mutate(ig_grande = ifelse(nome_ig_extraido %in% igs_grandes, 1, 0))

painel <- painel %>%
  left_join(anos_ig %>% select(cod_municipio, nome_ig_extraido, ig_grande),
            by = "cod_municipio") %>%
  mutate(
    mun_f = as.factor(cod_municipio),
    ano_f = as.factor(ano),
    pos_trat_grande = pos_tratamento & ig_grande == 1,
    pos_trat_pequena = pos_tratamento & (ig_grande == 0 | is.na(ig_grande))
  )

cat("  ✓ Dados carregados\n\n")

# ==============================================================================
# 2. DEFINIR VARIÁVEIS DE OUTCOME
# ==============================================================================

outcomes <- list(
  # IFDM
  list(var = "ifdm_geral", nome = "IFDM Geral", tipo = "Desenvolvimento"),

  # PIB (log)
  list(var = "log_pib_pc", nome = "log(PIB per capita)", tipo = "Renda"),

  # VA Setorial (log)
  list(var = "log_va_agro", nome = "log(VA Agropecuária)", tipo = "Setorial"),
  list(var = "log_va_ind", nome = "log(VA Indústria)", tipo = "Setorial"),
  list(var = "log_va_serv", nome = "log(VA Serviços)", tipo = "Setorial"),

  # Participação
  list(var = "part_agro", nome = "Part. Agropecuária (%)", tipo = "Estrutura")
)

cat("2. Variáveis a testar:\n")
for(i in 1:length(outcomes)) {
  cat("  ", i, ". ", outcomes[[i]]$nome, " (", outcomes[[i]]$tipo, ")\n", sep="")
}
cat("\n")

# ==============================================================================
# 3. ANÁLISE POR IG ESPECÍFICA - MÚLTIPLAS VARIÁVEIS
# ==============================================================================

cat("3. Estimando heterogeneidade por IG específica...\n\n")

# Top 3 IGs
top3_igs <- c("Planalto de Vitória da Conquista",
              "Vale do Café",
              "Noroeste Fluminense")

resultados_completos <- data.frame()

for(ig_nome in top3_igs) {

  cat("═══════════════════════════════════════════════════════════════════\n")
  cat("IG:", ig_nome, "\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")

  # Filtrar painel
  painel_ig <- painel %>%
    filter(is.na(nome_ig_extraido) | nome_ig_extraido == ig_nome) %>%
    mutate(
      tratado_ig = !is.na(nome_ig_extraido) & nome_ig_extraido == ig_nome,
      pos_trat_ig = tratado_ig & pos_tratamento
    )

  # Testar cada outcome
  for(i in 1:length(outcomes)) {
    outcome <- outcomes[[i]]
    var <- outcome$var
    nome <- outcome$nome
    tipo <- outcome$tipo

    cat("  [", i, "/", length(outcomes), "] ", nome, "\n", sep="")

    # Filtrar NAs
    painel_var <- painel_ig %>%
      filter(!is.na(.data[[var]]))

    if(nrow(painel_var) < 100) {
      cat("      ⚠ Poucos dados\n")
      next
    }

    # Estimar modelo
    tryCatch({
      formula_did <- as.formula(paste(var, "~ pos_trat_ig + as.factor(cod_municipio) + as.factor(ano)"))
      modelo <- lm(formula_did, data = painel_var)

      vcov_cl <- vcovCL(modelo, cluster = painel_var$cod_municipio)
      coef_rob <- coeftest(modelo, vcov = vcov_cl)

      if("pos_trat_igTRUE" %in% rownames(coef_rob)) {
        att <- coef_rob["pos_trat_igTRUE", "Estimate"]
        se <- coef_rob["pos_trat_igTRUE", "Std. Error"]
        p <- coef_rob["pos_trat_igTRUE", "Pr(>|t|)"]

        # Calcular efeito %
        if(grepl("log", var)) {
          efeito_pct <- (exp(att) - 1) * 100
        } else if(grepl("part", var)) {
          efeito_pct <- NA  # Já em pontos percentuais
        } else {
          # Para IFDM, calcular % sobre média controles
          media_ctrl <- mean(painel_var[[var]][!painel_var$tratado_ig], na.rm=TRUE)
          efeito_pct <- (att / media_ctrl) * 100
        }

        sig <- case_when(
          p < 0.01 ~ "***",
          p < 0.05 ~ "**",
          p < 0.10 ~ "*",
          TRUE ~ ""
        )

        cat("      ATT: ", sprintf("%.5f", att), " | p: ", sprintf("%.4f", p), " ", sig, "\n", sep="")

        resultados_completos <- rbind(resultados_completos, data.frame(
          IG = ig_nome,
          Tipo = tipo,
          Variavel = nome,
          ATT = att,
          SE = se,
          p_valor = p,
          Efeito_Pct = efeito_pct,
          IC_Inf = att - 1.96*se,
          IC_Sup = att + 1.96*se,
          Significativo = sig,
          N_obs = nrow(painel_var),
          stringsAsFactors = FALSE
        ))
      }
    }, error = function(e) {
      cat("      ✗ Erro\n")
    })
  }
  cat("\n")
}

# ==============================================================================
# 4. ANÁLISE GRANDES vs PEQUENAS - MÚLTIPLAS VARIÁVEIS
# ==============================================================================

cat("4. Estimando IGs Grandes vs Pequenas (múltiplas variáveis)...\n\n")

resultados_tamanho <- data.frame()

for(i in 1:length(outcomes)) {
  outcome <- outcomes[[i]]
  var <- outcome$var
  nome <- outcome$nome
  tipo <- outcome$tipo

  cat("  [", i, "/", length(outcomes), "] ", nome, "\n", sep="")

  # Filtrar NAs
  painel_var <- painel %>%
    filter(!is.na(.data[[var]]))

  if(nrow(painel_var) < 100) {
    cat("      ⚠ Poucos dados\n")
    next
  }

  # Modelo com interação
  tryCatch({
    formula_het <- as.formula(paste(var, "~ pos_trat_grande + pos_trat_pequena + mun_f + ano_f"))
    modelo <- lm(formula_het, data = painel_var)

    vcov_cl <- vcovCL(modelo, cluster = painel_var$cod_municipio)
    coef_rob <- coeftest(modelo, vcov = vcov_cl)

    # Grandes
    if("pos_trat_grandeTRUE" %in% rownames(coef_rob)) {
      att_g <- coef_rob["pos_trat_grandeTRUE", "Estimate"]
      se_g <- coef_rob["pos_trat_grandeTRUE", "Std. Error"]
      p_g <- coef_rob["pos_trat_grandeTRUE", "Pr(>|t|)"]

      # Pequenas
      att_p <- coef_rob["pos_trat_pequenaTRUE", "Estimate"]
      se_p <- coef_rob["pos_trat_pequenaTRUE", "Std. Error"]
      p_p <- coef_rob["pos_trat_pequenaTRUE", "Pr(>|t|)"]

      # Diferença
      dif <- att_g - att_p
      se_dif <- sqrt(se_g^2 + se_p^2)
      p_dif <- 2 * pt(-abs(dif/se_dif), df = nrow(painel_var) - 2)

      cat("      Grandes: ", sprintf("%.5f", att_g), " (p=", sprintf("%.3f", p_g), ") | ",
          "Pequenas: ", sprintf("%.5f", att_p), " (p=", sprintf("%.3f", p_p), ")\n", sep="")

      resultados_tamanho <- rbind(resultados_tamanho, data.frame(
        Tipo = tipo,
        Variavel = nome,
        ATT_Grandes = att_g,
        SE_Grandes = se_g,
        p_Grandes = p_g,
        ATT_Pequenas = att_p,
        SE_Pequenas = se_p,
        p_Pequenas = p_p,
        Diferenca = dif,
        SE_Diferenca = se_dif,
        p_Diferenca = p_dif,
        stringsAsFactors = FALSE
      ))
    }
  }, error = function(e) {
    cat("      ✗ Erro\n")
  })
}

# ==============================================================================
# 5. APRESENTAR RESULTADOS
# ==============================================================================

cat("\n\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║              RESULTADOS - HETEROGENEIDADE COMPLETA            ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("═══════════════════════════════════════════════════════════════════\n")
cat("TABELA 1: IGs ESPECÍFICAS - MÚLTIPLAS VARIÁVEIS\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

if(nrow(resultados_completos) > 0) {
  # Tabela pivotada
  tabela_pivot <- resultados_completos %>%
    select(IG, Variavel, ATT, p_valor, Significativo) %>%
    mutate(
      Resultado = paste0(sprintf("%.4f", ATT), " ", Significativo)
    ) %>%
    select(-ATT, -p_valor, -Significativo) %>%
    pivot_wider(names_from = IG, values_from = Resultado)

  print(tabela_pivot, n = 50)

  cat("\n\n")

  # Resumo por tipo
  cat("RESUMO POR TIPO DE VARIÁVEL:\n\n")

  resumo <- resultados_completos %>%
    group_by(Tipo, IG) %>%
    summarise(
      N_sig = sum(p_valor < 0.10),
      N_total = n(),
      Pct_sig = (N_sig / N_total) * 100,
      .groups = "drop"
    )

  print(resumo)
}

cat("\n\n═══════════════════════════════════════════════════════════════════\n")
cat("TABELA 2: GRANDES vs PEQUENAS - MÚLTIPLAS VARIÁVEIS\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

if(nrow(resultados_tamanho) > 0) {
  print(resultados_tamanho %>%
          select(Variavel, ATT_Grandes, p_Grandes, ATT_Pequenas, p_Pequenas, Diferenca, p_Diferenca),
        row.names = FALSE)
}

# ==============================================================================
# 6. GRÁFICO - HEATMAP DE HETEROGENEIDADE
# ==============================================================================

cat("\n\n5. Gerando gráfico de heterogeneidade (heatmap)...\n")

if(nrow(resultados_completos) > 0) {

  # Criar dados para heatmap
  heatmap_data <- resultados_completos %>%
    mutate(
      Variavel_short = case_when(
        grepl("IFDM", Variavel) ~ "IFDM",
        grepl("PIB per capita", Variavel) ~ "PIB pc",
        grepl("VA Agro", Variavel) ~ "VA Agro",
        grepl("VA Ind", Variavel) ~ "VA Ind",
        grepl("VA Serv", Variavel) ~ "VA Serv",
        grepl("Part", Variavel) ~ "Part Agro",
        TRUE ~ Variavel
      ),
      IG_short = case_when(
        grepl("Planalto", IG) ~ "Planalto (BA)",
        grepl("Vale", IG) ~ "Vale do Café (RJ)",
        grepl("Noroeste", IG) ~ "Noroeste (RJ)",
        TRUE ~ IG
      ),
      Sig_marker = ifelse(p_valor < 0.05, "*", "")
    )

  p_heat <- ggplot(heatmap_data, aes(x = IG_short, y = Variavel_short, fill = ATT)) +
    geom_tile(color = "white", size = 0.5) +
    geom_text(aes(label = paste0(sprintf("%.3f", ATT), Sig_marker)),
              color = "white", size = 3.5, fontface = "bold") +
    scale_fill_gradient2(
      low = "red", mid = "gray90", high = "darkgreen",
      midpoint = 0,
      limits = c(-0.05, 0.05),
      name = "ATT"
    ) +
    labs(
      title = "Heterogeneidade: Efeitos das IGs por Variável",
      subtitle = "Vermelho = negativo | Verde = positivo | * = p<0.05",
      x = "",
      y = ""
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      plot.title = element_text(face = "bold", size = 14),
      panel.grid = element_blank()
    )

  ggsave("Resultados/Heterogeneidade_Heatmap.png", p_heat, width = 10, height = 6, dpi = 300)
  cat("  ✓ Heatmap salvo\n")
}

# ==============================================================================
# 7. SALVAR RESULTADOS
# ==============================================================================

cat("\n6. Salvando resultados...\n")

if(nrow(resultados_completos) > 0) {
  write.csv(resultados_completos,
            "Resultados/Heterogeneidade_IGs_MultiVariaveis.csv",
            row.names = FALSE)
  cat("  ✓ Heterogeneidade_IGs_MultiVariaveis.csv\n")
}

if(nrow(resultados_tamanho) > 0) {
  write.csv(resultados_tamanho,
            "Resultados/Heterogeneidade_Tamanho_MultiVariaveis.csv",
            row.names = FALSE)
  cat("  ✓ Heterogeneidade_Tamanho_MultiVariaveis.csv\n")
}

# Relatório
sink("Resultados/Relatorio_Heterogeneidade_Completa.txt")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("   ANÁLISE DE HETEROGENEIDADE - MÚLTIPLAS VARIÁVEIS\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")
cat("Data:", format(Sys.Date(), "%d/%m/%Y"), "\n\n")

cat("VARIÁVEIS TESTADAS:\n")
for(i in 1:length(outcomes)) {
  cat("  ", i, ". ", outcomes[[i]]$nome, "\n", sep="")
}
cat("\n")

cat("═══════════════════════════════════════════════════════════════════\n")
cat("RESULTADOS POR IG ESPECÍFICA\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

if(nrow(resultados_completos) > 0) {
  for(ig in unique(resultados_completos$IG)) {
    cat("\n", ig, ":\n", sep="")
    cat(strrep("-", nchar(ig) + 1), "\n", sep="")

    res_ig <- resultados_completos %>% filter(IG == ig)

    for(i in 1:nrow(res_ig)) {
      cat("  ", res_ig$Variavel[i], ": ATT = ", sprintf("%.4f", res_ig$ATT[i]),
          " (p = ", sprintf("%.3f", res_ig$p_valor[i]), ") ", res_ig$Significativo[i], "\n", sep="")
    }
  }
}

cat("\n\n═══════════════════════════════════════════════════════════════════\n")
cat("RESUMO DE SIGNIFICÂNCIA\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

if(nrow(resultados_completos) > 0) {
  resumo_sig <- resultados_completos %>%
    group_by(IG) %>%
    summarise(
      Total_vars = n(),
      Sig_5pct = sum(p_valor < 0.05),
      Sig_10pct = sum(p_valor < 0.10),
      .groups = "drop"
    )

  print(resumo_sig, row.names = FALSE)
}

cat("\n═══════════════════════════════════════════════════════════════════\n")
sink()

cat("\n✓ ANÁLISE DE HETEROGENEIDADE COMPLETA - CONCLUÍDA!\n\n")
