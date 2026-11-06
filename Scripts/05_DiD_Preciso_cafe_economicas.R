# ==============================================================================
# Script 05b: DiD PRECISO - CAFÉ (VARIÁVEIS ECONÔMICAS)
# Objetivo: DiD usando ano REAL de concessão + Variáveis Econômicas
# Expansão: Adiciona PIB, VA Setorial como outcomes
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

cat("\n╔═════════════════════════════════════════════════════════════════╗\n")
cat("║    DiD PRECISO - CAFÉ (Variáveis Econômicas + Anos Exatos)     ║\n")
cat("╚═════════════════════════════════════════════════════════════════╝\n\n")

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

cat("  ✓ IGs de café com ano:", nrow(cafe_inpi), "\n\n")

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
  filter(grepl("\\(Café\\)|\\(Coffee\\)|\\(Conilon\\)", produto_ig, ignore.case = TRUE)) %>%
  mutate(nome_ig_extraido = trimws(str_extract(produto_ig, "^[^(]+")))

# Join com INPI
cafe_mapa_anos <- cafe_mapa %>%
  left_join(cafe_inpi, by = c("nome_ig_extraido" = "nome_ig_clean"))

# Match manual para IGs que não deram match
cafe_mapa_anos <- cafe_mapa_anos %>%
  mutate(ano_concessao = case_when(
    grepl("Baturité", nome_ig_extraido) ~ 2017,
    grepl("Caparaó", nome_ig_extraido) ~ 2021,
    grepl("Santa Teresa", nome_ig_extraido) ~ 2021,
    grepl("Região de Machado", nome_ig_extraido) ~ 2014,
    grepl("Circuito", nome_ig_extraido) ~ 2020,
    grepl("Norte Pioneiro", nome_ig_extraido) ~ 2012,
    grepl("Noroeste Fluminense", nome_ig_extraido) ~ 2014,
    grepl("Planalto de Vitória", nome_ig_extraido) ~ 2015,
    grepl("Vale do Café", nome_ig_extraido) ~ 2014,
    grepl("Vale do Ivinhema", nome_ig_extraido) ~ 2015,
    grepl("Chapada Diamantina", nome_ig_extraido) ~ 2015,
    TRUE ~ ano_concessao
  ))

cafe_mapa_anos <- cafe_mapa_anos %>%
  mutate(
    municipio_clean = toupper(str_trim(municipio)),
    municipio_clean = iconv(municipio_clean, to = "ASCII//TRANSLIT")
  )

cat("  ✓ Municípios com ano de concessão:", sum(!is.na(cafe_mapa_anos$ano_concessao)), "\n\n")

# ==============================================================================
# 4. PREPARAR PAINEL IFDM + PIB
# ==============================================================================

cat("4. Criando painel IFDM + PIB com anos exatos...\n")

# ========================
# 4.1 IFDM
# ========================
ifdm <- read_excel("Dados/IFDM_2013_2023_painel_tratado.xlsx",
                   sheet = "Painel IFDM 2013-2023") %>%
  filter(cod_municipio %in% cod_pareados) %>%
  mutate(
    municipio_clean = toupper(str_trim(municipio)),
    municipio_clean = iconv(municipio_clean, to = "ASCII//TRANSLIT")
  )

cat("  ✓ IFDM carregado:", nrow(ifdm), "obs\n")

# ========================
# 4.2 PIB
# ========================
pib <- read_excel("Dados/PIB_Municipal_2002_2023_painel_IG.xlsx",
                  sheet = "Painel 2002-2023") %>%
  # Padronizar código: remover dígito verificador (7 dígitos → 6 dígitos)
  mutate(cod_municipio = floor(cod_municipio / 10)) %>%
  filter(cod_municipio %in% cod_pareados) %>%
  rename(
    pib_total = pib_r1000,
    va_agropecuaria = vab_agropecuaria_r1000,
    va_industria = vab_industria_r1000,
    va_servicos = vab_servicos_r1000
  ) %>%
  mutate(
    # Calcular participação agropecuária
    part_agro = (va_agropecuaria / pib_total) * 100,
    # Log para lidar com outliers
    log_pib_pc = log(pib_percapita + 1),
    log_va_agro = log(va_agropecuaria + 1),
    log_va_ind = log(va_industria + 1),
    log_va_serv = log(va_servicos + 1)
  ) %>%
  select(cod_municipio, ano, pib_total, pib_percapita,
         va_agropecuaria, va_industria, va_servicos, part_agro,
         log_pib_pc, log_va_agro, log_va_ind, log_va_serv)

