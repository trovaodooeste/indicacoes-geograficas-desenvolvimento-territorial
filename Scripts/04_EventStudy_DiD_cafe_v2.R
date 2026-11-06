# ==============================================================================
# Script 04: Event Study / Difference-in-Differences - CAFÉ (Versão Simplificada)
# Objetivo: Analisar evolução ANTES e DEPOIS da concessão da IG
# Metodologia: DiD com lm() e efeitos fixos
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
  filter(!is.na(ano_concessao))

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

# Extrair nome da IG
cafe_mapa$nome_ig_extraido <- sapply(strsplit(cafe_mapa$produto_ig, " \\("), function(x) x[1])

# Match parcial para casos comuns (já que sabemos os anos)
cafe_mapa_anos <- cafe_mapa %>%
  mutate(
    ano_concessao = case_when(
      grepl("Baturité|Serra de Baturité", nome_ig_extraido) ~ 2017,
      grepl("Cerrado Mineiro", nome_ig_extraido) ~ 2005,
      grepl("Vale do Café", nome_ig_extraido) ~ 2014,
      grepl("Noroeste Fluminense", nome_ig_extraido) ~ 2014,
      grepl("Vale do Ivinhema", nome_ig_extraido) ~ 2014,
      grepl("Circuito das Águas", nome_ig_extraido) ~ 2014,
      grepl("Planalto de Vitória da Conquista", nome_ig_extraido) ~ 2015,
      grepl("Contrafortes da Mantiqueira", nome_ig_extraido) ~ 2014,
      grepl("Região de Piraju", nome_ig_extraido) ~ 2014,
      grepl("Chapada Diamantina", nome_ig_extraido) ~ 2015,
      grepl("Divinolândia", nome_ig_extraido) ~ 2014,
      grepl("Região de Machado", nome_ig_extraido) ~ 2014,
      grepl("Região de Poços de Caldas", nome_ig_extraido) ~ 2014,
      grepl("Dois Córregos", nome_ig_extraido) ~ 2014,
      grepl("Guaxupé", nome_ig_extraido) ~ 2014,
      grepl("Itu", nome_ig_extraido) ~ 2014,
      grepl("Santa Teresa", nome_ig_extraido) ~ 2017,
      TRUE ~ 2017  # Default: maioria foi em 2017
    ),
    municipio_clean = toupper(municipio),
    municipio_clean = iconv(municipio_clean, to = "ASCII//TRANSLIT")
  )

cat("  ✓ Municípios com ano de concessão:", nrow(cafe_mapa_anos), "\n\n")

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
    tratado = ifelse(!is.na(ano_concessao), 1, 0),
    tempo_relativo = ifelse(tratado == 1, ano - ano_concessao, NA),
    pos_tratamento = ifelse(tratado == 1 & ano >= ano_concessao, 1, 0)
  )

cat("  ✓ Painel criado:", nrow(painel), "observações\n")
cat("  ✓ Municípios tratados:", n_distinct(painel$cod_municipio[painel$tratado == 1]), "\n")
cat("  ✓ Municípios controle:", n_distinct(painel$cod_municipio[painel$tratado == 0]), "\n\n")

# ==============================================================================
# 4. TENDÊNCIAS PRÉ-TRATAMENTO
# ==============================================================================

cat("4. Analisando tendências pré-tratamento...\n")

