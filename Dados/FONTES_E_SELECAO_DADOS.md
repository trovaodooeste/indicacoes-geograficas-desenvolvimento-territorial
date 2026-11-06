# FONTES E SELEÇÃO DOS DADOS

**Data de coleta:** 17/06/2026  
**Responsável pela coleta:** Automática via script (Claude Code)

---

## 1. DADOS JÁ EXISTENTES NO PROJETO

### 1.1 IFDM — Índice FIRJAN de Desenvolvimento Municipal
- **Fonte:** Federação das Indústrias do Rio de Janeiro (FIRJAN)
- **URL:** https://www.firjan.com.br/ifdm/
- **Arquivo:** `Dados/IFDM_2013_2023_painel_tratado.xlsx`
- **Período:** 2013–2023 (painel balanceado)
- **Cobertura:** 5.570 municípios brasileiros
- **Variáveis selecionadas:**
  - `ifdm_geral`: Índice geral (0–1)
  - `ifdm_emprego_renda`: Subíndice emprego e renda (0–1) ← proxy de emprego
  - `ifdm_educacao`: Subíndice educação (0–1)
  - `ifdm_saude`: Subíndice saúde (0–1)
- **Nota:** O subíndice `ifdm_emprego_renda` é calculado com base em dados da RAIS (vínculos formais e salários), sendo um proxy de emprego adequado para a análise.

### 1.2 PIB Municipal — IBGE
- **Fonte:** IBGE — Produto Interno Bruto dos Municípios
- **URL:** https://www.ibge.gov.br/estatisticas/economicas/contas-nacionais/9088-produto-interno-bruto-dos-municipios.html
- **Arquivo:** `Dados/PIB_Municipal_2002_2023_painel_IG.xlsx`
- **Período:** 2002–2023
- **Cobertura:** 5.570 municípios
- **Variáveis selecionadas:**
  - PIB per capita (R$)
  - PIB total (R$ milhões)
  - Valor Adicionado Agropecuário (R$ mil)
  - Valor Adicionado Industrial (R$ mil)
  - Valor Adicionado de Serviços (R$ mil)

### 1.3 Indicações Geográficas — INPI + MAPA
- **Fonte 1:** Instituto Nacional da Propriedade Industrial (INPI)
- **URL INPI:** https://www.gov.br/inpi/pt-br/servicos/indicacoes-geograficas/lista-das-ig-concedidas
- **Arquivo 1:** `Dados/IGs_Brasil_INPI_x_DataSebrae.xlsx`
- **Fonte 2:** Ministério da Agricultura, Pecuária e Abastecimento (MAPA)
- **URL MAPA:** https://www.gov.br/agricultura/pt-br/assuntos/indicacao-geografica
- **Arquivo 2:** `Dados/IGs- tabela MAPA.xlsx`
- **Selecionadas:** IGs de **café** (87 municípios, 7 IGs)
- **Variáveis:** Município, UF, nome da IG, ano de concessão

---

## 2. DADOS BAIXADOS AUTOMATICAMENTE EM 17/06/2026

### 2.1 Exportações de Café por Município — ComexStat (MDIC)

- **Fonte:** Ministério do Desenvolvimento, Indústria, Comércio e Serviços (MDIC)
- **Sistema:** Balança Comercial Brasileira — ComexStat
- **URL base de download:** `https://balanca.economia.gov.br/balanca/bd/comexstat-bd/mun/`
- **Arquivos originais baixados:**

| Arquivo | Tamanho | Status |
|---------|---------|--------|
| EXP_2013_MUN.csv | 35 MB | ✅ Baixado |
| EXP_2014_MUN.csv | 36 MB | ✅ Baixado |
| EXP_2015_MUN.csv | 36 MB | ✅ Baixado |
| EXP_2016_MUN.csv | 37 MB | ✅ Baixado |
| EXP_2017_MUN.csv | 38 MB | ✅ Baixado |
| EXP_2018_MUN.csv | 39 MB | ✅ Baixado |
| EXP_2019_MUN.csv | 49 MB | ✅ Baixado |
| EXP_2020_MUN.csv | 47 MB | ✅ Baixado |
| EXP_2021_MUN.csv | 52 MB | ✅ Baixado |
| EXP_2022_MUN.csv | 52 MB | ✅ Baixado |
| EXP_2023_MUN.csv | 54 MB | ✅ Baixado |
| TABELAS_AUXILIARES.xlsx | 5,3 MB | ✅ Baixado |

