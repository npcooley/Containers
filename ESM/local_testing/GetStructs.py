###### -- generate pdb files for AA sequences ---------------------------------

import sys
import warnings
import torch
import time
import psutil
# this is creating FutureWarnings
with warnings.catch_warnings():
    warnings.simplefilter("ignore", category=FutureWarning)
    from esm.models.esm3 import ESM3
    from esm.sdk.api import ESM3InferenceClient, ESMProtein, GenerationConfig

import os
import argparse
from Bio import SeqIO
import re


# import tqdm
try:
    from tqdm import tqdm
except ImportError:
    tqdm = lambda x: x  # Fallback if tqdm is not installed

def sanitize_id(seq_id):
    return re.sub(r'\W+', '_', seq_id)

def main(fasta_file, outdir, show_progress, model_name, device):
  
  # untar the model to the right place, and logging in won't be necessary
  # it looks for the named model in $HOME/.cache/<whatever>, that's where
  # currently "esm3_sm_open_v1" is the model i know?
  # model: ESM3InferenceClient = ESM3.from_pretrained("esm3_sm_open_v1").to("cpu")
  # Initialize model
  # this line also spits out FutureWarnings
  model: ESM3InferenceClient = ESM3.from_pretrained(model_name).to(device)
  records = list(SeqIO.parse(fasta_file, "fasta"))

  for record in records:
    # set the prompt
    prompt = str(record.seq)
    
    # load it into the ESM object
    protein = ESMProtein(sequence=prompt)
    
    # cuda memory starting points
    if device == "cuda":
      torch.cuda.reset_peak_memory_stats()
      start_mem = torch.cuda.memory_allocated()
      start_peak = torch.cuda.max_memory_allocated()
    elif device == "cpu":
      process = psutil.Process(os.getpid())
      start_mem = process.memory_info().rss
    
    # grab timings...
    start_time = time.time()
    try:
      protein = model.generate(protein, GenerationConfig(track="structure", num_steps=8))
    except torch.cuda.OutOfMemoryError as e:
      print(f"Skipping {record.id}")
    end_time = time.time()
    if device == "cuda":
      end_mem = torch.cuda.memory_allocated()
      peak_mem = torch.cuda.max_memory_allocated()
      # memory meta data in MiB:
      mem_used = (end_mem - start_mem) / (1024 ** 2)
      peak_used = (peak_mem - start_mem) / (1024 ** 2)
    elif device == "cpu":
      end_mem = process.memory_info().rss
      cpu_memory_used = (end_mem - start_mem) / (1024 ** 2)
    
    # write out the pdb file
    pdb_filename = f"{sanitize_id(record.id)}.pdb"
    protein.to_pdb(pdb_filename)
    
    # write out the metadata
    mean_plddt = protein.plddt.mean().item()
    ptm_score = protein.ptm.item()
    aa_count = len(prompt)
    prediction_time = end_time - start_time
    score_out = f"{sanitize_id(record.id)}.txt"
    with open(score_out, "w") as f:
      f.write(f"Mean pLDDT: {mean_plddt:.4f}\n")
      f.write(f"pTM score: {ptm_score:.4f}\n")
      f.write(f"seq len: {aa_count}\n")
      f.write(f"time: {prediction_time:.2f}\n")
      f.write(f"device: {device}\n")
      if device == "cuda":
        f.write(f"GPU memory used: {mem_used:.2f} MiB\n")
        f.write(f"GPU peak memory during generation: {peak_used:.2f} MiB\n")
      elif device == "cpu":
        f.write(f"CPU memory used: {cpu_memory_used:.2f} MiB\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Predict protein structures from a FASTA file.")
    parser.add_argument("fasta", help="Path to the FASTA file containing protein sequences.")
    parser.add_argument("--outdir", default="predicted_structures", help="Output directory for PDB files.")
    parser.add_argument("--progress", action="store_true", help="Show a progress bar during prediction.")
    parser.add_argument("--model", required=True, help="ESM3 model name, e.g., esm3_sm_open_v1.")
    parser.add_argument("--device", choices=["cpu", "cuda"], default="cpu", help="Device to run model on.")

    args = parser.parse_args()
    main(args.fasta, args.outdir, args.progress, args.model, args.device)




