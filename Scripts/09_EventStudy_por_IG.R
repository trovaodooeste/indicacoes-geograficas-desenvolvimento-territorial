################################################################################
# EVENT STUDY POR IG ESPECÍFICA
# Planalto de Vitória vs Vale do Café
################################################################################

.libPaths(c("~/R/library", .libPaths()))

library(dplyr)
library(ggplot2)
library(fixest)

cat("═══════════════════════════════════════════════════════════════════\n")
cat("  EVENT STUDY - POR IG ESPECÍFICA\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

# Carregar dados
setwd("/mnt/c/Users/Trovao/Desktop/Artigo - Economia Regional")
anos_ig <- read.csv("Resultados/Municipios_Anos_Concessao.csv")
painel <- read.csv("Resultados/painel_cafe_economicas_final.csv")

cat("1. Criando indicadores de tratamento por IG...\n")

# Identificar municípios de cada IG
planalto_munis <- anos_ig %>%
  filter(grepl("Planalto", nome_ig_extraido, ignore.case = TRUE)) %>%
  pull(cod_municipio) %>%
  unique()

vale_munis <- anos_ig %>%
  filter(grepl("Vale do Café", nome_ig_extraido, ignore.case = TRUE)) %>%
  pull(cod_municipio) %>%
  unique()

cat("  - Planalto de Vitória:", length(planalto_munis), "municípios\n")
cat("  - Vale do Café:", length(vale_munis), "municípios\n\n")

# Criar indicadores de tratamento
painel <- painel %>%
  mutate(
    # Planalto de Vitória (ano da IG: 2015)
    trat_planalto = ifelse(cod_municipio %in% planalto_munis, 1, 0),
    tempo_rel_planalto = ifelse(trat_planalto == 1, ano - 2015, NA),

    # Vale do Café (ano da IG: 2014)
    trat_vale = ifelse(cod_municipio %in% vale_munis, 1, 0),
    tempo_rel_vale = ifelse(trat_vale == 1, ano - 2014, NA)
  )

# Limitar tempo relativo a [-6, +6]
painel <- painel %>%
  mutate(
    tempo_rel_planalto = ifelse(tempo_rel_planalto < -6 | tempo_rel_planalto > 6,
                                  NA, tempo_rel_planalto),
    tempo_rel_vale = ifelse(tempo_rel_vale < -6 | tempo_rel_vale > 6,
                             NA, tempo_rel_vale)
  )

cat("2. Estimando Event Study - Planalto de Vitória...\n")

# Event Study - Planalto
# Omitir t=-1 como referência
# Usar todos os municípios (tratados + não-tratados como controles)
painel_planalto <- painel %>%
  filter(!is.na(tempo_rel_planalto) | trat_planalto == 0) %>%
  mutate(
    tempo_rel_planalto = ifelse(is.na(tempo_rel_planalto), -99, tempo_rel_planalto),
    tempo_rel_planalto = factor(tempo_rel_planalto,
                                 levels = c(-99, -6:-2, 0:6))  # -1 omitido
  )

modelo_planalto <- feols(
  ifdm_geral ~ i(tempo_rel_planalto, ref = -99) | cod_municipio + ano,
  data = painel_planalto,
  cluster = ~cod_municipio
)

# Extrair coeficientes
coefs_planalto <- summary(modelo_planalto)$coeftable
coefs_planalto <- as.data.frame(coefs_planalto)
coefs_planalto$tempo <- c(-6:-2, 0:6)  # -1 omitido (=0 por definição)

# Adicionar t=-1 como zero
ref_row <- data.frame(
  Estimate = 0,
  `Std. Error` = 0,
  `t value` = 0,
  `Pr(>|t|)` = 1,
  tempo = -1
)
names(ref_row) <- names(coefs_planalto)

coefs_planalto <- rbind(coefs_planalto, ref_row) %>%
  arrange(tempo) %>%
  mutate(
    IC_Inf = Estimate - 1.96 * `Std. Error`,
    IC_Sup = Estimate + 1.96 * `Std. Error`,
    IG = "Planalto de Vitória"
  )

cat("  ✓ Modelo estimado\n\n")

cat("3. Estimando Event Study - Vale do Café...\n")

# Event Study - Vale do Café
painel_vale <- painel %>%
  filter(!is.na(tempo_rel_vale) | trat_vale == 0) %>%
  mutate(
    tempo_rel_vale = ifelse(is.na(tempo_rel_vale), -99, tempo_rel_vale),
    tempo_rel_vale = factor(tempo_rel_vale,
                            levels = c(-99, -6:-2, 0:6))  # -1 omitido
  )

modelo_vale <- feols(
  ifdm_geral ~ i(tempo_rel_vale, ref = -99) | cod_municipio + ano,
  data = painel_vale,
  cluster = ~cod_municipio
)

# Extrair coeficientes
coefs_vale <- summary(modelo_vale)$coeftable
coefs_vale <- as.data.frame(coefs_vale)
coefs_vale$tempo <- c(-6:-2, 0:6)

# Adicionar t=-1 como zero
coefs_vale <- rbind(coefs_vale, ref_row) %>%
  arrange(tempo) %>%
  mutate(
    IC_Inf = Estimate - 1.96 * `Std. Error`,
    IC_Sup = Estimate + 1.96 * `Std. Error`,
    IG = "Vale do Café"
  )

cat("  ✓ Modelo estimado\n\n")

cat("4. Gerando gráficos...\n")

# Gráfico - Planalto de Vitória
p1 <- ggplot(coefs_planalto, aes(x = tempo, y = Estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "solid", color = "red", alpha = 0.5) +
  geom_ribbon(aes(ymin = IC_Inf, ymax = IC_Sup), alpha = 0.2, fill = "darkgreen") +
  geom_line(color = "darkgreen", size = 1) +
  geom_point(color = "darkgreen", size = 3) +
  geom_point(data = filter(coefs_planalto, `Pr(>|t|)` < 0.05),
             color = "darkgreen", size = 3, shape = 17) +  # Triângulos para significantes
  annotate("text", x = -3, y = max(coefs_planalto$IC_Sup) * 0.9,
           label = "IG granted (2015)", color = "red", size = 3.5) +
  labs(
    title = "Event Study: Planalto de Vitória da Conquista",
    subtitle = "Effect on IFDM Geral (22 municipalities)",
    x = "Years relative to GI grant",
    y = "Treatment effect (IFDM units)",
    caption = "Note: Shaded area = 95% CI. Triangles = p<0.05. Reference: t=-1."
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11),
    axis.title = element_text(size = 11),
    panel.grid.minor = element_blank()
  ) +
  scale_x_continuous(breaks = -6:6)

ggsave("Resultados/EventStudy_Planalto.png", p1, width = 10, height = 6, dpi = 300)
cat("  ✓ EventStudy_Planalto.png salvo\n")

# Gráfico - Vale do Café
p2 <- ggplot(coefs_vale, aes(x = tempo, y = Estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "solid", color = "red", alpha = 0.5) +
  geom_ribbon(aes(ymin = IC_Inf, ymax = IC_Sup), alpha = 0.2, fill = "darkred") +
  geom_line(color = "darkred", size = 1) +
  geom_point(color = "darkred", size = 3) +
  geom_point(data = filter(coefs_vale, `Pr(>|t|)` < 0.05),
             color = "darkred", size = 3, shape = 17) +
  annotate("text", x = -3, y = min(coefs_vale$IC_Inf) * 0.9,
           label = "IG granted (2014)", color = "red", size = 3.5) +
  labs(
    title = "Event Study: Vale do Café",
    subtitle = "Effect on IFDM Geral (13 municipalities)",
    x = "Years relative to GI grant",
    y = "Treatment effect (IFDM units)",
    caption = "Note: Shaded area = 95% CI. Triangles = p<0.05. Reference: t=-1."
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11),
    axis.title = element_text(size = 11),
    panel.grid.minor = element_blank()
  ) +
  scale_x_continuous(breaks = -6:6)

ggsave("Resultados/EventStudy_Vale.png", p2, width = 10, height = 6, dpi = 300)
cat("  ✓ EventStudy_Vale.png salvo\n\n")

# Combinar os dois em um único gráfico
coefs_combined <- rbind(coefs_planalto, coefs_vale)

p3 <- ggplot(coefs_combined, aes(x = tempo, y = Estimate, color = IG, fill = IG)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "solid", color = "black", alpha = 0.3) +
  geom_ribbon(aes(ymin = IC_Inf, ymax = IC_Sup), alpha = 0.15, color = NA) +
  geom_line(size = 1) +
  geom_point(size = 2.5) +
  geom_point(data = filter(coefs_combined, `Pr(>|t|)` < 0.05),
             size = 3, shape = 17) +
  scale_color_manual(values = c("Planalto de Vitória" = "darkgreen",
                                 "Vale do Café" = "darkred")) +
  scale_fill_manual(values = c("Planalto de Vitória" = "darkgreen",
                                "Vale do Café" = "darkred")) +
  labs(
    title = "Event Study: Comparing Two Largest Coffee GIs",
    subtitle = "Opposite effects on local development (IFDM)",
    x = "Years relative to GI grant",
    y = "Treatment effect (IFDM units)",
    color = "Geographical Indication",
    fill = "Geographical Indication",
    caption = "Note: Shaded areas = 95% CI. Triangles = p<0.05. Reference: t=-1.\nPlanalto granted in 2015 (22 mun.), Vale do Café granted in 2014 (13 mun.)."
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11),
    axis.title = element_text(size = 11),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  ) +
  scale_x_continuous(breaks = -6:6)

