"""
Standard typer CLI

Called as follows:

python3 scripts/deduplicate.py \\
--sequences {input.sequences} \\
--output {output}

"""

import typer
from Bio import SeqIO
import itertools
import pyllist


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
        values = [val/seqs for char, val in site.items() if char in "ACGT"]
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
    site_information = { i: info for i, info in enumerate(mismatch_prob_per_site(composition)) if info > 0 }
    site_information = sorted(site_information.items(), key=lambda x: x[1], reverse=True)
    return [x[0] for x in site_information]



def deduplicate(input: str, output: str):
    """
    Deduplicate sequences in a file

    Args:
        sequences: path to sequences file
        output: path to output file
    """
    with open(input, "r") as f:
        sequences = [
            {   "id": record.id,
                "seq": str(record.seq),
                "number_informative_sites": informative_sites(str(record.seq)),
            }
            for record in itertools.islice(SeqIO.parse(f, "fasta"), 0, None)
        ]

    sequences = sorted(sequences, key=lambda x: x["number_informative_sites"], reverse=True)

    composition = composition_per_site(sequences)

    info_sites = informative_indexes_sorted_by_entropy(composition)

    dll = pyllist.dllist(sequences)

    dup_list = []

    ying = dll.first
    while ying is not None:
        yang = ying.next
        while yang is not None:
            if identical(str(ying.value["seq"]),str(yang.value["seq"]), info_sites):
                print(f"Removing {yang.value['id']} as identical to {ying.value['id']}")
                to_remove = yang
                dup_list.append(yang.value["id"])
                yang = yang.next
                dll.remove(to_remove)
            else:
                yang = yang.next
        ying = ying.next

    with open(output, "w") as f:
        for dup in dup_list:
            f.write(f"{dup}\n")


if __name__ == "__main__":
    # deduplicate("results/b1/masked.fasta", "data/deduplicated.fasta")
    typer.run(deduplicate)
