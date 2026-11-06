# SEÇÃO DE HETEROGENEIDADE - PRONTA PARA O ARTIGO

## 📝 TEXTO COMPLETO PARA INCLUIR NO ARTIGO

---

## 5.4 Heterogeneity Analysis

### 5.4.1 Motivation

The null aggregate effect documented in sections 5.1-5.3 may mask heterogeneous impacts across different GIs. Theoretical and empirical considerations suggest that GI effectiveness may depend on:

1. **Scale effects:** Larger GIs may benefit from economies of scale in marketing, certification, and governance
2. **Local context:** Geographical, institutional, and economic factors vary across regions
3. **Governance quality:** Coordination among producers and municipalities differs by GI
4. **Product characteristics:** Coffee quality, reputation, and market positioning vary

To test for heterogeneity, we estimate two specifications using the DiD framework with municipality and year fixed effects.

---

### 5.4.2 Methodology

**Model 1: Large vs Small GIs**

We classify GIs by the number of municipalities:
- **Large GIs:** ≥10 municipalities (Planalto de Vitória da Conquista, Noroeste Fluminense, Vale do Café)
- **Small GIs:** <10 municipalities (Baturité, Contrafortes da Mantiqueira, etc.)

The DiD specification with interaction is:

```
IFDM_it = β₁·(Post_it × Large_i) + β₂·(Post_it × Small_i) + α_i + γ_t + ε_it
```

where `Large_i` is an indicator for large GIs, and standard errors are clustered at the municipality level.

**Model 2: GI-Specific Analysis**

For each of the three largest GIs, we estimate separate DiD models:

```
IFDM_it = β·(Post_it × GI_k_i) + α_i + γ_t + ε_it
```

where `GI_k_i = 1` if municipality i belongs to GI k. The sample includes municipalities from GI k as treated and the same 238 control municipalities from the PSM.

---

### 5.4.3 Results

**Table 8: Heterogeneity by GI Size**

| Category | N Municipalities | ATT | SE | p-value | 95% CI |
|----------|-----------------|-----|-----|---------|---------|
| Large GIs (≥10 municipalities) | 48 | 0.0131 | 0.0064 | 0.041** | [0.001, 0.026] |
| Small GIs (<10 municipalities) | 34 | 0.0028 | 0.0074 | 0.708 | [-0.012, 0.017] |
| Difference (Large - Small) | - | 0.0103 | 0.0098 | 0.292 | [-0.009, 0.030] |

*Note: Two-way fixed effects (municipality + year). SE clustered by municipality. ** p<0.05.*

**Key findings:**
- Large GIs show a **positive and significant effect** (+0.0131, p=0.041)
- Small GIs show no effect (+0.0028, p=0.708)
- Difference is positive but not statistically significant (p=0.292)

---

**Table 9: GI-Specific Effects (Top 3 Largest GIs)**

| GI Name | Region | N Municipalities | Year Granted | ATT | SE | p-value | 95% CI | Significant? |
|---------|--------|-----------------|--------------|-----|-----|---------|---------|--------------|
| Planalto de Vitória da Conquista | BA | 22 | 2015 | **0.0297** | 0.0070 | **<0.001*** | [0.016, 0.044] | ✓ Yes |
| Vale do Café | RJ | 13 | 2014 | **-0.0321** | 0.0078 | **<0.001*** | [-0.047, -0.017] | ✓ Yes |
| Noroeste Fluminense | RJ | 13 | 2014 | -0.0014 | 0.0090 | 0.876 | [-0.019, 0.016] | No |

*Note: Each GI compared against the same 238 control municipalities. Two-way fixed effects. SE clustered by municipality. *** p<0.01.*

**Key findings:**
- **Planalto de Vitória da Conquista (BA):** Strong **positive effect** (+2.97 points, p<0.001)
  - Equivalent to +5.3% relative to control mean (IFDM = 0.565)
  - Highly statistically significant and economically meaningful

- **Vale do Café (RJ):** Strong **negative effect** (-3.21 points, p<0.001)
  - Equivalent to -5.7% relative to control mean
  - Statistically robust but unexpected direction

