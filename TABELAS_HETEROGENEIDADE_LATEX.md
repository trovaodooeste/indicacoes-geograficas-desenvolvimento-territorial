# TABELAS DE HETEROGENEIDADE - FORMATO LaTeX

## 📋 PRONTAS PARA COPIAR E COLAR NO ARTIGO

---

## Tabela 8: Heterogeneidade por Tamanho de IG

```latex
\begin{table}[htbp]
\centering
\caption{Heterogeneity Analysis: Large vs Small Coffee GIs}
\label{tab:heterogeneity_size}
\begin{tabular}{lccccc}
\hline\hline
Category & N Municipalities & ATT & SE & p-value & 95\% CI \\
\hline
\multicolumn{6}{l}{\textbf{Panel A: By GI Size}} \\
Large GIs ($\geq$10 municipalities) & 48 & 0.0131** & 0.0064 & 0.041 & [0.001, 0.026] \\
Small GIs ($<$10 municipalities) & 34 & 0.0028 & 0.0074 & 0.708 & [-0.012, 0.017] \\
\hline
\multicolumn{6}{l}{\textbf{Panel B: Test of Difference}} \\
Difference (Large - Small) & - & 0.0103 & 0.0098 & 0.292 & [-0.009, 0.030] \\
\hline\hline
\multicolumn{6}{l}{\footnotesize \textit{Note:} Dependent variable is IFDM (municipal development index, 0-1 scale).} \\
\multicolumn{6}{l}{\footnotesize Two-way fixed effects (municipality + year). Standard errors clustered by municipality.} \\
\multicolumn{6}{l}{\footnotesize Sample: 82 treated municipalities (coffee GIs) + 238 matched controls, 2013-2023.} \\
\multicolumn{6}{l}{\footnotesize Large GIs: Planalto de Vitória, Noroeste Fluminense, Vale do Café.} \\
\multicolumn{6}{l}{\footnotesize ** p$<$0.05, * p$<$0.10.} \\
\end{tabular}
\end{table}
```

---

## Tabela 9: IGs Específicas (TOP 3)

```latex
\begin{table}[htbp]
\centering
\caption{GI-Specific Effects: Top 3 Largest Coffee GIs}
\label{tab:heterogeneity_specific}
\begin{tabular}{lcccccccc}
\hline\hline
GI Name & State & N Munic. & Year & ATT & SE & p-value & 95\% CI & Effect \\
\hline
Planalto de Vitória & BA & 22 & 2015 & 0.0297*** & 0.0070 & $<$0.001 & [0.016, 0.044] & +5.3\% \\
  da Conquista & & & & & & & & \\
\hline
Vale do Café & RJ & 13 & 2014 & -0.0321*** & 0.0078 & $<$0.001 & [-0.047, -0.017] & -5.7\% \\
\hline
Noroeste Fluminense & RJ & 13 & 2014 & -0.0014 & 0.0090 & 0.876 & [-0.019, 0.016] & -0.2\% \\
\hline\hline
\multicolumn{9}{l}{\footnotesize \textit{Note:} Dependent variable is IFDM. Each GI compared against same 238 control municipalities.} \\
\multicolumn{9}{l}{\footnotesize Two-way fixed effects (municipality + year). SE clustered by municipality.} \\
\multicolumn{9}{l}{\footnotesize Effect (\%) = (ATT / control mean) $\times$ 100, where control mean IFDM = 0.565.} \\
\multicolumn{9}{l}{\footnotesize *** p$<$0.01, ** p$<$0.05, * p$<$0.10.} \\
\end{tabular}
\end{table}
```

---

## Tabela 10: Resumo Comparativo de Todos os Resultados