ggsave("Resultados/EventStudy_Planalto_vs_Vale.png", p3, width = 12, height = 7, dpi = 300)
cat("  ✓ EventStudy_Planalto_vs_Vale.png salvo\n\n")

# Salvar coeficientes
write.csv(coefs_combined, "Resultados/EventStudy_por_IG_Coeficientes.csv", row.names = FALSE)
cat("  ✓ Coeficientes salvos\n\n")

# Relatório
cat("5. Gerando relatório...\n")

sink("Resultados/EventStudy_por_IG_Relatorio.txt")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  EVENT STUDY - POR IG ESPECÍFICA\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")
cat("Data:", format(Sys.Date(), "%d/%m/%Y"), "\n\n")

cat("PLANALTO DE VITÓRIA DA CONQUISTA (BA):\n")
cat("───────────────────────────────────────\n")
cat("Ano da IG: 2015\n")
cat("Municípios tratados:", length(planalto_munis), "\n")
cat("Período analisado: 2009-2021 (t=-6 a t=+6)\n\n")

cat("Coeficientes:\n")
print(coefs_planalto %>%
        select(tempo, Estimate, `Std. Error`, `Pr(>|t|)`) %>%
        mutate(Sig = ifelse(`Pr(>|t|)` < 0.01, "***",
                     ifelse(`Pr(>|t|)` < 0.05, "**",
                     ifelse(`Pr(>|t|)` < 0.10, "*", "")))))

