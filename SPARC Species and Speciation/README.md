# SPARC Species and Speciation

## Current revision: October 16, 2026

The approved KC cleansing revision replaces the original 24 bundled targets and 95 required facets with 40 focused KCs and 19 diagnostic misconceptions. The existing dynamic-instruction-agent-v2 and dynamic-instruction-student-v2 controllers are retained. Examples instantiate KCs and remain supporting content; they are not separate targets. Cautions already represented by misconceptions are removed from KC requirements. The unsupported proof-from-matching-trees demand (M20) is removed. M17 now has the fact-rule corrective category.

## Files and use

- Agent sources are in this folder: `SPARC_Species_and_Speciation_agent_TDF.json` and matching `_agent_stims.json`. The current [agent upload ZIP](../SPARC_Species_and_Speciation_agent.zip) is at the repository root.
- Student sources are in this folder: `SPARC_Species_and_Speciation_student_TDF.json` and matching `_student_stims.json`. The current [student upload ZIP](../SPARC_Species_and_Speciation_student.zip) is at the repository root.
- [Complete English lesson review](Lesson%20review.html), including the complete KC and misconception inventory, original-to-revised mapping, and example content map.
- [KC cleansing review](KC%20cleansing%20review.html) records the same approved content revision.

The current JSON and the two root-level upload ZIPs are the canonical lesson packages, with agent-selected and student-selected controllers. Redundant archives have been removed. Current JSON and ZIP archives contain the existing localhost TDF identities for intentional replacement, not duplication. No grant or proposal files were changed.

## Learner experience and completion

One adaptive chapter unit in each condition covers 40 required KCs. Agent selection and the six existing student instructional choices are retained. The existing fresh-document centrality calculation selects S22, Hybrid speciation (mean outgoing similarity 0.687158), as the initial target in both conditions. Selection remains adaptive, not a fixed chapter sequence.

All 40 KCs must meet the inherited coverage threshold 0.8, with no active authored misconception at support 0.2. The separate 96-turn cap is unchanged. Reaching the cap is not mastery and its sufficiency for the revised inventory has not been measured. There are no cumulative required-facet checklists.

## Identity, library, and existing state

Existing TDF and page IDs are retained. KC identities use `dynamic.biology-species-speciation-hlw4e-ch21-002.kc.*`. On October 16 the old localhost package and its two lessons were deleted through the normal application method, as requested. That deletion also removed their 80 history rows. After the user extended the OpenRouter key limit, the cleaned package uploaded successfully. Both versions are now installed at revision 1 following deletion and fresh creation. No old scores are converted into revised KC scores.

The 112-entry shared instructional library, its content, embeddings, assets, exclusions, and references are preserved. Retrieval does not filter by KC or lesson identity. Component-type and question-response-format restrictions, cosine reuse cutoff 0.992, and question-repetition cutoff 0.88 are unchanged. Generation model and reasoning configuration are unchanged. The package's existing model field is retained; runtime provider settings remain owned by the application.

## Embedding-generated graph

Portable lesson JSON and current upload ZIPs contain no KC graph values. Upload generates the graph by embedding the 40 expectation statements with `google/gemini-embedding-001` and computing normalized cosine similarity with the existing shared implementation. The runtime graph contains 40 x 39 = 1560 directed non-self relationships; centrality is their mean outgoing strength. Package input cannot supply graph facts or an expectation relationship matrix, and downloads omit generated graph values. An embedding failure stops upload. The earlier parent-copy and fixed 0.1/0.6/0.9 graph was unauthorized and has been removed; plots and starting-target conclusions based on it are invalid.

Both uploaded conditions have identical generated graphs. There are 780 distinct pairs, 778 distinct similarities, and an observed range of 0.510327–0.838635. The highest display cutoff that leaves every node with at least one link is **0.714963**, retaining equality. It leaves 105 pairs and one connected component. Any higher cutoff isolates S15C, Subspecies, whose strongest link is to S02 at 0.714963. At 0.9 no links remain. This display cutoff changes no stored graph or selection parameter.

## Complete authored KCs

Fact, model, rule, fact-model, fact-rule, model-rule, and fact-model-rule are the existing seven categories. Model-rule represents a principle.

