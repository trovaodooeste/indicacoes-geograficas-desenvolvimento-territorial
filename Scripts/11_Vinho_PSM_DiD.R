# ==============================================================================
# Script 11: PSM + DiD — IGs de Vinho
# Objetivo: Estimar efeito das IGs de vinho no IFDM dos municípios brasileiros
# Pré-requisito: Script 09_Vinho_Mapeamento.R (gera municipios_vinho_tratados.csv)
# Data: Junho 2026
#
# NOTA SOBRE STAGGERED TREATMENT:
#   Vale dos Vinhedos (2002) e Vales da Uva Goethe (2012) não têm período
#   pré-tratamento limpo nesta janela (painel inicia em 2013). Isso é uma
#   limitação reconhecida. O PSM em 2013 usa características parcialmente
#   pós-tratamento para esses 9 municípios.
#   O Event Study é restrito aos municípios com tratamento >= 2013.
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
cat("║          PSM + DiD — IGs DE VINHO NO BRASIL                   ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

# ==============================================================================
# 1. CARREGAR DADOS
# ==============================================================================

cat("1. Carregando dados...\n")

tratados_vinho <- read.csv("Resultados/municipios_vinho_tratados.csv",
                            stringsAsFactors = FALSE)
cat("   Municípios tratados:", nrow(tratados_vinho), "\n")

ifdm_raw <- read_excel("Dados/IFDM_2013_2023_painel_tratado.xlsx")
cat("   Painel IFDM:", nrow(ifdm_raw), "obs |",
    n_distinct(ifdm_raw$cod_municipio), "municípios |",
    n_distinct(ifdm_raw$ano), "anos\n\n")

# ==============================================================================
# 2. CONSTRUIR PAINEL DE VINHO
# ==============================================================================

cat("2. Construindo painel...\n")

cod_tratados <- unique(tratados_vinho$cod_municipio)

painel_vinho <- ifdm_raw %>%
  select(cod_municipio, uf, municipio, ano,
         ifdm_geral, ifdm_educacao, ifdm_saude, ifdm_emprego_renda) %>%
  mutate(tratado = cod_municipio %in% cod_tratados) %>%
  left_join(
    tratados_vinho %>% select(cod_municipio, ano_concessao, IG_principal),
    by = "cod_municipio"
  ) %>%
  mutate(
    pos_tratamento = case_when(
      tratado & !is.na(ano_concessao) & ano >= ano_concessao ~ TRUE,
      tratado & !is.na(ano_concessao) & ano < ano_concessao  ~ FALSE,
      !tratado ~ FALSE,
      TRUE ~ NA
    ),
    tempo_relativo = case_when(
      tratado & !is.na(ano_concessao) ~ ano - ano_concessao,
      TRUE ~ NA_real_
    )
  )

cat("   Tratados:", n_distinct(painel_vinho$cod_municipio[painel_vinho$tratado]), "\n")
cat("   Controles potenciais:", n_distinct(painel_vinho$cod_municipio[!painel_vinho$tratado]), "\n\n")

# ==============================================================================
# 3. PSM — CROSS-SECTION 2013
# ==============================================================================

cat("3. Propensity Score Matching (cross-section 2013)...\n")
cat("   Especificação: NN 3:1, caliper=0.05, logit, com reposição\n\n")

base_2013 <- painel_vinho %>%
  filter(ano == 2013) %>%
  filter(!is.na(ifdm_geral), !is.na(ifdm_educacao),
         !is.na(ifdm_saude), !is.na(ifdm_emprego_renda))

cat("   Obs 2013:", nrow(base_2013), "| Tratados:", sum(base_2013$tratado),
    "| Controles:", sum(!base_2013$tratado), "\n\n")

set.seed(42)
psm_res <- tryCatch({
  matchit(
    tratado ~ ifdm_geral + ifdm_educacao + ifdm_saude + ifdm_emprego_renda,
    data     = base_2013,
    method   = "nearest",
    distance = "logit",
    ratio    = 3,
    caliper  = 0.05,
    replace  = TRUE
  )
}, error = function(e) {
  cat("   caliper=0.05 falhou:", e$message, "\n   Tentando caliper=0.10...\n")
  matchit(
    tratado ~ ifdm_geral + ifdm_educacao + ifdm_saude + ifdm_emprego_renda,
    data     = base_2013,
    method   = "nearest",
    distance = "logit",
    ratio    = 3,
    caliper  = 0.10,
    replace  = TRUE
  )
})

cat("   Resultado do matching:\n")
print(summary(psm_res)$nn)
cat("\n")

matched_2013  <- match.data(psm_res)
cod_matched   <- unique(matched_2013$cod_municipio)

cat("   Municípios matched:", length(cod_matched), "\n")
cat("   Tratados:", sum(matched_2013$tratado), "| Controles:", sum(!matched_2013$tratado), "\n\n")

# Painel longitudinal para os municípios matched
painel_matched <- painel_vinho %>%
  filter(cod_municipio %in% cod_matched) %>%
  left_join(
    matched_2013 %>% select(cod_municipio, weights, distance),
    by = "cod_municipio"
  )

write.csv(painel_matched,  "Resultados/painel_vinho_matched.csv",     row.names = FALSE)
write.csv(matched_2013,    "Resultados/base_vinho_matched_2013.csv",  row.names = FALSE)
cat("   ✓ painel_vinho_matched.csv\n")
cat("   ✓ base_vinho_matched_2013.csv\n\n")

# ==============================================================================
# 4. PSM CROSS-SECTION — ATT (anos 2018 e 2022)
# ==============================================================================

cat("4. ATT PSM Cross-Section...\n\n")

calc_att_psm <- function(dados, variavel, ano_res) {
  d <- dados %>% filter(ano == ano_res, !is.na(.data[[variavel]]))
  if (sum(d$tratado, na.rm=T) < 3 || is.null(d$weights)) return(NULL)
  mod <- tryCatch(
    lm(as.formula(paste(variavel, "~ tratado")), data = d, weights = d$weights),
    error = function(e) NULL
  )
  if (is.null(mod)) return(NULL)
  cr <- coeftest(mod, vcov = vcovHC(mod, type="HC1"))
  idx <- grep("tratadoTRUE", rownames(cr))
  if (length(idx) == 0) return(NULL)
  att <- cr[idx, 1]; se <- cr[idx, 2]; pv <- cr[idx, 4]
  mc  <- mean(d[[variavel]][!d$tratado], na.rm=TRUE)
  data.frame(Metodo="PSM", Ano=ano_res, Variavel=variavel, ATT=att, SE=se,
             p_value=pv, Media_Controle=mc, Efeito_Pct=att/abs(mc)*100,
             Sig=ifelse(pv<0.01,"***",ifelse(pv<0.05,"**",ifelse(pv<0.10,"*",""))))
}

variaveis <- c("ifdm_geral","ifdm_educacao","ifdm_saude","ifdm_emprego_renda")

res_psm <- do.call(rbind, lapply(c(2018, 2022), function(a)
  do.call(rbind, lapply(variaveis, function(v)
    calc_att_psm(painel_matched, v, a)))))

cat("═══ PSM Cross-Section ════════════════════════════════════════════\n\n")
if (!is.null(res_psm)) {
  print(res_psm %>% select(Ano, Variavel, ATT, SE, p_value, Efeito_Pct, Sig),
        row.names=FALSE, digits=4)
}

# ==============================================================================
# 5. DiD — PAINEL COMPLETO COM EFEITOS FIXOS
# ==============================================================================

cat("\n5. DiD com efeitos fixos (painel matched 2013-2023)...\n\n")

calc_att_did <- function(dados, variavel) {
  d <- dados %>%
    filter(!is.na(.data[[variavel]]), !is.na(pos_tratamento)) %>%
    mutate(mun_f = as.factor(cod_municipio), ano_f = as.factor(ano))
  if (sum(d$pos_tratamento, na.rm=T) < 5) return(NULL)
  mod <- tryCatch(
    lm(as.formula(paste(variavel, "~ pos_tratamento + mun_f + ano_f")), data=d),
    error = function(e) NULL
  )
  if (is.null(mod)) return(NULL)
  cr <- coeftest(mod, vcov=vcovCL(mod, cluster=d$cod_municipio))
  idx <- grep("pos_tratamentoTRUE", rownames(cr))
  if (length(idx) == 0) return(NULL)
  att <- cr[idx,1]; se <- cr[idx,2]; pv <- cr[idx,4]
  mc  <- mean(d[[variavel]][!d$pos_tratamento], na.rm=TRUE)
  data.frame(Metodo="DiD", Variavel=variavel, ATT=att, SE=se, p_value=pv,
             Media_Controle=mc, Efeito_Pct=att/abs(mc)*100,
             IC_Inf=att-1.96*se, IC_Sup=att+1.96*se,
             Sig=ifelse(pv<0.01,"***",ifelse(pv<0.05,"**",ifelse(pv<0.10,"*",""))))
}

res_did <- do.call(rbind, lapply(variaveis, function(v) calc_att_did(painel_matched, v)))

cat("═══ DiD com Efeitos Fixos (painel matched, 2013-2023) ═══════════\n\n")
if (!is.null(res_did)) {
  print(res_did %>% select(Variavel, ATT, SE, p_value, Efeito_Pct, Sig),
        row.names=FALSE, digits=4)
}

# ==============================================================================
# 6. EVENT STUDY — TENDÊNCIAS PARALELAS
# ==============================================================================

cat("\n6. Event Study (tendências paralelas)...\n")
cat("   Restrito a municípios com concessão >= 2013 (pré-período limpo)\n\n")

painel_es <- painel_matched %>%
  filter(!is.na(ifdm_geral)) %>%
  filter(is.na(ano_concessao) | ano_concessao >= 2013) %>%
  mutate(
    mun_f = as.factor(cod_municipio),
    ano_f = as.factor(ano),
    tr_bin = case_when(
      is.na(tempo_relativo)   ~ NA_real_,
      tempo_relativo <= -3    ~ -3,
      tempo_relativo == -2    ~ -2,
      tempo_relativo == -1    ~ -1,
      tempo_relativo == 0     ~ 0,
      tempo_relativo == 1     ~ 1,
      tempo_relativo == 2     ~ 2,
      tempo_relativo >= 3     ~ 3
    )
  )

trat_clean <- painel_es %>%
  filter(tratado) %>%
  distinct(cod_municipio, municipio, ano_concessao)
cat("   Tratados com pré-período limpo:", nrow(trat_clean),
    "(", paste(sort(unique(trat_clean$ano_concessao)), collapse=", "), ")\n\n")

if (nrow(trat_clean) >= 5) {
  # Dummies de evento (excluindo t=-1 como referência)
  periodos_es <- c(-3, -2, 0, 1, 2, 3)
  dum_names   <- paste0("D", ifelse(periodos_es<0, paste0("m", abs(periodos_es)), periodos_es))

  for (i in seq_along(periodos_es)) {
    t_val <- periodos_es[i]
    painel_es[[dum_names[i]]] <- as.integer(
      !is.na(painel_es$tr_bin) & painel_es$tr_bin == t_val
    )
  }

  formula_es <- as.formula(
    paste("ifdm_geral ~", paste(dum_names, collapse=" + "), "+ mun_f + ano_f")
  )

  tryCatch({
    mod_es <- lm(formula_es, data = painel_es)
    cr_es  <- coeftest(mod_es, vcov=vcovCL(mod_es, cluster=painel_es$cod_municipio))

    es_res <- do.call(rbind, lapply(seq_along(dum_names), function(i) {
      idx <- which(rownames(cr_es) == dum_names[i])
      if (length(idx) == 0) return(NULL)
      data.frame(periodo=periodos_es[i],
                 coef=cr_es[idx,1], se=cr_es[idx,2], pv=cr_es[idx,4])
    }))
    # Adicionar referência (-1 = 0)
    es_res <- rbind(es_res, data.frame(periodo=-1, coef=0, se=NA, pv=NA)) %>%
      arrange(periodo)

    cat("═══ Event Study — IFDM Geral ════════════════════════════════════\n\n")
    print(es_res, row.names=FALSE, digits=4)

    pre_sig <- es_res %>% filter(periodo < -1, !is.na(pv), pv < 0.10)
    if (nrow(pre_sig) == 0) {
      cat("\n   ✓ Tendências paralelas: nenhum período pré-tratamento significativo (p>0.10)\n")
    } else {
      cat("\n   ⚠️  VIOLAÇÃO de tendências paralelas:\n")
      print(pre_sig)
    }

    write.csv(es_res, "Resultados/EventStudy_Vinho.csv", row.names=FALSE)
    cat("   ✓ Resultados/EventStudy_Vinho.csv\n")

  }, error = function(e) cat("   Erro no Event Study:", e$message, "\n"))
} else {
  cat("   ⚠️  Poucos tratados com pré-período limpo para Event Study confiável\n")
}

# ==============================================================================
# 7. SALVAR RESULTADOS CONSOLIDADOS
# ==============================================================================

cat("\n7. Salvando resultados consolidados...\n")

res_todos <- bind_rows(
  if (!is.null(res_psm)) res_psm %>% mutate(Produto = "Vinho") else NULL,
  if (!is.null(res_did)) res_did %>% mutate(Produto = "Vinho", Ano = NA_integer_) else NULL
)

write.csv(res_todos, "Resultados/ATT_Vinho.csv", row.names=FALSE)
cat("   ✓ Resultados/ATT_Vinho.csv\n\n")

# ==============================================================================
# 8. RESUMO FINAL
# ==============================================================================

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║              RESUMO — PSM + DiD VINHO                         ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("Municípios tratados (vinho): 31\n")
cat("  2002: Vale dos Vinhedos IP (3 mun RS)\n")
cat("  2012: Vales da Uva Goethe (6 mun SC)\n")
cat("  2014: Vale do São Francisco (5 mun PE/BA)\n")
cat("  2015: Altos Montes + Campanha Gaúcha + Farroupilha (17 mun RS)\n\n")

if (!is.null(res_did)) {
  cat("═══ Resultado principal — DiD IFDM Geral ════════════════════\n")
  r <- res_did %>% filter(Variavel == "ifdm_geral")
  if (nrow(r) > 0) {
    cat(sprintf("  ATT = %+.4f  SE = %.4f  p = %.3f  %s\n",
                r$ATT, r$SE, r$p_value, r$Sig))
    if (r$p_value > 0.10) {
      cat("  → Efeito NÃO SIGNIFICATIVO (consistente com café)\n")
    } else {
      cat("  → Efeito SIGNIFICATIVO!\n")
    }
  }
}

cat("\n✓ Script 11 concluído!\n\n")
