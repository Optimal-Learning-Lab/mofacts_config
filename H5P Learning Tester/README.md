# H5P Learning Tester

This folder contains a five-cluster MoFaCTS learning-session example for H5P integration testing.

It reuses the same five self-hosted H5P package references as the sibling `H5P Tester` assessment example, but authors them as adaptive learning practice rather than an assessment schedule. Each H5P activity is placed in its own cluster, so each cluster acts as its own knowledge component.

The `.h5p` files are self-contained package assets: each one bundles its required H5P library folders, so a normal MoFaCTS package upload can install the libraries and content together without a separate deploy-time H5P seed step.

## Files

- `H5P_Learning_Tester_TDF.json`: one learning unit over clusters `0-4`.
- `H5P_Learning_Tester_stims.json`: five stimulus clusters, one H5P activity per cluster.
- `multiple-choice-713.h5p`: source package for the Multiple Choice item.
- `fill-in-the-blanks-837.h5p`: source package for the Fill in the Blanks item.
- `drag-and-drop-712.h5p`: source package for the Drag and Drop item.
- `drag-the-words-1399.h5p`: source package for the Drag the Words item.
- `true-false-question-34806.h5p`: source package for the True/False item.

## Required H5P Package Targets

- `multiple-choice-713.h5p` -> `h5p-tester-multichoice-001`
- `fill-in-the-blanks-837.h5p` -> `h5p-tester-fill-blanks-001`
- `drag-and-drop-712.h5p` -> `h5p-tester-drag-drop-matching-001`
- `drag-the-words-1399.h5p` -> `h5p-tester-drag-words-001`
- `true-false-question-34806.h5p` -> `h5p-tester-true-false-001`