cat("  ✓ PIB carregado:", nrow(pib), "obs\n")

# ========================
# 4.3 JUNTAR IFDM + PIB
# ========================
painel_completo <- ifdm %>%
  left_join(pib, by = c("cod_municipio", "ano")) %>%
  # Join com anos de concessão
  left_join(
    cafe_mapa_anos %>% select(municipio_clean, uf, ano_concessao),
    by = c("municipio_clean", "uf")
  )

# Criar variável tratado/controle
painel_completo <- painel_completo %>%
  mutate(
    tratado = !is.na(ano_concessao),
    tempo_relativo = ifelse(tratado, ano - ano_concessao, NA),
    pos_tratamento = tratado & (ano >= ano_concessao)
  )

cat("  ✓ Painel completo criado:", nrow(painel_completo), "obs\n")
cat("  ✓ Tratados:", sum(painel_completo$tratado[!duplicated(painel_completo$cod_municipio)]), "\n")
cat("  ✓ Controles:", sum(!painel_completo$tratado[!duplicated(painel_completo$cod_municipio)]), "\n\n")

# ==============================================================================
# 5. DiD - MÚLTIPLOS OUTCOMES
# ==============================================================================

cat("5. Estimando DiD para MÚLTIPLOS outcomes...\n\n")

# Preparar fatores
painel_completo$mun_f <- as.factor(painel_completo$cod_municipio)
painel_completo$ano_f <- as.factor(painel_completo$ano)

# LISTA DE OUTCOMES
outcomes <- list(
  # IFDM
  list(var = "ifdm_geral", nome = "IFDM Geral"),
  list(var = "ifdm_emprego_renda", nome = "IFDM Emprego"),
  list(var = "ifdm_educacao", nome = "IFDM Educação"),
  list(var = "ifdm_saude", nome = "IFDM Saúde"),

  # ECONÔMICAS - NÍVEIS
  list(var = "pib_percapita", nome = "PIB per capita (R$)"),
  list(var = "va_agropecuaria", nome = "VA Agropecuária (R$ mil)"),
  list(var = "va_industria", nome = "VA Indústria (R$ mil)"),
  list(var = "va_servicos", nome = "VA Serviços (R$ mil)"),
  list(var = "part_agro", nome = "Part. Agropecuária (%)"),

  # ECONÔMICAS - LOG (mais robusto)
  list(var = "log_pib_pc", nome = "log(PIB per capita)"),
  list(var = "log_va_agro", nome = "log(VA Agropecuária)"),
  list(var = "log_va_ind", nome = "log(VA Indústria)"),
  list(var = "log_va_serv", nome = "log(VA Serviços)")
)

# Estimar DiD para cada outcome
resultados_did <- data.frame()

