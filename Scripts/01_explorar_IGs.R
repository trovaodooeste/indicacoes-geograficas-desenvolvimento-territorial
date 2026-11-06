# ==============================================================================
# Script 01: Exploração das Indicações Geográficas Brasileiras
# Objetivo: Identificar municípios com IGs de café, vinho e outros produtos agrícolas
# Autores: Ariana e Wellington
# Data: Junho 2026
# ==============================================================================

# Limpar ambiente
rm(list = ls())

# Carregar pacotes necessários
if(!require(readxl)) install.packages("readxl")
if(!require(dplyr)) install.packages("dplyr")
if(!require(tidyr)) install.packages("tidyr")
if(!require(stringr)) install.packages("stringr")

library(readxl)
library(dplyr)
library(tidyr)
library(stringr)

# Definir diretório de trabalho
# AJUSTE O CAMINHO PARA O SEU COMPUTADOR!
setwd("C:/Users/Trovao/Desktop/Artigo - Economia Regional")

# ==============================================================================
# 1. CARREGAR DADOS DE IGs
# ==============================================================================

# Arquivo principal de IGs
igs <- read_excel("Dados/IGs_Brasil_INPI_x_DataSebrae.xlsx")

# Explorar estrutura
cat("\n=== ESTRUTURA DO DATASET DE IGs ===\n")
cat("Dimensões:", nrow(igs), "linhas x", ncol(igs), "colunas\n\n")

cat("Colunas disponíveis:\n")
print(names(igs))

cat("\n\nPrimeiras 10 linhas:\n")
print(head(igs, 10))

cat("\n\nResumo das variáveis:\n")
print(str(igs))

# ==============================================================================
# 2. CLASSIFICAR PRODUTOS POR CATEGORIA
# ==============================================================================

cat("\n\n=== CLASSIFICAÇÃO DAS IGs ===\n")

# Verificar se existe coluna de produto/tipo
# (ajustar conforme estrutura real do arquivo)

# Contar IGs totais
cat("\nTotal de IGs no Brasil:", nrow(igs), "\n")

# Se houver coluna de produto, fazer tabela de frequência
if("Produto" %in% names(igs)) {
  cat("\nIGs por tipo de produto:\n")
  print(table(igs$Produto))
}

# ==============================================================================
# 3. IDENTIFICAR PRODUTOS AGRÍCOLAS
# ==============================================================================

# Criar categorias baseadas no nome do produto
# (ajustar padrões conforme necessário)

cat("\n\n=== IDENTIFICAÇÃO DE PRODUTOS AGRÍCOLAS ===\n")

# Função para classificar produtos
classificar_produto <- function(nome_produto) {
  nome_lower <- tolower(nome_produto)

  case_when(
    str_detect(nome_lower, "café|coffee") ~ "Café",
    str_detect(nome_lower, "vinho|wine|espumante|uva") ~ "Vinho",
    str_detect(nome_lower, "queijo|cheese") ~ "Queijo",
    str_detect(nome_lower, "cachaça|aguardente") ~ "Cachaça",
    str_detect(nome_lower, "mel|própolis") ~ "Mel/Própolis",
    str_detect(nome_lower, "banana|laranja|manga|uva|fruta") ~ "Frutas",
    str_detect(nome_lower, "carne|linguiça|salame|presunto") ~ "Carnes/Embutidos",
    str_detect(nome_lower, "arroz|feijão|milho") ~ "Grãos",
    str_detect(nome_lower, "bordado|renda|artesanato") ~ "Artesanato",
    str_detect(nome_lower, "pedra|mármore|granito") ~ "Minerais",
    TRUE ~ "Outros"
  )
}

# Aplicar classificação (ajustar nome da coluna conforme arquivo)
# Assumindo que existe coluna "Nome" ou "Produto"
if("Nome" %in% names(igs)) {
  igs$Categoria <- classificar_produto(igs$Nome)
} else if("Produto" %in% names(igs)) {
  igs$Categoria <- classificar_produto(igs$Produto)
}

# Contar por categoria
if("Categoria" %in% names(igs)) {
  cat("\nIGs por Categoria:\n")
  categoria_count <- igs %>%
    count(Categoria) %>%
    arrange(desc(n))
  print(categoria_count)

  # Identificar produtos agrícolas
  produtos_agricolas <- c("Café", "Vinho", "Queijo", "Cachaça",
                          "Mel/Própolis", "Frutas", "Carnes/Embutidos", "Grãos")

  igs_agricolas <- igs %>%
    filter(Categoria %in% produtos_agricolas)

  cat("\n\nTotal de IGs AGRÍCOLAS:", nrow(igs_agricolas), "\n")
  cat("Total de IGs NÃO-AGRÍCOLAS:", nrow(igs) - nrow(igs_agricolas), "\n")
}

# ==============================================================================
# 4. MUNICÍPIOS COM IGs DE CAFÉ E VINHO
# ==============================================================================

cat("\n\n=== MUNICÍPIOS COM IGs DE CAFÉ ===\n")
if("Categoria" %in% names(igs)) {
  cafe <- igs %>% filter(Categoria == "Café")
  cat("IGs de Café:", nrow(cafe), "\n")
  if(nrow(cafe) > 0) {
    print(cafe %>% select(1:5))  # Mostrar primeiras 5 colunas
  }

  cat("\n\n=== MUNICÍPIOS COM IGs DE VINHO ===\n")
  vinho <- igs %>% filter(Categoria == "Vinho")
  cat("IGs de Vinho:", nrow(vinho), "\n")
  if(nrow(vinho) > 0) {
    print(vinho %>% select(1:5))
  }
}

# ==============================================================================
# 5. SALVAR RESULTADOS
# ==============================================================================

# Criar pasta de resultados
dir.create("Resultados", showWarnings = FALSE)

# Salvar classificação das IGs
if(exists("igs_agricolas")) {
  write.csv(igs_agricolas,
            "Resultados/IGs_agricolas.csv",
            row.names = FALSE,
            fileEncoding = "UTF-8")

  cat("\n\nArquivo salvo: Resultados/IGs_agricolas.csv\n")
}

# Salvar resumo
sink("Resultados/resumo_IGs.txt")
cat("=== RESUMO DAS INDICAÇÕES GEOGRÁFICAS NO BRASIL ===\n\n")
cat("Data da análise:", format(Sys.Date(), "%d/%m/%Y"), "\n\n")
cat("Total de IGs:", nrow(igs), "\n\n")
if(exists("categoria_count")) {
  cat("Distribuição por categoria:\n")
  print(categoria_count)
}
sink()

cat("\n\n✓ Exploração concluída!\n")
cat("Verifique a pasta 'Resultados' para os arquivos gerados.\n")
