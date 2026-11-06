# ==============================================================================
# Script 09: Mapeamento Corrigido de Municípios com IGs de Vinho
# Objetivo: Lista definitiva de tratados usando códigos do IFDM (6 dígitos)
# Fonte: INPI (datas) + busca por nome no IFDM (códigos)
# Data: Junho 2026
#
# IGs DE VINHO USADAS (datas confirmadas pelo INPI):
#   Vale dos Vinhedos IP  = 22/11/2002  (3 mun RS)
#   Vales da Uva Goethe   = 27/11/2012  (~6 mun SC)
#   Vale do São Francisco = 22/10/2014  (5 mun BA/PE — vinho)
#   Altos Montes          = 27/10/2015  (2 mun RS)
#   Campanha Gaúcha       = 27/10/2015  (14 mun RS) ← data corrigida (era 2020)
#   Farroupilha           = 27/10/2015  (1 mun RS)
#
# EXCLUÍDOS:
#   Vale do Submédio São Francisco (2011): Fruticultura/uvas de mesa (81 mun)
#   Jundiahy SP (2017): Uva Niágara de Mesa
#   Marialva PR (2017): Uva de mesa
#   IGs de 2021: insuficiente post-treatment no painel 2013-2023
#
# IMPORTANTE: cod_municipio aqui é o código 6 dígitos do IFDM
#   (NÃO é o código IBGE 7 dígitos dividido por 10 — o IFDM usa sequência própria)
#   Códigos obtidos buscando por nome no arquivo IFDM_2013_2023_painel_tratado.xlsx
# ==============================================================================

.libPaths(c("~/R/library", .libPaths()))
rm(list = ls())

library(readxl)
library(dplyr)

setwd("C:/Users/Trovao/Desktop/Artigo - Economia Regional")

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║         MAPEAMENTO CORRIGIDO DE IGs DE VINHO NO BRASIL        ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

# ==============================================================================
# 1. LISTA DEFINITIVA — códigos verificados no IFDM por busca de nome
# ==============================================================================