tendencias <- painel %>%
  group_by(ano, tratado) %>%
  summarise(
    ifdm_medio = mean(ifdm_geral, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(grupo = ifelse(tratado == 1, "Com IG Café", "Sem IG"))

p_tend <- ggplot(tendencias, aes(x = ano, y = ifdm_medio, color = grupo)) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  geom_vline(xintercept = 2017, linetype = "dashed", alpha = 0.3) +
  labs(title = "Evolução do IFDM: Tratados vs Controles (2013-2023)",
       x = "Ano", y = "IFDM Médio", color = "Grupo") +
  theme_minimal()

ggsave("Resultados/DiD_Tendencias.png", p_tend, width = 10, height = 6)
cat("  ✓ Gráfico salvo\n\n")

# ==============================================================================
# 5. MODELO DiD SIMPLES
# ==============================================================================

cat("5. Estimando modelo DiD...\n\n")

# Criar dummies de município e ano
painel$mun_factor <- as.factor(painel$cod_municipio)
painel$ano_factor <- as.factor(painel$ano)

# Modelo DiD
modelo_did <- lm(ifdm_geral ~ pos_tratamento + mun_factor + ano_factor,
                 data = painel)

# Erros robustos clusterizados
vcov_cluster <- vcovCL(modelo_did, cluster = painel$cod_municipio)
coef_robust <- coeftest(modelo_did, vcov = vcov_cluster)

cat("═══════════════════════════════════════════════════════════\n")
cat("                 MODELO DiD - IFDM GERAL\n")
cat("═══════════════════════════════════════════════════════════\n\n")
cat("Coeficiente pós-tratamento:\n")
print(coef_robust["pos_tratamento", ])

att_did <- coef_robust["pos_tratamento", "Estimate"]
se_did <- coef_robust["pos_tratamento", "Std. Error"]
p_did <- coef_robust["pos_tratamento", "Pr(>|t|)"]

cat("\n\nATT DiD:", sprintf("%.5f", att_did), "\n")
cat("Erro Padrão:", sprintf("%.5f", se_did), "\n")
cat("p-value:", sprintf("%.4f", p_did), "\n")
cat("IC 95%: [", sprintf("%.5f", att_did - 1.96*se_did), ",",
    sprintf("%.5f", att_did + 1.96*se_did), "]\n")

# ==============================================================================
# 6. EVENT STUDY
# ==============================================================================

cat("\n\n6. Estimando Event Study...\n\n")

# Criar dummies para cada tempo relativo (-5 a +5)
for(t in -5:5) {
  if(t == -1) next  # Omitir -1 como referência
  painel[[paste0("tempo_", t)]] <- ifelse(painel$tempo_relativo == t, 1, 0)
  painel[[paste0("tempo_", t)]][is.na(painel[[paste0("tempo_", t)]])] <- 0
}

# Modelo event study
formula_event <- as.formula(paste("ifdm_geral ~",
                                  paste(paste0("tempo_", c(-5:-2, 0:5)), collapse = " + "),
                                  "+ mun_factor + ano_factor"))

modelo_event <- lm(formula_event, data = painel)
vcov_event <- vcovCL(modelo_event, cluster = painel$cod_municipio)
coef_event <- coeftest(modelo_event, vcov = vcov_event)

# Extrair coeficientes
tempos <- c(-5:-2, 0:5)
event_coefs <- sapply(tempos, function(t) {
  var_name <- paste0("tempo_", t)
  c(coef_event[var_name, "Estimate"], coef_event[var_name, "Std. Error"])
})

event_data <- data.frame(
  tempo = tempos,
  coef = event_coefs[1, ],
  se = event_coefs[2, ]
) %>%
  mutate(
    ic_inf = coef - 1.96 * se,
    ic_sup = coef + 1.96 * se
  )

# Adicionar referência
event_data <- rbind(
  event_data,
  data.frame(tempo = -1, coef = 0, se = 0, ic_inf = 0, ic_sup = 0)
) %>%
  arrange(tempo)

cat("═══════════════════════════════════════════════════════════\n")
cat("              EVENT STUDY - COEFICIENTES\n")
cat("═══════════════════════════════════════════════════════════\n\n")
print(event_data, row.names = FALSE)

# Gráfico
p_event <- ggplot(event_data, aes(x = tempo, y = coef)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = ic_inf, ymax = ic_sup), width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "blue") +
  labs(title = "Event Study: Efeito da IG de Café no IFDM",
       subtitle = "IC 95% | Ano -1 como referência | Efeitos fixos município + ano",
       x = "Anos Relativos à Concessão da IG",
       y = "Efeito no IFDM") +
  theme_minimal()

ggsave("Resultados/DiD_EventStudy.png", p_event, width = 10, height = 6)
cat("\n  ✓ Gráfico salvo\n\n")

# ==============================================================================
# 7. SALVAR RESULTADOS
# ==============================================================================

cat("7. Salvando resultados...\n")

did_results <- data.frame(
  Modelo = "DiD Two-Way FE",
  ATT = att_did,
  SE = se_did,
  p_value = p_did,
  IC_Inf = att_did - 1.96 * se_did,
  IC_Sup = att_did + 1.96 * se_did,
  Significativo = ifelse(p_did < 0.10, "Sim", "Não")
)

write.csv(did_results, "Resultados/DiD_Resultados_Cafe.csv", row.names = FALSE)
write.csv(event_data, "Resultados/EventStudy_Coeficientes_Cafe.csv", row.names = FALSE)

cat("  ✓ Resultados salvos\n\n")

# ==============================================================================
# 8. CONCLUSÃO
# ==============================================================================

cat("╔═══════════════════════════════════════════════════════════╗\n")
cat("║                    CONCLUSÃO DiD                          ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

cat("RESULTADO DiD:\n")
print(did_results, row.names = FALSE)

cat("\n\nINTERPRETAÇÃO:\n")
if(p_did < 0.10) {
  cat("  ✓ Efeito SIGNIFICATIVO (p <", sprintf("%.3f", p_did), ")\n")
  cat("  → IG de café causa mudança de", sprintf("%.4f", att_did), "no IFDM\n")
  if(att_did > 0) {
    cat("  → Efeito POSITIVO no desenvolvimento\n")
  } else {
    cat("  → Efeito NEGATIVO no desenvolvimento\n")
  }
} else {
  cat("  ⚠️ Efeito NÃO significativo (p =", sprintf("%.3f", p_did), ")\n")
  cat("  → Mesmo com DiD, não há evidência de efeito causal\n")
  cat("  → Consistente com resultado do PSM!\n")
}

cat("\n✓ ANÁLISE CONCLUÍDA!\n\n")
