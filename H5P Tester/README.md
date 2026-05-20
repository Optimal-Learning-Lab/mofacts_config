# H5P Tester Items

This folder contains a five-item MoFaCTS assessment system for final H5P integration testing.

The current target is the final H5P assessment contract, not a button-trial workaround and not an external-display smoke file. Each stimulus uses `display.h5p` with `sourceType: "self-hosted"`, a stable `contentId`, package metadata, `completionPolicy: "xapi-completed"`, and `scorePolicy: "record-only"`. The assessment template marks the trials as H5P trials rather than native MoFaCTS button or text tests.

The assessment template currently uses:

```text
0,h,h,0
```

The intended meaning is:

- first position `0`: use stimulus offset 0 in the selected cluster;
- second position `h`: H5P owns the interaction surface;
- third position `h`: H5P-defined assessment event/result, not a native MoFaCTS `t` test response;
- fourth position `0`: schedule location offset.

The app does not yet support `h,h` assessment templates or self-hosted H5P package playback. This folder is therefore a forward implementation target for the final behavior. If a temporary passive-display smoke test is needed before final support lands, use a separate scratch fixture. Do not commit an external-embed or native-response fallback shape as the canonical H5P tester.

## Files

- `H5P_Tester_Items_TDF.json`: one assessment unit with five trials.
- `H5P_Tester_Items_stims.json`: five stimulus clusters, one self-hosted H5P final-test target per cluster.
- `multiple-choice-713.h5p`: source package for the Multiple Choice item.
- `fill-in-the-blanks-837.h5p`: source package for the Fill in the Blanks item.
- `drag-and-drop-712.h5p`: source package for the Drag and Drop item.
- `drag-the-words-1399.h5p`: source package for the Drag the Words item.
- `true-false-question-34806.h5p`: source package for the True/False item.

## Demonstration Types

1. Multiple Choice: atomic choice event.
2. Fill in the Blanks: multi-blank text-entry event candidates.
3. Drag and Drop Matching: multi-part placement events.
4. Drag the Words: text-token placement events.
5. True/False Question: atomic binary judgment.

## Normalization Targets

The drag-and-drop matching item is the main multi-row history target. A later H5P normalizer/interpreter should be able to convert one H5P activity attempt into an ordered sequence of history-write candidates, one per placement, preserving:

- dragged item id/label;
- target/drop-zone id/label;
- correctness for that placement;
- event index within the H5P batch;
- event timestamp;
- latency since the previous H5P event;
- parent H5P content id and batch id.

The other items provide contrast for atomic, text-part, token-placement, and binary-result normalization.

## Required H5P Package Targets

The stimulus file references five local package files and five stable content ids:

- `multiple-choice-713.h5p` -> `h5p-tester-multichoice-001`
- `fill-in-the-blanks-837.h5p` -> `h5p-tester-fill-blanks-001`
- `drag-and-drop-712.h5p` -> `h5p-tester-drag-drop-matching-001`
- `drag-the-words-1399.h5p` -> `h5p-tester-drag-words-001`
- `true-false-question-34806.h5p` -> `h5p-tester-true-false-001`

When self-hosted H5P package support is implemented, these package filenames should be importable into same-origin H5P content records using the listed content ids. The architecture plan defines what MoFaCTS should be able to read from the H5P runtime's own event data and then produce through the event-ingestion bridge, widget normalizers, H5P assessment recorder, and history writer.

This is the canonical final-test target. A separate external-embed fixture may be created later for Phase 1 passive display testing, but this folder should represent the real event-producing H5P assessment path.
