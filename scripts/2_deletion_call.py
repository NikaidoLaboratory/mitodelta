# Step 2. Detecting candidate deletions by LAST alignment

import os
import subprocess
import time
import numpy as np
import gzip
import glob


# Load config
def load_config(config_file):
    user_preferences = {}
    with open(config_file, 'r') as file:
        for line in file:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            var, value = map(str.strip, line.split('=', 1))
            user_preferences[var] = value
    return user_preferences


# LAST alignment
def last_align(p1, lastal, threads, lastindex, tag, lastsp, mfcv, samtools, mtfaindex, gcov, bg2bw):
    print(f"{time.strftime('%Y-%m-%d %H:%M:%S')}: Map to MT genome")
    subprocess.run(f"cp {p1} tmp_{tag}.fq", shell=True, check=True)
    subprocess.run(f"{lastal} -Q1 -e80 -P{threads} {lastindex} tmp_{tag}.fq | {lastsp} > tmp_{tag}.maf", shell=True, check=True)
    subprocess.run(f"{mfcv} sam -d tmp_{tag}.maf | {samtools} view -@ {threads} -bt {mtfaindex} - | {samtools} sort -@ {threads} -o bam/{tag}.bam -", shell=True, check=True)
    subprocess.run(f"{samtools} index bam/{tag}.bam", shell=True, check=True)
    subprocess.run(f"{mfcv} tab tmp_{tag}.maf > tab/{tag}.tab", shell=True, check=True)
    # COMPRESS TAB
    subprocess.run(f"gzip -f tab/{tag}.tab", shell=True, check=True)
    # GENERATE BIGWIG
    print(f"{time.strftime('%Y-%m-%d %H:%M:%S')}: Generate Bigwig")
    subprocess.run(f"{gcov} -split -ibam bam/{tag}.bam -bg | sort -k1,1 -k2,2n > tmp_{tag}.bg", shell=True, check=True)
    subprocess.run(f"{bg2bw} tmp_{tag}.bg {mtfaindex} bw/{tag}.bw", shell=True, check=True)
    os.remove(f"tmp_{tag}.bg")


# Remove tmp file
def remove_tmp(tag):
    file_patterns = [
        f"tmp_{tag}*",
        f"tmp1_{tag}*",
        f"tmp2_{tag}*",
        f"tmp_final_{tag}*",
        f"tmp_random_{tag}*"
]
    for pattern in file_patterns:
        files_to_remove = glob.glob(pattern)
        for file in files_to_remove:
            try:
                os.remove(file)
            except FileNotFoundError:
                pass  


# Check paired
def paired_check(path):
    check_paired = 0
    result = subprocess.run(f"zcat {path} | tail -n 1", shell=True, capture_output=True, text=True)
    line = result.stdout.strip()
    elements = line.split('\t')
    if len(elements) > 6 and elements[6].endswith('/1'):
        check_paired = 1
    return check_paired


# Build hash
def build_hash(file, check_paired, score_threshold, evalue_threshold):
    hash = {}
    check_hash = {}

    with gzip.open(file, 'rt') as f:
        for line in f:
            line = line.strip()
            if line.startswith('#'):
                continue

            elements = line.split()
            score = float(elements[0])
            chr = elements[1]
            start = int(elements[2])
            length = int(elements[3])
            end = start + length
            read_start = int(elements[7])
            id = None
            mate = 1
            if check_paired == 0:
                id = elements[6]
                if id.endswith('_1') or id.endswith('_2'):
                    mate = int(id[-1])
                    id = id[:-2]
            elif check_paired == 1:
                name = elements[6].split('/')
                id = name[0]
                mate = int(name[1])

            strand = elements[9]
            evalue = float(elements[12].split('=')[-1])

            if id in check_hash and f"{start}{length}" in check_hash[id]:
                continue

            if id not in check_hash:
                check_hash[id] = {}
            check_hash[id][f"{start}{length}"] = True

            if mate > 1:
                mate = 2

            if score < score_threshold or evalue > evalue_threshold:
                continue

            if id not in hash:
                hash[id] = {}
            if mate not in hash[id]:
                hash[id][mate] = {'starts': [], 'ends': [], 'rstarts': [], 'strands': [], 'scores': [], 'evalue': [], 'lengths': []}

            hash[id][mate]['starts'].append(start)
            hash[id][mate]['ends'].append(end)
            hash[id][mate]['rstarts'].append(read_start)
            hash[id][mate]['strands'].append(strand)
            hash[id][mate]['scores'].append(score)
            hash[id][mate]['evalue'].append(evalue)
            hash[id][mate]['lengths'].append(length)

    return hash


