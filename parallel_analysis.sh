#!/bash/bin/
"""
This script automates the processing and analysis of molecular dynamics (MD) simulations. It segments trajectory data into smaller intervals, performs RMSD and contact distance calculations for each segment, and then concatenates the results for comprehensive analysis. The script is designed to handle multiple ligands and produce summary plots of the analysis.
"""
# Replace 'PDB_ID' with the appropriate PDB ID as needed.
#Provide 'molecule_*.itp' in order for the code to have the ligand number. 
base_dir=$(pwd)
mkdir -p "$base_dir/analysis"
mdtot_dir="$base_dir/analysis"
analysis_dir="$base_dir/analysis"
mkdir -p "$analysis_dir"

process_segment() {
    segment_num=$1
    input_xtc=$2
    input_tpr=$3
    segment_length_ns=$4
    mdtot_dir=$5
    start_time_ns=$((segment_num * segment_length_ns))
    end_time_ns=$(((segment_num + 1) * segment_length_ns))
    segment_output_prefix="$mdtot_dir/segment_${segment_num}"

    echo "Processing segment from $start_time_ns to $end_time_ns ns"
    echo -e "4\n4" | gmx rms -s "$input_tpr" -f "$input_xtc" -o "${segment_output_prefix}_rmsd.xvg" -b $start_time_ns -e $end_time_ns -tu ns
    echo -e "1\n13" | gmx mindist -f "$input_xtc" -s "$input_tpr" -od "${segment_output_prefix}_mindist.xvg" -b $start_time_ns -e $end_time_ns -tu ns
    echo -e "1\n13" | gmx mindist -f "$input_xtc" -s "$input_tpr" -tu ns -on "${segment_output_prefix}_numberofcontacts.xvg" -b $start_time_ns -e $end_time_ns
    echo -e "13\n13" | gmx rms -f "$input_xtc" -s "$input_tpr" -tu ns -o "${segment_output_prefix}_rmsd_lig.xvg" -b $start_time_ns -e $end_time_ns
}

export -f process_segment
concatenate_and_cleanup() {
    output_prefix=$1
    num_segments=$2
    output_file="$mdtot_dir/${output_prefix}_all_segments.xvg"
    echo "# Combined output for $output_prefix" > "$output_file"

    for segment_num in $(seq 0 $((num_segments - 1))); do
        segment_file="$mdtot_dir/segment_${segment_num}_${output_prefix}.xvg"
        if [ -f "$segment_file" ]; then
            if [ "$segment_num" -ne 0 ]; then
                tail -n +2 "$segment_file" >> "$output_file"
            else
                cat "$segment_file" >> "$output_file"
            fi
            rm "$segment_file"
        fi
    done
}

for file in "$base_dir"/molecule_*.itp; do
    ligand_name=$(basename "$file" | grep -o '[0-9]\+' | head -1)
    echo "The ligand name is $ligand_name"
    
    total_time_ns=300
    segment_length_ns=20
    tpr_dir="$base_dir/tpr"
    xtc_dir="$base_dir/production" 
    input_tpr="$tpr_dir/md1_PDB_ID_${ligand_name}.tpr"
    input_xtc="$xtc_dir/PDB_ID_${ligand_name}.xtc"
    

    num_segments=$((total_time_ns / segment_length_ns))
    cd "$mdtot_dir" || exit 1
    seq 0 $((num_segments - 1)) | parallel -j 15 process_segment {} "$input_xtc" "$input_tpr" "$segment_length_ns" "$mdtot_dir"
    cd "$base_dir"
    concatenate_and_cleanup "rmsd" "$num_segments"
    concatenate_and_cleanup "mindist" "$num_segments"
    concatenate_and_cleanup "numberofcontacts" "$num_segments"
    concatenate_and_cleanup "rmsd_lig" "$num_segments"
done
find "$mdtot_dir" -name '#*' -exec rm {} +
python "$base_dir/plot_data.py" "$mdtot_dir" "$analysis_dir"
rm analysis/mindist.xvg