- **Localização:** `Dados/ComexStat_Raw/`

#### Critério de Seleção dos Dados de Exportação:
- **Produto selecionado:** SH4 = **0901** (Café, mesmo torrado ou descafeinado; cascas e películas de café; sucedâneos do café que contenham café em qualquer proporção)
- **Período:** 2013–2023 (11 anos)
- **Agregação:** Soma anual por município de origem da exportação
  - `KG_LIQUIDO_TOTAL` = soma de todos os kg exportados no ano
  - `VL_FOB_USD_TOTAL` = soma do valor FOB em USD no ano
  - `preco_medio_usd_kg` = VL_FOB_USD_TOTAL / KG_LIQUIDO_TOTAL (a calcular)

#### Resumo dos Dados Selecionados:

| Ano | Nº Municípios Exportadores | Volume Total (mil kg) | Valor Total (USD milhões) |
|-----|---------------------------|----------------------|--------------------------|
| 2013 | 124 | 1.700.174 | 4.596 |
| 2014 | 138 | 1.987.863 | 6.052 |
| 2015 | 139 | 2.006.521 | 5.565 |
| 2016 | 150 | 1.825.958 | 4.856 |
| 2017 | 156 | 1.649.592 | 4.613 |
| 2018 | 184 | 1.828.877 | 4.372 |
| 2019 | 212 | 2.232.813 | 4.585 |
| 2020 | 226 | 2.379.069 | 4.996 |
| 2021 | 221 | 2.288.336 | 5.833 |
| 2022 | 221 | 2.135.408 | 8.542 |
| 2023 | 242 | 2.121.037 | 7.351 |

- **Arquivo processado:** `Dados/ComexStat_Cafe_Municipios.csv`

#### Estrutura do arquivo processado:
```
CO_ANO  : Ano (2013–2023)
CO_MUN  : Código do município (ComexStat, 7 dígitos)
SG_UF_MUN : Sigla do estado
KG_LIQUIDO_TOTAL : Peso líquido total exportado (kg)
VL_FOB_USD_TOTAL : Valor FOB total exportado (USD)
```

#### Observação importante sobre o código de município:
O campo `CO_MUN` do ComexStat utiliza uma codificação própria.
A correspondência com o código IBGE (6 dígitos) está na planilha
`Dados/ComexStat_Raw/TABELAS_AUXILIARES.xlsx` → aba "UF_MUN".
O script R de integração (Script 10) realiza o de-para automaticamente.

---

## 3. DADOS NÃO OBTIDOS — LIMITAÇÕES

### 3.1 Emprego Formal (RAIS) — Contagem bruta
- **Fonte:** Ministério do Trabalho e Emprego (MTE) — RAIS
- **Motivo da não coleta:** Arquivos de microdados muito grandes (>1 GB por ano)
- **Alternativa adotada:** Uso do `ifdm_emprego_renda` como proxy de emprego
  - Este subíndice é calculado pelo FIRJAN com base nos dados da RAIS
  - Captura tanto taxa de emprego quanto nível salarial
- **Como obter futuramente:** 
  - FTP: ftp://ftp.mtps.gov.br/pdet/microdados/
  - Portal PDET: https://bi.mte.gov.br/bgcaged/
  - Pacote R: `basedosdados` (tabela: br_me_rais.microdados_vinculos)

### 3.2 Turismo
- **Variável:** Empregos no turismo (usada por Medeiros et al. 2021)
- **Motivo da não coleta:** Requer RAIS filtrada por setor (CNAE 5500 e similares)
- **Status:** Não incluída nesta versão do artigo

---

## 4. REFERÊNCIA METODOLÓGICA

Os dados de exportação seguem a nomenclatura da **NCM (Nomenclatura Comum do Mercosul)**, 
que para café corresponde ao capítulo SH 09, especificamente:

- **SH4 = 0901**: Café (torrado ou não, descafeinado ou não)
  - 090111: Café não torrado, não descafeinado
  - 090112: Café não torrado, descafeinado  
  - 090121: Café torrado, não descafeinado
  - 090122: Café torrado, descafeinado
  - 090190: Outros (cascas, sucedâneos)

**Decisão metodológica:** Selecionamos o nível SH4 (4 dígitos) para capturar 
todas as formas de café exportado, em linha com Medeiros et al. (2021).

---

*Gerado automaticamente em 17/06/2026*