# Remove duplicates
def remove_duplicates(hash):
    check_duplicates = {}

    for id, data in list(hash.items()):
        starts1 = 'NULL'
        ends1 = 'NULL'
        lengths1 = 'NULL'
        starts2 = 'NULL'
        ends2 = 'NULL'
        lengths2 = 'NULL'
        count1 = 0
        count2 = 0

        if 1 in data:
            starts1 = ''.join(map(str, data[1]['starts']))
            ends1 = ''.join(map(str, data[1]['ends']))
            lengths1 = ''.join(map(str, data[1]['lengths']))
            count1 = len(data[1]['starts'])

        if 2 in data:
            starts2 = ''.join(map(str, data[2]['starts']))
            ends2 = ''.join(map(str, data[2]['ends']))
            lengths2 = ''.join(map(str, data[2]['lengths']))
            count2 = len(data[2]['starts'])

        signature1 = f"{starts1}:{ends1}:{lengths1}"
        signature2 = f"{starts2}:{ends2}:{lengths2}"

        signatures = sorted([signature1, signature2])
        signature = ''.join(signatures)

        if signature in check_duplicates and count1 > 0 and count2 > 0:
            del hash[id]
        else:
            check_duplicates[signature] = check_duplicates.get(signature, 0) + 1


# Print non-split BED
def print_bed(hash, tag, refchr):
    filename = f"tmp_{tag}_nosplit.bed"
    with open(filename, 'w') as abed:
        for id, data in hash.items():
            for read, read_data in data.items():
                name = f"{id}_{read}"
                count = len(read_data['starts'])
                if count > 1:
                    continue
                start = read_data['starts'][0]
                end = read_data['ends'][0]
                abed.write(f"{refchr}\t{start}\t{end}\t{name}\n")

    subprocess.run(f"sort -k2,2n {filename} -o {filename}", shell=True, check=True)
    return filename


# Process hash
def process_hash(hash, bedfile, breakpointfile, msize, tag, split_length, dloop1, dloop2, deletion_threshold_min, deletion_threshold_max, paired_distance, split_distance_threshold, refchr):
    bps = f"tmp_{tag}_bps.bed"
    bpe = f"tmp_{tag}_bpe.bed"
    delhash = process_hash1(hash, bedfile, breakpointfile, msize, bps, bpe, split_length, deletion_threshold_min, deletion_threshold_max, paired_distance, refchr)

    with open(bps, 'w') as bps_file, open(bpe, 'w') as bpe_file, open(breakpointfile, 'w') as bp_file:
        for id, data in hash.items():
            for read, read_data in data.items():
                name = f"{id}_{read}"
                count = len(read_data['starts'])
                if count != 2:
                    continue

                min_len = min(read_data['lengths'])
                if min_len < split_length:
                    continue

                read_starts = read_data['starts']
                read_ends = read_data['ends']
                read_strands = read_data['strands']
                read_lengths = read_data['lengths']
                read_local_starts = read_data['rstarts']

                read_check = 'no'
                if (read_starts[0] < read_starts[1] and read_local_starts[0] > read_local_starts[1]) or \
                   (read_starts[0] > read_starts[1] and read_local_starts[0] < read_local_starts[1]) or \
                   (read_starts[0] <= read_starts[1] and read_local_starts[0] < read_local_starts[1] and read_starts[1] < read_ends[0]) or \
                   (read_starts[0] >= read_starts[1] and read_local_starts[0] > read_local_starts[1] and read_ends[1] > read_starts[0]):
                    read_check = 'yes'

                min_start = min(read_starts)
                max_end = max(read_ends)
                if min_start <= dloop1 and max_end >= dloop2:
                    continue

                size, start, end = get_frag_distance(read_starts, read_ends, read_check, msize)
                if size < deletion_threshold_min or size > deletion_threshold_max:
                    continue
                if read_strands[0] != read_strands[1]:
                    continue

                start = 1 if start == 0 else start
                end = 1 if end == 0 else end

                pair = 1 if read == 2 else 2
                paired_support = 'no'
                distance_paired_support = paired_support_func(hash, id, read, pair)
                if distance_paired_support <= paired_distance:
                    paired_support = 'yes'

                split_distance = get_split_distance(read_local_starts, read_lengths)
                if split_distance > split_distance_threshold:
                    continue

                read_scores = read_data['scores']
                len_data = generate_bed(id, read, read_starts, read_ends, read_lengths, read_scores, read_strands[0], msize, refchr)

                readid = f"{id}_{read}"
                clusterid = f"cluster_{count}"
                delhash[readid] = {
                    'breakstart': len_data[2],
                    'breakend': len_data[3],
                    'breaksize': len_data[4],
                    'readcheck': read_check,
                    'lenstart': len_data[0],
                    'lenend': len_data[1]
                }

                start = len_data[2]
                end = len_data[3]
                size = len_data[4]

                bp_file.write(f"{refchr}\t{name}\t{size}\t{start}\t{end}\t{read_lengths[0]}\t{read_lengths[1]}\t{paired_support}\t{distance_paired_support}\t{read_check}\n")
                if read_check == 'no':
                    bps_file.write(f"{refchr}\t{start}\t{start}\t{name}\t0\t+\n")
                    bpe_file.write(f"{refchr}\t{end}\t{end}\t{name}\t0\t+\n")
                else:
                    bps_file.write(f"{refchr}\t{start}\t{start}\t{name}\t0\t-\n")
                    bpe_file.write(f"{refchr}\t{end}\t{end}\t{name}\t0\t-\n")

    return delhash


