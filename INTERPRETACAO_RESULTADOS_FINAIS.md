# INTERPRETAÇÃO DOS RESULTADOS: IG DE CAFÉ E DESENVOLVIMENTO MUNICIPAL

## RESUMO EXECUTIVO

**Questão de Pesquisa:** As Indicações Geográficas (IGs) de café causam impacto no desenvolvimento municipal brasileiro (medido pelo IFDM)?

**Métodos Utilizados:**
1. Propensity Score Matching (PSM) - análise cross-section
2. Difference-in-Differences (DiD) - análise de painel com anos EXATOS de concessão
3. Event Study - efeitos dinâmicos ano a ano

**CONCLUSÃO PRINCIPAL:**
**NÃO há evidência robusta de efeito causal das IGs de café no IFDM.**

Embora o DiD mostre efeito marginalmente significativo (p=0.08), este resultado é **invalidado pela violação da suposição de tendências paralelas**. O PSM, mais apropriado para este contexto, confirma ausência de efeito causal.

---

## 1. RESULTADOS DETALHADOS

### 1.1 Propensity Score Matching (PSM)

**Especificação:** Nearest Neighbor 3:1, caliper 0.01, com reposição

| Variável | ATT | p-value | IC 95% | Significativo? |
|----------|-----|---------|--------|----------------|
| IFDM Geral | +0.0094 | 0.575 | [-0.0231, 0.0419] | **NÃO** |
| IFDM Emprego | -0.0029 | 0.832 | [-0.0303, 0.0244] | **NÃO** |

**Amostra:** 83 municípios tratados (com IG café) pareados com 237 controles

**Robustez:** 0 de 8 especificações alternativas mostraram efeito significativo

**Interpretação PSM:** Municípios com IG de café não apresentam IFDM diferente de municípios similares sem IG quando controlamos por características observáveis (população, PIB per capita, estrutura produtiva).

---

### 1.2 Difference-in-Differences (DiD)

**Especificação:** Two-Way Fixed Effects (município + ano) com erros clusterizados

| Variável | ATT | SE | p-value | IC 95% | Significativo? |
|----------|-----|-----|---------|--------|----------------|
| IFDM Geral | **+0.0088** | 0.0051 | **0.081** | [-0.0011, 0.0187] | **SIM* (10%)** |
| IFDM Emprego | +0.0007 | 0.0054 | 0.902 | [-0.0100, 0.0113] | NÃO |

**Amostra:** 86 municípios tratados com anos EXATOS de concessão (2012-2017)
- 2012: 5 municípios
- 2014: 50 municípios
- 2015: 23 municípios
- 2017: 8 municípios

**Interpretação DiD (APARENTE):** Efeito positivo marginalmente significativo de +0.88 pontos percentuais no IFDM.

---

### 1.3 Event Study (CRÍTICO!)

**Coeficientes por Ano Relativo à Concessão:**

| Ano Relativo | Coeficiente | IC 95% | Significativo? |
|--------------|-------------|---------|----------------|
| -4 | -0.0099 | [-0.0286, 0.0089] | Não |
| -3 | -0.0144 | [-0.0337, 0.0049] | Não |
| **-2** | **-0.0315** | **[-0.0478, -0.0152]** | **SIM** ⚠️ |
| -1 | 0.0000 | (referência) | - |
| 0 | -0.0044 | [-0.0151, 0.0062] | Não |
| +1 | -0.0035 | [-0.0131, 0.0060] | Não |
| +2 | -0.0101 | [-0.0200, -0.0001] | Marginal |
| +3 | -0.0043 | [-0.0128, 0.0042] | Não |
| +4 | -0.0033 | [-0.0112, 0.0046] | Não |
| +5 | +0.0029 | [-0.0040, 0.0099] | Não |
| +6 | +0.0028 | [-0.0044, 0.0101] | Não |

**⚠️ ATENÇÃO:** Coeficiente pré-tratamento no ano -2 é **SIGNIFICATIVAMENTE NEGATIVO**

---

## 2. ANÁLISE CRÍTICA: VIOLAÇÃO DE TENDÊNCIAS PARALELAS

### 2.1 O Problema

O **pressuposto fundamental** do DiD é que tratados e controles teriam evoluído de forma **paralela** na ausência do tratamento (IG). Este pressuposto é **TESTÁVEL** olhando os anos PRÉ-tratamento.