for(i in 1:length(outcomes)) {
  outcome <- outcomes[[i]]
  var <- outcome$var
  nome <- outcome$nome

  cat("  Estimando:", nome, "\n")

  # Verificar se variável existe e tem dados
  if(!(var %in% names(painel_completo))) {
    cat("    ⚠ Variável não encontrada, pulando...\n")
    next
  }

  # Remover NAs
  painel_var <- painel_completo %>%
    filter(!is.na(.data[[var]]))

  if(nrow(painel_var) < 100) {
    cat("    ⚠ Poucos dados disponíveis, pulando...\n")
    next
  }

  # Estimar modelo
  formula_did <- as.formula(paste(var, "~ pos_tratamento + mun_f + ano_f"))

  tryCatch({
    modelo <- lm(formula_did, data = painel_var)
    vcov_cl <- vcovCL(modelo, cluster = painel_var$cod_municipio)
    coef_rob <- coeftest(modelo, vcov = vcov_cl)

    # Extrair resultados
    att <- coef_rob["pos_tratamento", "Estimate"]
    se <- coef_rob["pos_tratamento", "Std. Error"]
    t_stat <- coef_rob["pos_tratamento", "t value"]
    p_val <- coef_rob["pos_tratamento", "Pr(>|t|)"]

    # Guardar
    resultados_did <- rbind(resultados_did, data.frame(
      Variavel = nome,
      ATT = att,
      SE = se,
      t_stat = t_stat,
      p_value = p_val,
      N_obs = nrow(painel_var),
      stringsAsFactors = FALSE
    ))

    cat("    ✓ ATT =", sprintf("%.5f", att),
        "| p =", sprintf("%.3f", p_val), "\n")

  }, error = function(e) {
    cat("    ✗ Erro na estimação:", e$message, "\n")
  })
}

# Adicionar significância e ICs
resultados_did$Significancia <- case_when(
  resultados_did$p_value < 0.01 ~ "***",
  resultados_did$p_value < 0.05 ~ "**",
  resultados_did$p_value < 0.10 ~ "*",
  TRUE ~ ""
)

resultados_did$IC_Inferior <- resultados_did$ATT - 1.96 * resultados_did$SE
resultados_did$IC_Superior <- resultados_did$ATT + 1.96 * resultados_did$SE

# ==============================================================================
# 6. APRESENTAR RESULTADOS
# ==============================================================================

cat("\n\n╔═════════════════════════════════════════════════════════════════╗\n")
cat("║              DiD - RESULTADOS COMPLETOS (Anos Exatos)          ║\n")
cat("╚═════════════════════════════════════════════════════════════════╝\n\n")