# Process hash1
def process_hash1(hash, bedfile, breakpointfile, msize, bps, bpe, split_length, deletion_threshold_min, deletion_threshold_max, paired_distance, refchr):
    delhash = {}

    with open(breakpointfile, 'w') as bp_file, open(bedfile, 'w') as bed, open(bps, 'w') as bps_file, open(bpe, 'w') as bpe_file:
        for id, data in hash.items():
            for read, read_data in data.items():
                name = f"{id}_{read}"
                count = len(read_data['starts'])
                if count != 3:
                    continue

                read_starts = read_data['starts']
                read_ends = read_data['ends']
                read_strands = read_data['strands']
                read_lengths = read_data['lengths']
                read_scores = read_data['scores']
                read_local_starts = read_data['rstarts']

                strands = {strand: 1 for strand in read_strands}
                count_read_strands = len(strands)
                if count_read_strands != 1:
                    continue

                pos = [1000, 1000, 1000, 1000]
                if 0 in read_starts:
                    pos[0] = 0
                if msize in read_starts:
                    pos[1] = msize
                if 0 in read_ends:
                    pos[2] = 0
                if msize in read_ends:
                    pos[3] = msize

                if (pos[0] != 1000 or pos[1] != 1000) and (pos[2] != 1000 or pos[3] != 1000):
                    sort_hash = {}
                    for i in range(3):
                        sort_hash[read_local_starts[i]] = {
                            'start': read_starts[i],
                            'end': read_ends[i],
                            'strand': read_strands[i],
                            'length': read_lengths[i],
                            'score': read_scores[i]
                        }

                    order_count = 1
                    for local_start in sorted(sort_hash.keys()):
                        start_check = sort_hash[local_start]['start']
                        end_check = sort_hash[local_start]['end']
                        pos_check = 'no'
                        if not (start_check == 0 or start_check == msize or end_check == 0 or end_check == msize):
                            pos_check = 'yes'
                        if pos_check == 'yes':
                            break
                        order_count += 1

                    delete_count = 3 if order_count == 1 else 1
                    order_count = 1
                    for local_start in sorted(sort_hash.keys()):
                        if order_count == delete_count:
                            del sort_hash[local_start]
                        order_count += 1

                    read_startsN = []
                    read_endsN = []
                    read_strandsN = []
                    read_local_startsN = []
                    read_scoresN = []
                    read_lengthsN = []
                    for local_start in sorted(sort_hash.keys()):
                        read_startsN.append(sort_hash[local_start]['start'])
                        read_endsN.append(sort_hash[local_start]['end'])
                        read_local_startsN.append(local_start)
                        read_strandsN.append(sort_hash[local_start]['strand'])
                        read_scoresN.append(sort_hash[local_start]['score'])
                        read_lengthsN.append(sort_hash[local_start]['length'])

                    min_len = min(read_lengthsN)
                    if min_len < split_length:
                        continue

                    read_check = 'no'
                    if (read_startsN[0] < read_startsN[1] and read_local_startsN[0] > read_local_startsN[1]) or \
                       (read_startsN[0] > read_startsN[1] and read_local_startsN[0] < read_local_startsN[1]):
                        read_check = 'yes'

                    size, start, end = get_frag_distance(read_startsN, read_endsN, read_check, msize)
                    if size < deletion_threshold_min or size > deletion_threshold_max:
                        continue

                    pair = 1 if read == 2 else 2
                    paired_support = 'no'
                    distance_paired_support = paired_support_func(hash, id, read, pair)
                    if distance_paired_support <= paired_distance:
                        paired_support = 'yes'

                    start = 1 if start == 0 else start
                    end = 1 if end == 0 else end

                    split_distance = get_split_distance(read_local_startsN, read_lengthsN)
                    if split_distance > 5:
                        continue

                    len_data = generate_bed1(id, read, read_startsN, read_endsN, read_lengthsN, read_scoresN, read_strandsN[0], refchr)
                    readid = f"{id}_{read}"
                    clusterid = f"cluster_{count}"
                    delhash[readid] = {
                        'breakstart': start,
                        'breakend': end,
                        'breaksize': size,
                        'readcheck': read_check,
                        'lenstart': len_data[0],
                        'lenend': len_data[1]
                    }

                    bp_file.write(f"{refchr}\t{name}\t{size}\t{start}\t{end}\t{read_lengthsN[0]}\t{read_lengthsN[1]}\t{paired_support}\t{distance_paired_support}\t{read_check}\n")
                    if read_check == 'no':
                        bps_file.write(f"{refchr}\t{start}\t{start}\t{name}\t0\t+\n")
                        bpe_file.write(f"{refchr}\t{end}\t{end}\t{name}\t0\t+\n")
                    else:
                        bps_file.write(f"{refchr}\t{start}\t{start}\t{name}\t0\t-\n")
                        bpe_file.write(f"{refchr}\t{end}\t{end}\t{name}\t0\t-\n")

    return delhash


