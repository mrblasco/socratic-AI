import os
os.environ["TOKENIZERS_PARALLELISM"] = "false"

import json
from sentence_transformers import SentenceTransformer, util
import numpy as np
from openai import OpenAI
from tqdm import tqdm

from dotenv import load_dotenv
load_dotenv()

# --- Configuration ---

client = OpenAI(
    api_key=os.environ.get("OPENAI_API_KEY"),
)

model = SentenceTransformer('all-MiniLM-L6-v2')

def compute_coherence(dialogue):
    utterances = [turn['utterance'] for turn in dialogue]
    if len(utterances) < 2:
        return None
    embeddings = model.encode(utterances, convert_to_tensor=True)
    similarities = [util.cos_sim(embeddings[i], embeddings[i+1]).item() for i in range(len(embeddings)-1)]
    return float(np.mean(similarities))

def evaluate_pedagogical(dialogue, prompt_template=None):
    dialogue_text = "\n".join([f"{t['speaker']}: {t['utterance']}" for t in dialogue])

    if prompt_template is None:
        prompt_template = load_prompt("analysis/prompts/evaluate_pedagogical.txt")
    
    prompt = prompt_template.format(dialogue_text=dialogue_text)
    response = client.responses.create(
        model="gpt-4o",
        instructions="You are an educational evaluator.",
        input=prompt,
    )
    try:
        pedagogical_json = json.loads(response.output_text)
    except Exception as e:
        pedagogical_json = {"error": str(e), "raw_output": response.output_text}

    return pedagogical_json

def evaluate_dialogue(dialogue, prompt_template=None):
    coherence = compute_coherence(dialogue['context'])
    pedagogical = evaluate_pedagogical(dialogue['context'], prompt_template=prompt_template)
    result = {
        "dialogue_id": dialogue['dialogue_id'],
        "evaluation": {
            "dialogue_quality": {"coherence": coherence},
            "pedagogical_value": pedagogical
        }
    }
    return result

def evaluate_all(dialogues, prompt_template_path: str):
    prompt_template = load_prompt(prompt_template_path)
    results = []
    for d in tqdm(dialogues, desc="Evaluating dialogues"):
        result = evaluate_dialogue(d, prompt_template)
        results.append(result)
    return results

def load_dialogues(filename: str):
    with open(filename, "r") as f:
        dialogues = json.load(f)
    return dialogues

def save_results(results, filename="dialogue_evaluation_results.json"):
    with open(filename, "w") as f:
        json.dump(results, f, indent=2)
    print(f"✅ Results saved to {filename}")


def load_prompt(filename):
    with open(filename, "r") as f:
        return f.read()


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Evaluate teacher-student dialogues.")
    parser.add_argument("--input", type=str, help="Path to input JSON file containing dialogues")
    parser.add_argument("--output", type=str, help="Path to output JSON file")
    parser.add_argument("--prompt",type=str, help="Path to custom evaluation prompt template")
    args = parser.parse_args()

    dialogues = load_dialogues(args.input)
    results = evaluate_all(dialogues, args.prompt or "analysis/prompts/evaluate_pedagogical.txt")
    save_results(results, args.output or "dialogue_evaluation_results.json")
