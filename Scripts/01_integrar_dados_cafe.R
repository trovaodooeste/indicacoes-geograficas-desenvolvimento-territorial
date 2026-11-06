# ==============================================================================
# ==============================================================================

.libPaths(c("~/R/library", .libPaths()))

rm(list = ls())

library(readxl)
library(dplyr)
library(tidyr)
library(stringr)

setwd("/mnt/c/Users/Trovao/Desktop/Artigo - Economia Regional")

cat("\n╔═══════════════════════════════════════════════════════════╗\n")
cat("║        INTEGRAÇÃO DE DADOS - INDICAÇÕES GEOGRÁFICAS CAFÉ  ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

# ==============================================================================
# 1. CARREGAR DADOS
# ==============================================================================

cat("1. Carregando dados...\n")

# MAPA - Municípios com IGs
mapa <- read_excel("Dados/IGs- tabela MAPA.xlsx", skip = 1)
names(mapa) <- c("municipio", "uf", "produto_ig")
cat("  ✓ MAPA carregado:", nrow(mapa), "municípios\n")

# IFDM - Painel 2013-2023
ifdm <- read_excel("Dados/IFDM_2013_2023_painel_tratado.xlsx",
                   sheet = "Painel IFDM 2013-2023")
cat("  ✓ IFDM carregado:", nrow(ifdm), "observações\n")

# PIB - Painel 2002-2023
pib <- read_excel("Dados/PIB_Municipal_2002_2023_painel_IG.xlsx",
                  sheet = "Painel 2002-2023") %>%
  mutate(
    # Padronizar código: remover dígito verificador (7 dígitos → 6 dígitos)
    cod_municipio = floor(cod_municipio / 10)
  )
cat("  ✓ PIB carregado:", nrow(pib), "observações\n")
cat("  ✓ Códigos padronizados (7→6 dígitos)\n\n")

# ==============================================================================
# 2. IDENTIFICAR MUNICÍPIOS COM IG DE CAFÉ
# ==============================================================================

cat("2. Identificando municípios com IG de Café...\n")

# Filtrar apenas café (busca precisa)
cafe_mapa <- mapa %>%
  filter(grepl("\\(Café\\)|\\(Coffee\\)|\\(Conilon\\)", produto_ig, ignore.case = TRUE)) %>%
  mutate(
    IG_Cafe = 1,
    # Padronizar nome do município para matching
    municipio_clean = toupper(str_trim(municipio)),
    municipio_clean = iconv(municipio_clean, to = "ASCII//TRANSLIT") # Remover acentos
  )

cat("  ✓ Municípios com IG Café:", nrow(cafe_mapa), "\n")
cat("  ✓ IGs identificadas:", n_distinct(cafe_mapa$produto_ig), "\n\n")

# Mostrar resumo das IGs
cat("  Resumo das IGs de Café:\n")
igs_count <- cafe_mapa %>%
  count(produto_ig, sort = TRUE)
print(igs_count, n = Inf)
cat("\n")

# ==============================================================================
# 3. MATCHING MUNICÍPIO - OBTER CÓDIGO IBGE
# ==============================================================================

cat("3. Fazendo matching de municípios (nome → código IBGE)...\n")

# Criar versão limpa do nome no IFDM para matching
ifdm_municipios <- ifdm %>%
  select(cod_municipio, uf, municipio) %>%
  distinct() %>%
  mutate(
    municipio_clean = toupper(str_trim(municipio)),
    municipio_clean = iconv(municipio_clean, to = "ASCII//TRANSLIT")
  )

# Join por nome + UF
cafe_com_codigo <- cafe_mapa %>%
  left_join(ifdm_municipios,
            by = c("municipio_clean" = "municipio_clean", "uf" = "uf"))

# Verificar matching
nao_matched <- cafe_com_codigo %>% filter(is.na(cod_municipio))

if(nrow(nao_matched) > 0) {
  cat("\n  ⚠️ ATENÇÃO: Alguns municípios não foram encontrados:\n")
  print(nao_matched[, c("municipio", "uf", "produto_ig")])
  cat("\n")
} else {
  cat("  ✓ Todos os municípios foram encontrados!\n")
}

# Remover não-matched e ficar só com os códigos
cafe_codigos <- cafe_com_codigo %>%
  filter(!is.na(cod_municipio)) %>%
  select(cod_municipio, municipio.x, uf, produto_ig, IG_Cafe) %>%
  rename(municipio = municipio.x) %>%
  distinct()

cat("  ✓ Municípios com código IBGE:", nrow(cafe_codigos), "\n\n")

# ==============================================================================
# 4. INTEGRAR COM IFDM (VARIÁVEIS DE RESULTADO)
# ==============================================================================

cat("4. Integrando com IFDM...\n")

# Pegar anos recentes (2018-2023) para análise cross-section
# Podemos ajustar depois se quiser painel
ifdm_recente <- ifdm %>%
  filter(ano >= 2018) %>%
  group_by(cod_municipio) %>%
  summarise(
    municipio = first(municipio),
    uf = first(uf),
    IFDM = mean(ifdm_geral, na.rm = TRUE),
    IFDM_Emprego = mean(ifdm_emprego_renda, na.rm = TRUE),
    IFDM_Educacao = mean(ifdm_educacao, na.rm = TRUE),
    IFDM_Saude = mean(ifdm_saude, na.rm = TRUE),
    n_obs_ifdm = n()
  )

cat("  ✓ IFDM médio 2018-2023 calculado para", nrow(ifdm_recente), "municípios\n\n")

# ==============================================================================
# 5. INTEGRAR COM PIB (COVARIÁVEIS + RESULTADO)
# ==============================================================================

cat("5. Integrando com PIB...\n")

# Pegar anos recentes (2018-2021, PIB costuma ter defasagem)
pib_recente <- pib %>%
  filter(ano >= 2018, ano <= 2021) %>%
  group_by(cod_municipio) %>%
  summarise(
    PIB_Total = mean(pib_r1000, na.rm = TRUE),
    PIB_Percapita = mean(pib_percapita, na.rm = TRUE),
    VA_Agropecuaria = mean(vab_agropecuaria_r1000, na.rm = TRUE),
    VA_Industria = mean(vab_industria_r1000, na.rm = TRUE),
    VA_Servicos = mean(vab_servicos_r1000, na.rm = TRUE),
    n_obs_pib = n()
  ) %>%
  mutate(
    # Participação da agropecuária no PIB (%)
    Part_Agro = (VA_Agropecuaria / PIB_Total) * 100
  )

cat("  ✓ PIB médio 2018-2021 calculado para", nrow(pib_recente), "municípios\n\n")

# ==============================================================================
# 6. JUNTAR TUDO
# ==============================================================================

cat("6. Criando base integrada...\n")

# Primeiro juntar IFDM + PIB (todos os municípios)
base_completa <- ifdm_recente %>%
  left_join(pib_recente, by = "cod_municipio")

# Depois adicionar indicador de IG Café
base_completa <- base_completa %>%
  left_join(
    cafe_codigos %>% select(cod_municipio, IG_Cafe, produto_ig),
    by = "cod_municipio"
  ) %>%
  mutate(
    # Preencher NA com 0 (municípios sem IG Café)
    IG_Cafe = ifelse(is.na(IG_Cafe), 0, IG_Cafe)
  )

cat("  ✓ Base completa:\n")
cat("    - Total de municípios:", nrow(base_completa), "\n")
cat("    - Tratados (IG Café):", sum(base_completa$IG_Cafe), "\n")
cat("    - Controles (sem IG):", sum(base_completa$IG_Cafe == 0), "\n")
cat("    - Variáveis:", ncol(base_completa), "\n\n")

# ==============================================================================
# 7. ESTATÍSTICAS DESCRITIVAS POR GRUPO
# ==============================================================================

cat("╔═══════════════════════════════════════════════════════════╗\n")
cat("║               ESTATÍSTICAS DESCRITIVAS                    ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

# Municípios com IG Café
cat("MUNICÍPIOS COM IG CAFÉ (Tratados):\n")
cafe_stats <- base_completa %>%
  filter(IG_Cafe == 1) %>%
  summarise(
    N = n(),
    IFDM_medio = mean(IFDM, na.rm = TRUE),
    IFDM_Emprego_medio = mean(IFDM_Emprego, na.rm = TRUE),
    PIB_PC_medio = mean(PIB_Percapita, na.rm = TRUE),
    Part_Agro_media = mean(Part_Agro, na.rm = TRUE)
  )
print(cafe_stats)

cat("\n\nMUNICÍPIOS SEM IG (Controles):\n")
sem_cafe_stats <- base_completa %>%
  filter(IG_Cafe == 0) %>%
  summarise(
    N = n(),
    IFDM_medio = mean(IFDM, na.rm = TRUE),
    IFDM_Emprego_medio = mean(IFDM_Emprego, na.rm = TRUE),
    PIB_PC_medio = mean(PIB_Percapita, na.rm = TRUE),
    Part_Agro_media = mean(Part_Agro, na.rm = TRUE)
  )
print(sem_cafe_stats)

# Diferença simples (antes do matching)
cat("\n\nDIFERENÇA SIMPLES (Tratados - Controles):\n")
diff_simples <- cafe_stats %>%
  summarise(
    Diff_IFDM = cafe_stats$IFDM_medio - sem_cafe_stats$IFDM_medio,
    Diff_IFDM_Emprego = cafe_stats$IFDM_Emprego_medio - sem_cafe_stats$IFDM_Emprego_medio,
    Diff_PIB_PC = cafe_stats$PIB_PC_medio - sem_cafe_stats$PIB_PC_medio,
    Diff_Part_Agro = cafe_stats$Part_Agro_media - sem_cafe_stats$Part_Agro_media
  )
print(diff_simples)

cat("\n⚠️ ATENÇÃO: Esta é a diferença SEM controlar por covariáveis!\n")
cat("   O PSM vai estimar o efeito CAUSAL após matching.\n\n")

# ==============================================================================
# 8. SALVAR BASE INTEGRADA
# ==============================================================================

cat("8. Salvando base integrada...\n")

# Criar diretório de resultados se não existir
if(!dir.exists("Resultados")) {
  dir.create("Resultados")
}

# Salvar base completa
write.csv(base_completa,
          "Resultados/base_cafe_psm.csv",
          row.names = FALSE,
          fileEncoding = "UTF-8")

cat("  ✓ Base salva: Resultados/base_cafe_psm.csv\n")

# Salvar lista de municípios tratados
write.csv(cafe_codigos,
          "Resultados/municipios_cafe_tratados.csv",
          row.names = FALSE,
          fileEncoding = "UTF-8")

cat("  ✓ Lista de tratados salva: Resultados/municipios_cafe_tratados.csv\n\n")

# ==============================================================================
# 9. RESUMO FINAL
# ==============================================================================

cat("╔═══════════════════════════════════════════════════════════╗\n")
cat("║                   INTEGRAÇÃO CONCLUÍDA                    ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

cat("PRÓXIMOS PASSOS:\n")
cat("  1. Revisar base integrada (Resultados/base_cafe_psm.csv)\n")
cat("  2. Verificar dados faltantes (NAs)\n")
cat("  3. Executar PSM (Script 02_PSM_cafe.R)\n\n")

cat("✓ SCRIPT CONCLUÍDO COM SUCESSO!\n\n")