# Check if the pair of a split read lies within a given threshold distance to a fragment of the split read
def paired_support_func(hash, id, read, pair):
    distance = 1000

    if pair in hash[id]:
        distance1 = 0
        distance2 = 0

        read_starts = hash[id][read]['starts']
        read_ends = hash[id][read]['ends']

        pair_start = hash[id][pair]['starts'][0]
        pair_end = hash[id][pair]['ends'][0]

        if read_starts[0] > pair_end:
            distance1 = read_starts[0] - pair_end
        elif pair_start > read_ends[0]:
            distance1 = pair_start - read_ends[0]

        if read_starts[1] > pair_end:
            distance2 = read_starts[1] - pair_end
        elif pair_start > read_ends[1]:
            distance2 = pair_start - read_ends[1]

        distance = min(distance1, distance2)
    return distance


# Get the size of putative deletion and the breakpoints
def get_frag_distance(starts, ends, read_check, msize):
    frag1_start = starts[0]
    frag2_start = starts[1]
    frag1_end = ends[0]
    frag2_end = ends[1]

    if read_check == 'no':
        if frag1_start > frag2_end:
            size = frag1_start - frag2_end
            return size, frag2_end, frag1_start
        elif frag2_start > frag1_end:
            size = frag2_start - frag1_end
            return size, frag1_end, frag2_start
        elif frag1_start < frag2_start and frag2_end <= frag1_end:
            size = msize - frag2_end + frag1_start
            return size, frag1_start, frag2_end
        elif frag2_start < frag1_start and frag1_end <= frag2_end:
            size = msize - frag2_end + frag1_start
            return size, frag1_start, frag2_end
        elif frag1_start <= frag2_start and frag1_end <= frag2_end:
            size = msize - frag2_start + frag1_end
            return size, frag1_end, frag2_start
        elif frag2_start <= frag1_start and frag2_end <= frag1_end:
            size = msize - frag1_end + frag2_start
            return size, frag2_start, frag1_end

    if read_check == 'yes':
        if frag1_start > frag2_end:
            size = (msize - frag1_end) + frag2_start
            return size, frag2_start, frag1_end
        elif frag2_start > frag1_end:
            size = (msize - frag2_end) + frag1_start
            return size, frag1_start, frag2_end
        elif frag1_start <= frag2_start and frag1_end <= frag2_end:
            size = msize - frag2_start + frag1_end
            return size, frag1_end, frag2_start
        elif frag2_start <= frag1_start and frag2_end <= frag1_end:
            size = msize - frag1_end + frag2_start
            return size, frag2_start, frag1_end
        elif frag1_start < frag2_start and frag2_end <= frag1_end:
            size = msize - frag2_end + frag1_start
            return size, frag1_start, frag2_end
        elif frag2_start < frag1_start and frag1_end <= frag2_end:
            size = msize - frag2_end + frag1_start
            return size, frag1_start, frag2_end

    return None


