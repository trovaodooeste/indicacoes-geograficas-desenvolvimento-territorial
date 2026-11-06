# ==============================================================================
# Script 10: PSM com Variáveis de Emprego e Exportações - Café
# Objetivo: Replicar e ampliar análise de Medeiros et al. (2021) com emprego
#           e exportações, respondendo à sugestão do professor orientador
# Data: Junho 2026
#
# DADOS NECESSÁRIOS (ver instruções de download abaixo):
#   - Emprego: RAIS por município (2013-2023) - portal do MTE/IBGE
#   - Exportações: ComexStat por município e NCM 09 (café) - MDIC
# ==============================================================================

# ==============================================================================
# INSTRUÇÕES DE DOWNLOAD DOS DADOS
# ==============================================================================
#
# 1. EMPREGO (RAIS/CAGED):
#    - Acesse: https://bi.mte.gov.br/bgcaged/login.php
#    - OU: IBGE SIDRA Tabela 4195 (Vínculos empregatícios por município)
#    - Alternativa mais fácil: BasedosDados.org (pacote basedosdados no R)
#      install.packages("basedosdados")
#      Tabela: br_me_rais.microdados_estabelecimentos
#    - Variáveis necessárias: total_vinculos_ativos, total_salarios, municpio
#    - Período: 2013-2023 (anual)
#
# 2. EXPORTAÇÕES (ComexStat):
#    - Acesse: http://comexstat.mdic.gov.br/pt/municipio
#    - Filtrar: NCM capítulo 09 (Café, chá, mate)
#    - Agregar: por município, por ano (2013-2023)
#    - Exportar: CSV ou Excel
#    - Variáveis: municipio, ano, valor_fob_usd, kg_liquido
#
# ==============================================================================

.libPaths(c("~/R/library", .libPaths()))
rm(list = ls())

library(readxl)
library(dplyr)
library(MatchIt)
library(lmtest)
library(sandwich)

setwd("C:/Users/Trovao/Desktop/Artigo - Economia Regional")

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║     PSM - EMPREGO E EXPORTAÇÕES - IGs DE CAFÉ                 ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

# ==============================================================================
# 1. CARREGAR BASE JÁ EXISTENTE (café + IFDM + PIB)
# ==============================================================================

cat("1. Carregando base existente...\n")

base_existente <- read.csv("Resultados/base_cafe_matched.csv")
cat("   Base pareada carregada:", nrow(base_existente), "observações\n")
cat("   Municípios:", n_distinct(base_existente$cod_municipio), "\n")
cat("   Colunas:", paste(names(base_existente), collapse = ", "), "\n\n")

# ==============================================================================
# 2. CARREGAR DADOS DE EMPREGO (RAIS)
# ==============================================================================

cat("2. Carregando dados de emprego (RAIS)...\n\n")

# OPÇÃO A: Arquivo baixado do portal CAGED/RAIS
# Descomente quando tiver o arquivo:
#
# rais <- read.csv("Dados/RAIS_Municipios_2013_2023.csv", sep = ";") %>%
#   rename(
#     cod_municipio = Municipio_IBGE,   # ajustar nome da coluna
#     ano = Ano,
#     emprego_total = Total_Vinculos,
#     salario_medio = Salario_Medio
#   ) %>%
#   select(cod_municipio, ano, emprego_total, salario_medio) %>%
#   mutate(cod_municipio = as.integer(cod_municipio))

# OPÇÃO B: BasedosDados (recomendado - dados limpos)
# Requer autenticação com Google:
#
# library(basedosdados)
# set_billing_id("seu-projeto-google")
# rais <- bdplyr("br_me_rais.microdados_vinculos") %>%
#   filter(ano %in% 2013:2023) %>%
#   group_by(id_municipio, ano) %>%
#   summarise(emprego_total = n(), salario_medio = mean(valor_remuneracao_media)) %>%
#   collect()

# OPÇÃO C: Dados simulados para teste do script (remover quando tiver dados reais)
cat("   ⚠️  USANDO DADOS SIMULADOS - substituir por dados reais do RAIS!\n\n")
cat("   Instruções:\n")
cat("   - Baixe do portal: https://bi.mte.gov.br/bgcaged/\n")
cat("   - OU use o pacote 'basedosdados' no R\n")
cat("   - Salve em: Dados/RAIS_Municipios_2013_2023.csv\n\n")

municipios_na_base <- unique(base_existente$cod_municipio)
anos_na_base <- unique(base_existente$ano)

