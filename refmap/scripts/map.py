# %%
def parse_alignment(alignment_string):
    """Parse the alignment string into structured deletion and insertion data."""
    alignment_start, alignment_end, deletions_part, insertions_part = (
        alignment_string.strip().split("\t")
    )

    # Extract deletion ranges
    deletion_ranges = [(1, int(alignment_start)-1), (int(alignment_end), 200000)]
    if deletions_part:
        for part in deletions_part.split(","):
            part = part.strip()
            if "-" in part:
                start_end = part.split("-")
                try:
                    start, end = int(start_end[0]), int(start_end[1])
                    deletion_ranges.append((start, end))
                except ValueError:
                    print(f"Invalid deletion range: {part}")
            else:
                try:
                    pos = int(part)
                    deletion_ranges.append((pos, pos))
                except ValueError:
                    print(f"Invalid deletion position: {part}")

    # Extract insertions
    insertions = {}
    if insertions_part:
        # First split by commas
        for item in insertions_part.split(","):
            parts = item.split(":", 1)  # Split only on the first colon
            try:
                pos, seq = parts
                insertions[int(pos)] = len(seq)
            except ValueError:
                print(f"Invalid insertion format: {item}")

    return deletion_ranges, insertions


# %%


def create_position_mapping(deletion_ranges, insertion_ranges):
    """Create a mapping from target positions to query positions."""
    deletions = list(sorted(deletion_ranges, key=lambda x: x[0]))
    insertions = list(sorted(insertion_ranges.items(), key=lambda x: x[0]))

    del_idx = 0
    ins_idx = 0
    mapping = {}
    i = 1
    offset = 0
    while i < 200000:
        if del_idx < len(deletions) and deletions[del_idx][0] == i:
            start, end = deletions[del_idx]
            j = i + offset
            for k in range(end - start + 1):
                mapping[i] = j
                i += 1
            offset -= end - start + 1
            del_idx += 1
            continue

        if ins_idx < len(insertions) and insertions[ins_idx][0] == i:
            pos, length = insertions[ins_idx]
            mapping[i] = j
            ins_idx += 1
            offset += length
            continue

        # If not in deletion or insertion, just map directly
        mapping[i] = i + offset
        i += 1
    return mapping



def map_coordinates(alignment_string):
    """Parse alignment and return target to query position mapping."""
    deletion_ranges, insertions = parse_alignment(alignment_string)
    return create_position_mapping(deletion_ranges, insertions)


def map_coordinates_from_file(file_path):
    """Read alignment strings from a file and return their mappings."""
    # Use second line
    # Read file, then look at second line
    with open(file_path, "r") as file:
        lines = file.readlines()
        alignment_string = lines[1].strip()
        return map_coordinates(alignment_string)


def write_mapping_to_file(mapping, output_file):
    """Write the mapping to a file."""
    with open(output_file, "w") as file:
        for target_pos, query_pos in mapping.items():
            file.write(f"{target_pos}\t{query_pos}\n")


# %%
# mapping = map_coordinates_from_file("refmap/results/filtered.tsv")
# %%
# write_mapping_to_file(mapping, "refmap/results/mapping.txt")

# %%
# allow to be called directly with args
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Map coordinates from alignment string."
    )
    parser.add_argument(
        "-i", "--input", type=str, help="Input file containing alignment string."
    )
    parser.add_argument(
        "-o", "--output", type=str, help="Output file to write mapping."
    )
    args = parser.parse_args()

    mapping = map_coordinates_from_file(args.input)

    if args.output:
        write_mapping_to_file(mapping, args.output)
    else:
        print(mapping)
