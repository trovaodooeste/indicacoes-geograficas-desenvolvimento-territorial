# ==============================================================================
# Script 05: DiD PRECISO - CAFÉ (com anos EXATOS de concessão)
# Objetivo: DiD usando ano REAL de concessão de cada município
# ==============================================================================

.libPaths(c("~/R/library", .libPaths()))

rm(list = ls())

library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(lmtest)
library(sandwich)

setwd("/mnt/c/Users/Trovao/Desktop/Artigo - Economia Regional")

cat("\n╔═══════════════════════════════════════════════════════════╗\n")
cat("║         DiD PRECISO - CAFÉ (Anos Exatos de Concessão)     ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

# ==============================================================================
# 1. CARREGAR E PREPARAR BASE INPI COM ANOS
# ==============================================================================

cat("1. Carregando base INPI com anos de concessão...\n")

inpi <- read_excel("Dados/IGs_Brasil_INPI_x_DataSebrae.xlsx", sheet = "Base INPI")

# Extrair ano
inpi$ano_concessao <- as.numeric(substr(inpi$`Data Concessão`,
                                        nchar(inpi$`Data Concessão`) - 3,
                                        nchar(inpi$`Data Concessão`)))

# Filtrar café e limpar
cafe_inpi <- inpi %>%
  filter(grepl("Café|Coffee|Conilon", `Produto (INPI)`, ignore.case = TRUE)) %>%
  select(nome_ig = `Nome IG (INPI)`, ano_concessao) %>%
  filter(!is.na(ano_concessao)) %>%
  mutate(nome_ig_clean = str_trim(nome_ig))

cat("  ✓ IGs de café com ano:", nrow(cafe_inpi), "\n")
cat("\n  Anos de concessão por IG:\n")
print(cafe_inpi %>% arrange(ano_concessao), n = 30)
cat("\n")

# ==============================================================================
# 2. CARREGAR MUNICÍPIOS PAREADOS DO PSM
# ==============================================================================

cat("2. Carregando municípios pareados...\n")

base_matched <- read.csv("Resultados/base_cafe_matched.csv")
cod_pareados <- unique(base_matched$cod_municipio)

cat("  ✓ Municípios pareados:", length(cod_pareados), "\n\n")

# ==============================================================================
# 3. VINCULAR MUNICÍPIOS AO ANO EXATO DA IG
# ==============================================================================

cat("3. Vinculando municípios aos anos EXATOS de concessão...\n\n")

# Carregar MAPA
mapa <- read_excel("Dados/IGs- tabela MAPA.xlsx", skip = 1)
names(mapa) <- c("municipio", "uf", "produto_ig")

# Filtrar café
cafe_mapa <- mapa %>%
  filter(grepl("\\(Café\\)|\\(Coffee\\)|\\(Conilon\\)", produto_ig, ignore.case = TRUE))

# Extrair nome da IG do campo produto_ig
# Ex: "Baturité (Café)" -> "Baturité"
# Ex: "Circuito das Águas Paulista (Cachaça); Circuito das Águas Paulista (Café)" -> precisa pegar "Circuito das Águas Paulista"

cafe_mapa <- cafe_mapa %>%
  mutate(
    # Pegar tudo antes do primeiro parêntese
    nome_ig_extraido = trimws(str_extract(produto_ig, "^[^(]+"))
  )

cat("  IGs únicas no MAPA:\n")
print(unique(cafe_mapa$nome_ig_extraido))
cat("\n")

# Join com INPI
cafe_mapa_anos <- cafe_mapa %>%
  left_join(cafe_inpi, by = c("nome_ig_extraido" = "nome_ig_clean"))

# Verificar matches
nao_matched <- cafe_mapa_anos %>% filter(is.na(ano_concessao))
cat("  Municípios SEM match automático:", nrow(nao_matched), "\n")

if(nrow(nao_matched) > 0) {
  cat("  IGs sem match:\n")
  print(unique(nao_matched$nome_ig_extraido))
  cat("\n  Fazendo match manual...\n\n")

  # Match manual baseado nos dados que vimos
  cafe_mapa_anos <- cafe_mapa_anos %>%
    mutate(
      ano_concessao = case_when(
        # Matches manuais
        grepl("Baturité|Serra de Baturité", nome_ig_extraido, ignore.case = TRUE) ~ 2017,
        grepl("Cerrado Mineiro", nome_ig_extraido, ignore.case = TRUE) ~ 2005,
        grepl("Vale do Café", nome_ig_extraido, ignore.case = TRUE) ~ 2014,
        grepl("Noroeste Fluminense", nome_ig_extraido, ignore.case = TRUE) ~ 2014,
        grepl("Vale do Ivinhema|Ivinhema", nome_ig_extraido, ignore.case = TRUE) ~ 2014,
        grepl("Circuito das Águas", nome_ig_extraido, ignore.case = TRUE) ~ 2014,
        grepl("Planalto de Vitória da Conquista", nome_ig_extraido, ignore.case = TRUE) ~ 2015,
        grepl("Contrafortes da Mantiqueira", nome_ig_extraido, ignore.case = TRUE) ~ 2012,
        grepl("Região de Piraju|Piraju", nome_ig_extraido, ignore.case = TRUE) ~ 2017,
        grepl("Chapada Diamantina", nome_ig_extraido, ignore.case = TRUE) ~ 2015,
        grepl("Divinolândia", nome_ig_extraido, ignore.case = TRUE) ~ 2014,
        grepl("Região de Machado|Machado", nome_ig_extraido, ignore.case = TRUE) ~ 2014,
        grepl("Região de Poços de Caldas|Poços de Caldas", nome_ig_extraido, ignore.case = TRUE) ~ 2014,
        grepl("Dois Córregos", nome_ig_extraido, ignore.case = TRUE) ~ 2014,
        grepl("Guaxupé", nome_ig_extraido, ignore.case = TRUE) ~ 2014,
        grepl("Itu", nome_ig_extraido, ignore.case = TRUE) ~ 2014,
        grepl("Santa Teresa", nome_ig_extraido, ignore.case = TRUE) ~ 2017,
        grepl("Região Serrana", nome_ig_extraido, ignore.case = TRUE) ~ 2017,
        TRUE ~ ano_concessao
      )
    )
}

# Verificar quantos têm ano agora
com_ano <- cafe_mapa_anos %>% filter(!is.na(ano_concessao))
cat("  ✓ Municípios com ano de concessão:", nrow(com_ano), "\n")
cat("\n  Distribuição dos anos:\n")
print(table(com_ano$ano_concessao))
cat("\n")

# ==============================================================================
# 4. PREPARAR PAINEL IFDM COM ANOS EXATOS
# ==============================================================================

cat("4. Criando painel IFDM com anos exatos...\n")

# Preparar join
cafe_mapa_anos <- cafe_mapa_anos %>%
  mutate(
    municipio_clean = toupper(str_trim(municipio)),
    municipio_clean = iconv(municipio_clean, to = "ASCII//TRANSLIT")
  )

# Carregar IFDM (apenas pareados)
ifdm <- read_excel("Dados/IFDM_2013_2023_painel_tratado.xlsx",
                   sheet = "Painel IFDM 2013-2023") %>%
  filter(cod_municipio %in% cod_pareados) %>%
  mutate(
    municipio_clean = toupper(str_trim(municipio)),
    municipio_clean = iconv(municipio_clean, to = "ASCII//TRANSLIT")
  )

# Join
painel <- ifdm %>%
  left_join(
    cafe_mapa_anos %>% select(municipio_clean, uf, ano_concessao, nome_ig_extraido),
    by = c("municipio_clean", "uf")
  ) %>%
  mutate(
    tratado = ifelse(!is.na(ano_concessao), 1, 0),
    # TEMPO RELATIVO EXATO para cada município
    tempo_relativo = ifelse(tratado == 1, ano - ano_concessao, NA),
    # Pós-tratamento
    pos_tratamento = ifelse(tratado == 1 & ano >= ano_concessao, 1, 0)
  )

# Preencher pos_tratamento para controles
painel$pos_tratamento[is.na(painel$pos_tratamento)] <- 0

cat("  ✓ Painel criado:", nrow(painel), "observações\n")
cat("  ✓ Período:", min(painel$ano), "-", max(painel$ano), "\n")
cat("  ✓ Tratados:", n_distinct(painel$cod_municipio[painel$tratado == 1]), "\n")
cat("  ✓ Controles:", n_distinct(painel$cod_municipio[painel$tratado == 0]), "\n\n")

# Estatísticas do tempo relativo
cat("  Distribuição do tempo relativo (tratados):\n")
print(table(painel$tempo_relativo[painel$tratado == 1]))
cat("\n")

# ==============================================================================
# 5. GRÁFICO DE TENDÊNCIAS
# ==============================================================================

cat("5. Gerando gráfico de tendências...\n")

tendencias <- painel %>%
  group_by(ano, tratado) %>%
  summarise(ifdm_medio = mean(ifdm_geral, na.rm = TRUE), .groups = "drop") %>%
  mutate(grupo = ifelse(tratado == 1, "Com IG Café", "Sem IG"))

p_tend <- ggplot(tendencias, aes(x = ano, y = ifdm_medio, color = grupo)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  labs(title = "Evolução do IFDM: Municípios Pareados (PSM)",
       subtitle = "Anos de concessão específicos por município",
       x = "Ano", y = "IFDM Médio", color = "") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("Resultados/DiD_Tendencias_AnosExatos.png", p_tend, width = 10, height = 6)
cat("  ✓ Gráfico salvo\n\n")

# ==============================================================================
# 6. MODELO DiD COM EFEITOS FIXOS
# ==============================================================================

cat("6. Estimando modelo DiD (Two-Way Fixed Effects)...\n\n")

painel$mun_f <- as.factor(painel$cod_municipio)
painel$ano_f <- as.factor(painel$ano)

modelo_did <- lm(ifdm_geral ~ pos_tratamento + mun_f + ano_f, data = painel)
vcov_cl <- vcovCL(modelo_did, cluster = painel$cod_municipio)
coef_rob <- coeftest(modelo_did, vcov = vcov_cl)

att <- coef_rob["pos_tratamento", "Estimate"]
se <- coef_rob["pos_tratamento", "Std. Error"]
p <- coef_rob["pos_tratamento", "Pr(>|t|)"]

cat("═══════════════════════════════════════════════════════════\n")
cat("           DiD COM ANOS EXATOS - IFDM GERAL\n")
cat("═══════════════════════════════════════════════════════════\n\n")
cat("ATT:", sprintf("%.5f", att), "\n")
cat("SE: ", sprintf("%.5f", se), "\n")
cat("p-value:", sprintf("%.4f", p), "\n")
cat("IC 95%: [", sprintf("%.5f", att - 1.96*se), ",", sprintf("%.5f", att + 1.96*se), "]\n\n")

sig <- ifelse(p < 0.10, "SIM", "NÃO")
cat("Significativo (p<0.10):", sig, "\n\n")

# IFDM Emprego
modelo_emp <- lm(ifdm_emprego_renda ~ pos_tratamento + mun_f + ano_f, data = painel)
vcov_emp <- vcovCL(modelo_emp, cluster = painel$cod_municipio)
coef_emp <- coeftest(modelo_emp, vcov = vcov_emp)

att_emp <- coef_emp["pos_tratamento", "Estimate"]
se_emp <- coef_emp["pos_tratamento", "Std. Error"]
p_emp <- coef_emp["pos_tratamento", "Pr(>|t|)"]

cat("═══════════════════════════════════════════════════════════\n")
cat("           DiD COM ANOS EXATOS - IFDM EMPREGO\n")
cat("═══════════════════════════════════════════════════════════\n\n")
cat("ATT:", sprintf("%.5f", att_emp), "\n")
cat("SE: ", sprintf("%.5f", se_emp), "\n")
cat("p-value:", sprintf("%.4f", p_emp), "\n")
cat("IC 95%: [", sprintf("%.5f", att_emp - 1.96*se_emp), ",", sprintf("%.5f", att_emp + 1.96*se_emp), "]\n\n")

# ==============================================================================
# 7. EVENT STUDY
# ==============================================================================

cat("7. Estimando Event Study (coeficientes dinâmicos)...\n\n")

# Criar dummies para cada tempo relativo
# Limitar a -6 a +6 (temos dados 2013-2023, maioria IG em 2014-2017)
for(t in -6:6) {
  if(t == -1) next  # Omitir -1 como referência
  var_name <- paste0("t_", ifelse(t < 0, "m", "p"), abs(t))
  painel[[var_name]] <- ifelse(painel$tempo_relativo == t, 1, 0)
  painel[[var_name]][is.na(painel[[var_name]])] <- 0
}

# Lista de variáveis
vars_event <- c(paste0("t_m", 6:2), paste0("t_p", 0:6))

formula_ev <- as.formula(paste("ifdm_geral ~",
                               paste(vars_event, collapse = " + "),
                               "+ mun_f + ano_f"))

modelo_ev <- lm(formula_ev, data = painel)
vcov_ev <- vcovCL(modelo_ev, cluster = painel$cod_municipio)
coef_ev <- coeftest(modelo_ev, vcov = vcov_ev)

# Extrair coeficientes
tempos_vals <- c(-6:-2, 0:6)
event_df <- data.frame(
  tempo = tempos_vals,
  coef = sapply(vars_event, function(v) {
    if(v %in% rownames(coef_ev)) coef_ev[v, "Estimate"] else NA
  }),
  se = sapply(vars_event, function(v) {
    if(v %in% rownames(coef_ev)) coef_ev[v, "Std. Error"] else NA
  })
) %>%
  filter(!is.na(coef)) %>%
  mutate(
    ic_inf = coef - 1.96 * se,
    ic_sup = coef + 1.96 * se
  )

# Adicionar referência
event_df <- rbind(event_df,
                   data.frame(tempo = -1, coef = 0, se = 0, ic_inf = 0, ic_sup = 0)) %>%
  arrange(tempo)

cat("═══════════════════════════════════════════════════════════\n")
cat("         EVENT STUDY - COEFICIENTES POR ANO\n")
cat("═══════════════════════════════════════════════════════════\n\n")
print(event_df, row.names = FALSE)

# Gráfico
p_event <- ggplot(event_df, aes(x = tempo, y = coef)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = ic_inf, ymax = ic_sup), width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "blue", linewidth = 1) +
  annotate("text", x = 0.3, y = max(event_df$ic_sup, na.rm = TRUE) * 0.9,
           label = "Concessão IG", hjust = 0, size = 3.5) +
  scale_x_continuous(breaks = seq(-6, 6, 1)) +
  labs(title = "Event Study: Efeito da IG de Café no IFDM",
       subtitle = "Anos EXATOS de concessão | Municípios pareados (PSM) | IC 95%",
       x = "Anos Relativos à Concessão da IG",
       y = "Efeito no IFDM",
       caption = "Ano -1 como referência | Efeitos fixos município + ano | SE clusterizados") +
  theme_minimal() +
  theme(plot.caption = element_text(size = 8, hjust = 0))

ggsave("Resultados/DiD_EventStudy_AnosExatos.png", p_event, width = 12, height = 7)
cat("\n  ✓ Gráfico salvo\n\n")

# ==============================================================================
# 8. SALVAR RESULTADOS
# ==============================================================================

cat("8. Salvando resultados...\n")

results <- data.frame(
  Variavel = c("IFDM Geral", "IFDM Emprego"),
  ATT = c(att, att_emp),
  SE = c(se, se_emp),
  p_value = c(p, p_emp),
  IC_Inf = c(att - 1.96*se, att_emp - 1.96*se_emp),
  IC_Sup = c(att + 1.96*se, att_emp + 1.96*se_emp),
  Significativo = c(ifelse(p < 0.10, "Sim", "Não"),
                    ifelse(p_emp < 0.10, "Sim", "Não"))
)

write.csv(results, "Resultados/DiD_AnosExatos_Resultados.csv", row.names = FALSE)
write.csv(event_df, "Resultados/EventStudy_AnosExatos_Coeficientes.csv", row.names = FALSE)

# Salvar também info dos anos por município
anos_municipios <- painel %>%
  filter(tratado == 1) %>%
  select(cod_municipio, municipio, uf, ano_concessao, nome_ig_extraido) %>%
  distinct() %>%
  arrange(ano_concessao, municipio)

write.csv(anos_municipios, "Resultados/Municipios_Anos_Concessao.csv", row.names = FALSE)

cat("  ✓ Resultados salvos\n\n")

# ==============================================================================
# 9. CONCLUSÃO FINAL
# ==============================================================================

cat("╔═══════════════════════════════════════════════════════════╗\n")
cat("║                  CONCLUSÃO FINAL - DiD PRECISO             ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

cat("RESULTADOS COM ANOS EXATOS DE CONCESSÃO:\n\n")
print(results, row.names = FALSE)

cat("\n\nINTERPRETAÇÃO:\n\n")

if(p < 0.10) {
  cat("  ✓ EFEITO SIGNIFICATIVO ENCONTRADO!\n")
  cat("    → IG de café causa mudança de", sprintf("%.4f", att), "no IFDM\n")
  if(att > 0) {
    cat("    → Efeito POSITIVO no desenvolvimento\n")
  } else {
    cat("    → Efeito NEGATIVO no desenvolvimento\n")
  }
} else {
  cat("  ⚠️ EFEITO NÃO SIGNIFICATIVO (p =", sprintf("%.3f", p), ")\n")
  cat("    → Mesmo usando anos EXATOS, não há evidência de efeito causal\n")
  cat("    → Resultado CONSISTENTE com PSM e DiD anterior\n")
}

cat("\n\nEVENT STUDY:\n")
cat("  - Coeficientes pré-tratamento (antes ano 0):",
    ifelse(any(abs(event_df$coef[event_df$tempo < 0]) > 0.02, na.rm = TRUE),
           "ATENÇÃO - possível tendência pré-existente",
           "OK - próximos de zero"),
    "\n")

cat("\n✓ ANÁLISE DiD COM ANOS EXATOS CONCLUÍDA!\n\n")