# Get the distance between split reads
def get_split_distance(starts, lengths):
    local1_start = starts[0]
    local2_start = starts[1]
    local1_length = lengths[0]
    local2_length = lengths[1]

    if local1_start > local2_start:
        distance = local1_start - local2_start - local2_length
        return distance
    elif local2_start > local1_start:
        distance = local2_start - local1_start - local1_length
        return distance

    return None


# Generate a bed file for the split reads for IGV visualization
def generate_bed(id, read, starts, ends, lengths, scores, strand, msize, refchr):
    len_data = []

    frag1_start = starts[0]
    frag2_start = starts[1]
    frag1_end = ends[0]
    frag2_end = ends[1]
    frag1_length = lengths[0]
    frag2_length = lengths[1]
    frag1_score = scores[0]
    frag2_score = scores[1]
    score = int((frag1_score + frag2_score) / 2)

    if frag1_start > frag2_end and strand == '-':
        start = frag2_start
        end = frag1_end
        bstart = frag2_end
        bend = frag1_start
        size = frag1_start - frag2_end
        block_start = frag1_start - start
        start = 1 if start == 0 else start
        end = 1 if end == 0 else end
        bstart = 1 if bstart == 0 else bstart
        bend = 1 if bend == 0 else bend
        print(f"{refchr}\t{start}\t{end}\t{id}_{read}\t{score}\t{strand}\t{start}\t{end}\t0\t2\t{frag2_length},{frag1_length}\t0,{block_start}")
        len_data = [frag2_length, frag1_length, bstart, bend, size]

    elif frag1_start > frag2_end and strand == '+':
        start = frag2_start
        end = frag1_end
        bstart = frag2_start
        bend = frag1_end
        size = 1 + msize - frag1_end + frag2_start
        block_start = frag1_start - start
        start = 1 if start == 0 else start
        end = 1 if end == 0 else end
        bstart = 1 if bstart == 0 else bstart
        bend = 1 if bend == 0 else bend
        print(f"{refchr}\t{start}\t{end}\t{id}_{read}\t{score}\t{strand}\t{start}\t{end}\t0\t2\t{frag2_length},{frag1_length}\t0,{block_start}")
        len_data = [frag1_length, frag2_length, bstart, bend, size]

    elif frag2_start > frag1_end and strand == '+':
        start = frag1_start
        end = frag2_end
        bstart = frag1_end
        bend = frag2_start
        size = frag2_start - frag1_end
        block_start = frag2_start - start
        start = 1 if start == 0 else start
        end = 1 if end == 0 else end
        bstart = 1 if bstart == 0 else bstart
        bend = 1 if bend == 0 else bend
        print(f"{refchr}\t{start}\t{end}\t{id}_{read}\t{score}\t{strand}\t{start}\t{end}\t0\t2\t{frag1_length},{frag2_length}\t0,{block_start}")
        len_data = [frag1_length, frag2_length, bstart, bend, size]

    elif frag2_start > frag1_end and strand == '-':
        start = frag1_start
        end = frag2_end
        bstart = frag1_start
        bend = frag2_end
        size = 1 + msize - frag2_end + frag1_start
        block_start = frag2_start - start
        start = 1 if start == 0 else start
        end = 1 if end == 0 else end
        bstart = 1 if bstart == 0 else bstart
        bend = 1 if bend == 0 else bend
        print(f"{refchr}\t{start}\t{end}\t{id}_{read}\t{score}\t{strand}\t{start}\t{end}\t0\t2\t{frag1_length},{frag2_length}\t0,{block_start}")
        len_data = [frag2_length, frag1_length, bstart, bend, size]

    elif frag2_start < frag1_end and strand == '+':
        start = frag1_start
        end = frag2_end
        bstart = frag2_start
        bend = frag1_end
        size = msize - frag1_end + frag2_start
        block_start = frag1_end - start
        start = 1 if start == 0 else start
        end = 1 if end == 0 else end
        bstart = 1 if bstart == 0 else bstart
        bend = 1 if bend == 0 else bend
        print(f"{refchr}\t{start}\t{end}\t{id}_{read}\t{score}\t{strand}\t{start}\t{end}\t0\t2\t{frag1_length},{frag2_length}\t0,{block_start}")
        len_data = [frag2_length, frag1_length, bstart, bend, size]

    elif frag1_start < frag2_end and strand == '-':
        start = frag2_start
        end = frag1_end
        bstart = frag1_start
        bend = frag2_end
        size = msize - frag2_end + frag1_start
        block_start = frag2_end - start
        start = 1 if start == 0 else start
        end = 1 if end == 0 else end
        bstart = 1 if bstart == 0 else bstart
        bend = 1 if bend == 0 else bend
        print(f"{refchr}\t{start}\t{end}\t{id}_{read}\t{score}\t{strand}\t{start}\t{end}\t0\t2\t{frag1_length},{frag2_length}\t0,{block_start}")
        len_data = [frag2_length, frag1_length, bstart, bend, size]

    return len_data


