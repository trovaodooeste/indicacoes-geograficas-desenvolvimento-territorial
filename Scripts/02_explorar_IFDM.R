# ==============================================================================
# Script 02: Exploração dos Dados de IFDM
# Objetivo: Analisar Índice Firjan de Desenvolvimento Municipal (2013-2023)
# Variável de resultado principal do estudo
# ==============================================================================

rm(list = ls())

library(readxl)
library(dplyr)
library(ggplot2)
library(tidyr)

setwd("C:/Users/Trovao/Desktop/Artigo - Economia Regional")

# ==============================================================================
# 1. CARREGAR DADOS IFDM
# ==============================================================================

cat("\n=== CARREGANDO DADOS IFDM ===\n")

# Dados já tratados em painel
ifdm <- read_excel("Dados/IFDM_2013_2023_painel_tratado.xlsx")

cat("Dimensões:", nrow(ifdm), "linhas x", ncol(ifdm), "colunas\n\n")
cat("Colunas:\n")
print(names(ifdm))

cat("\n\nPrimeiras linhas:\n")
print(head(ifdm, 10))

# ==============================================================================
# 2. ESTRUTURA DOS DADOS
# ==============================================================================

cat("\n\n=== ESTRUTURA DO PAINEL IFDM ===\n")

# Verificar anos disponíveis
if("Ano" %in% names(ifdm)) {
  cat("\nAnos disponíveis:\n")
  print(table(ifdm$Ano))
}

# Número de municípios
if("Município" %in% names(ifdm) | "MUNICIPIO" %in% names(ifdm)) {
  municipio_col <- ifelse("Município" %in% names(ifdm), "Município", "MUNICIPIO")
  n_mun <- length(unique(ifdm[[municipio_col]]))
  cat("\nNúmero de municípios:", n_mun, "\n")
}

# ==============================================================================
# 3. COMPONENTES DO IFDM
# ==============================================================================

cat("\n\n=== COMPONENTES DO IFDM ===\n")
cat("IFDM possui 3 dimensões:\n")
cat("1. Emprego & Renda\n")
cat("2. Educação\n")
cat("3. Saúde\n\n")

# Estatísticas descritivas dos índices
indices <- c("IFDM", "IFDM_Emprego", "IFDM_Educacao", "IFDM_Saude")

# Ajustar nomes conforme arquivo real
cat("Estatísticas descritivas:\n")
for(idx in indices) {
  if(idx %in% names(ifdm)) {
    cat("\n", idx, ":\n")
    print(summary(ifdm[[idx]]))
  }
}

# ==============================================================================
# 4. EVOLUÇÃO TEMPORAL DO IFDM
# ==============================================================================

cat("\n\n=== EVOLUÇÃO DO IFDM NO BRASIL ===\n")

# IFDM médio por ano
if("Ano" %in% names(ifdm) & "IFDM" %in% names(ifdm)) {
  evolucao <- ifdm %>%
    group_by(Ano) %>%
    summarise(
      IFDM_medio = mean(IFDM, na.rm = TRUE),
      IFDM_mediano = median(IFDM, na.rm = TRUE),
      IFDM_min = min(IFDM, na.rm = TRUE),
      IFDM_max = max(IFDM, na.rm = TRUE)
    )

  print(evolucao)

  # Gráfico de evolução
  p <- ggplot(evolucao, aes(x = Ano, y = IFDM_medio)) +
    geom_line(size = 1.2, color = "blue") +
    geom_point(size = 3, color = "blue") +
    labs(
      title = "Evolução do IFDM Médio no Brasil (2013-2023)",
      x = "Ano",
      y = "IFDM Médio",
      caption = "Fonte: FIRJAN"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
      axis.text = element_text(size = 11)
    )

  ggsave("Resultados/evolucao_IFDM.png", p, width = 10, height = 6, dpi = 300)
  cat("\nGráfico salvo: Resultados/evolucao_IFDM.png\n")
}

# ==============================================================================
# 5. CLASSIFICAÇÃO DO IFDM
# ==============================================================================

cat("\n\n=== CLASSIFICAÇÃO DO DESENVOLVIMENTO ===\n")
cat("Baixo desenvolvimento: 0.0 - 0.4\n")
cat("Desenvolvimento regular: 0.4 - 0.6\n")
cat("Desenvolvimento moderado: 0.6 - 0.8\n")
cat("Alto desenvolvimento: 0.8 - 1.0\n\n")

# Classificar municípios (ano mais recente)
if("IFDM" %in% names(ifdm) & "Ano" %in% names(ifdm)) {
  ifdm_recente <- ifdm %>%
    filter(Ano == max(Ano, na.rm = TRUE)) %>%
    mutate(
      Classificacao = case_when(
        IFDM < 0.4 ~ "Baixo",
        IFDM < 0.6 ~ "Regular",
        IFDM < 0.8 ~ "Moderado",
        IFDM <= 1.0 ~ "Alto",
        TRUE ~ NA_character_
      )
    )

  cat("Distribuição em", max(ifdm$Ano, na.rm = TRUE), ":\n")
  print(table(ifdm_recente$Classificacao))
}

# ==============================================================================
# 6. VALORES AUSENTES
# ==============================================================================

cat("\n\n=== ANÁLISE DE VALORES AUSENTES ===\n")

missing_summary <- ifdm %>%
  summarise(across(everything(), ~sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "Variavel", values_to = "NA_count") %>%
  mutate(Percentual = round(NA_count / nrow(ifdm) * 100, 2)) %>%
  arrange(desc(NA_count))

print(missing_summary)

# ==============================================================================
# 7. SALVAR ESTATÍSTICAS
# ==============================================================================

# Salvar resumo
sink("Resultados/resumo_IFDM.txt")
cat("=== RESUMO DOS DADOS DE IFDM ===\n\n")
cat("Período:", min(ifdm$Ano, na.rm = TRUE), "-", max(ifdm$Ano, na.rm = TRUE), "\n")
cat("Municípios:", length(unique(ifdm[[municipio_col]])), "\n")
cat("Observações:", nrow(ifdm), "\n\n")
cat("Estatísticas do IFDM:\n")
print(summary(ifdm$IFDM))
sink()

cat("\n\n✓ Exploração do IFDM concluída!\n")
