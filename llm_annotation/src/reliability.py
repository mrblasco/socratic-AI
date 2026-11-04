#!/usr/bin/env python3
"""Inter- and intra-rater reliability for the LLM rating panel.

Reads the long CSV written by `eval_dialogue.py collect`. For each rubric
(prompt) and dimension reports:
  * intra-rater: Krippendorff's alpha (ordinal) across repeats, per model;
  * inter-rater: alpha across models, using each model's median over repeats;
  * mean absolute difference between the models' scores;
and writes the chats with the largest disagreement for manual reading.

Usage:
  uv run python src/reliability.py \\
      --csv output/llm_ratings_holdout_long.csv --out output/reliability_holdout
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd


def kripp_alpha_ordinal(matrix: np.ndarray) -> float:
    """Krippendorff's alpha, ordinal metric.

    matrix: raters x units, NaN for missing. Scores are integer categories.
    """
    values = np.unique(matrix[~np.isnan(matrix)])
    if len(values) < 2:
        return float("nan")
    idx = {v: i for i, v in enumerate(values)}
    k = len(values)
    o = np.zeros((k, k))
    for unit in matrix.T:
        vals = unit[~np.isnan(unit)]
        m = len(vals)
        if m < 2:
            continue
        for i, a in enumerate(vals):
            for j, b in enumerate(vals):
                if i != j:
                    o[idx[a], idx[b]] += 1.0 / (m - 1)
    n_c = o.sum(axis=1)
    n = n_c.sum()
    if n <= 1:
        return float("nan")

    # ordinal distance: squared sum of marginals between categories
    delta = np.zeros((k, k))
    for c in range(k):
        for d in range(k):
            if c == d:
                continue
            lo, hi = min(c, d), max(c, d)
            s = n_c[lo:hi + 1].sum() - (n_c[lo] + n_c[hi]) / 2
            delta[c, d] = s**2
    d_o = (o * delta).sum() / n
    d_e = (np.outer(n_c, n_c) * delta).sum() / (n * (n - 1))
    return float(1 - d_o / d_e) if d_e > 0 else float("nan")


def label(csv_rater: str) -> tuple[str, str, str]:
    prompt, model, mode = csv_rater.split("__")
    return prompt, model, mode


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", type=Path, default=Path("output/llm_ratings_holdout_long.csv"))
    ap.add_argument("--out", type=Path, default=Path("output/reliability_holdout"))
    ap.add_argument("--top", type=int, default=20)
    args = ap.parse_args()

    df = pd.read_csv(args.csv)
    df["score"] = pd.to_numeric(df["score"], errors="coerce")
    df[["prompt", "model_id", "mode"]] = df["rater"].apply(lambda r: pd.Series(label(r)))
    args.out.mkdir(parents=True, exist_ok=True)

    rows = []
    for (prompt, mode, dim), g in df.groupby(["prompt", "mode", "dimension"]):
        row = {"prompt": prompt, "mode": mode, "dimension": dim}

        # intra-rater: repeats within model
        for model, gm in g.groupby("model_id"):
            wide = gm.pivot(index="chat_id", columns="rep", values="score")
            row[f"alpha_repeats[{model}]"] = kripp_alpha_ordinal(wide.to_numpy(float).T)

        # inter-rater: model medians over repeats
        med = g.groupby(["chat_id", "model_id"])["score"].median().unstack()
        row["alpha_between_models"] = kripp_alpha_ordinal(med.to_numpy(float).T)
        if med.shape[1] >= 2:
            a, b = med.iloc[:, 0], med.iloc[:, 1]
            row["mean_abs_diff"] = float((a - b).abs().mean())
            row["mean_diff(first-second)"] = float((a - b).mean())
            row["models"] = " vs ".join(med.columns)
        row["n_chats"] = int(med.dropna(how="all").shape[0])
        # binary items: percent agreement and Gwet's AC1 between the two raters
        if set(g["score"].dropna().unique()) <= {0, 1} and med.shape[1] == 2:
            ok = g.pivot_table(index="chat_id", columns="model_id", values="score",
                               aggfunc="first").dropna()
            x, y = ok.iloc[:, 0].to_numpy(), ok.iloc[:, 1].to_numpy()
            pa, p = (x == y).mean(), (x.mean() + y.mean()) / 2
            pe = 2 * p * (1 - p)
            row["pct_agree"] = float(pa * 100)
            row["ac1"] = float((pa - pe) / (1 - pe)) if pe < 1 else float("nan")
            row["prevalence"] = f"{x.mean():.2f}/{y.mean():.2f}"
        # rank correlation between the two raters
        if med.shape[1] == 2:
            row["spearman"] = float(med.iloc[:, 0].rank().corr(med.iloc[:, 1].rank()))
        row["share_na"] = float(g["score"].isna().mean())
        rows.append(row)

    out = pd.DataFrame(rows).sort_values(["prompt", "mode", "dimension"])
    out.to_csv(args.out / "reliability_table.csv", index=False)
    pd.set_option("display.width", 200, "display.max_columns", 20)
    print(out.round(2).to_string(index=False))

    # largest disagreements across models (per chat, summed over dimensions)
    med = (df.groupby(["prompt", "mode", "chat_id", "dimension", "model_id"])["score"]
             .median().unstack())
    if med.shape[1] >= 2:
        med["absdiff"] = (med.iloc[:, 0] - med.iloc[:, 1]).abs()
        worst = (med.reset_index().groupby(["prompt", "mode", "chat_id"])["absdiff"]
                 .sum().sort_values(ascending=False).head(args.top))
        worst.to_csv(args.out / "largest_disagreements.csv")
        print("\nLargest disagreements written to", args.out / "largest_disagreements.csv")


if __name__ == "__main__":
    main()