| KC | Authored statement | Category |
| --- | --- | --- |
| S01A | Species as biological groups. Explain how variation within species and differences between species produce recognizable morphological or genetic clusters. | model |
| S01B | Species change and split. Explain why evolving populations and the splitting of lineages make species boundaries difficult to define. | model |
| S02 | Biological species membership. Use actual or potential interbreeding that produces viable, fertile offspring, together with reproductive isolation from other groups, to identify biological species. | fact-rule |
| S03 | A shared species gene pool. Explain how reproduction and migration spread alleles within a species and how restricted gene exchange permits populations to diverge. | model |
| S04 | Selecting usable species evidence. Select species evidence suited to the organisms and observations available: reproductive evidence for living sexual populations, or morphological, molecular, ecological, or ancestry evidence for strictly asexual organisms, fossils, or other cases where reproductive testing is unavailable. | rule |
| S05A | Morphospecies identification. Use similarity in observable form to identify morphospecies. | fact-rule |
| S05B | Polymorphism. Recognize polymorphism as the occurrence of different phenotypes within one species. | fact |
| S05C | Cryptic species. Recognize cryptic species as distinct species whose organisms look similar. | fact |
| S06 | DNA barcode identification. Identify a specimen by matching a relevant DNA sequence to reference sequences associated with identified species. | fact-rule |
| S07 | Species maintained despite hybridization. Explain how selection against hybrids can maintain distinct species despite some genetic exchange. | model |
| S08A | Ecological niche. Describe an ecological niche as a species’ role and environmental and resource requirements. | fact |
| S08B | Ecological species identification. Use ecological requirements to distinguish lineages, relating ecological differences to competition for resources when niches overlap. | model-rule |
| S09 | Phylogenetic species identification. Use common ancestry, lineage membership, and shared lineage fate as evidence for a phylogenetic species grouping. | fact-rule |
| S10 | Timing of reproductive barriers. Classify a reproductive barrier as prezygotic when it acts before fertilization or postzygotic when it acts after fertilization. | fact-rule |
| S11A | Geographic isolation. Identify geographic isolation and explain how separation in space prevents reproductive encounters. | fact-model |
| S11B | Ecological isolation. Identify ecological isolation and explain how different habitat use separates reproductive encounters. | fact-model |
| S11C | Temporal isolation. Identify temporal isolation and explain how different reproductive times prevent reproductive encounters. | fact-model |
| S11D | Behavioral isolation. Identify behavioral isolation and explain how differences in courtship signals or responses prevent mating. | fact-model |
| S12A | Mechanical isolation. Identify mechanical isolation and explain how incompatible reproductive anatomy prevents mating. | fact-model |
| S12B | Gametic isolation. Identify gametic isolation and explain how incompatibility between gametes or reproductive recognition interactions prevents fertilization. | fact-model |
| S13A | Hybrid inviability. Identify hybrid inviability and explain how incompatible parental genetic contributions can prevent normal development. | fact-model |
| S13B | Hybrid sterility. Identify hybrid sterility and explain how chromosome-pairing incompatibilities can prevent a viable hybrid from producing functional gametes. | fact-model |
| S13C | Relatedness and genetic compatibility. Explain the chapter’s general relationship between closer genetic relatedness and less extreme reproductive incompatibility. | model |
| S14 | Reproductive costs and barrier timing. Explain how barriers before fertilization can avoid investment in embryos that would not produce fertile descendants. | model |
| S15A | Divergence leading to reproductive isolation. Explain how different mutations become fixed in separated populations, accumulating differences that can produce reproductive incompatibility. | model |
| S15B | Partial reproductive isolation. Recognize partial reproductive isolation as reduced hybrid viability or fertility between populations. | fact |
| S15C | Subspecies. Recognize subspecies as differentiated geographic forms within a species, sometimes designated by an additional scientific-name term. | fact |
| S16A | Allopatric and sympatric speciation. Classify speciation as allopatric or sympatric according to whether diverging populations were geographically separated or occupied the same area. | fact-rule |
| S16B | Dispersal and vicariance. Classify geographic separation as dispersal when organisms establish a distant population, or vicariance when a new barrier divides an existing population. | fact-rule |
| S17 | Peripatric speciation. Recognize a small peripheral population as a peripatric setting and explain how stronger drift and different selection pressures promote its divergence. | fact-model-rule |
| S18 | Adaptive radiation. Recognize rapid diversification from a common ancestor into ecologically different species and explain how ecological opportunity and population isolation promote it. | fact-model-rule |
| S19 | Co-speciation. Identify co-speciation and explain how splitting of a host lineage separates parasite populations that subsequently diverge. | fact-model |
| S20 | Disruptive selection and sympatric divergence. Explain how selection against intermediate hybrids can counter the homogenizing effect of gene flow and allow populations in the same area to diverge. | model |
| S21A | Inferring geographic speciation history. Evaluate a proposed speciation history using geographic separation and genetic relationships, considering the populations’ locations during divergence. | model-rule |
| S21B | Constraining speciation timing. Use the formation of a barrier or the age of an island to constrain a population’s possible history of separation or colonization. | rule |
| S22 | Hybrid speciation. Identify hybrid speciation from a viable, reproducing hybrid lineage that is reproductively isolated from parental species, and explain how a distinct ecological role can support its persistence. | model-rule |
| S23A | Auto- and allopolyploid origins. Classify a polyploid as autopolyploid when it originates within one species or allopolyploid when it originates through hybridization of different species. | fact-rule |
| S23B | Formation of a polyploid lineage. Explain how the joining of unreduced gametes can produce a polyploid lineage. | model |
| S23C | Genome doubling in plant evolution. Explain how the prevalence of even chromosome numbers supports a role for genome doubling in plant evolution. | model |
| S24 | Selection and speciation. Use the roles of drift and selection to explain how speciation can occur with or without natural selection and how selection can occur without speciation. | model-rule |