cat("═══════════════════════════════════════════════════════════════════\n")
cat("A. INDICADORES DE DESENVOLVIMENTO (IFDM)\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

ifdm_results <- resultados_did %>%
  filter(grepl("IFDM", Variavel))

print(ifdm_results[, c("Variavel", "ATT", "SE", "IC_Inferior", "IC_Superior",
                       "p_value", "Significancia")], row.names = FALSE)

cat("\n\n═══════════════════════════════════════════════════════════════════\n")
cat("B. INDICADORES ECONÔMICOS - NÍVEIS\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

econ_niveis <- resultados_did %>%
  filter(grepl("PIB|VA|Part\\.", Variavel) & !grepl("log", Variavel))

if(nrow(econ_niveis) > 0) {
  print(econ_niveis[, c("Variavel", "ATT", "SE", "IC_Inferior", "IC_Superior",
                        "p_value", "Significancia")], row.names = FALSE)
}

cat("\n\n═══════════════════════════════════════════════════════════════════\n")
cat("C. INDICADORES ECONÔMICOS - LOG (Variação %)\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

econ_log <- resultados_did %>%
  filter(grepl("log", Variavel))

if(nrow(econ_log) > 0) {
  econ_log$Var_Percentual <- (exp(econ_log$ATT) - 1) * 100

  print(econ_log[, c("Variavel", "ATT", "Var_Percentual", "SE",
                     "p_value", "Significancia")], row.names = FALSE)

  cat("\nNota: Var_Percentual = variação % aproximada (exp(coef) - 1)\n")
}

cat("\n\nSignificância: *** p<0.01, ** p<0.05, * p<0.10\n")

# ==============================================================================
# 7. EVENT STUDY - PIB PER CAPITA
# ==============================================================================

cat("\n\n6. Estimando Event Study para PIB per capita...\n")

# Criar dummies de tempo relativo
painel_event <- painel_completo %>%
  filter(tratado, !is.na(tempo_relativo), !is.na(log_pib_pc)) %>%
  filter(tempo_relativo >= -6 & tempo_relativo <= 6)

# Criar dummies (ano -1 como referência)
for(t in c(-6:-2, 0:6)) {
  var_name <- paste0("rel_", ifelse(t < 0, "m", "p"), abs(t))
  painel_event[[var_name]] <- as.numeric(painel_event$tempo_relativo == t)
}

# Adicionar controles
painel_event <- painel_event %>%
  bind_rows(
    painel_completo %>% filter(!tratado, !is.na(log_pib_pc))
  )

painel_event$mun_f <- as.factor(painel_event$cod_municipio)
painel_event$ano_f <- as.factor(painel_event$ano)

# Estimar
vars_event <- c(paste0("rel_m", 6:2), paste0("rel_p", 0:6))
formula_ev <- as.formula(paste("log_pib_pc ~",
                               paste(vars_event, collapse = " + "),
                               "+ mun_f + ano_f"))

modelo_ev <- lm(formula_ev, data = painel_event)
vcov_ev <- vcovCL(modelo_ev, cluster = painel_event$cod_municipio)
coef_ev <- coeftest(modelo_ev, vcov = vcov_ev)

# Extrair coeficientes
event_df <- data.frame(
  tempo = c(-6:-2, 0:6),
  coef = NA,
  se = NA,
  ic_inf = NA,
  ic_sup = NA
)

for(i in 1:nrow(event_df)) {
  t <- event_df$tempo[i]
  var <- paste0("rel_", ifelse(t < 0, "m", "p"), abs(t))

  if(var %in% rownames(coef_ev)) {
    event_df$coef[i] <- coef_ev[var, "Estimate"]
    event_df$se[i] <- coef_ev[var, "Std. Error"]
    event_df$ic_inf[i] <- event_df$coef[i] - 1.96 * event_df$se[i]
    event_df$ic_sup[i] <- event_df$coef[i] + 1.96 * event_df$se[i]
  }
}

# Adicionar referência (ano -1)
event_df <- rbind(
  event_df[event_df$tempo < 0, ],
  data.frame(tempo = -1, coef = 0, se = 0, ic_inf = 0, ic_sup = 0),
  event_df[event_df$tempo >= 0, ]
)

# Gráfico
p_event_pib <- ggplot(event_df, aes(x = tempo, y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", linewidth = 0.8) +
  geom_ribbon(aes(ymin = ic_inf, ymax = ic_sup), alpha = 0.2, fill = "steelblue") +
  geom_line(color = "steelblue", linewidth = 1) +
  geom_point(size = 3, color = "steelblue") +
  scale_x_continuous(breaks = seq(-6, 6, 1)) +
  labs(title = "Event Study: Efeito da IG de Café no PIB per capita (log)",
       subtitle = "Anos EXATOS de concessão | Municípios pareados (PSM) | IC 95%",
       x = "Anos Relativos à Concessão da IG",
       y = "Efeito no log(PIB per capita)",
       caption = "Ano -1 como referência | Efeitos fixos município + ano | SE clusterizados") +
  theme_minimal() +
  theme(plot.caption = element_text(size = 8, hjust = 0))

ggsave("Resultados/EventStudy_PIB_AnosExatos.png", p_event_pib,
       width = 10, height = 6, dpi = 300)

cat("  ✓ Gráfico salvo: Resultados/EventStudy_PIB_AnosExatos.png\n")

# ==============================================================================
# 8. SALVAR RESULTADOS
# ==============================================================================

cat("\n\n7. Salvando resultados...\n")

write.csv(resultados_did,
          "Resultados/DiD_AnosExatos_Economicas_Resultados.csv",
          row.names = FALSE)

write.csv(event_df,
          "Resultados/EventStudy_PIB_AnosExatos_Coeficientes.csv",
          row.names = FALSE)

cat("  ✓ Resultados salvos:\n")
cat("    - DiD_AnosExatos_Economicas_Resultados.csv\n")
cat("    - EventStudy_PIB_AnosExatos_Coeficientes.csv\n")

cat("\n\n✓ ANÁLISE DiD (VARIÁVEIS ECONÔMICAS) - CONCLUÍDA!\n\n")
