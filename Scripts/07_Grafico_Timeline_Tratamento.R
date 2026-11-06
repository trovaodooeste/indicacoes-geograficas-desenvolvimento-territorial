# ==============================================================================
# Script 07: Gráfico Timeline de Tratamento
# Objetivo: Visualizar anos exatos de concessão das IGs de café
# ==============================================================================

.libPaths(c("~/R/library", .libPaths()))

rm(list = ls())

library(dplyr)
library(ggplot2)
library(tidyr)

setwd("/mnt/c/Users/Trovao/Desktop/Artigo - Economia Regional")

cat("\n=== GRÁFICO TIMELINE DE TRATAMENTO ===\n\n")

# ==============================================================================
# 1. CARREGAR DADOS
# ==============================================================================

anos_ig <- read.csv("Resultados/Municipios_Anos_Concessao.csv")

cat("Municípios com IG:", nrow(anos_ig), "\n")
cat("Anos de concessão:", paste(sort(unique(anos_ig$ano_concessao)), collapse=", "), "\n\n")

# ==============================================================================
# 2. PREPARAR DADOS PARA VISUALIZAÇÃO
# ==============================================================================

# Contar municípios por ano e IG
timeline <- anos_ig %>%
  group_by(ano_concessao, nome_ig_extraido) %>%
  summarise(n_municipios = n(), .groups = "drop") %>%
  arrange(ano_concessao, desc(n_municipios))

# Total por ano
total_por_ano <- anos_ig %>%
  count(ano_concessao, name = "total") %>%
  mutate(percentual = round(total / sum(total) * 100, 1))

cat("Distribuição por ano:\n")
print(total_por_ano)
cat("\n")

# ==============================================================================
# 3. GRÁFICO 1: TIMELINE COM BARRAS EMPILHADAS POR IG
# ==============================================================================

cat("Criando gráfico 1: Timeline por IG...\n")

# Selecionar top IGs (mais de 3 municípios)
igs_principais <- timeline %>%
  filter(n_municipios >= 3) %>%
  pull(nome_ig_extraido)

timeline_plot <- timeline %>%
  mutate(
    ig_grupo = ifelse(nome_ig_extraido %in% igs_principais,
                      nome_ig_extraido,
                      "Outras IGs")
  )

p1 <- ggplot(timeline_plot, aes(x = factor(ano_concessao), y = n_municipios, fill = ig_grupo)) +
  geom_col(color = "white", linewidth = 0.3) +
  geom_text(data = total_por_ano,
            aes(x = factor(ano_concessao), y = total, label = paste0(total, " municípios\n(", percentual, "%)")),
            inherit.aes = FALSE, vjust = -0.5, size = 3.5, fontface = "bold") +
  scale_fill_brewer(palette = "Set3", name = "Indicação Geográfica") +
  labs(
    title = "Distribuição Temporal das Concessões de IGs de Café",
    subtitle = "Anos exatos de concessão por Indicação Geográfica (2012-2017)",
    x = "Ano de Concessão",
    y = "Número de Municípios",
    caption = "Fonte: INPI/MAPA. Total: 82 municípios com IG de café."
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5),
    axis.title = element_text(size = 11),
    legend.position = "bottom",
    legend.title = element_text(face = "bold"),
    panel.grid.major.x = element_blank(),
    plot.caption = element_text(size = 8, hjust = 0)
  ) +
  guides(fill = guide_legend(nrow = 3)) +
  ylim(0, max(total_por_ano$total) * 1.15)

ggsave("Resultados/Timeline_Tratamento_IGs.png", p1, width = 10, height = 7, dpi = 300)
cat("  ✓ Timeline_Tratamento_IGs.png\n")

# ==============================================================================
# 4. GRÁFICO 2: PAINEL DE TRATAMENTO (Municípios x Anos)
# ==============================================================================

cat("Criando gráfico 2: Painel de tratamento...\n")

# Criar painel completo 2013-2023
anos_painel <- 2013:2023

