# RESULTADOS - PROPENSITY SCORE MATCHING
## Impacto das Indicações Geográficas de Café no Desenvolvimento Municipal

**Data:** 07/06/2026
**Metodologia:** Propensity Score Matching (Nearest Neighbor, 3:1, Caliper 0.01)

---

## 📊 RESUMO EXECUTIVO

Após aplicar Propensity Score Matching para controlar por variáveis pré-tratamento, **não encontramos evidência de efeito causal significativo** das Indicações Geográficas de café sobre o desenvolvimento municipal (IFDM) ou PIB per capita.

**Resultado principal:** ATT não significativo para todas as variáveis de resultado.

---

## 1. AMOSTRA E MATCHING

### 1.1 Amostra Inicial
- **Tratados (IG Café):** 87 municípios
- **Controles (sem IG):** 5.463 municípios
- **Total:** 5.550 municípios (após remover NAs)

### 1.2 Municípios Pareados
- **Tratados pareados:** 83 (95.4%)
- **Controles pareados:** 237 municípios
- **Effective Sample Size (ESS):** 224.64
- **Tratados descartados:** 4 municípios (fora do caliper)

### 1.3 IGs de Café Representadas
- Planalto de Vitória da Conquista (BA): 22 municípios
- Vale do Café (RJ): 16 municípios
- Noroeste Fluminense (RJ): 13 municípios
- Vale do Ivinhema (MS): 9 municípios
- Baturité (CE): 5 municípios
- Outros: 18 municípios em 14 IGs

---

## 2. BALANCEAMENTO DAS COVARIÁVEIS

### 2.1 Resumo do Balanceamento

| Variável | Diff. Antes | Diff. Após | Status |
|----------|-------------|------------|--------|
| Distance | 0.486 | 0.000 | ✅ Balanceado |
| PIB per capita | 0.139 | -0.034 | ✅ Balanceado |
| Part. Agropecuária | **-0.416** | **0.012** | ✅ **Excelente** |
| VA Agropecuária | -0.064 | 0.176 | ⚠️ Não balanceado |
| VA Indústria | 0.060 | -0.103 | ⚠️ Não balanceado |
| VA Serviços | -0.050 | -0.073 | ✅ Balanceado |
| IFDM Educação | 0.092 | 0.047 | ✅ Balanceado |
| IFDM Saúde | **0.345** | **-0.004** | ✅ **Excelente** |

**Balanceamento:** 6 de 8 variáveis balanceadas (< 0.1)

### 2.2 Interpretação
- O matching reduziu drasticamente os desequilíbrios pré-existentes
- Participação da agropecuária e IFDM Saúde foram perfeitamente balanceados
- Valores Adicionados (Agro e Indústria) ainda mostram algum desequilíbrio
  - Possível causa: alta variância dessas variáveis

---

## 3. RESULTADOS - AVERAGE TREATMENT EFFECT ON TREATED (ATT)

### 3.1 Efeitos Estimados

| Variável | ATT | Erro Padrão | t-stat | p-value | IC 95% | Significância |
|----------|-----|-------------|--------|---------|--------|---------------|
| **IFDM** | +0.0094 | 0.0168 | 0.56 | 0.575 | [-0.023, +0.042] | Não |
| **IFDM Emprego** | +0.0222 | 0.0269 | 0.82 | 0.411 | [-0.031, +0.075] | Não |
| **IFDM Educação** | +0.0065 | 0.0180 | 0.36 | 0.720 | [-0.029, +0.042] | Não |
| **IFDM Saúde** | -0.0004 | 0.0129 | -0.03 | 0.975 | [-0.026, +0.025] | Não |
| **PIB per capita** | -R$ 1.119 | R$ 3.302 | -0.34 | 0.735 | [-R$7.592, +R$5.354] | Não |

### 3.2 Interpretação dos Resultados

**Nenhum efeito estatisticamente significativo foi encontrado** (todos p > 0.10).

#### IFDM (Índice Firjan de Desenvolvimento)
- ATT = +0.0094 (não significativo, p = 0.575)
- Intervalo de confiança inclui zero: [-0.023, +0.042]
- **Conclusão:** IG de café NÃO causa melhoria significativa no IFDM geral

#### IFDM Emprego e Renda
- ATT = +0.0222 (não significativo, p = 0.411)
- Maior magnitude entre os componentes do IFDM, mas ainda não significativo
- **Conclusão:** Evidência fraca de possível efeito positivo, mas não conclusivo

#### PIB per capita
- ATT = -R$ 1.119 (não significativo, p = 0.735)
- Efeito praticamente nulo
- IC muito amplo: [-R$7.592, +R$5.354]
- **Conclusão:** IG de café NÃO causa mudança significativa no PIB per capita

---

## 4. COMPARAÇÃO: DIFERENÇA SIMPLES vs ATT

| Indicador | Diferença Simples | ATT (PSM) | Mudança |
|-----------|-------------------|-----------|---------|
| IFDM | +0.031 (+5.6%)** | +0.009 (ns) | **-71%** |
| IFDM Emprego | +0.047 (+8.4%)** | +0.022 (ns) | **-53%** |
| PIB per capita | +R$4.507 (+16.5%)** | -R$1.119 (ns) | **-124%** |