rais_simulado <- expand.grid(
  cod_municipio = municipios_na_base,
  ano = anos_na_base
) %>%
  mutate(
    emprego_total = round(rnorm(n(), mean = 5000, sd = 3000)),
    salario_medio = round(rnorm(n(), mean = 2000, sd = 500), 2)
  )

# SUBSTITUIR PELA LINHA ABAIXO QUANDO TIVER DADOS REAIS:
rais <- rais_simulado
# rais <- read.csv("Dados/RAIS_Municipios_2013_2023.csv") %>% ...

# ==============================================================================
# 3. CARREGAR DADOS DE EXPORTAÇÕES (COMEXSTAT)
# ==============================================================================

cat("3. Carregando dados de exportações (ComexStat)...\n\n")

# ARQUIVO DO COMEXSTAT - baixar em:
# http://comexstat.mdic.gov.br/pt/municipio
# Filtrar: NCM 09 (café), anos 2013-2023, por município de origem
#
# Descomente quando tiver o arquivo:
#
# comexstat <- read.csv("Dados/ComexStat_Cafe_Municipios_2013_2023.csv", sep = ";") %>%
#   rename(
#     cod_municipio = CO_MUN_GEO,   # código IBGE do município
#     ano = CO_ANO,
#     valor_exportado_usd = VL_FOB,
#     quantidade_kg = KG_LIQUIDO
#   ) %>%
#   group_by(cod_municipio, ano) %>%
#   summarise(
#     valor_exportado_usd = sum(valor_exportado_usd, na.rm = TRUE),
#     quantidade_kg = sum(quantidade_kg, na.rm = TRUE),
#     .groups = "drop"
#   ) %>%
#   mutate(
#     preco_medio_usd_kg = valor_exportado_usd / quantidade_kg,
#     log_exportacoes = log(valor_exportado_usd + 1)
#   )

cat("   ⚠️  USANDO DADOS SIMULADOS - substituir por dados reais do ComexStat!\n\n")
cat("   Instruções:\n")
cat("   - Acesse: http://comexstat.mdic.gov.br/pt/municipio\n")
cat("   - Filtrar NCM capítulo 09 (Café)\n")
cat("   - Selecionar período 2013-2023\n")
cat("   - Agrupar por município\n")
cat("   - Salve em: Dados/ComexStat_Cafe_Municipios_2013_2023.csv\n\n")

comexstat_simulado <- expand.grid(
  cod_municipio = municipios_na_base,
  ano = anos_na_base
) %>%
  mutate(
    valor_exportado_usd = round(abs(rnorm(n(), mean = 500000, sd = 800000))),
    quantidade_kg = round(abs(rnorm(n(), mean = 200000, sd = 300000))),
    preco_medio_usd_kg = valor_exportado_usd / pmax(quantidade_kg, 1),
    log_exportacoes = log(valor_exportado_usd + 1)
  )

# SUBSTITUIR PELA LINHA ABAIXO QUANDO TIVER DADOS REAIS:
comexstat <- comexstat_simulado
# comexstat <- read.csv("Dados/ComexStat_Cafe_Municipios_2013_2023.csv") %>% ...

# ==============================================================================
# 4. INTEGRAR TUDO
# ==============================================================================

cat("4. Integrando base existente + emprego + exportações...\n")

painel_completo <- base_existente %>%
  left_join(rais, by = c("cod_municipio", "ano")) %>%
  left_join(comexstat, by = c("cod_municipio", "ano"))

cat("   Observações na base integrada:", nrow(painel_completo), "\n")
cat("   Municípios:", n_distinct(painel_completo$cod_municipio), "\n")
cat("   Missing emprego:", sum(is.na(painel_completo$emprego_total)), "\n")
cat("   Missing exportações:", sum(is.na(painel_completo$valor_exportado_usd)), "\n\n")

# ==============================================================================
# 5. PSM - EMPREGO E EXPORTAÇÕES
# ==============================================================================

cat("5. Estimando ATT para emprego e exportações (PSM)...\n\n")

# Pegar pesos do matching anterior
# (assumindo que a base já tem os pesos do PSM original)
if(!"weights" %in% names(painel_completo)) {
  cat("   ⚠️  Coluna 'weights' não encontrada. Usando peso = 1.\n")
  painel_completo$weights <- 1
}

# Selecionar ano pós-tratamento (usar o mesmo do estudo principal)
# Para PSM cross-section: 2016 ou 2018 (como Medeiros et al.)
ano_resultado <- 2016  # Ajustar se necessário

dados_psm <- painel_completo %>%
  filter(ano == ano_resultado)

cat("   Ano de resultado:", ano_resultado, "\n")
cat("   Observações:", nrow(dados_psm), "\n\n")