painel_tratamento <- anos_ig %>%
  select(cod_municipio, municipio, ano_concessao) %>%
  expand_grid(ano = anos_painel) %>%
  mutate(
    status = case_when(
      ano < ano_concessao ~ "Pré-tratamento",
      ano >= ano_concessao ~ "Pós-tratamento",
      TRUE ~ "Controle"
    )
  ) %>%
  group_by(ano, status) %>%
  summarise(n_municipios = n(), .groups = "drop")

# Adicionar controles (municípios sem IG)
base_matched <- read.csv("Resultados/base_cafe_matched.csv")
n_controles <- sum(base_matched$IG_Cafe == 0)

controles_painel <- data.frame(
  ano = anos_painel,
  status = "Controles (sem IG)",
  n_municipios = n_controles
)

painel_completo <- bind_rows(painel_tratamento, controles_painel)

# Ordenar status
painel_completo$status <- factor(painel_completo$status,
                                 levels = c("Controles (sem IG)", "Pré-tratamento", "Pós-tratamento"))

p2 <- ggplot(painel_completo, aes(x = ano, y = n_municipios, fill = status)) +
  geom_area(alpha = 0.7, position = "stack") +
  geom_vline(xintercept = c(2012, 2014, 2015, 2017),
             linetype = "dashed", color = "red", alpha = 0.5) +
  annotate("text", x = 2012, y = 320, label = "2012", size = 3, color = "red", angle = 90, vjust = -0.5) +
  annotate("text", x = 2014, y = 320, label = "2014", size = 3, color = "red", angle = 90, vjust = -0.5) +
  annotate("text", x = 2015, y = 320, label = "2015", size = 3, color = "red", angle = 90, vjust = -0.5) +
  annotate("text", x = 2017, y = 320, label = "2017", size = 3, color = "red", angle = 90, vjust = -0.5) +
  scale_fill_manual(
    values = c("Controles (sem IG)" = "#E0E0E0",
               "Pré-tratamento" = "#FFF59D",
               "Pós-tratamento" = "#81C784"),
    name = "Status do Tratamento"
  ) +
  scale_x_continuous(breaks = 2013:2023) +
  labs(
    title = "Evolução do Status de Tratamento (2013-2023)",
    subtitle = "Municípios transitam de pré para pós-tratamento conforme ano de concessão da IG",
    x = "Ano",
    y = "Número de Municípios",
    caption = "Linhas vermelhas indicam anos de concessão de IGs. Total: 320 municípios pareados (82 tratados + 238 controles)."
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5),
    axis.title = element_text(size = 11),
    legend.position = "bottom",
    legend.title = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(size = 8, hjust = 0)
  )

ggsave("Resultados/Painel_Status_Tratamento.png", p2, width = 11, height = 7, dpi = 300)
cat("  ✓ Painel_Status_Tratamento.png\n")

# ==============================================================================
# 5. GRÁFICO 3: DISTRIBUIÇÃO GEOGRÁFICA POR ANO
# ==============================================================================

cat("Criando gráfico 3: Distribuição geográfica...\n")

geo_dist <- anos_ig %>%
  count(ano_concessao, uf) %>%
  group_by(ano_concessao) %>%
  mutate(
    percentual = round(n / sum(n) * 100, 1),
    label = paste0(uf, " (", n, ")")
  )

p3 <- ggplot(geo_dist, aes(x = factor(ano_concessao), y = n, fill = uf)) +
  geom_col(position = "dodge", color = "white", linewidth = 0.3) +
  geom_text(aes(label = n), position = position_dodge(width = 0.9),
            vjust = -0.5, size = 3) +
  scale_fill_brewer(palette = "Spectral", name = "Estado") +
  labs(
    title = "Distribuição Geográfica das IGs de Café por Ano",
    subtitle = "Número de municípios por estado e ano de concessão",
    x = "Ano de Concessão",
    y = "Número de Municípios",
    caption = "Estados: BA (Bahia), CE (Ceará), ES (Espírito Santo), MG (Minas Gerais), MS (Mato Grosso do Sul), PR (Paraná), RJ (Rio de Janeiro), SP (São Paulo)."
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5),
    axis.title = element_text(size = 11),
    legend.position = "bottom",
    legend.title = element_text(face = "bold"),
    panel.grid.major.x = element_blank(),
    plot.caption = element_text(size = 8, hjust = 0)
  )