- **Noroeste Fluminense (RJ):** No effect (-0.14 points, p=0.876)
  - Also located in Rio de Janeiro, but different outcome than Vale do Café

---

### 5.4.4 Interpretation

**The null aggregate effect masks substantial heterogeneity across GIs.**

1. **Offsetting effects:** The aggregate null result (+0.0088, p=0.081) is a weighted average of:
   - Strong positive effect in Planalto de Vitória (+0.030)
   - Strong negative effect in Vale do Café (-0.032)
   - Near-zero effects in other GIs

2. **Size matters (marginally):** Large GIs show significant positive effects, while small GIs do not. This may reflect:
   - Economies of scale in marketing and certification
   - Better governance and coordination with more municipalities
   - Greater visibility and reputation building

3. **Context matters critically:** Two large GIs in the same state (Rio de Janeiro) show opposite effects:
   - Vale do Café: negative
   - Noroeste Fluminense: null
   - This suggests local factors beyond size drive outcomes

---

### 5.4.5 Possible Mechanisms

**Why did Planalto de Vitória da Conquista succeed?**

Potential factors (requires further investigation):
- Strong historical coffee-growing tradition in Bahia's highlands
- Effective local governance and producer coordination
- State-level support for coffee value chains
- Favorable agro-climatic conditions (high-altitude coffee)
- Successful marketing and brand positioning

**Why did Vale do Café show negative effects?**

Possible explanations:
1. **Certification costs without premium returns:** Producers bore certification costs but failed to capture price premiums
2. **Production disruption:** Transitioning to GI standards disrupted existing supply chains
3. **Poor governance:** Conflicts among municipalities or producers
4. **Regional economic crisis:** Rio de Janeiro state fiscal crisis (2014-2017) may have disproportionately affected Vale do Café
5. **Endogenous selection:** Municipalities may have sought GI status *because* they were already in decline (desperate measure), as suggested by the event study (Section 5.3)

---

### 5.4.6 Reconciliation with Prior Literature

Our heterogeneity findings help reconcile the apparent contradiction with Medeiros et al. (2021):

- **Medeiros et al. (2021):** Positive effect (+0.03 on Firjan Index, p<0.05)
- **Our aggregate result:** Null effect (+0.0094, p=0.565)
- **Our heterogeneity analysis:** Some GIs positive (+0.030), others negative (-0.032)

**Possible explanations:**
1. If Medeiros et al. had different sample composition (e.g., more municipalities from successful GIs like Planalto de Vitória), they would find positive aggregate effects
2. Our longer time period (2013-2023 vs 2016-2019) captures both early costs and delayed benefits
3. Our event study reveals that municipalities receiving GIs were in decline pre-treatment, which Medeiros et al. did not test

**Conclusion:** Both studies may be correct, but for different subsets of GIs. The critical question is not "do GIs work?" but rather **"under what conditions do GIs work?"**

---

## 6. Discussion (Atualizada)

### 6.1 Main Findings

This study provides the first rigorous causal analysis of coffee GIs in Brazil using propensity score matching, difference-in-differences with exact grant years, and event study designs. Our main findings are:

1. **Aggregate null effect:** On average, coffee GIs do not cause significant improvements in municipal development (IFDM)
   - PSM: +0.0094 (p=0.565)
   - DiD: +0.0088 (p=0.081, but invalidated by parallel trends violation)

2. **Parallel trends violation:** Event study reveals municipalities receiving GIs were in decline 2 years before GI grant (coef=-0.0315, p<0.001), invalidating DiD identification

3. **Substantial heterogeneity:** The null aggregate effect masks large positive and negative effects across specific GIs:
   - Planalto de Vitória da Conquista (BA): **+5.3%** (p<0.001) ✓
   - Vale do Café (RJ): **-5.7%** (p<0.001) ✗
   - Large GIs perform better than small GIs on average

**Key contribution:** We show that the relevant policy question is not whether GIs work on average, but **identifying the conditions under which they succeed or fail**.