municipios_vinho <- rbind(

  # ─── VALE DOS VINHEDOS (IP) — 22/11/2002 ─────────────────────────────────
  data.frame(cod_municipio = 430210, Municipio = "Bento Gonçalves",  UF = "RS",
             IG_principal = "Vale dos Vinhedos", tipo_ig = "IP", ano_concessao = 2002),
  data.frame(cod_municipio = 430860, Municipio = "Garibaldi",         UF = "RS",
             IG_principal = "Vale dos Vinhedos", tipo_ig = "IP", ano_concessao = 2002),
  data.frame(cod_municipio = 431238, Municipio = "Monte Belo do Sul", UF = "RS",
             IG_principal = "Vale dos Vinhedos", tipo_ig = "IP", ano_concessao = 2002),

  # ─── VALES DA UVA GOETHE (IP) — 27/11/2012 ──────────────────────────────
  data.frame(cod_municipio = 421900, Municipio = "Urussanga",      UF = "SC",
             IG_principal = "Vales da Uva Goethe", tipo_ig = "IP", ano_concessao = 2012),
  data.frame(cod_municipio = 421240, Municipio = "Pedras Grandes", UF = "SC",
             IG_principal = "Vales da Uva Goethe", tipo_ig = "IP", ano_concessao = 2012),
  data.frame(cod_municipio = 420425, Municipio = "Cocal do Sul",   UF = "SC",
             IG_principal = "Vales da Uva Goethe", tipo_ig = "IP", ano_concessao = 2012),
  data.frame(cod_municipio = 421120, Municipio = "Morro da Fumaça",UF = "SC",
             IG_principal = "Vales da Uva Goethe", tipo_ig = "IP", ano_concessao = 2012),
  data.frame(cod_municipio = 421160, Municipio = "Nova Veneza",    UF = "SC",
             IG_principal = "Vales da Uva Goethe", tipo_ig = "IP", ano_concessao = 2012),
  data.frame(cod_municipio = 420700, Municipio = "Içara",          UF = "SC",
             IG_principal = "Vales da Uva Goethe", tipo_ig = "IP", ano_concessao = 2012),

  # ─── VALE DO SÃO FRANCISCO (VINHO/IP) — 22/10/2014 ──────────────────────
  # Atenção: NÃO confundir com "Vale do Submédio São Francisco" (2011, fruticultura)
  data.frame(cod_municipio = 261110, Municipio = "Petrolina",               UF = "PE",
             IG_principal = "Vale do São Francisco", tipo_ig = "IP", ano_concessao = 2014),
  data.frame(cod_municipio = 261260, Municipio = "Santa Maria da Boa Vista", UF = "PE",
             IG_principal = "Vale do São Francisco", tipo_ig = "IP", ano_concessao = 2014),
  data.frame(cod_municipio = 260875, Municipio = "Lagoa Grande",            UF = "PE",
             IG_principal = "Vale do São Francisco", tipo_ig = "IP", ano_concessao = 2014),
  data.frame(cod_municipio = 291840, Municipio = "Juazeiro",                UF = "BA",
             IG_principal = "Vale do São Francisco", tipo_ig = "IP", ano_concessao = 2014),
  data.frame(cod_municipio = 290990, Municipio = "Curaçá",                  UF = "BA",
             IG_principal = "Vale do São Francisco", tipo_ig = "IP", ano_concessao = 2014),

  # ─── ALTOS MONTES (IP) — 27/10/2015 ─────────────────────────────────────
  data.frame(cod_municipio = 430820, Municipio = "Flores da Cunha", UF = "RS",
             IG_principal = "Altos Montes", tipo_ig = "IP", ano_concessao = 2015),
  data.frame(cod_municipio = 430080, Municipio = "Antônio Prado",   UF = "RS",
             IG_principal = "Altos Montes", tipo_ig = "IP", ano_concessao = 2015),

  # ─── CAMPANHA GAÚCHA (IP) — 27/10/2015 ──────────────────────────────────
  # DATA CORRIGIDA: 2015 (não 2020 como constava antes)
  # 14 municípios da fronteira sul/oeste do RS
  data.frame(cod_municipio = 430160, Municipio = "Bagé",                    UF = "RS",
             IG_principal = "Campanha Gaúcha", tipo_ig = "IP", ano_concessao = 2015),
  data.frame(cod_municipio = 430660, Municipio = "Dom Pedrito",              UF = "RS",
             IG_principal = "Campanha Gaúcha", tipo_ig = "IP", ano_concessao = 2015),
  data.frame(cod_municipio = 431530, Municipio = "Quaraí",                   UF = "RS",
             IG_principal = "Campanha Gaúcha", tipo_ig = "IP", ano_concessao = 2015),
  data.frame(cod_municipio = 431710, Municipio = "Sant'Ana do Livramento",   UF = "RS",
             IG_principal = "Campanha Gaúcha", tipo_ig = "IP", ano_concessao = 2015),
  data.frame(cod_municipio = 430040, Municipio = "Alegrete",                 UF = "RS",
             IG_principal = "Campanha Gaúcha", tipo_ig = "IP", ano_concessao = 2015),
  data.frame(cod_municipio = 432240, Municipio = "Uruguaiana",               UF = "RS",
             IG_principal = "Campanha Gaúcha", tipo_ig = "IP", ano_concessao = 2015),
  data.frame(cod_municipio = 431060, Municipio = "Itaqui",                   UF = "RS",
             IG_principal = "Campanha Gaúcha", tipo_ig = "IP", ano_concessao = 2015),
  data.frame(cod_municipio = 431830, Municipio = "São Gabriel",              UF = "RS",
             IG_principal = "Campanha Gaúcha", tipo_ig = "IP", ano_concessao = 2015),
  data.frame(cod_municipio = 431640, Municipio = "Rosário do Sul",           UF = "RS",
             IG_principal = "Campanha Gaúcha", tipo_ig = "IP", ano_concessao = 2015),
  data.frame(cod_municipio = 431150, Municipio = "Lavras do Sul",            UF = "RS",
             IG_principal = "Campanha Gaúcha", tipo_ig = "IP", ano_concessao = 2015),
  data.frame(cod_municipio = 430290, Municipio = "Cacequi",                  UF = "RS",
             IG_principal = "Campanha Gaúcha", tipo_ig = "IP", ano_concessao = 2015),
  data.frame(cod_municipio = 431171, Municipio = "Maçambará",                UF = "RS",
             IG_principal = "Campanha Gaúcha", tipo_ig = "IP", ano_concessao = 2015),
  data.frame(cod_municipio = 431175, Municipio = "Manoel Viana",             UF = "RS",
             IG_principal = "Campanha Gaúcha", tipo_ig = "IP", ano_concessao = 2015),
  data.frame(cod_municipio = 431800, Municipio = "São Borja",                UF = "RS",
             IG_principal = "Campanha Gaúcha", tipo_ig = "IP", ano_concessao = 2015),

  # ─── FARROUPILHA (IP) — 27/10/2015 ──────────────────────────────────────
  data.frame(cod_municipio = 430790, Municipio = "Farroupilha", UF = "RS",
             IG_principal = "Farroupilha", tipo_ig = "IP", ano_concessao = 2015)
)