ggsave("Resultados/Distribuicao_Geografica_IGs.png", p3, width = 10, height = 7, dpi = 300)
cat("  ✓ Distribuicao_Geografica_IGs.png\n")

# ==============================================================================
# 6. TABELA RESUMO
# ==============================================================================

cat("\nCriando tabela resumo...\n")

# IGs por ano com detalhes
resumo_igs <- anos_ig %>%
  group_by(ano_concessao, nome_ig_extraido) %>%
  summarise(
    n_mun = n(),
    estados = paste(unique(uf), collapse = ", "),
    .groups = "drop"
  ) %>%
  arrange(ano_concessao, desc(n_mun))

write.csv(resumo_igs, "Resultados/Resumo_IGs_por_Ano.csv", row.names = FALSE)
cat("  ✓ Resumo_IGs_por_Ano.csv\n")

# ==============================================================================
# 7. RELATÓRIO
# ==============================================================================

sink("Resultados/Relatorio_Timeline_Tratamento.txt")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("           RELATÓRIO - TIMELINE DE TRATAMENTO (IGs CAFÉ)          \n")
cat("═══════════════════════════════════════════════════════════════════\n\n")
cat("Data:", format(Sys.Date(), "%d/%m/%Y"), "\n\n")

cat("RESUMO GERAL:\n")
cat("  Total de municípios com IG café:", nrow(anos_ig), "\n")
cat("  Total de municípios controle:", n_controles, "\n")
cat("  Total de municípios pareados:", nrow(anos_ig) + n_controles, "\n")
cat("  Período de análise: 2013-2023\n")
cat("  Anos de concessão: 2012, 2014, 2015, 2017\n\n")

cat("DISTRIBUIÇÃO POR ANO:\n\n")
print(total_por_ano)

cat("\n\nIGs PRINCIPAIS (≥3 municípios):\n\n")
print(resumo_igs %>% filter(n_mun >= 3))

cat("\n\nESTADOS REPRESENTADOS:\n\n")
estados_resumo <- anos_ig %>%
  count(uf, sort = TRUE)
print(estados_resumo)

cat("\n\n═══════════════════════════════════════════════════════════════════\n")
cat("IMPLICAÇÕES METODOLÓGICAS:\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")
cat("1. TRATAMENTO ESCALONADO (Staggered Adoption):\n")
cat("   - Municípios recebem tratamento em momentos diferentes\n")
cat("   - 4 coortes de tratamento: 2012, 2014, 2015, 2017\n")
cat("   - Maior coorte: 2014 (56.1% dos tratados)\n\n")

cat("2. ESPECIFICAÇÃO DiD:\n")
cat("   - Variável: pos_tratamento_it = 1[ano_t >= ano_concessao_i]\n")
cat("   - Comparação: municípios ANTES vs DEPOIS da própria IG\n")
cat("   - Controles: municípios nunca tratados (238 municípios)\n\n")

cat("3. VANTAGENS:\n")
cat("   - Usa variação temporal completa (2013-2023)\n")
cat("   - Captura heterogeneidade por tempo de exposição\n")
cat("   - Mais poder estatístico que tratamento único\n\n")

cat("4. ATENÇÃO:\n")
cat("   - Efeitos podem variar por coorte\n")
cat("   - ATT captura efeito MÉDIO entre coortes\n")
cat("   - Possível heterogeneidade dinâmica\n\n")

cat("═══════════════════════════════════════════════════════════════════\n")
sink()

cat("\n✓ GRÁFICOS E RELATÓRIO CRIADOS!\n\n")
cat("Arquivos gerados:\n")
cat("  1. Timeline_Tratamento_IGs.png - Distribuição por ano e IG\n")
cat("  2. Painel_Status_Tratamento.png - Evolução tratamento 2013-2023\n")
cat("  3. Distribuicao_Geografica_IGs.png - Distribuição por estado\n")
cat("  4. Resumo_IGs_por_Ano.csv - Tabela detalhada\n")
cat("  5. Relatorio_Timeline_Tratamento.txt - Relatório completo\n\n")
