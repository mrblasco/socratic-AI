#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import logging
import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
from dotenv import load_dotenv
from openai import OpenAI
from sentence_transformers import SentenceTransformer, util
from tqdm import tqdm


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")
load_dotenv()

logger = logging.getLogger(__name__)

@dataclass(frozen=True)
class Config:
    """Runtime configuration for dialogue evaluation."""

    openai_model: str = "gpt-4o"
    embedding_model: str = "all-MiniLM-L6-v2"
    default_prompt: Path = Path(
        "analysis/prompts/evaluate_pedagogical.txt"
    )


# ---------------------------------------------------------------------------
# I/O helpers
# ---------------------------------------------------------------------------

def load_json(path: Path) -> Any:
    """Load JSON from a file."""
    try:
        with path.open("r", encoding="utf-8") as file:
            return json.load(file)
    except FileNotFoundError:
        raise FileNotFoundError(f"Input file not found: {path}")
    except json.JSONDecodeError as exc:
        raise ValueError(f"Invalid JSON in {path}: {exc}") from exc


def save_json(data: Any, path: Path) -> None:
    """Save data as formatted JSON."""
    path.parent.mkdir(parents=True, exist_ok=True)

    with path.open("w", encoding="utf-8") as file:
        json.dump(data, file, indent=2, ensure_ascii=False)

    logger.info("Results saved to %s", path)


def load_prompt(path: Path) -> str:
    """Load a prompt template from disk."""
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        raise FileNotFoundError(f"Prompt file not found: {path}")


# ---------------------------------------------------------------------------
# Evaluator
# ---------------------------------------------------------------------------