cat("Total de municípios tratados (vinho):", nrow(municipios_vinho), "\n\n")
cat("Distribuição por IG:\n")
print(municipios_vinho %>% count(IG_principal, tipo_ig, ano_concessao) %>% arrange(ano_concessao))

# ==============================================================================
# 2. VERIFICAR COBERTURA NO IFDM
# ==============================================================================

cat("\n2. Verificando cobertura no painel IFDM...\n")

ifdm <- tryCatch(
  read_excel("Dados/IFDM_2013_2023_painel_tratado.xlsx"),
  error = function(e) { cat("   ERRO:", e$message, "\n"); NULL }
)

if (!is.null(ifdm)) {
  codigos_ifdm <- unique(ifdm$cod_municipio)
  municipios_vinho$no_ifdm <- municipios_vinho$cod_municipio %in% codigos_ifdm

  nao_enc <- municipios_vinho %>% filter(!no_ifdm)
  if (nrow(nao_enc) > 0) {
    cat("\n   ⚠️  Não encontrados no IFDM:\n")
    print(nao_enc %>% select(cod_municipio, Municipio, UF, IG_principal))
  } else {
    cat("   ✓ Todos os municípios encontrados no IFDM!\n")
  }
  cat("   Cobertura:", sum(municipios_vinho$no_ifdm), "de", nrow(municipios_vinho), "\n")
} else {
  municipios_vinho$no_ifdm <- NA
}

# ==============================================================================
# 3. SALVAR
# ==============================================================================

cat("\n3. Salvando...\n")
write.csv(municipios_vinho, "Resultados/municipios_vinho_tratados.csv",
          row.names = FALSE, fileEncoding = "UTF-8")
cat("   ✓ Resultados/municipios_vinho_tratados.csv\n\n")

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                        RESUMO FINAL                           ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
cat("Municípios tratados (vinho):  ", nrow(municipios_vinho), "\n")
cat("IGs incluídas:                ", n_distinct(municipios_vinho$IG_principal), "\n")
cat("Coortes: 2002, 2012, 2014, 2015\n")
cat("Período mínimo pós-tratamento: 2015 → 8 anos (painel 2013-2023)\n")
cat("PSM ratio 3:1 → ~", nrow(municipios_vinho)*3, "controles\n\n")

cat("Coortes:\n")
cat("  2002: Vale dos Vinhedos IP  — 3 mun (RS)\n")
cat("  2012: Vales da Uva Goethe  — 6 mun (SC)\n")
cat("  2014: Vale do São Francisco — 5 mun (PE/BA)\n")
cat("  2015: Altos Montes          — 2 mun (RS)\n")
cat("  2015: Campanha Gaúcha       — 14 mun (RS)\n")
cat("  2015: Farroupilha           — 1 mun (RS)\n\n")
cat("✓ Script 09 concluído! Próximo: Script 11_Vinho_PSM_DiD.R\n")