# Função para calcular ATT
calcular_att <- function(dados, variavel, pesos = NULL) {
  if(!variavel %in% names(dados)) return(NULL)
  if(is.null(pesos)) pesos <- rep(1, nrow(dados))

  formula <- as.formula(paste(variavel, "~ IG_Cafe"))

  tryCatch({
    modelo <- lm(formula, data = dados, weights = pesos)
    vcov_r <- vcovHC(modelo, type = "HC1")
    coef_r <- coeftest(modelo, vcov = vcov_r)

    media_controle <- mean(dados[[variavel]][dados$IG_Cafe == 0], na.rm = TRUE)

    data.frame(
      Variavel = variavel,
      ATT = coef_r["IG_Cafe", "Estimate"],
      SE = coef_r["IG_Cafe", "Std. Error"],
      t_stat = coef_r["IG_Cafe", "t value"],
      p_value = coef_r["IG_Cafe", "Pr(>|t|)"],
      Media_Controle = media_controle,
      Efeito_Percentual = coef_r["IG_Cafe", "Estimate"] / media_controle * 100,
      IC_Inferior = coef_r["IG_Cafe", "Estimate"] - 1.96 * coef_r["IG_Cafe", "Std. Error"],
      IC_Superior = coef_r["IG_Cafe", "Estimate"] + 1.96 * coef_r["IG_Cafe", "Std. Error"]
    )
  }, error = function(e) NULL)
}

# Identificar coluna de tratamento
col_tratamento <- names(dados_psm)[grepl("IG_Cafe|ig_cafe|tratado", names(dados_psm))][1]
if(!is.null(col_tratamento)) {
  dados_psm$IG_Cafe <- dados_psm[[col_tratamento]]
}

# Variáveis de resultado a testar
variaveis_resultado <- c(
  "emprego_total",         # Total de empregos formais (RAIS)
  "salario_medio",         # Salário médio (RAIS)
  "valor_exportado_usd",   # Valor exportado em USD (ComexStat)
  "quantidade_kg",         # Quantidade exportada em kg (ComexStat)
  "preco_medio_usd_kg",    # Preço médio (ComexStat)
  "log_exportacoes"        # Log do valor exportado
)

resultados_psm <- do.call(rbind, lapply(variaveis_resultado, function(v) {
  calcular_att(dados_psm, v, pesos = dados_psm$weights)
}))

# Adicionar significância
if(!is.null(resultados_psm)) {
  resultados_psm$Significancia <- case_when(
    resultados_psm$p_value < 0.01 ~ "***",
    resultados_psm$p_value < 0.05 ~ "**",
    resultados_psm$p_value < 0.10 ~ "*",
    TRUE ~ ""
  )
}

# ==============================================================================
# 6. APRESENTAR RESULTADOS
# ==============================================================================

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                    RESULTADOS - PSM                           ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("═══════════════════════════════════════════════════════════════════\n")
cat("EMPREGO E EXPORTAÇÕES - IGs DE CAFÉ\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

if(!is.null(resultados_psm)) {
  print(resultados_psm %>%
    select(Variavel, ATT, SE, p_value, Efeito_Percentual, Significancia),
    row.names = FALSE)
} else {
  cat("Nenhum resultado calculado.\n")
}

cat("\nComparação com Medeiros et al. (2021):\n")
cat("  Emprego (empregos/1000 hab) - Medeiros: +30.64** (p<0.05)\n")
cat("  Exportações (USD)           - Medeiros: +2.866.133 (não sig.)\n")
cat("  Preço médio (USD/kg)        - Medeiros: +0.78** (p<0.05)\n\n")

# ==============================================================================
# 7. SALVAR RESULTADOS
# ==============================================================================

cat("7. Salvando resultados...\n")

if(!is.null(resultados_psm)) {
  write.csv(resultados_psm,
            "Resultados/ATT_Cafe_Emprego_Exportacoes.csv",
            row.names = FALSE)
  cat("   ✓ Resultados/ATT_Cafe_Emprego_Exportacoes.csv\n")
}

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                    PRÓXIMOS PASSOS                            ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
cat("1. Baixar dados reais do RAIS (emprego):\n")
cat("   https://bi.mte.gov.br/bgcaged/\n\n")
cat("2. Baixar dados reais do ComexStat (exportações café):\n")
cat("   http://comexstat.mdic.gov.br/pt/municipio\n\n")
cat("3. Substituir dados simulados pelos reais (ver seções 2 e 3)\n\n")
cat("4. Rodar Script 11 (DiD para emprego e exportações)\n\n")
cat("✓ Script concluído!\n")