## Source and boundaries

Morris et al., Biology: How Life Works, fourth edition (2023), Chapter 21, printed pages 434–453: [publisher sample](https://prod-cat-files.macmillan.cloud/CMS/SampleChapters/402518043f7e6a04529ce12a085b196578ba59c4/2023-ml-morris-HLW4e-ch21_flipbook/index.html). Target statements are original paraphrases. No textbook pages, copied figures, or Achieve questions are redistributed. Mutation, selection, drift, fertilization, meiosis, chromosome sets, and nondisjunction remain supporting prior knowledge; their new chapter connections are the targets. Named chapter cases are supporting content rather than recall obligations.

## Verification and evidence

On October 16 the graph-input bypass and unused manual list/matrix helpers were removed from application code. The authoring schema no longer exposes relationship weights or provenance. Seventeen focused tests passed, along with full application typecheck and lint (zero errors; 28 existing warnings). A live package containing the complete old graph was rejected before lesson changes. Both successful uploads were read back: each has 40 nodes and 1560 directed relationships, matching stored centralities, unchanged approved 40 KCs and 19 misconceptions, and identical graphs across conditions. Both pass runtime document construction, working-memory construction, and fresh-document candidate selection. The shared instructional library remains at 112 records with an identical complete fingerprint.

The first replacement request was rejected with HTTP 403 before generation and incurred no embedding cost. The successful retry used two batches of 40 KC statement embeddings; each batch contained 6235 characters, with individual statements of 90–324 characters. A conservative $0.00531936 allowance, including maximum retries, is retained in the spending ledger because the upload path does not persist exact per-request cost. The conservative tracked test total is $24.381962795, leaving approximately $0.618 in the original $25 authorization. This local ledger is not a reconciliation of all cumulative usage on the provider key. Current status is recorded in [Replacement verification](Replacement%20verification.html). No instructional generation was needed for graph replacement. No release build, production/staging deployment, commit, or push was performed. Earlier run-through results in [Testing run-throughs](Testing%20run-throughs.md) describe the older 24-target version and do not establish completion of the revised lesson.

## KC progression

Both units set `sparcsession.startingKC` to `dynamic.biology-species-speciation-hlw4e-ch21-002.kc.s06` (DNA barcode identification). Upload generates an exact maximum-weight Hamiltonian path with this fixed starting endpoint from the full embedding-derived graph. Practice selects the first KC in that saved path below the existing coverage criterion, skipping incidentally mastered KCs. Misconception repair and instructional move selection are unchanged. Paths are server-generated and are not authored in these files.
