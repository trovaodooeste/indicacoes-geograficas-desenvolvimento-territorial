# Scripts de Análise - Indicações Geográficas e Desenvolvimento Regional

Este diretório contém os scripts R para análise do impacto das IGs no desenvolvimento territorial dos municípios brasileiros.

---

## 📋 Ordem de Execução

Execute os scripts na seguinte ordem:

### **Fase 1: Exploração dos Dados**

1. **`01_explorar_IGs.R`**
   - Carrega e explora dados de Indicações Geográficas
   - Classifica produtos (café, vinho, queijos, frutas, etc.)
   - Identifica municípios com IGs agrícolas
   - **Output**: `Resultados/IGs_agricolas.csv`

2. **`02_explorar_IFDM.R`**
   - Analisa Índice Firjan (2013-2023)
   - Calcula estatísticas descritivas
   - Gera gráficos de evolução temporal
   - **Output**: `Resultados/resumo_IFDM.txt`, gráficos

3. **`03_explorar_PIB.R`**
   - Explora PIB Municipal (2002-2023)
   - Foca em PIB agropecuário (importante para matching!)
   - Calcula PIB per capita
   - **Output**: `Resultados/resumo_PIB.txt`, gráficos

---

## ⚙️ Configuração Inicial

### 1. Instalar Pacotes Necessários

Abra o RStudio e execute:

```r
# Pacotes principais
install.packages(c(
  "readxl",      # Ler arquivos Excel
  "dplyr",       # Manipulação de dados
  "tidyr",       # Organização de dados
  "stringr",     # Manipulação de strings
  "ggplot2"      # Gráficos
))

# Pacotes para PSM (instalar depois)
install.packages(c(
  "MatchIt",     # Propensity Score Matching
  "cobalt",      # Teste de balanceamento
  "lmtest",      # Testes estatísticos
  "sandwich"     # Erros robustos
))
```

### 2. Ajustar Diretório de Trabalho

**IMPORTANTE**: Em cada script, ajuste a linha:

```r
setwd("C:/Users/Trovao/Desktop/Artigo - Economia Regional")
```

Para o caminho correto no seu computador.

---

## 📁 Estrutura de Pastas Esperada

```
Artigo - Economia Regional/
├── Dados/
│   ├── IGs_Brasil_INPI_x_DataSebrae.xlsx
│   ├── IFDM_2013_2023_painel_tratado.xlsx
│   └── PIB_Municipal_2002_2023_painel_IG.xlsx
├── Scripts/
│   ├── 01_explorar_IGs.R
│   ├── 02_explorar_IFDM.R
│   └── 03_explorar_PIB.R
└── Resultados/          # ← Será criada automaticamente
    ├── IGs_agricolas.csv
    ├── resumo_IGs.txt
    ├── resumo_IFDM.txt
    └── evolucao_IFDM.png
```

---

## 🚀 Como Executar

### Opção 1: Executar Todos de Uma Vez

Crie um novo script `run_all.R`:

```r
source("Scripts/01_explorar_IGs.R")
source("Scripts/02_explorar_IFDM.R")
source("Scripts/03_explorar_PIB.R")
```

### Opção 2: Executar Individualmente

1. Abra o RStudio
2. Abra o script (ex: `01_explorar_IGs.R`)
3. Execute linha por linha (Ctrl + Enter) ou todo o script (Ctrl + Shift + Enter)
4. Verifique os resultados na pasta `Resultados/`

---

## ⚠️ Possíveis Problemas

### Erro: "cannot open file 'Dados/...xlsx'"

**Solução**: Verifique se:
- O caminho do `setwd()` está correto
- Os arquivos Excel estão na pasta `Dados/`
- O nome dos arquivos está exato (incluindo maiúsculas/minúsculas)

### Erro: "could not find function..."

**Solução**: Instale o pacote faltante:
```r
install.packages("nome_do_pacote")
```

### Arquivo Excel muito grande (PIB_Municipal)

**Solução**:
- Tenha paciência, o arquivo tem 15MB
- Pode demorar 10-30 segundos para carregar
- Se der erro de memória, aumente limite: `memory.limit(size = 10000)`

---

## 📊 Próximos Scripts (em desenvolvimento)

4. **Integração de Dados** - Juntar IGs + IFDM + PIB
5. **Estatísticas Descritivas** - Tratados vs Controle
6. **Propensity Score Matching** - Estimação do PSM
7. **Cálculo do ATT** - Efeito das IGs
8. **Análise de Robustez** - Validação dos resultados

---

## 📝 Notas Importantes

1. **Não modifique os arquivos originais** na pasta `Dados/`
2. **Sempre verifique os outputs** na pasta `Resultados/`
3. **Leia os resumos `.txt`** antes de prosseguir para o próximo script
4. **Anote qualquer problema** encontrado para discutirmos

---

## 🆘 Precisa de Ajuda?

Se encontrar erros ou tiver dúvidas:
1. Anote a mensagem de erro completa
2. Verifique qual linha do código deu erro
3. Compartilhe comigo para ajustarmos

---

**Última atualização**: Junho 2026
**Autores**: Ariana e Wellington
