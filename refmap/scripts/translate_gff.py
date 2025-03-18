#%%
#!/usr/bin/env python3
# GFF adapter script
# Transfers qualifiers from source GFF to query GFF based on coordinate mappings

# Function to parse GFF file
def parse_gff(filename):
    features = {}
    with open(filename, 'r') as handle:
        for line in handle:
            # Skip comment lines for parsing, but don't discard them
            if line.startswith('#'):
                continue

            # Parse the GFF line
            fields = line.strip().split('\t')
            if len(fields) < 9:
                # Skip malformed lines for feature parsing
                continue

            seqid, source, feature_type, start, end, score, strand, phase, attributes = fields

            # Convert start to int for indexing
            start_pos = int(start)

            # Store features by type and start position
            if feature_type not in features:
                features[feature_type] = {}

            features[feature_type][start_pos] = {
                'line': line.strip(),
                'fields': fields,
                'qualifiers': attributes
            }

    return features

# Function to parse mapping file
def parse_mapping(filename):
    mapping = {}
    inverse_mapping = {}

    with open(filename, 'r') as handle:
        for line in handle:
            fields = line.strip().split()
            if len(fields) >= 2:
                qry_pos = int(fields[0])
                src_pos = int(fields[1])

                mapping[qry_pos] = src_pos

                if src_pos not in inverse_mapping:
                    inverse_mapping[src_pos] = []
                inverse_mapping[src_pos].append(qry_pos)

    return mapping, inverse_mapping

# Function to find the nearest feature
def find_nearest_feature(start, features_dict, max_distance=100):
    for i in range(1, max_distance + 1):
        if start - i in features_dict:
            return start - i
        if start + i in features_dict:
            return start + i
    return None

# Main process
def transfer_qualifiers(src_gff, qry_gff, mapping_file, output_file):
    # Parse the GFF files
    src_features = parse_gff(src_gff)

    # Parse the mapping file
    mapping, inverse_mapping = parse_mapping(mapping_file)

    # Process the query GFF and replace qualifiers
    with open(qry_gff, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            # Always write every line to ensure nothing is lost

            # For comment lines, write as-is
            if line.startswith('#'):
                outfile.write(line)
                continue

            # Parse the fields
            fields = line.strip().split('\t')

            # For malformed lines (less than 9 fields), write as-is
            if len(fields) < 9:
                outfile.write(line)
                continue

            # Extract the relevant fields
            seqid, source, feature_type, start, end, score, strand, phase, attributes = fields
            start_pos = int(start)

            # Check if we have a mapping for this position
            if start_pos in inverse_mapping:
                src_start = inverse_mapping[start_pos][0]

                # Check if we have a corresponding feature in source GFF
                if feature_type in src_features and src_start in src_features[feature_type]:
                    # Replace qualifiers from source feature
                    src_qualifiers = src_features[feature_type][src_start]['qualifiers']
                    fields[8] = src_qualifiers
                    print(f"Replaced qualifiers for {feature_type} at {start_pos} with feature at {src_start}")
                else:
                    # Try to find the nearest feature
                    if feature_type in src_features:
                        nearest_start = find_nearest_feature(src_start, src_features[feature_type])
                        if nearest_start is not None:
                            src_qualifiers = src_features[feature_type][nearest_start]['qualifiers']
                            fields[8] = src_qualifiers
                            print(f"Used nearest feature for {feature_type} at {start_pos}: found at {nearest_start}")
                        else:
                            print(f"Could not find corresponding feature for {feature_type} at {start_pos}")
                    else:
                        print(f"Feature type {feature_type} not found in source GFF")

            # Write the modified line
            outfile.write('\t'.join(fields) + '\n')

    print(f"Processed GFF written to {output_file}")

#%%

src_gff = "phylogenetic/defaults/genome_annotation.gff3"
qry_gff = "phylogenetic/defaults/clade-i/genome_annotation.gff3"
mapping_file = "refmap/results/mapping.tsv"
output_file = "refmap/results/translated_gff.gff3"

transfer_qualifiers(src_gff, qry_gff, mapping_file, output_file)
# %%