class DialogueEvaluator:
    """Evaluate teacher-student dialogues."""

    def __init__(
        self,
        config: Config,
        openai_client: OpenAI | None = None,
    ) -> None:
        self.config = config

        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key and openai_client is None:
            raise RuntimeError(
                "OPENAI_API_KEY environment variable is not set."
            )

        self.client = openai_client or OpenAI(api_key=api_key)

        logger.info(
            "Loading embedding model: %s",
            config.embedding_model,
        )
        self.embedding_model = SentenceTransformer(
            config.embedding_model
        )

    def compute_coherence(
        self,
        dialogue: list[dict[str, Any]],
    ) -> float | None:
        """Compute mean cosine similarity between consecutive utterances."""
        utterances = [
            turn["utterance"]
            for turn in dialogue
            if isinstance(turn, dict) and "utterance" in turn
        ]

        if len(utterances) < 2:
            return None

        embeddings = self.embedding_model.encode(
            utterances,
            convert_to_tensor=True,
        )

        similarities = [
            util.cos_sim(
                embeddings[i],
                embeddings[i + 1],
            ).item()
            for i in range(len(embeddings) - 1)
        ]

        return float(np.mean(similarities))

    def evaluate_pedagogical(
        self,
        dialogue: list[dict[str, Any]],
        prompt_template: str,
    ) -> dict[str, Any]:
        """Evaluate the pedagogical value of a dialogue using OpenAI."""
        dialogue_text = "\n".join(
            f"{turn['speaker']}: {turn['utterance']}"
            for turn in dialogue
        )

        try:
            prompt = prompt_template.format(
                dialogue_text=dialogue_text,
            )
        except KeyError as exc:
            raise ValueError(
                f"Prompt template contains an unknown variable: {exc}"
            ) from exc

        response = self.client.responses.create(
            model=self.config.openai_model,
            instructions="You are an educational evaluator.",
            input=prompt,
        )

        output = response.output_text.strip()

        try:
            parsed = json.loads(output)

            if not isinstance(parsed, dict):
                return {
                    "error": "Expected JSON object",
                    "raw_output": output,
                }

            return parsed

        except json.JSONDecodeError as exc:
            logger.warning(
                "OpenAI returned invalid JSON: %s",
                exc,
            )

            return {
                "error": str(exc),
                "raw_output": output,
            }

    def evaluate_dialogue(
        self,
        dialogue: dict[str, Any],
        prompt_template: str,
    ) -> dict[str, Any]:
        """Evaluate a single dialogue."""
        dialogue_id = dialogue.get("dialogue_id")
        context = dialogue.get("context")

        if not dialogue_id:
            raise ValueError("Dialogue is missing 'dialogue_id'.")

        if not isinstance(context, list):
            raise ValueError(
                f"Dialogue {dialogue_id!r} is missing a valid 'context' list."
            )

        coherence = self.compute_coherence(context)

        pedagogical = self.evaluate_pedagogical(
            context,
            prompt_template,
        )

        return {
            "dialogue_id": dialogue_id,
            "evaluation": {
                "dialogue_quality": {
                    "coherence": coherence,
                },
                "pedagogical_value": pedagogical,
            },
        }

    def evaluate_all(
        self,
        dialogues: list[dict[str, Any]],
        prompt_template: str,
        limit: int | None = None,
    ) -> list[dict[str, Any]]:
        """Evaluate all dialogues."""
        if limit is not None:
            dialogues = dialogues[:limit]

        results: list[dict[str, Any]] = []

        for dialogue in tqdm(
            dialogues,
            desc="Evaluating dialogues",
        ):
            try:
                result = self.evaluate_dialogue(
                    dialogue,
                    prompt_template,
                )
                results.append(result)

            except Exception as exc:
                dialogue_id = dialogue.get(
                    "dialogue_id",
                    "<unknown>",
                )

                logger.exception(
                    "Failed to evaluate dialogue %s",
                    dialogue_id,
                )

                results.append(
                    {
                        "dialogue_id": dialogue_id,
                        "evaluation": {
                            "error": str(exc),
                        },
                    }
                )

        return results

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="dialogue-eval",
        description="Evaluate teacher-student dialogues.",
    )

    subparsers = parser.add_subparsers(
        dest="command",
        required=True,
    )

    evaluate_parser = subparsers.add_parser(
        "evaluate",
        help="Evaluate dialogues from a JSON file.",
    )

    evaluate_parser.add_argument(
        "--input",
        "-i",
        type=Path,
        required=True,
        help="Path to input JSON file.",
    )

    evaluate_parser.add_argument(
        "--output",
        "-o",
        type=Path,
        default=Path("dialogue_evaluation_results.json"),
        help="Path to output JSON file.",
    )

    evaluate_parser.add_argument(
        "--prompt",
        "-p",
        type=Path,
        help="Path to evaluation prompt template.",
    )

    evaluate_parser.add_argument(
        "--model",
        default="gpt-4o",
        help="OpenAI model to use.",
    )

    evaluate_parser.add_argument(
        "--embedding-model",
        default="all-MiniLM-L6-v2",
        help="SentenceTransformer model to use.",
    )

    evaluate_parser.add_argument(
        "--limit",
        type=int,
        help="Evaluate only the first N dialogues.",
    )

    evaluate_parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose logging.",
    )

    return parser


def run_evaluate(args: argparse.Namespace) -> int:
    """Execute the evaluate command."""
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s: %(message)s",
    )

    if not args.input.exists():
        logger.error("Input file does not exist: %s", args.input)
        return 1

    if args.limit is not None and args.limit <= 0:
        logger.error("--limit must be greater than zero.")
        return 1

    prompt_path = args.prompt or Path(
        "analysis/prompts/evaluate_pedagogical.txt"
    )

    if not prompt_path.exists():
        logger.error("Prompt file does not exist: %s", prompt_path)
        return 1

    try:
        dialogues = load_json(args.input)

        if not isinstance(dialogues, list):
            logger.error(
                "Input JSON must contain a list of dialogues."
            )
            return 1

        prompt_template = load_prompt(prompt_path)

        config = Config(
            openai_model=args.model,
            embedding_model=args.embedding_model,
        )

        evaluator = DialogueEvaluator(config)

        results = evaluator.evaluate_all(
            dialogues=dialogues,
            prompt_template=prompt_template,
            limit=args.limit,
        )

        save_json(results, args.output)

    except Exception as exc:
        logger.error("%s", exc)
        return 1

    return 0


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.command == "evaluate":
        return run_evaluate(args)

    parser.error(f"Unknown command: {args.command}")
    return 1

if __name__ == "__main__":
    sys.exit(main())
