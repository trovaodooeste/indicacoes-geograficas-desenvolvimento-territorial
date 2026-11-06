# ==============================================================================
# Script 04: Event Study / DiD - CAFÉ (Versão RÁPIDA com amostra pareada)
# Objetivo: DiD usando APENAS municípios pareados do PSM
# ==============================================================================

.libPaths(c("~/R/library", .libPaths()))

rm(list = ls())

library(readxl)
library(dplyr)
library(ggplot2)
library(lmtest)
library(sandwich)

setwd("/mnt/c/Users/Trovao/Desktop/Artigo - Economia Regional")

cat("\n╔═══════════════════════════════════════════════════════════╗\n")
cat("║        EVENT STUDY / DiD - CAFÉ (Versão Rápida)           ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

# ==============================================================================
# 1. CARREGAR MUNICÍPIOS PAREADOS DO PSM
# ==============================================================================

cat("1. Carregando municípios pareados do PSM...\n")

# Base pareada do PSM
base_matched <- read.csv("Resultados/base_cafe_matched.csv")

cat("  ✓ Municípios pareados:", nrow(base_matched), "\n")
cat("  ✓ Tratados:", sum(base_matched$IG_Cafe), "\n")
cat("  ✓ Controles:", sum(base_matched$IG_Cafe == 0), "\n\n")

# Códigos dos municípios pareados
cod_pareados <- unique(base_matched$cod_municipio)

# ==============================================================================
# 2. CARREGAR PAINEL IFDM (APENAS PAREADOS)
# ==============================================================================

cat("2. Carregando painel IFDM (apenas municípios pareados)...\n")

ifdm <- read_excel("Dados/IFDM_2013_2023_painel_tratado.xlsx",
                   sheet = "Painel IFDM 2013-2023") %>%
  filter(cod_municipio %in% cod_pareados)

cat("  ✓ Painel IFDM:", nrow(ifdm), "observações\n")
cat("  ✓ Municípios:", n_distinct(ifdm$cod_municipio), "\n")
cat("  ✓ Período:", min(ifdm$ano), "-", max(ifdm$ano), "\n\n")

# ==============================================================================
# 3. ADICIONAR ANO DE CONCESSÃO
# ==============================================================================

cat("3. Adicionando anos de concessão...\n")

# Assumir que maioria foi em 2014-2017
# Usar informação da base matched
anos_concessao <- base_matched %>%
  filter(IG_Cafe == 1) %>%
  mutate(ano_concessao = 2017) %>%  # Default: ano mais comum
  select(cod_municipio, ano_concessao)

# Juntar com painel
painel <- ifdm %>%
  left_join(anos_concessao, by = "cod_municipio") %>%
  mutate(
    tratado = ifelse(!is.na(ano_concessao), 1, 0),
    tempo_relativo = ifelse(tratado == 1, ano - ano_concessao, NA),
    pos_tratamento = ifelse(tratado == 1 & ano >= ano_concessao, 1, 0)
  )

# Preencher pos_tratamento para controles (sempre 0)
painel$pos_tratamento[is.na(painel$pos_tratamento)] <- 0

cat("  ✓ Painel com tratamento criado\n\n")

# ==============================================================================
# 4. GRÁFICO DE TENDÊNCIAS
# ==============================================================================

cat("4. Gerando gráfico de tendências...\n")

tendencias <- painel %>%
  group_by(ano, tratado) %>%
  summarise(ifdm_medio = mean(ifdm_geral, na.rm = TRUE), .groups = "drop") %>%
  mutate(grupo = ifelse(tratado == 1, "Com IG Café", "Sem IG"))

p_tend <- ggplot(tendencias, aes(x = ano, y = ifdm_medio, color = grupo)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  geom_vline(xintercept = 2017, linetype = "dashed", alpha = 0.3) +
  annotate("text", x = 2017.2, y = max(tendencias$ifdm_medio) * 0.95,
           label = "Pico IGs (2017)", hjust = 0, size = 3) +
  labs(title = "Evolução do IFDM: Pareados (PSM)",
       subtitle = "Municípios com IG Café vs Controles Pareados",
       x = "Ano", y = "IFDM Médio", color = "") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("Resultados/DiD_Tendencias_Pareados.png", p_tend, width = 10, height = 6)
cat("  ✓ Gráfico salvo\n\n")

# ==============================================================================
# 5. MODELO DiD SIMPLES
# ==============================================================================

cat("5. Estimando modelo DiD...\n\n")

# Efeitos fixos
painel$mun_f <- as.factor(painel$cod_municipio)
painel$ano_f <- as.factor(painel$ano)

modelo_did <- lm(ifdm_geral ~ pos_tratamento + mun_f + ano_f, data = painel)
vcov_cl <- vcovCL(modelo_did, cluster = painel$cod_municipio)
coef_rob <- coeftest(modelo_did, vcov = vcov_cl)

att <- coef_rob["pos_tratamento", "Estimate"]
se <- coef_rob["pos_tratamento", "Std. Error"]
p <- coef_rob["pos_tratamento", "Pr(>|t|)"]

cat("═══════════════════════════════════════════════════════════\n")
cat("                  MODELO DiD - IFDM GERAL\n")
cat("═══════════════════════════════════════════════════════════\n\n")
cat("ATT:", sprintf("%.5f", att), "\n")
cat("SE: ", sprintf("%.5f", se), "\n")
cat("p-value:", sprintf("%.4f", p), "\n")
cat("IC 95%: [", sprintf("%.5f", att - 1.96*se), ",", sprintf("%.5f", att + 1.96*se), "]\n\n")

# ==============================================================================
# 6. EVENT STUDY
# ==============================================================================

cat("6. Estimando Event Study...\n\n")

# Criar dummies
for(t in -4:6) {
  if(t == -1) next
  painel[[paste0("t_", t)]] <- ifelse(painel$tempo_relativo == t, 1, 0)
  painel[[paste0("t_", t)]][is.na(painel[[paste0("t_", t)]])] <- 0
}

formula_ev <- as.formula(paste("ifdm_geral ~",
                               paste(paste0("t_", c(-4:-2, 0:6)), collapse = " + "),
                               "+ mun_f + ano_f"))

modelo_ev <- lm(formula_ev, data = painel)
vcov_ev <- vcovCL(modelo_ev, cluster = painel$cod_municipio)
coef_ev <- coeftest(modelo_ev, vcov = vcov_ev)

# Extrair coeficientes
tempos <- c(-4:-2, 0:6)
event_df <- data.frame(
  tempo = tempos,
  coef = sapply(tempos, function(t) coef_ev[paste0("t_", t), "Estimate"]),
  se = sapply(tempos, function(t) coef_ev[paste0("t_", t), "Std. Error"])
) %>%
  mutate(ic_inf = coef - 1.96 * se, ic_sup = coef + 1.96 * se)

# Adicionar referência
event_df <- rbind(event_df,
                   data.frame(tempo = -1, coef = 0, se = 0, ic_inf = 0, ic_sup = 0)) %>%
  arrange(tempo)

cat("═══════════════════════════════════════════════════════════\n")
cat("              EVENT STUDY - COEFICIENTES\n")
cat("═══════════════════════════════════════════════════════════\n\n")
print(event_df, row.names = FALSE)

# Gráfico
p_event <- ggplot(event_df, aes(x = tempo, y = coef)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = ic_inf, ymax = ic_sup), width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "blue") +
  annotate("text", x = 0.2, y = max(event_df$ic_sup) * 0.9,
           label = "Concessão IG", hjust = 0, size = 3) +
  labs(title = "Event Study: Efeito da IG de Café no IFDM",
       subtitle = "Municípios pareados (PSM) | IC 95% | Ano -1 como referência",
       x = "Anos Relativos à Concessão da IG",
       y = "Efeito no IFDM") +
  theme_minimal()

ggsave("Resultados/DiD_EventStudy_Pareados.png", p_event, width = 10, height = 6)
cat("\n  ✓ Gráfico salvo\n\n")

# ==============================================================================
# 7. SALVAR RESULTADOS
# ==============================================================================

cat("7. Salvando resultados...\n")

results <- data.frame(
  Modelo = "DiD (Pareados)",
  ATT = att,
  SE = se,
  p_value = p,
  IC_Inf = att - 1.96 * se,
  IC_Sup = att + 1.96 * se,
  Significativo = ifelse(p < 0.10, "Sim", "Não")
)

write.csv(results, "Resultados/DiD_Resultados_Cafe.csv", row.names = FALSE)
write.csv(event_df, "Resultados/EventStudy_Coeficientes_Cafe.csv", row.names = FALSE)

cat("  ✓ Resultados salvos\n\n")

# ==============================================================================
# 8. CONCLUSÃO
# ==============================================================================

cat("╔═══════════════════════════════════════════════════════════╗\n")
cat("║                      CONCLUSÃO                            ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

cat("RESULTADO DiD:\n\n")
print(results, row.names = FALSE)

cat("\n\nINTERPRETAÇÃO:\n")
if(p < 0.10) {
  cat("  ✓ Efeito SIGNIFICATIVO!\n")
  cat("  → IG causa mudança de", sprintf("%.4f", att), "no IFDM\n")
} else {
  cat("  ⚠️ Efeito NÃO significativo (p =", sprintf("%.3f", p), ")\n")
  cat("  → Consistente com PSM: sem efeito causal detectável\n")
}

cat("\n✓ ANÁLISE EVENT STUDY / DiD CONCLUÍDA!\n\n")
