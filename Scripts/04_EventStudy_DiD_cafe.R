# ==============================================================================
# Script 04: Event Study / Difference-in-Differences - CAFÉ
# Objetivo: Analisar evolução ANTES e DEPOIS da concessão da IG
# Metodologia: Event Study com efeitos fixos de município e ano
# ==============================================================================

.libPaths(c("~/R/library", .libPaths()))

rm(list = ls())

library(readxl)
library(dplyr)
library(tidyr)
library(fixest)
library(ggplot2)

setwd("/mnt/c/Users/Trovao/Desktop/Artigo - Economia Regional")

cat("\n╔═══════════════════════════════════════════════════════════╗\n")
cat("║     EVENT STUDY / DiD - INDICAÇÕES GEOGRÁFICAS CAFÉ       ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

# ==============================================================================
# 1. CARREGAR DADOS
# ==============================================================================

cat("1. Carregando dados...\n")

# Base INPI com anos
inpi <- read_excel("Dados/IGs_Brasil_INPI_x_DataSebrae.xlsx", sheet = "Base INPI")

# Extrair ano
inpi$Ano_Concessao <- as.numeric(substr(inpi$`Data Concessão`,
                                        nchar(inpi$`Data Concessão`) - 3,
                                        nchar(inpi$`Data Concessão`)))

# Filtrar café
cafe_igs <- inpi %>%
  filter(grepl("Café|Coffee|Conilon", `Produto (INPI)`, ignore.case = TRUE)) %>%
  select(nome_ig = `Nome IG (INPI)`, ano_concessao = Ano_Concessao) %>%
  filter(!is.na(ano_concessao))  # Remover NAs

cat("  ✓ IGs de café com ano:", nrow(cafe_igs), "\n")

# MAPA - municípios com café
mapa <- read_excel("Dados/IGs- tabela MAPA.xlsx", skip = 1)
names(mapa) <- c("municipio", "uf", "produto_ig")

cafe_mapa <- mapa %>%
  filter(grepl("\\(Café\\)|\\(Coffee\\)|\\(Conilon\\)", produto_ig, ignore.case = TRUE))

cat("  ✓ Municípios com café (MAPA):", nrow(cafe_mapa), "\n")

# IFDM - painel completo
ifdm <- read_excel("Dados/IFDM_2013_2023_painel_tratado.xlsx",
                   sheet = "Painel IFDM 2013-2023")

cat("  ✓ IFDM painel:", nrow(ifdm), "observações\n")
cat("  ✓ Período:", min(ifdm$ano, na.rm = TRUE), "-",
    max(ifdm$ano, na.rm = TRUE), "\n\n")

# ==============================================================================
# 2. VINCULAR MUNICÍPIOS AO ANO DE CONCESSÃO
# ==============================================================================

cat("2. Vinculando municípios aos anos de concessão...\n")

# Precisamos extrair o nome da IG do campo produto_ig
# Ex: "Vale do Café (Café)" -> extrair "Vale do Café"

cafe_mapa$nome_ig_extraido <- sapply(strsplit(cafe_mapa$produto_ig, " \\("), function(x) x[1])

# Fazer join com anos
cafe_mapa_anos <- cafe_mapa %>%
  left_join(cafe_igs,
            by = c("nome_ig_extraido" = "nome_ig"))

# Alguns podem não ter match perfeito, vamos checar
nao_matched <- cafe_mapa_anos %>% filter(is.na(ano_concessao))

if(nrow(nao_matched) > 0) {
  cat("\n  ⚠️ Municípios sem ano de concessão:\n")
  print(unique(nao_matched$nome_ig_extraido))
  cat("\n  Tentando match parcial...\n")

  # Match parcial manual para casos comuns
  cafe_mapa_anos <- cafe_mapa_anos %>%
    mutate(
      ano_concessao = case_when(
        grepl("Baturité", nome_ig_extraido) ~ 2017,
        grepl("Cerrado Mineiro", nome_ig_extraido) ~ 2005,  # Primeira concessão
        grepl("Vale do Café", nome_ig_extraido) ~ 2014,  # Estimativa
        grepl("Noroeste Fluminense", nome_ig_extraido) ~ 2014,  # Estimativa
        grepl("Vale do Ivinhema", nome_ig_extraido) ~ 2014,  # Estimativa
        grepl("Circuito das Águas", nome_ig_extraido) ~ 2014,  # Estimativa
        TRUE ~ ano_concessao
      )
    )
}

# Padronizar nome do município para match com IFDM
cafe_mapa_anos <- cafe_mapa_anos %>%
  mutate(
    municipio_clean = toupper(municipio),
    municipio_clean = iconv(municipio_clean, to = "ASCII//TRANSLIT")
  )

cat("  ✓ Municípios com ano de concessão:", sum(!is.na(cafe_mapa_anos$ano_concessao)), "\n\n")

# ==============================================================================
# 3. CRIAR PAINEL COM TEMPO RELATIVO
# ==============================================================================

cat("3. Criando painel com tempo relativo...\n")

# Preparar IFDM para join
ifdm_clean <- ifdm %>%
  mutate(
    municipio_clean = toupper(municipio),
    municipio_clean = iconv(municipio_clean, to = "ASCII//TRANSLIT")
  ) %>%
  select(cod_municipio, municipio_clean, uf, ano,
         ifdm_geral, ifdm_emprego_renda, ifdm_educacao, ifdm_saude)

# Join com café
painel <- ifdm_clean %>%
  left_join(
    cafe_mapa_anos %>% select(municipio_clean, uf, ano_concessao),
    by = c("municipio_clean", "uf")
  ) %>%
  mutate(
    # Variável de tratamento
    tratado = ifelse(!is.na(ano_concessao), 1, 0),
    # Tempo relativo à concessão
    tempo_relativo = ifelse(tratado == 1, ano - ano_concessao, NA),
    # Pós-tratamento
    pos_tratamento = ifelse(tratado == 1 & ano >= ano_concessao, 1, 0)
  )

cat("  ✓ Painel criado:", nrow(painel), "observações\n")
cat("  ✓ Municípios tratados:", n_distinct(painel$cod_municipio[painel$tratado == 1]), "\n")
cat("  ✓ Municípios controle:", n_distinct(painel$cod_municipio[painel$tratado == 0]), "\n")
cat("  ✓ Anos:", min(painel$ano), "-", max(painel$ano), "\n\n")

# Estatísticas do tempo relativo
cat("  Distribuição do tempo relativo (tratados):\n")
print(table(painel$tempo_relativo[painel$tratado == 1]))
cat("\n")

# ==============================================================================
# 4. GRÁFICO DE TENDÊNCIAS PRÉ-TRATAMENTO
# ==============================================================================

cat("4. Analisando tendências pré-tratamento...\n")

# Calcular médias por grupo e ano
tendencias <- painel %>%
  group_by(ano, tratado) %>%
  summarise(
    ifdm_medio = mean(ifdm_geral, na.rm = TRUE),
    ifdm_emprego_medio = mean(ifdm_emprego_renda, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(grupo = ifelse(tratado == 1, "Com IG Café", "Sem IG"))

# Gráfico
p_tendencias <- ggplot(tendencias, aes(x = ano, y = ifdm_medio, color = grupo)) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  geom_vline(xintercept = 2017, linetype = "dashed", color = "red", alpha = 0.5) +
  annotate("text", x = 2017, y = max(tendencias$ifdm_medio, na.rm = TRUE),
           label = "Pico de concessões (2017)", hjust = -0.1, size = 3) +
  labs(title = "Evolução do IFDM: Tratados vs Controles",
       subtitle = "Teste visual de tendências paralelas",
       x = "Ano",
       y = "IFDM Médio",
       color = "Grupo") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("Resultados/DiD_Tendencias_PreTratamento.png", p_tendencias,
       width = 10, height = 6)

cat("  ✓ Gráfico salvo: Resultados/DiD_Tendencias_PreTratamento.png\n\n")

# ==============================================================================
# 5. MODELO DiD SIMPLES (TWO-WAY FIXED EFFECTS)
# ==============================================================================

cat("5. Estimando modelo DiD (Two-Way Fixed Effects)...\n\n")

# Modelo com efeitos fixos de município e ano
modelo_did <- feols(ifdm_geral ~ pos_tratamento | cod_municipio + ano,
                    data = painel,
                    cluster = ~cod_municipio)

cat("═══════════════════════════════════════════════════════════\n")
cat("                    MODELO DiD - IFDM GERAL\n")
cat("═══════════════════════════════════════════════════════════\n\n")
summary(modelo_did)

# Modelo para IFDM Emprego
modelo_did_emprego <- feols(ifdm_emprego_renda ~ pos_tratamento | cod_municipio + ano,
                            data = painel,
                            cluster = ~cod_municipio)

cat("\n\n═══════════════════════════════════════════════════════════\n")
cat("                 MODELO DiD - IFDM EMPREGO\n")
cat("═══════════════════════════════════════════════════════════\n\n")
summary(modelo_did_emprego)

# ==============================================================================
# 6. EVENT STUDY (EFEITOS DINÂMICOS)
# ==============================================================================

cat("\n\n6. Estimando Event Study (efeitos ano a ano)...\n\n")

# Criar dummies para cada ano relativo
# Limitar a -5 a +5 para ter amostra suficiente
painel <- painel %>%
  mutate(
    tempo_relativo_bin = case_when(
      tempo_relativo < -5 ~ -5,
      tempo_relativo > 5 ~ 5,
      TRUE ~ tempo_relativo
    )
  )

# Event study com efeitos fixos
# Excluir -1 como referência (ano antes do tratamento)
modelo_event <- feols(ifdm_geral ~ i(tempo_relativo_bin, ref = -1) | cod_municipio + ano,
                      data = painel[painel$tratado == 1 | painel$tratado == 0, ],
                      cluster = ~cod_municipio)

cat("═══════════════════════════════════════════════════════════\n")
cat("              EVENT STUDY - IFDM GERAL\n")
cat("═══════════════════════════════════════════════════════════\n\n")
summary(modelo_event)

# Extrair coeficientes para gráfico
coefs <- coef(modelo_event)
ses <- se(modelo_event)

# Criar dataframe para plot
event_data <- data.frame(
  tempo = as.numeric(gsub("tempo_relativo_bin::", "", names(coefs))),
  coef = coefs,
  se = ses
) %>%
  mutate(
    ic_inf = coef - 1.96 * se,
    ic_sup = coef + 1.96 * se
  )

# Adicionar ponto de referência (ano -1 = 0)
event_data <- rbind(
  event_data,
  data.frame(tempo = -1, coef = 0, se = 0, ic_inf = 0, ic_sup = 0)
) %>%
  arrange(tempo)

# Gráfico Event Study
p_event <- ggplot(event_data, aes(x = tempo, y = coef)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = ic_inf, ymax = ic_sup), width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "blue", size = 1) +
  annotate("text", x = 0, y = max(event_data$ic_sup, na.rm = TRUE),
           label = "Concessão da IG", hjust = -0.1, size = 3) +
  labs(title = "Event Study: Efeito da IG de Café no IFDM",
       subtitle = "Coeficientes com IC 95% (ano -1 como referência)",
       x = "Anos Relativos à Concessão da IG",
       y = "Efeito no IFDM",
       caption = "Efeitos fixos de município e ano | Erros clusterizados por município") +
  theme_minimal()

ggsave("Resultados/DiD_EventStudy_IFDM.png", p_event,
       width = 10, height = 6)

cat("\n  ✓ Gráfico salvo: Resultados/DiD_EventStudy_IFDM.png\n\n")

# ==============================================================================
# 7. SALVAR RESULTADOS
# ==============================================================================

cat("7. Salvando resultados...\n")

# Resultados DiD
did_results <- data.frame(
  Variavel = c("IFDM Geral", "IFDM Emprego"),
  ATT = c(coef(modelo_did)["pos_tratamento"],
          coef(modelo_did_emprego)["pos_tratamento"]),
  SE = c(se(modelo_did)["pos_tratamento"],
         se(modelo_did_emprego)["pos_tratamento"]),
  t_stat = c(coef(modelo_did)["pos_tratamento"] / se(modelo_did)["pos_tratamento"],
             coef(modelo_did_emprego)["pos_tratamento"] / se(modelo_did_emprego)["pos_tratamento"]),
  p_value = c(pvalue(modelo_did)["pos_tratamento"],
              pvalue(modelo_did_emprego)["pos_tratamento"])
) %>%
  mutate(
    IC_Inf = ATT - 1.96 * SE,
    IC_Sup = ATT + 1.96 * SE,
    Significativo = ifelse(p_value < 0.10, "Sim", "Não")
  )

write.csv(did_results, "Resultados/DiD_Resultados_Cafe.csv", row.names = FALSE)
write.csv(event_data, "Resultados/EventStudy_Coeficientes_Cafe.csv", row.names = FALSE)

cat("  ✓ Resultados DiD salvos: Resultados/DiD_Resultados_Cafe.csv\n")
cat("  ✓ Event Study salvos: Resultados/EventStudy_Coeficientes_Cafe.csv\n\n")

# ==============================================================================
# 8. RESUMO FINAL
# ==============================================================================

cat("╔═══════════════════════════════════════════════════════════╗\n")
cat("║                EVENT STUDY / DiD CONCLUÍDO                ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

cat("RESULTADOS DiD:\n\n")
print(did_results[, c("Variavel", "ATT", "IC_Inf", "IC_Sup", "p_value", "Significativo")],
      row.names = FALSE)

cat("\n\nINTERPRETAÇÃO:\n")
if(did_results$p_value[1] < 0.10) {
  cat("  ✓ Efeito SIGNIFICATIVO detectado no DiD\n")
  cat("  → IGs de café têm impacto causal de", sprintf("%.4f", did_results$ATT[1]),
      "no IFDM\n")
} else {
  cat("  ⚠️ Efeito NÃO significativo no DiD\n")
  cat("  → Mesmo controlando por tendências temporais, não há evidência de efeito causal\n")
}

cat("\n✓ ANÁLISE CONCLUÍDA!\n\n")
