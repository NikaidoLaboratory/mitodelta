import sys

def parse_maf_to_blast(input_file, output_file):
    """Convert LAST output to simplified BLAST tabular format."""
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        s_info = None
        q_info = None

        for line in infile:
            if line.startswith("#") or not line.strip():
                continue

            # Parse MAF block
            if line.startswith('a '):  # MAF alignment block start
                pass

            elif line.startswith('s '):  # Sequence block (subject)
                cols = line.strip().split()

                if s_info is None:  # First 's' line: Subject sequence
                    subject_id = cols[1]
                    s_start = int(cols[2]) + 1  # Convert to 0-based index
                    s_end = int(cols[2]) + int(cols[3])
                    s_info = (subject_id, s_start, s_end)

                else:  # Second 's' line: Query sequence
                    query_id = cols[1]
                    q_start = int(cols[2]) + 1
                    q_end = int(cols[3])
                    q_len = int(cols[5])
                    q_seq = cols[6]
                    q_info = (query_id, q_start, q_end, q_len, q_seq)

                    alignment_length = len(q_seq)

                    # Write the result in BLAST tabular format
                    outfile.write("{},{},{},{},{},{},{}\n".format(
                        q_info[0],q_info[1],q_info[2],s_info[1],s_info[2],q_info[3],alignment_length
                    ))

                    # Reset subject_info and query_info for next alignment
                    s_info = None
                    q_info = None

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python maftoblast.py <maf_input> <blast_output>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    parse_maf_to_blast(input_file, output_file)

