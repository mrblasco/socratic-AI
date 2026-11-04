#!/usr/bin/env python3
"""Rate student-AI dialogues with one or more LLMs.

Design goals (see ../docs/revision_plan.md, Part B):
  * provider-agnostic (OpenAI, Anthropic) so a rater panel can be built;
  * schema-constrained output, so no free-text JSON parsing;
  * every raw response is saved, with model, prompt hash and settings;
  * resumable: existing valid ratings are skipped;
  * `--student-only` rates the student's turns alone (blinding check);
  * `collect` merges all runs into one long CSV for reliability analysis.

Usage (from llm_annotation/):
  uv run python src/eval_dialogue.py rate \\
      --prompt prompts/rate_student.txt --dimensions ... \\
      --model openai:gpt-4o --reps 3 --out ratings/<run>
  uv run python src/eval_dialogue.py collect --out ratings/<run> --csv output/<run>_long.csv
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import logging
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Literal

from dotenv import load_dotenv
from pydantic import ValidationError, create_model
from tqdm import tqdm

load_dotenv()
logger = logging.getLogger(__name__)

DEFAULT_PROMPT = Path("prompts/rate_student.txt")
DEFAULT_INPUT = Path("input/dialogues.json")
DEFAULT_OUT = Path("ratings/holdout")
DEFAULT_DIMENSIONS = (
    "accuracy",
    "depth",
    "engagement",
    "clarity",
    "learning_outcome",
    "reasoning_quality",
    "question_asking",
    "knowledge_building",
    "effort_seriousness",
)
SYSTEM = "You are an educational evaluator."
MAX_ATTEMPTS = 5


# ---------------------------------------------------------------------------
# Schema
# ---------------------------------------------------------------------------

def build_schema(dimensions: tuple[str, ...], optional: tuple[str, ...] = (),
                 binary: tuple[str, ...] = ()):
    """Pydantic model: each dimension is an integer 1-5 (0/1 if binary; null if optional)."""
    def scale(d: str):
        base = Literal[0, 1] if d in binary else Literal[1, 2, 3, 4, 5]
        return (base | None) if d in optional else base

    fields: dict[str, Any] = {d: (scale(d), ...) for d in dimensions}
    fields["comments"] = (str, ...)
    return create_model("Rating", **fields)


# ---------------------------------------------------------------------------
# Providers
# ---------------------------------------------------------------------------

class Rater:
    """One model behind one provider API."""

    def __init__(self, spec: str, temperature: float | None, schema) -> None:
        if ":" not in spec:
            raise ValueError("--model must look like 'provider:model-id'")
        self.provider, self.model = spec.split(":", 1)
        self.temperature = temperature
        self.schema = schema
        self.spec = spec

        if self.provider == "openai":
            from openai import OpenAI

            self.client = OpenAI()
        elif self.provider == "anthropic":
            import anthropic

            self.client = anthropic.Anthropic()
        else:
            raise ValueError(f"Unknown provider: {self.provider}")

    def rate(self, prompt: str) -> tuple[dict[str, Any], dict[str, Any]]:
        """Return (parsed rating, metadata). Raises on failure."""
        if self.provider == "openai":
            return self._openai(prompt)
        return self._anthropic(prompt)

    def _openai(self, prompt):
        kwargs: dict[str, Any] = dict(
            model=self.model,
            instructions=SYSTEM,
            input=prompt,
            text_format=self.schema,
        )
        if self.temperature is not None:
            kwargs["temperature"] = self.temperature
        try:
            resp = self.client.responses.parse(**kwargs)
        except Exception as exc:  # some models reject temperature
            if "temperature" in str(exc) and "temperature" in kwargs:
                logger.warning("%s rejects temperature; retrying without", self.spec)
                kwargs.pop("temperature")
                self.temperature = None
                resp = self.client.responses.parse(**kwargs)
            else:
                raise
        parsed = resp.output_parsed
        if parsed is None:
            raise ValueError(f"No parsed output: {resp.output_text[:200]}")
        usage = resp.usage.model_dump() if resp.usage else {}
        return parsed.model_dump(), {"usage": usage, "model_returned": resp.model}

    def _anthropic(self, prompt):
        schema = self.schema.model_json_schema()
        schema["additionalProperties"] = False
        kwargs: dict[str, Any] = dict(
            model=self.model,
            max_tokens=1500,
            system=SYSTEM,
            messages=[{"role": "user", "content": prompt}],
            output_config={"format": {"type": "json_schema", "schema": schema}},
        )
        if self.temperature is not None:
            kwargs["temperature"] = self.temperature
        try:
            resp = self.client.messages.create(**kwargs)
        except Exception as exc:
            if "temperature" in str(exc) and "temperature" in kwargs:
                logger.warning("%s rejects temperature; retrying without", self.spec)
                kwargs.pop("temperature")
                self.temperature = None
                resp = self.client.messages.create(**kwargs)
            else:
                raise
        text = "".join(b.text for b in resp.content if b.type == "text")
        parsed = self.schema.model_validate_json(text)
        usage = resp.usage.model_dump() if resp.usage else {}
        return parsed.model_dump(), {"usage": usage, "model_returned": resp.model}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def sha(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:12]


def git_commit() -> str | None:
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"], text=True, stderr=subprocess.DEVNULL
        ).strip()
    except Exception:
        return None


def load_dialogues(path: Path) -> list[dict[str, Any]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise ValueError("Input JSON must be a list of dialogues")
    ids = [d.get("dialogue_id") for d in data]
    if None in ids or len(set(ids)) != len(ids):
        raise ValueError("dialogue_id missing or duplicated")
    for d in data:
        if not isinstance(d.get("context"), list) or not d["context"]:
            raise ValueError(f"Dialogue {d['dialogue_id']} has no context")
    return data


def dialogue_text(context: list[dict[str, Any]], student_only: bool) -> str:
    turns = [t for t in context if not student_only or t["speaker"] == "user"]
    return "\n".join(f"{t['speaker']}: {t['utterance']}" for t in turns)


def run_dir(out_root: Path, spec: str, prompt: Path, student_only: bool) -> Path:
    mode = "student" if student_only else "full"
    name = spec.replace(":", "_").replace("/", "-")
    return out_root / f"{prompt.stem}__{name}__{mode}"


def result_path(rdir: Path, chat_id: Any, rep: int) -> Path:
    return rdir / f"{chat_id}__rep{rep}.json"


def is_valid(path: Path, schema) -> bool:
    if not path.exists():
        return False
    try:
        schema.model_validate(json.loads(path.read_text())["rating"])
        return True
    except (ValueError, KeyError, ValidationError):
        return False


def rate_one(rater, prompt_template, dialogue, rep, rdir, student_only, meta):
    chat_id = dialogue["dialogue_id"]
    text = dialogue_text(dialogue["context"], student_only)
    prompt = prompt_template.format(dialogue_text=text)

    last_exc: Exception | None = None
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            rating, extra = rater.rate(prompt)
            record = {
                "chat_id": chat_id,
                "rep": rep,
                **meta,
                "temperature": rater.temperature,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "attempts": attempt,
                "rating": rating,
                **extra,
            }
            result_path(rdir, chat_id, rep).write_text(
                json.dumps(record, indent=2, ensure_ascii=False), encoding="utf-8"
            )
            return chat_id, rep, None
        except Exception as exc:
            last_exc = exc
            status = getattr(exc, "status_code", None)
            if status is not None and 400 <= status < 500 and status not in (408, 409, 429):
                logger.error("chat %s rep %s: non-retryable %s: %s", chat_id, rep, status, exc)
                break
            wait = 2**attempt
            logger.warning("chat %s rep %s attempt %s failed: %s", chat_id, rep, attempt, exc)
            time.sleep(wait)
    return chat_id, rep, str(last_exc)


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def cmd_rate(args) -> int:
    prompt_template = args.prompt.read_text(encoding="utf-8")
    dimensions = tuple(args.dimensions.split(","))
    optional = tuple(x for x in args.optional.split(",") if x)
    binary = tuple(x for x in args.binary.split(",") if x)
    schema = build_schema(dimensions, optional, binary)
    dialogues = load_dialogues(args.input)
    if args.ids_file:
        keep = set(json.loads(args.ids_file.read_text()))
        dialogues = [d for d in dialogues if d["dialogue_id"] in keep]
    if args.limit:
        dialogues = dialogues[: args.limit]

    rater = Rater(args.model, args.temperature, schema)
    rdir = run_dir(args.out, args.model, args.prompt, args.student_only)
    rdir.mkdir(parents=True, exist_ok=True)

    meta = {
        "provider": rater.provider,
        "model": rater.model,
        "student_only": args.student_only,
        "prompt_file": str(args.prompt),
        "prompt_hash": sha(prompt_template),
        "dimensions": list(dimensions),
        "optional_dimensions": list(optional),
        "binary_dimensions": list(binary),
        "ids_file": str(args.ids_file) if args.ids_file else None,
    }
    manifest_path = rdir / "manifest.json"
    if manifest_path.exists():
        old = json.loads(manifest_path.read_text())
        if old.get("prompt_hash") != meta["prompt_hash"] and not args.force:
            logger.error(
                "Prompt changed since this run was started (%s -> %s). "
                "Use a new --out or pass --force.",
                old.get("prompt_hash"), meta["prompt_hash"],
            )
            return 1
    manifest_path.write_text(
        json.dumps({**meta, "git_commit": git_commit(), "input": str(args.input),
                    "n_dialogues": len(dialogues), "reps": args.reps,
                    "started": datetime.now(timezone.utc).isoformat()}, indent=2)
    )

    jobs = [
        (d, rep)
        for rep in range(1, args.reps + 1)
        for d in dialogues
        if not is_valid(result_path(rdir, d["dialogue_id"], rep), schema)
    ]
    logger.info("%s: %d to rate (%d already done)", args.model, len(jobs),
                len(dialogues) * args.reps - len(jobs))

    failures = []
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = [
            pool.submit(rate_one, rater, prompt_template, d, rep, rdir,
                        args.student_only, meta)
            for d, rep in jobs
        ]
        for fut in tqdm(as_completed(futures), total=len(futures), desc=args.model):
            chat_id, rep, err = fut.result()
            if err:
                failures.append({"chat_id": chat_id, "rep": rep, "error": err})

    if failures:
        (rdir / "failures.json").write_text(json.dumps(failures, indent=2))
        logger.error("%d ratings failed; see %s", len(failures), rdir / "failures.json")
        return 2
    (rdir / "failures.json").unlink(missing_ok=True)
    return 0


def cmd_collect(args) -> int:
    rows = []
    for path in sorted(args.out.glob("*/*__rep*.json")):
        rec = json.loads(path.read_text())
        rater = path.parent.name
        for dim, score in rec["rating"].items():
            if dim == "comments":
                continue
            rows.append({
                "chat_id": rec["chat_id"], "rater": rater, "provider": rec["provider"],
                "model": rec["model"], "student_only": rec["student_only"],
                "rep": rec["rep"], "prompt_hash": rec["prompt_hash"],
                "dimension": dim, "score": "" if score is None else score,
            })
    if not rows:
        logger.error("No ratings found under %s", args.out)
        return 1
    args.csv.parent.mkdir(parents=True, exist_ok=True)
    with args.csv.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    logger.info("Wrote %d rows to %s", len(rows), args.csv)
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="eval_dialogue", description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="command", required=True)

    r = sub.add_parser("rate", help="Rate dialogues with one model.")
    r.add_argument("--input", "-i", type=Path, default=DEFAULT_INPUT)
    r.add_argument("--model", required=True, help="provider:model-id, e.g. openai:gpt-4o")
    r.add_argument("--prompt", type=Path, default=DEFAULT_PROMPT)
    r.add_argument("--dimensions", default=",".join(DEFAULT_DIMENSIONS),
                   help="Comma-separated rating fields the prompt asks for.")
    r.add_argument("--optional", default="",
                   help="Comma-separated dimensions that may be null (not applicable).")
    r.add_argument("--binary", default="",
                   help="Comma-separated dimensions scored 0/1 instead of 1-5.")
    r.add_argument("--ids-file", type=Path, help="JSON list of dialogue_ids to rate.")
    r.add_argument("--out", type=Path, default=DEFAULT_OUT)
    r.add_argument("--reps", type=int, default=1, help="Repeats per dialogue.")
    r.add_argument("--temperature", type=float, default=0.0)
    r.add_argument("--workers", type=int, default=4)
    r.add_argument("--limit", type=int, help="Only the first N dialogues (testing).")
    r.add_argument("--student-only", action="store_true",
                   help="Show the rater only the student's turns.")
    r.add_argument("--force", action="store_true",
                   help="Continue a run even if the prompt hash changed.")
    r.set_defaults(func=cmd_rate)

    c = sub.add_parser("collect", help="Merge all saved ratings into one long CSV.")
    c.add_argument("--out", type=Path, default=DEFAULT_OUT)
    c.add_argument("--csv", type=Path, default=Path("output/llm_ratings_holdout_long.csv"))
    c.set_defaults(func=cmd_collect)
    return p


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    args = build_parser().parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
