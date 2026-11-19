#!/usr/bin/env python3
"""Write a copy of a long ratings CSV without the chats listed in a JSON ID file.

Used to drop the 12 dialogues whose v1 IDs merged a Brussels and a Seville chat.
Usage: uv run python src/drop_chats.py --csv IN.csv --drop input/colliding_chat_ids.json --out OUT.csv
"""
import argparse
import json
from pathlib import Path

import pandas as pd

ap = argparse.ArgumentParser()
ap.add_argument("--csv", type=Path, required=True)
ap.add_argument("--drop", type=Path, required=True)
ap.add_argument("--out", type=Path, required=True)
args = ap.parse_args()

df = pd.read_csv(args.csv)
drop = set(json.loads(args.drop.read_text()))
kept = df[~df["chat_id"].isin(drop)]
kept.to_csv(args.out, index=False)
print(f"{df['chat_id'].nunique()} chats -> {kept['chat_id'].nunique()} chats ({args.out})")
