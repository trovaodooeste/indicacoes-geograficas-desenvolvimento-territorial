# Indicações Geográficas e Desenvolvimento Territorial no Brasil: Evidências Causais de Café e Vinho

**Autores:** Ariana Oliveira Gusmão, Wellington Gubiani Maiberg, Hilton Manoel Dias Ribeiro  
**Disciplina:** Desenvolvimento Regional e Territorial Produtivo (DRTP)  
**Instituição:** Universidade Federal do Espírito Santo (UFES)  
**Período:** 2026

---

## Sobre o artigo

Este trabalho estima o efeito causal do registro de Indicações Geográficas (IGs) sobre o desenvolvimento municipal nas cadeias produtivas do café e do vinho no Brasil. Para isso, combinamos três métodos: Propensity Score Matching (PSM), Diferenças em Diferenças (DiD) com efeitos fixos e Event Study, aplicados a um painel de municípios brasileiros entre 2013 e 2023.

O estudo retoma e questiona os resultados de Medeiros et al. (2021), que identificaram efeitos positivos das IGs usando PSM em corte transversal. A incorporação da dimensão temporal revela que o pressuposto de tendências paralelas, necessário para inferência causal, é violado no caso do café, tornando o efeito estimado por PSM não-causal.

### Principais resultados

**Café (87 municípios tratados, pareados 3:1):**
- PSM: ATT IFDM Geral = +0,009 (p = 0,575), nenhuma das 8 especificações de robustez significativa
- DiD: ATT = +0,009 (p = 0,081), marginalmente significativo, mas espúrio
- Event Study: coeficiente em t-2 = -0,031 (p < 0,001), violação grave das tendências paralelas
- Conclusão: ausência de efeito causal das IGs de café

**Vinho (31 municípios tratados, 6 IGs):**
- PSM: ATT IFDM Geral = +0,020 (p = 0,402), não significativo
- DiD IFDM Geral: ATT = +0,009 (p = 0,210), não significativo
- DiD IFDM Emprego/Renda: ATT = +0,027 (p = 0,006), significativo a 1%
- Event Study (coortes 2014-2015): coeficiente em t-2 = -0,001 (p = 0,907), tendências paralelas válidas
- Conclusão: efeito real sobre emprego e renda, condicionado ao caráter intensivo em trabalho do setor

---

## Estrutura do repositório

```
.
├── artigo_principal.tex          # Texto do artigo (LaTeX)
├── artigo_principal.pdf          # PDF compilado
├── referencias.bib               # Bibliografia
├── Dados/
│   ├── IFDM_2013_2023_painel_tratado.xlsx     # FIRJAN, 2013-2023
│   ├── PIB_Municipal_2002_2023_painel_IG.xlsx  # IBGE, PIB e VA setorial
│   ├── IGs- tabela MAPA.xlsx                   # Municípios com IGs (MAPA)
│   ├── IGs_Brasil_INPI_x_DataSebrae.xlsx       # 161 IGs registradas (INPI)
│   ├── ComexStat_Cafe_Municipios.csv           # Exportações de café por município
│   └── FONTES_E_SELECAO_DADOS.md              # Documentação das fontes
├── Scripts/
│   ├── 01_integrar_dados_cafe.R
│   ├── 02_PSM_cafe.R
│   ├── 02_PSM_cafe_economicas.R
│   ├── 03_Robustez_PSM_cafe_v2.R
│   ├── 05_DiD_Preciso_cafe.R
│   ├── 06_DiD_Economicas_FINAL.R
│   ├── 08_Heterogeneidade_IGs.R
│   ├── 09_Vinho_Mapeamento.R
│   ├── 10_Exportacoes_PSM_DiD.R
│   └── 11_Vinho_PSM_DiD.R
├── Resultados/                   # CSVs e figuras gerados pelos scripts
└── Figuras_Artigo/               # Figuras prontas usadas no artigo
```

Os arquivos brutos do ComexStat (`Dados/ComexStat_Raw/`) e o arquivo compactado `Dados.rar` não estão no repositório por volume. Ver seção Dados abaixo.

---

## Dados

| Base | Fonte | Período | Acesso |
|------|-------|---------|--------|
| IFDM | FIRJAN | 2013-2023 | firjan.com.br/ifdm |
| PIB Municipal | IBGE | 2002-2023 | ibge.gov.br |
| Indicações Geográficas | INPI + MAPA | até 2023 | gov.br/inpi, gov.br/agricultura |
| Exportações | ComexStat/MDIC | 2013-2023 | balanca.economia.gov.br/balanca/bd/comexstat-bd/mun/ |

Atenção: o IFDM utiliza sequência própria de 6 dígitos, diferente do código IBGE (7 dígitos). Não converter diretamente. Os municípios devem ser cruzados por nome.

---

## Como reproduzir

### Dependências

R 4.x com os pacotes:

```r
install.packages(c(
  "readxl", "dplyr", "tidyr", "stringr", "ggplot2",
  "MatchIt", "cobalt", "lmtest", "sandwich",
  "fixest", "did", "sf"
))
```

### Ordem de execução

1. `01_integrar_dados_cafe.R` - integra MAPA + IFDM + PIB para café
2. `02_PSM_cafe.R` - PSM baseline (IFDM Geral, NN 3:1, caliper 0,01)
3. `02_PSM_cafe_economicas.R` - PSM para variáveis econômicas (PIB, VA, exportações)
4. `03_Robustez_PSM_cafe_v2.R` - 8 especificações alternativas de robustez
5. `05_DiD_Preciso_cafe.R` - DiD com efeitos fixos usando datas exatas de concessão
6. `06_DiD_Economicas_FINAL.R` - DiD para variáveis econômicas
7. `08_Heterogeneidade_IGs.R` - análise de heterogeneidade por produto
8. `09_Vinho_Mapeamento.R` - mapeamento dos municípios de vinho
9. `10_Exportacoes_PSM_DiD.R` - PSM e DiD para exportações de café
10. `11_Vinho_PSM_DiD.R` - PSM, DiD e Event Study para vinho

Ajuste o `setwd()` no início de cada script para o caminho local do repositório.

---

## Referência principal

Medeiros, M., Raiher, A. P., & Cielo, I. D. (2021). Geographical Indications and their Impact on Territorial Development: Empirical Evidence for Brazilian Municipalities. *Land Use Policy*, 111, 105797.