# Generate a BED for the split reads for IGV visualization (reads which split twice, once due to deletion/duplication and once due to genome circularity)
def generate_bed1(id, read, starts, ends, lengths, scores, strand, refchr):
    len_data = []

    frag1_start = starts[0]
    frag2_start = starts[1]
    frag1_end = ends[0]
    frag2_end = ends[1]
    frag1_length = lengths[0]
    frag2_length = lengths[1]
    frag1_score = scores[0]
    frag2_score = scores[1]
    score = int((frag1_score + frag2_score) / 2)

    if frag1_start > frag2_end:
        start = frag2_start
        end = frag1_end
        block_start = frag1_start - start
        print(f"{refchr}\t{start}\t{end}\t{id}_{read}\t{score}\t{strand}\t{start}\t{end}\t0\t2\t{frag2_length},{frag1_length}\t0,{block_start}")
        len_data = [frag2_length, frag1_length]

    elif frag2_start > frag1_end:
        start = frag1_start
        end = frag2_end
        block_start = frag2_start - start
        print(f"{refchr}\t{start}\t{end}\t{id}_{read}\t{score}\t{strand}\t{start}\t{end}\t0\t2\t{frag1_length},{frag2_length}\t0,{block_start}")
        len_data = [frag1_length, frag2_length]

    return len_data


# Get cluster
def get_cluster(delhash, breakthreshold, tag, sortBed, clusterBed):
    bps = f"tmp_{tag}_bps.bed"
    bpe = f"tmp_{tag}_bpe.bed"
    bpsc = f"tmp_{tag}_bps.cls"
    bpec = f"tmp_{tag}_bpe.cls"
    clusterhash = {}

    subprocess.run(f"{sortBed} -i {bps} | {clusterBed} -s -d {breakthreshold} -i stdin > {bpsc}", shell=True, check=True)
    subprocess.run(f"{sortBed} -i {bpe} | {clusterBed} -s -d {breakthreshold} -i stdin > {bpec}", shell=True, check=True)

    bps_hash = {}
    with open(bpsc, 'r') as bps_file:
        for line in bps_file:
            fields = line.strip().split('\t')
            readid = fields[3]
            clusterid = fields[6]
            bps_hash[readid] = clusterid

    bpe_hash = {}
    with open(bpec, 'r') as bpe_file:
        for line in bpe_file:
            fields = line.strip().split('\t')
            readid = fields[3]
            clusterid = fields[6]
            bpe_hash[readid] = clusterid

    for readid in delhash:
        if readid in bps_hash and readid in bpe_hash:
            clusterids = bps_hash[readid]
            clusteride = bpe_hash[readid]
            clusterid = f"cluster{clusterids}{clusteride}"
            if clusterid not in clusterhash:
                clusterhash[clusterid] = {}
            clusterhash[clusterid][readid] = delhash[readid]

    return clusterhash