**O que encontramos:**
- Anos -4 e -3: Coeficientes negativos (não significativos)
- **Ano -2: Coeficiente -0.0315 (SIGNIFICATIVO)**

Isto significa que municípios com IG estavam em **trajetória DESCENDENTE** 2 anos antes da concessão, comparado aos controles.

### 2.2 Visualização Gráfica

O gráfico de Event Study mostra claramente:
1. **Pré-tratamento (anos -4 a -1):** Coeficientes negativos, com tendência de piora
2. **Pós-tratamento (anos 0 a +6):** Coeficientes próximos de zero ou levemente negativos

O gráfico de tendências mostra:
- Ambos os grupos crescem após 2017
- Grupo tratado cresce *um pouco* mais rápido
- Mas AMBOS estavam com trajetória irregular no período 2013-2017

### 2.3 Implicações

Quando tendências paralelas são violadas, o estimador DiD é **ENVIESADO**. O "efeito" positivo encontrado (ATT = +0.0088) pode estar capturando:

1. **Reversão à média:** Municípios em declínio (ano -2) naturalmente tendem a se recuperar
2. **Fatores omitidos:** Políticas ou choques econômicos que afetaram diferencialmente municípios cafeeiros
3. **Seleção endógena:** Municípios solicitam IG justamente quando estão em dificuldade
4. **Choques comuns:** A melhora pós-2017 pode ser devido a fatores macroeconômicos (preço do café, clima, etc.)

**Conclusão:** O efeito DiD NÃO pode ser interpretado como causal.

---

## 3. RECONCILIANDO PSM vs DiD

### Por que resultados diferentes?

| Método | Resultado | O que controla | Suposição chave |
|--------|-----------|----------------|-----------------|
| **PSM** | Sem efeito (p=0.58) | Características observáveis em 2013 | Seleção em observáveis |
| **DiD** | Efeito positivo* (p=0.08) | Diferenças fixas entre municípios + tendências temporais | **Tendências paralelas** |

**PSM:**
- Compara municípios similares em 2013 (população, PIB, estrutura econômica)
- Resultado: IFDM dos tratados = IFDM dos controles
- Interpretação: IG não causa diferença detectável

**DiD:**
- Compara EVOLUÇÃO ao longo do tempo
- Resultado: Tratados melhoram +0.88 pp mais que controles
- **MAS:** Tendências pré-tratamento não eram paralelas!
- Interpretação: Efeito espúrio, não causal

### Qual método confiar?

**Neste caso, PSM é mais confiável porque:**

1. **Tendências paralelas violadas:** DiD exige suposição não verificada
2. **PSM robusto:** 8 especificações diferentes, todas mostram efeito nulo
3. **Consistência interna:** Event Study não mostra padrão claro de melhora pós-tratamento
4. **Magnitude pequena:** Mesmo se aceito, efeito DiD é apenas 0.88 pp (pequeno para IFDM)

---

## 4. INTERPRETAÇÃO SUBSTANTIVA

### 4.1 Por que IGs de café podem NÃO ter efeito?

1. **Período de maturação longo:** Efeitos podem demorar >10 anos (Cerrado Mineiro, 2005, ainda não mostra efeito claro)

2. **Escala limitada:** IGs beneficiam principalmente grandes produtores organizados, não necessariamente toda economia municipal

3. **Efeito setorial, não municipal:** IG pode beneficiar setor cafeeiro sem transbordar para IFDM (educação, saúde, emprego geral)

4. **Diluição:** Município pode ter IG, mas café pode ser pequena parte da economia total

5. **Contrafactual inadequado:** Municípios sem IG podem ter outras vantagens compensatórias (outras culturas, indústria, turismo)

### 4.2 Comparação com Literatura

**Medeiros et al. (2021):**
- Também usaram PSM para IGs no Brasil
- Também encontraram efeitos fracos ou nulos para a maioria dos produtos
- Consistente com nossos achados

**Literatura internacional:**
- Efeitos de IGs são **heterogêneos**
- Produtos com maior valor agregado (vinhos) mostram efeitos mais claros
- Café pode ter menor elasticidade-preço da demanda para IGs

---

## 5. LIMITAÇÕES E PESQUISA FUTURA

### 5.1 Limitações Metodológicas

1. **Período de análise limitado:** 2013-2023 pode ser curto para efeitos de longo prazo

2. **Unidade de análise:** Município pode ser muito agregado (efeito pode existir apenas em distritos específicos)

