"""
Standard typer CLI with high-level parallelization
Called as follows:
python3 scripts/deduplicate.py \
--sequences {input.sequences} \
--output {output}
"""
import itertools
import multiprocessing
from functools import partial

import typer
from Bio import SeqIO


def informative_sites(sequence: str) -> int:
    """
    Count number of ACGT characters in a sequence
    """
    return sum([1 for c in sequence if c in "ACGT"])

def identical(seq1: str, seq2: str, info_sites: list) -> bool:
    """
    Check if two sequences are identical (up to Ns)
    Short circuit at the first difference
    """
    for i in info_sites:
        c1 = seq1[i]
        c2 = seq2[i]
        if c1 != c2 and c2 in "ACGT" and c1 in "ACGT":
            return False
    return True

def composition_per_site(sequences) -> list:
    """
    Compute the composition of each site in a list of sequences
    """
    length = len(sequences[0]["seq"])
    composition = [{} for _ in range(length)]
    for sequence in sequences:
        for i, c in enumerate(sequence["seq"]):
            if c not in composition[i]:
                composition[i][c] = 0
            # Increment the count for that character
            composition[i][c] += 1
    return composition

def mismatch_prob_per_site(composition: list) -> list:
    """
    Compute the mismatch probability of each site in a list of sequences
    For each character, probability of selecting it * probability of selecting a mismatching character
    """
    result = []
    seqs = sum(composition[0].values())
    for site in composition:
        values = [val / seqs for char, val in site.items() if char in "ACGT"]
        prob = 0
        for i, value in enumerate(values):
            for j, other_value in enumerate(values):
                if i < j:
                    prob += value * other_value
        result.append(prob)
    return result

def informative_indexes_sorted_by_entropy(composition: list) -> list:
    """
    List of indexes of informative sites sorted by entropy
    Uninformative sites are not included
    """
    site_information = {i: info for i, info in enumerate(mismatch_prob_per_site(composition)) if info > 0}
    site_information = sorted(site_information.items(), key=lambda x: x[1], reverse=True)
    return [x[0] for x in site_information]

def process_batch(batch_indices, all_sequences, info_sites):
    """
    Process a batch of ying sequences against all potential duplicates
    Returns a list of IDs to remove
    """
    duplicates = []

    for ying_idx in batch_indices:
        ying_seq = all_sequences[ying_idx]

        # Compare with all sequences that come after this one
        for yang_idx in range(ying_idx + 1, len(all_sequences)):
            yang_seq = all_sequences[yang_idx]

            if identical(ying_seq["seq"], yang_seq["seq"], info_sites):
                print(f"Removing {yang_seq['id']} as identical to {ying_seq['id']}")
                duplicates.append(yang_seq["id"])

    return duplicates

def deduplicate(input: str, output: str, num_processes: int = 10):
    """
    Deduplicate sequences in a file
    Args:
        sequences: path to sequences file
        output: path to output file
        num_processes: number of cores to use
    """
    with open(input, "r") as f:
        sequences = [
            {
                "id": record.id,
                "seq": str(record.seq),
                "number_informative_sites": informative_sites(str(record.seq)),
            }
            for record in itertools.islice(SeqIO.parse(f, "fasta"), 0, None)
        ]
    sequences = sorted(sequences, key=lambda x: x["number_informative_sites"], reverse=True)
    composition = composition_per_site(sequences)
    info_sites = informative_indexes_sorted_by_entropy(composition)

    # Divide work among processes - each process takes a batch of ying sequences
    num_sequences = len(sequences)
    batch_size = max(1, num_sequences // (num_processes * 5))  # Smaller batches for better load balancing

    # Create batches of indices
    batches = []
    for i in range(0, num_sequences-1, batch_size):  # -1 because the last sequence has nothing to compare against
        end = min(i + batch_size, num_sequences-1)
        batches.append(list(range(i, end)))

    # Process batches in parallel
    pool = multiprocessing.Pool(processes=num_processes)
    process_func = partial(process_batch, all_sequences=sequences, info_sites=info_sites)
    results = pool.map(process_func, batches)

    # Clean up
    pool.close()
    pool.join()

    # Combine results
    dup_list = {dup for batch_result in results for dup in batch_result}

    # Write output
    with open(output, "w") as f:
        for dup in dup_list:
            f.write(f"{dup}\n")

if __name__ == "__main__":
    typer.run(deduplicate)
