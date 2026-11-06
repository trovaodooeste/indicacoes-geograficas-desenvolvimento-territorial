# ==============================================================================
# Script 03: Exploração dos Dados de PIB Municipal
# Objetivo: Analisar PIB Municipal 2002-2023 em painel
# Variável de crescimento econômico
# ==============================================================================

rm(list = ls())

library(readxl)
library(dplyr)
library(ggplot2)
library(tidyr)

setwd("C:/Users/Trovao/Desktop/Artigo - Economia Regional")

# ==============================================================================
# 1. CARREGAR DADOS PIB
# ==============================================================================

cat("\n=== CARREGANDO DADOS PIB MUNICIPAL ===\n")
cat("ATENÇÃO: Este arquivo é grande (15MB), pode demorar um pouco...\n\n")

pib <- read_excel("Dados/PIB_Municipal_2002_2023_painel_IG.xlsx")

cat("✓ Dados carregados!\n")
cat("Dimensões:", nrow(pib), "linhas x", ncol(pib), "colunas\n\n")
cat("Colunas:\n")
print(names(pib))

cat("\n\nPrimeiras linhas:\n")
print(head(pib, 10))

# ==============================================================================
# 2. ESTRUTURA DO PAINEL
# ==============================================================================

cat("\n\n=== ESTRUTURA DO PAINEL PIB ===\n")

# Anos disponíveis
if("Ano" %in% names(pib)) {
  cat("\nAnos disponíveis:\n")
  anos <- sort(unique(pib$Ano))
  print(anos)
  cat("Período:", min(anos), "-", max(anos), "\n")
}

# Número de municípios
municipio_col <- names(pib)[str_detect(tolower(names(pib)), "munic")]
if(length(municipio_col) > 0) {
  n_mun <- length(unique(pib[[municipio_col[1]]]))
  cat("Número de municípios:", n_mun, "\n")
}

# ==============================================================================
# 3. COMPONENTES DO PIB
# ==============================================================================

cat("\n\n=== COMPONENTES DO PIB MUNICIPAL ===\n")

# Procurar colunas de PIB
colunas_pib <- names(pib)[str_detect(tolower(names(pib)), "pib|va_")]

cat("Colunas relacionadas ao PIB encontradas:\n")
print(colunas_pib)

# PIB total, PIB per capita, VA Agropecuária, VA Indústria, VA Serviços
# Estatísticas descritivas

cat("\n\nEstatísticas descritivas das principais variáveis:\n")
for(col in colunas_pib[1:min(5, length(colunas_pib))]) {
  cat("\n", col, ":\n")
  print(summary(pib[[col]]))
}

# ==============================================================================
# 4. PIB AGROPECUÁRIO - VARIÁVEL CHAVE PARA MATCHING
# ==============================================================================

cat("\n\n=== PIB AGROPECUÁRIO (Variável chave para PSM) ===\n")

# Procurar VA Agropecuária
va_agro_col <- names(pib)[str_detect(tolower(names(pib)), "agro|agr")]

if(length(va_agro_col) > 0) {
  cat("\nColuna de VA Agropecuária:", va_agro_col[1], "\n\n")

  # Estatísticas
  cat("Estatísticas do VA Agropecuária:\n")
  print(summary(pib[[va_agro_col[1]]]))

  # Participação da agropecuária no PIB total
  # (calcular se tiver PIB total)
  pib_total_col <- names(pib)[str_detect(tolower(names(pib)), "pib_total|pib$")]

  if(length(pib_total_col) > 0 & length(va_agro_col) > 0) {
    pib$Part_Agro <- (pib[[va_agro_col[1]]] / pib[[pib_total_col[1]]]) * 100

    cat("\n\nParticipação média da Agropecuária no PIB:\n")
    part_por_ano <- pib %>%
      group_by(Ano) %>%
      summarise(
        Part_Agro_Media = mean(Part_Agro, na.rm = TRUE),
        Part_Agro_Mediana = median(Part_Agro, na.rm = TRUE)
      )
    print(part_por_ano)
  }
}

# ==============================================================================
# 5. EVOLUÇÃO DO PIB PER CAPITA
# ==============================================================================

cat("\n\n=== EVOLUÇÃO DO PIB PER CAPITA ===\n")

# Procurar PIB per capita
pib_pc_col <- names(pib)[str_detect(tolower(names(pib)), "per.*capita|percapita")]

if(length(pib_pc_col) > 0) {
  evolucao_pib <- pib %>%
    group_by(Ano) %>%
    summarise(
      PIB_PC_medio = mean(.data[[pib_pc_col[1]]], na.rm = TRUE),
      PIB_PC_mediano = median(.data[[pib_pc_col[1]]], na.rm = TRUE)
    )

  print(evolucao_pib)

  # Gráfico
  p <- ggplot(evolucao_pib, aes(x = Ano, y = PIB_PC_medio)) +
    geom_line(size = 1.2, color = "darkgreen") +
    geom_point(size = 3, color = "darkgreen") +
    labs(
      title = "Evolução do PIB per capita Médio - Municípios Brasileiros",
      x = "Ano",
      y = "PIB per capita Médio (R$)",
      caption = "Fonte: IBGE"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 13),
      axis.text = element_text(size = 11)
    ) +
    scale_y_continuous(labels = scales::comma)

  ggsave("Resultados/evolucao_PIB_percapita.png", p, width = 10, height = 6, dpi = 300)
  cat("\nGráfico salvo: Resultados/evolucao_PIB_percapita.png\n")
}

# ==============================================================================
# 6. VALORES AUSENTES
# ==============================================================================

cat("\n\n=== ANÁLISE DE VALORES AUSENTES ===\n")

missing_summary <- pib %>%
  summarise(across(everything(), ~sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "Variavel", values_to = "NA_count") %>%
  mutate(Percentual = round(NA_count / nrow(pib) * 100, 2)) %>%
  filter(NA_count > 0) %>%
  arrange(desc(NA_count))

if(nrow(missing_summary) > 0) {
  cat("Variáveis com valores ausentes:\n")
  print(missing_summary)
} else {
  cat("✓ Nenhum valor ausente encontrado!\n")
}

# ==============================================================================
# 7. SALVAR RESUMO
# ==============================================================================

sink("Resultados/resumo_PIB.txt")
cat("=== RESUMO DOS DADOS DE PIB MUNICIPAL ===\n\n")
cat("Período:", min(pib$Ano, na.rm = TRUE), "-", max(pib$Ano, na.rm = TRUE), "\n")
cat("Municípios:", n_mun, "\n")
cat("Observações:", nrow(pib), "\n\n")
cat("Colunas disponíveis:\n")
print(names(pib))
sink()

cat("\n\n✓ Exploração do PIB Municipal concluída!\n")