# Build result
def build_results(hash, clusterhash, infile, refchr, cluster_read_count_threshold, tag, breakspan, intersectBed):
    clustercount = {}
    nosplitbed_file = f"tmp_{tag}_nosplit.bed"

    for clusterid, cluster_data in clusterhash.items():
        cluster_read_count = len(cluster_data)
        if cluster_read_count < cluster_read_count_threshold:
            continue

        print(f"Check {clusterid}")
        clustercheck = {}
        clustercount[clusterid] = {'wt': 0, 'mt': cluster_read_count, 'starts': [], 'ends': [], 'names': [], 'lenstarts': [], 'lenends': []}

        splitbed_fileS = f"tmp_{tag}.split.start.bed"
        splitbed_fileE = f"tmp_{tag}.split.end.bed"

        with open(splitbed_fileS, 'w') as sbeds, open(splitbed_fileE, 'w') as sbedE:
            for readid, read_data in cluster_data.items():
                breakstart = read_data['breakstart']
                breakend = read_data['breakend']
                lenstart = read_data['lenstart']
                lenend = read_data['lenend']

                clustercount[clusterid]['starts'].append(breakstart)
                clustercount[clusterid]['ends'].append(breakend)
                clustercount[clusterid]['names'].append(readid)
                clustercount[clusterid]['lenstarts'].append(lenstart)
                clustercount[clusterid]['lenends'].append(lenend)

                sbeds.write(f"{refchr}\t{breakstart}\t{breakstart}\n")
                sbedE.write(f"{refchr}\t{breakend}\t{breakend}\n")

        subprocess.run(f"sort -u -k2,2n -k3 {splitbed_fileS} -o {splitbed_fileS}", shell=True, check=True)
        subprocess.run(f"sort -u -k2,2n -k3 {splitbed_fileE} -o {splitbed_fileE}", shell=True, check=True)

        intersectbed_fileS = f"tmp_{tag}.intersect.start.bed"
        intersectbed_fileE = f"tmp_{tag}.intersect.end.bed"

        subprocess.run(f"{intersectBed} -wo -sorted -a {nosplitbed_file} -b {splitbed_fileS} > {intersectbed_fileS}", shell=True, check=True)
        with open(intersectbed_fileS, 'r') as is_file:
            for line in is_file:
                crd = line.strip().split('\t')
                start = int(crd[1])
                end = int(crd[2])
                name = crd[3]
                breakstart = int(crd[5])
                if name in clustercheck:
                    continue
                diffstart = breakstart - start
                diffend = end - breakstart
                if diffstart <= breakspan or diffend <= breakspan:
                    continue
                clustercount[clusterid]['wt1'] = clustercount[clusterid].get('wt1', 0) + 1
                clustercheck[name] = True

        subprocess.run(f"{intersectBed} -wo -sorted -a {nosplitbed_file} -b {splitbed_fileE} > {intersectbed_fileE}", shell=True, check=True)
        with open(intersectbed_fileE, 'r') as ie_file:
            for line in ie_file:
                crd = line.strip().split('\t')
                start = int(crd[1])
                end = int(crd[2])
                name = crd[3]
                breakend = int(crd[5])
                if name in clustercheck:
                    continue
                diffstart = breakend - start
                diffend = end - breakend
                if diffstart <= breakspan or diffend <= breakspan:
                    continue
                clustercount[clusterid]['wt2'] = clustercount[clusterid].get('wt2', 0) + 1
                clustercheck[name] = True

        subprocess.run(f"rm {splitbed_fileS} {intersectbed_fileS}", shell=True, check=True)
        subprocess.run(f"rm {splitbed_fileE} {intersectbed_fileE}", shell=True, check=True)

    return clustercount


# Print result
def print_result(clustercount, clusterfile):
    with open(clusterfile, 'w') as cf:
        for clusterid, data in clustercount.items():
            names = data['names']
            starts = data['starts']
            ends = data['ends']
            lenstarts = data['lenstarts']
            lenends = data['lenends']
            mt = data['mt']
            wt1 = data.get('wt1', 0)
            wt2 = data.get('wt2', 0)
            sum_wt = wt1 + wt2
            mean_wt = round(sum_wt / 2)

            names_print = ",".join(map(str, names))
            starts_print = ",".join(map(str, starts))
            ends_print = ",".join(map(str, ends))

            lenstarts_print = "NA"
            lenends_print = "NA"
            if len(lenstarts) > 0 and lenstarts[0] is not None:
                lenstarts_print = ",".join(map(str, lenstarts))
            if len(lenends) > 0 and lenends[0] is not None:
                lenends_print = ",".join(map(str, lenends))

            perc_hp = mt * 100 / (mt + mean_wt)

            cf.write(f"{clusterid}\t{names_print}\t{starts_print}\t{ends_print}\t{lenstarts_print}\t{lenends_print}\t{mt}\t{mean_wt}\t{perc_hp:.2f}\n")