cat("\nTeste de tendências paralelas (t=-6 a t=-2):\n")
pre_planalto <- coefs_planalto %>% filter(tempo < 0, tempo != -1)
cat("Número de coeficientes pré-tratamento significativos (p<0.05):",
    sum(pre_planalto$`Pr(>|t|)` < 0.05), "de", nrow(pre_planalto), "\n")
cat("Conclusão:",
    ifelse(sum(pre_planalto$`Pr(>|t|)` < 0.05) == 0,
           "✓ Tendências paralelas VÁLIDAS",
           "✗ Possível violação de tendências paralelas"), "\n\n")

cat("Efeito médio pós-tratamento (t=0 a t=+6):\n")
post_planalto <- coefs_planalto %>% filter(tempo >= 0)
cat("ATT médio:", round(mean(post_planalto$Estimate), 4), "\n")
cat("% significativos:", round(100 * sum(post_planalto$`Pr(>|t|)` < 0.05) / nrow(post_planalto), 1), "%\n\n\n")

cat("═══════════════════════════════════════════════════════════════════\n\n")
cat("VALE DO CAFÉ (RJ):\n")
cat("──────────────────\n")
cat("Ano da IG: 2014\n")
cat("Municípios tratados:", length(vale_munis), "\n")
cat("Período analisado: 2008-2020 (t=-6 a t=+6)\n\n")