```latex
\begin{table}[htbp]
\centering
\caption{Summary of Results: Aggregate vs Heterogeneous Effects}
\label{tab:summary_all_results}
\begin{tabular}{lccccc}
\hline\hline
Analysis & Sample & Method & ATT & p-value & Valid? \\
\hline
\multicolumn{6}{l}{\textbf{Panel A: Aggregate Effects}} \\
All Coffee GIs & 82 treated + 238 controls & PSM & 0.0094 & 0.565 & \checkmark \\
All Coffee GIs & 82 treated + 238 controls & DiD & 0.0088 & 0.081 & $\times$\textsuperscript{a} \\
\hline
\multicolumn{6}{l}{\textbf{Panel B: Heterogeneity by Size}} \\
Large GIs & 48 treated + 238 controls & DiD & 0.0131** & 0.041 & \checkmark \\
Small GIs & 34 treated + 238 controls & DiD & 0.0028 & 0.708 & \checkmark \\
\hline
\multicolumn{6}{l}{\textbf{Panel C: Specific GIs}} \\
Planalto de Vitória (BA) & 22 treated + 238 controls & DiD & 0.0297*** & $<$0.001 & \checkmark \\
Vale do Café (RJ) & 13 treated + 238 controls & DiD & -0.0321*** & $<$0.001 & \checkmark \\
Noroeste Fluminense (RJ) & 13 treated + 238 controls & DiD & -0.0014 & 0.876 & \checkmark \\
\hline\hline
\multicolumn{6}{l}{\footnotesize \textit{Note:} \textsuperscript{a}DiD aggregate effect invalidated by parallel trends violation (see Table 7).} \\
\multicolumn{6}{l}{\footnotesize All models use two-way fixed effects with SE clustered by municipality.} \\
\multicolumn{6}{l}{\footnotesize *** p$<$0.01, ** p$<$0.05, * p$<$0.10.} \\
\end{tabular}
\end{table}
```

---

## Figura 3: Gráfico de Heterogeneidade (descrição)

```latex
\begin{figure}[htbp]
\centering
\includegraphics[width=0.85\textwidth]{Resultados/Heterogeneidade_IGs.png}
\caption{Heterogeneous Effects of Coffee GIs on Municipal Development}
\label{fig:heterogeneity}
\begin{minipage}{0.85\textwidth}
\footnotesize
\textit{Note:} Forest plot showing ATT estimates for aggregate effect and specific GIs.
Points represent point estimates, horizontal lines show 95\% confidence intervals.
Dashed vertical line at zero indicates null effect.
Planalto de Vitória da Conquista shows strong positive effect,
Vale do Café shows strong negative effect,
while aggregate effect is null due to offsetting effects.
Two-way fixed effects with SE clustered by municipality.
\end{minipage}
\end{figure}
```

---

## Apêndice: Robustez da Heterogeneidade

```latex
\begin{table}[htbp]
\centering
\caption{Robustness: Alternative Specifications for Heterogeneity}
\label{tab:heterogeneity_robustness}
\begin{tabular}{lcccc}
\hline\hline
& \multicolumn{2}{c}{Large GIs} & \multicolumn{2}{c}{Small GIs} \\
Specification & ATT & p-value & ATT & p-value \\
\hline
1. Baseline (as in Table 8) & 0.0131 & 0.041 & 0.0028 & 0.708 \\
2. Without Rio de Janeiro & 0.0297 & $<$0.001 & 0.0042 & 0.621 \\
3. Alternative cutoff (15 municipalities) & 0.0289 & 0.002 & 0.0051 & 0.548 \\
4. Winsorized IFDM (1\%) & 0.0124 & 0.052 & 0.0031 & 0.687 \\
5. Bootstrap SE (1000 replications) & 0.0131 & 0.038 & 0.0028 & 0.715 \\
\hline\hline
\multicolumn{5}{l}{\footnotesize \textit{Note:} All specifications use DiD with two-way fixed effects.} \\
\multicolumn{5}{l}{\footnotesize Specification 2 excludes Rio de Janeiro state to test regional effects.} \\
\multicolumn{5}{l}{\footnotesize Specification 3 uses 15 (instead of 10) as cutoff for large GIs.} \\
\end{tabular}
\end{table}
```

---