### Main
def main():
    import sys
    if len(sys.argv) != 4:
        print("usage: python 2_last_alingment.py <config_file> <fastq file> <study name>")
        sys.exit(1)

    config_file = sys.argv[1]
    p1 = sys.argv[2]
    tag = sys.argv[3]

    if not os.path.exists(config_file):
        print(f"Configuration file missing, usage: python 2_last_alingment.py <config_file> <fastq file> <study name>")
        sys.exit(1)
    if not os.path.exists(p1):
        print(f"Read file missing, usage: python 2_last_alingment.py <config_file> <fastq file> <study name>")
        sys.exit(1)
    if not tag:
        print(f"Study name not given, usage: python 2_last_alingment.py <config_file> <fastq file> <study name>")
        sys.exit(1)
    
    directories = ['bam', 'del', 'tab', 'bw']
    for dir_name in directories:
        os.makedirs(dir_name, exist_ok=True)

    # Load config
    user_preferences = load_config(config_file)
    lastal = user_preferences.get('lastal')
    lastsp = user_preferences.get('lastsp')
    mfcv = user_preferences.get('mfcv')
    b2fq = user_preferences.get('b2fq')
    reformat = user_preferences.get('reformat')
    samtools = user_preferences.get('samtools')
    gcov = user_preferences.get('gcov')
    intersectBed = user_preferences.get('intersectBed')
    sortBed = user_preferences.get('sortBed')
    clusterBed = user_preferences.get('clusterBed')
    randomBed = user_preferences.get('randomBed')
    groupBy = user_preferences.get('groupBy')
    bg2bw = user_preferences.get('bg2bw')
    
    faindex = user_preferences.get('faindex')
    lastindex = user_preferences.get('lastindex')
    mtfaindex = user_preferences.get('mtfaindex')
    gsize = user_preferences.get('gsize')
    MT_fasta = user_preferences.get('MT_fasta')
    
    refchr = user_preferences.get('refchr')
    msize = int(user_preferences.get('msize', 0))
    orihs = int(user_preferences.get('orihs', 0))
    orihe = int(user_preferences.get('orihe', 0))
    orils = int(user_preferences.get('orils', 0))
    orile = int(user_preferences.get('orile', 0))
    exclude = int(user_preferences.get('exclude', 0))
    dloop1 = exclude
    dloop2 = msize - exclude
    hash = {}
    
    score_threshold = float(user_preferences.get('score_threshold', 0))
    evalue_threshold = float(user_preferences.get('evalue_threshold', 0))
    split_length = int(user_preferences.get('split_length', 0))
    paired_distance = int(user_preferences.get('paired_distance', 0))
    deletion_threshold_min = int(user_preferences.get('deletion_threshold_min', 0))
    deletion_threshold_max = int(user_preferences.get('deletion_threshold_max', 0))
    breakthreshold = int(user_preferences.get('breakthreshold', 0))
    cluster_threshold = int(user_preferences.get('cluster_threshold', 0))
    breakspan = int(user_preferences.get('breakspan', 0))
    sizelimit = int(user_preferences.get('sizelimit', 0))
    hplimit = float(user_preferences.get('hplimit', 0))
    flank = int(user_preferences.get('flank', 0))
    split_distance_threshold = int(user_preferences.get('split_distance_threshold', 0))
    
    rmtmp = user_preferences.get('rmtmp')
    threads = user_preferences.get('threads')


    # Align read via LAST
    last_align(p1, lastal, threads, lastindex, tag, lastsp, mfcv, samtools, mtfaindex, gcov, bg2bw)
    
    
    # Identify deletions
    infile = f"tab/{tag}.tab.gz"
    bedfile = f"del/{tag}.bed"
    breakpointfile = f"del/{tag}.breakpoint"
    clusterfile = f"del/{tag}.cluster"
    
    check_paired = paired_check(infile)
    print(f"{time.strftime('%Y-%m-%d %H:%M:%S')}: Build split read hash")
    hash = build_hash(infile, check_paired, score_threshold, evalue_threshold)
    remove_duplicates(hash)
    
    print(f"{time.strftime('%Y-%m-%d %H:%M:%S')}: Generate non-split read BED")
    nosplitbed_file = print_bed(hash, tag, refchr)
    
    print(f"{time.strftime('%Y-%m-%d %H:%M:%S')}: Process hash to get best deletion/duplication candidates")
    delhash = process_hash(hash, bedfile, breakpointfile, msize, tag, split_length, dloop1, dloop2, deletion_threshold_min, deletion_threshold_max, paired_distance, split_distance_threshold, refchr)
    
    print(f"{time.strftime('%Y-%m-%d %H:%M:%S')}: Build split read clusters")
    clusterhash = get_cluster(delhash, breakthreshold, tag, sortBed, clusterBed)
    
    print(f"{time.strftime('%Y-%m-%d %H:%M:%S')}: Generate and print results")
    clustercount = build_results(hash, clusterhash, infile, refchr, cluster_threshold, tag, breakspan, intersectBed)
    print_result(clustercount, clusterfile)


    # Remove tmp file
    if rmtmp == 'yes':
        remove_tmp(tag)




if __name__ == "__main__":
    main()