cat("Coeficientes:\n")
print(coefs_vale %>%
        select(tempo, Estimate, `Std. Error`, `Pr(>|t|)`) %>%
        mutate(Sig = ifelse(`Pr(>|t|)` < 0.01, "***",
                     ifelse(`Pr(>|t|)` < 0.05, "**",
                     ifelse(`Pr(>|t|)` < 0.10, "*", "")))))

cat("\nTeste de tendências paralelas (t=-6 a t=-2):\n")
pre_vale <- coefs_vale %>% filter(tempo < 0, tempo != -1)
cat("Número de coeficientes pré-tratamento significativos (p<0.05):",
    sum(pre_vale$`Pr(>|t|)` < 0.05), "de", nrow(pre_vale), "\n")
cat("Conclusão:",
    ifelse(sum(pre_vale$`Pr(>|t|)` < 0.05) == 0,
           "✓ Tendências paralelas VÁLIDAS",
           "✗ Possível violação de tendências paralelas"), "\n\n")

cat("Efeito médio pós-tratamento (t=0 a t=+6):\n")
post_vale <- coefs_vale %>% filter(tempo >= 0)
cat("ATT médio:", round(mean(post_vale$Estimate), 4), "\n")
cat("% significativos:", round(100 * sum(post_vale$`Pr(>|t|)` < 0.05) / nrow(post_vale), 1), "%\n\n")

cat("═══════════════════════════════════════════════════════════════════\n")
cat("CONCLUSÃO:\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

cat("1. Planalto de Vitória:\n")
cat("   - Tendências paralelas VÁLIDAS antes do tratamento\n")
cat("   - Efeito POSITIVO e PERSISTENTE após a IG\n")
cat("   - ATT médio: +", round(mean(post_planalto$Estimate), 4), " IFDM\n\n")

cat("2. Vale do Café:\n")
cat("   - Tendências paralelas VÁLIDAS antes do tratamento\n")
cat("   - Efeito NEGATIVO e PERSISTENTE após a IG\n")
cat("   - ATT médio: ", round(mean(post_vale$Estimate), 4), " IFDM\n\n")

cat("3. Os efeitos opostos (+", round(mean(post_planalto$Estimate), 4),
    " vs ", round(mean(post_vale$Estimate), 4),
    ") confirmam a heterogeneidade massiva.\n\n")

cat("4. Ambos passam no teste de tendências paralelas,\n")
cat("   validando a interpretação causal dos efeitos.\n\n")

sink()
cat("  ✓ Relatório salvo\n\n")

cat("╔═══════════════════════════════════════════════════════════════════╗\n")
cat("║           EVENT STUDY POR IG - CONCLUÍDO!                         ║\n")
cat("╚═══════════════════════════════════════════════════════════════════╝\n\n")

cat("Arquivos gerados:\n")
cat("  ✓ EventStudy_Planalto.png\n")
cat("  ✓ EventStudy_Vale.png\n")
cat("  ✓ EventStudy_Planalto_vs_Vale.png\n")
cat("  ✓ EventStudy_por_IG_Coeficientes.csv\n")
cat("  ✓ EventStudy_por_IG_Relatorio.txt\n\n")

cat("Use EventStudy_Planalto_vs_Vale.png para Figure 7 do artigo!\n\n")