3. **Variável de resultado:** IFDM pode não capturar benefícios específicos de IG (ex: preço do café, renda de cafeicultores)

4. **Viés de seleção residual:** Mesmo com PSM, podem existir diferenças não observáveis

5. **Timing heterogêneo:** Cerrado Mineiro (2005) vs outros (2014-2017) podem ter efeitos diferentes

### 5.2 Pesquisa Futura

**Recomendações para próximos estudos:**

1. **Análise no nível do produtor:**
   - Comparar renda/preços de cafeicultores COM vs SEM IG
   - Dados de cooperativas associadas às IGs

2. **Período mais longo:**
   - Estender análise para 2025-2030 quando houver mais dados
   - Focar em Cerrado Mineiro (2005) com 20 anos de dados

3. **Outras variáveis de resultado:**
   - Valor da produção de café
   - Exportações municipais
   - Empregos formais no setor agrícola
   - Número de estabelecimentos comerciais

4. **Análise de heterogeneidade:**
   - Diferenciar IP (Indicação de Procedência) vs DO (Denominação de Origem)
   - Separar por região (Sul/Sudeste vs Nordeste)
   - Tamanho do município (pequeno vs médio)

5. **Mecanismos:**
   - Estudar SE há efeito via preço, volume de produção, ou emprego
   - Entrevistas qualitativas com produtores e gestores de IGs

---

## 6. CONCLUSÃO FINAL

### Resposta à Pergunta de Pesquisa

**"As IGs de café causam impacto no desenvolvimento municipal (IFDM)?"**

**RESPOSTA: NÃO**

Com base em:
1. PSM mostra efeito nulo (robusto a 8 especificações)
2. DiD mostra efeito marginalmente significativo, MAS:
   - Violação de tendências paralelas
   - Event Study inconsistente
   - Magnitude pequena (0.88 pp)
3. Resultado consistente com Medeiros et al. (2021) para Brasil

### Implicações para Política Pública

1. **IGs NÃO são panaceia:** Não esperar transformação automática do desenvolvimento municipal

2. **Complementaridade necessária:** IGs devem vir acompanhadas de:
   - Infraestrutura (estradas, armazenamento)
   - Capacitação técnica
   - Políticas de marketing e exportação
   - Organização de produtores

3. **Expectativas realistas:** Efeitos, se existirem, são de longo prazo e específicos ao setor

4. **Foco em outros indicadores:** Avaliar IGs por impacto setorial (preço do café, renda de cafeicultores) em vez de IFDM municipal

### Para o Artigo

**Principais achados a reportar:**

1. ✅ PSM com 83 municípios tratados, 237 controles bem balanceados
2. ✅ ATT = +0.0094 (p=0.575) - efeito nulo
3. ✅ Robustez: 0/8 especificações significativas
4. ✅ DiD com anos exatos: ATT = +0.0088 (p=0.081)
5. ⚠️ MAS: Tendências paralelas violadas (ano -2 significativo)
6. ✅ Conclusão: Sem evidência de efeito causal

**Contribuição:**
- Primeiro estudo DiD com anos EXATOS de concessão de IG no Brasil
- Teste explícito de tendências paralelas via Event Study
- Evidência convergente PSM + DiD apontando para efeito nulo
- Consistente com literatura (Medeiros et al. 2021)

---

## APÊNDICE: ARQUIVOS GERADOS

### Scripts
1. `Scripts/01_integrar_dados_cafe.R` - Integração de dados
2. `Scripts/02_PSM_cafe.R` - PSM principal
3. `Scripts/03_Robustez_PSM_cafe_v2.R` - Robustez PSM
4. `Scripts/05_DiD_Preciso_cafe.R` - DiD com anos exatos

### Resultados
1. `Resultados/DiD_AnosExatos_Resultados.csv` - Resultados DiD
2. `Resultados/EventStudy_AnosExatos_Coeficientes.csv` - Event Study
3. `Resultados/Municipios_Anos_Concessao.csv` - Mapeamento município-ano
4. `Resultados/DiD_EventStudy_AnosExatos.png` - Gráfico Event Study
5. `Resultados/DiD_Tendencias_AnosExatos.png` - Gráfico tendências
6. `Resultados/PSM_*.csv` - Diversos resultados PSM

### Relatórios
1. `RESULTADOS_PSM_CAFE.md` - Relatório detalhado PSM
2. `INTERPRETACAO_RESULTADOS_FINAIS.md` - Este documento