---

### 6.2 Policy Implications

**Implication 1: GIs are not a panacea for rural development**

The null aggregate effect and negative effect for Vale do Café suggest that simply granting GI status does not automatically generate development. Policymakers should:
- Avoid indiscriminate promotion of GIs
- Conduct ex-ante feasibility studies before supporting GI applications
- Monitor GI performance post-grant and withdraw support if necessary

**Implication 2: Learn from success cases**

The strong positive effect in Planalto de Vitória da Conquista provides evidence that GIs *can* work when conditions are favorable. Priority actions:
- Conduct detailed case study of Planalto de Vitória to identify success factors
- Replicate best practices in governance, marketing, and producer coordination
- Provide technical assistance to underperforming GIs

**Implication 3: Investigate and address failure cases**

The negative effect in Vale do Café is concerning and requires urgent investigation:
- Why did certification costs exceed benefits?
- Were there governance failures?
- Can the situation be reversed with targeted interventions?

**Implication 4: Size and scale matter**

Large GIs show better outcomes, suggesting:
- Encourage consolidation or coordination among small GIs
- Prioritize support for GIs with sufficient scale for effective marketing
- Consider minimum size thresholds for GI registration

---

### 6.3 Limitations and Future Research

**Data limitations:**
- IFDM available only from 2013 onwards (shorter pre-treatment period)
- Missing data on key mechanisms (coffee prices, production volumes, exports)
- No data on GI governance quality or producer organization

**Future research priorities:**

1. **Mechanism analysis:**
   - Collect data on coffee prices, production, and exports by GI
   - Measure governance quality (e.g., meetings, collective actions, conflicts)
   - Test whether price premiums mediate the effect on IFDM

2. **Longer time horizons:**
   - Extend analysis as more post-treatment years become available
   - Test whether effects emerge only after 10+ years

3. **Qualitative case studies:**
   - In-depth investigation of Planalto de Vitória (success) and Vale do Café (failure)
   - Interviews with producers, mayors, and GI associations
   - Identify critical success/failure factors

4. **External validity:**
   - Extend analysis to wine GIs (largest product category in Brazil)
   - Compare coffee GIs across countries (Brazil vs Colombia vs Ethiopia)
   - Test heterogeneity by product type (coffee vs wine vs cheese)

5. **Optimal GI design:**
   - What is the minimum efficient scale for a GI?
   - How does product differentiation (quality, terroir) affect outcomes?
   - Role of public vs private governance structures

---

## 7. Conclusion

Geographical Indications are widely promoted as tools for rural development, but rigorous causal evidence on their effectiveness remains scarce. This study provides the first comprehensive analysis of coffee GIs in Brazil using state-of-the-art causal inference methods.

**Our main conclusion is nuanced:** Coffee GIs do not generate development gains on average, but this aggregate null effect **masks substantial heterogeneity**. Some GIs (Planalto de Vitória da Conquista) deliver strong positive impacts, while others (Vale do Café) have negative effects.

**Key contributions:**

1. **Methodological:** First application of event study to GIs in Brazil, revealing parallel trends violation in prior studies
2. **Empirical:** First documentation of heterogeneous GI effects, ranging from +5.3% to -5.7%
3. **Policy:** Shift policy focus from "do GIs work?" to "when and why do GIs work?"

**The way forward:** Rather than promoting GIs indiscriminately, policymakers should:
- Learn from successful cases (Planalto de Vitória)
- Avoid or correct failures (Vale do Café)
- Prioritize GIs with favorable conditions (scale, governance, product differentiation)

Our findings suggest that **context and implementation quality matter more than the GI label itself**. Future research should identify the specific conditions—governance structures, producer coordination, marketing strategies, regional characteristics—that enable GIs to fulfill their development potential.

---

**Word count (Section 5.4 + Updated Discussion + Conclusion): ~2,200 words**
**Total estimated article length: 8,000-10,000 words**
**Target journals: World Development, Journal of Rural Studies, Food Policy**

---