** Diferença observada antes do matching
ns = não significativo após matching

### 4.1 O que isso significa?

**Antes do PSM:** Municípios com IG de café pareciam mais desenvolvidos (+5.6% no IFDM, +16.5% no PIB).

**Após o PSM:** Esses efeitos desaparecem quando comparamos municípios **similares** em características pré-tratamento.

**Interpretação:** A diferença observada era devida à **seleção** (municípios já mais desenvolvidos conseguem obter IG), **NÃO ao efeito causal da IG**.

---

## 5. DISCUSSÃO

### 5.1 Resultado Surpreendente?

**Não necessariamente.** Nosso resultado difere de Medeiros et al. (2021), que encontraram efeitos positivos. Possíveis explicações:

1. **Heterogeneidade temporal:** Nossos dados são de 2018-2023, mais recentes
2. **Amostra diferente:** Usamos MAPA (87 municípios) vs amostra deles
3. **Covariáveis:** Controlamos por VA setoriais, não disponíveis no artigo original
4. **Maturação das IGs:** Muitas IGs de café são recentes (< 5 anos), efeitos podem demorar

### 5.2 Por que não houve efeito?

Possíveis explicações teóricas:

1. **Tempo insuficiente:** IGs precisam de 5-10 anos para gerar impacto mensurável
2. **Falta de coordenação:** IG registrada mas não implementada efetivamente
3. **Escala pequena:** Produtores com IG podem ser minoritários no município
4. **Spillovers limitados:** Benefícios concentrados em produtores certificados, não no município todo
5. **Custos de certificação:** Podem anular ganhos de preço premium

### 5.3 Limitações do Estudo

1. **Dados de PIB:** Defasagem (2018-2021), pode não capturar efeitos recentes
2. **Variáveis faltantes:**
   - Não temos dados de exportação municipal
   - Não temos dados de emprego por setor (RAIS)
   - Não temos dados de produção de café (PAM)
3. **Balanceamento imperfeito:** VA Agropecuária e VA Indústria ainda desbalanceados
4. **Amostra pequena:** 83 tratados limita poder estatístico
5. **Cross-section:** Não exploramos variação temporal (poderia fazer DiD ou painel)

---

## 6. ROBUSTEZ (SUGESTÕES PARA PRÓXIMOS PASSOS)

Para validar os resultados, seria importante:

1. **Testar sensibilidade ao caliper:**
   - Caliper 0.05, 0.02, 0.005
   - Ver se resultados mudam

2. **Testar outros ratios:**
   - 1:1, 2:1, 5:1
   - Trade-off entre viés e variância

3. **Reestimar sem VA setoriais:**
   - Variáveis desbalanceadas podem contaminar resultados
   - Modelo mais parcimonioso

4. **Análise de heterogeneidade:**
   - Separar por região (Sul, Sudeste, Nordeste)
   - Separar por tamanho da IG (>10 municípios vs <10)
   - Separar por tipo (IP vs DO)

5. **Adicionar covariáveis:**
   - Produção de café (PAM)
   - Estabelecimentos agropecuários (Censo Agro)
   - Emprego formal (RAIS)

6. **Diferenças-em-Diferenças:**
   - Explorar dimensão temporal
   - Controlar por tendências pré-tratamento

---

## 7. CONCLUSÕES

1. **Resultado principal:** Não há evidência de efeito causal significativo das IGs de café sobre IFDM ou PIB per capita

2. **Implicação teórica:** A associação positiva observada (municípios com IG são mais desenvolvidos) é devida à **seleção**, não à **causalidade**

3. **Implicação política:** IGs de café podem não ser suficientes para promover desenvolvimento territorial de forma ampla no município

4. **Ressalvas importantes:**
   - Efeitos podem existir mas ainda não serem detectáveis (tempo insuficiente)
   - Efeitos podem ser concentrados em produtores certificados, não no município todo
   - Dados melhores (exportação, emprego, produção) podem revelar efeitos que IFDM/PIB não capturam

5. **Próximos passos:**
   - Testar robustez (caliper, ratio, covariáveis)
   - Coletar dados adicionais (RAIS, PAM, exportações)
   - Investigar heterogeneidade (região, tamanho da IG, tempo desde certificação)

---

## ARQUIVOS GERADOS

- `Resultados/base_cafe_psm.csv` - Base integrada (5.550 municípios)
- `Resultados/base_cafe_matched.csv` - Base pareada (320 observações)
- `Resultados/ATT_Cafe.csv` - Resultados do ATT
- `Resultados/PSM_Cafe_LovePlot.png` - Gráfico de balanceamento
- `Resultados/relatorio_PSM_Cafe.txt` - Relatório técnico completo
- `Scripts/01_integrar_dados_cafe.R` - Script de integração
- `Scripts/02_PSM_cafe.R` - Script PSM

---

**Wellington e Ariana**
Junho 2026
