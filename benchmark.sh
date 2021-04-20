#!/bin/env bash

set -e
modes=("gdsddn" "nvme" "gdsnvme")
function usage {
	echo "$0 mode num_runs:10"
	echo "mode is one of: ${modes[@]}"
}

if (( "$#" < 1 )); then
	echo $#
	usage && exit 0
fi

case "$1" in
	"gdsddn")
		echo $1
		EXP_NAME="readLargeFileDDN"
		USE_GDS="--gdsbufreg --direct --cufile "
		FILE_NAME="/lustre/cheetah/data/yren/test_file" #1GB
		;;
	"nvme")
		echo $1
		EXP_NAME="readLargeFileNVME"
		USE_GDS="--direct "
		FILE_NAME="/raid/data/yren/test_file" #1GB
		;;
	"gdsnvme")
		EXP_NAME="readLargeFileCuFileNVME"
		USE_GDS="--gdsbufreg --direct --cufile "
		FILE_NAME="/raid/data/yren/test_file" #1GB
		;;
	*)
		echo "$1 not supported"
		usage && exit 0
		;;
esac
RUNS="${2:-10}"

echo "$EXP_NAME $USE_GDS $FILE_NAME $RUNS"

METRICS="--lat --lathisto --allelapsed --latpercent "
GPU_IDS=("0,1" "0,1,2,3" "0,1,6,7" "0,1,2,3,4,5,6,7")
CPU_WORKERS=(1 4 16 32 64 96 128)
BUFFER_SIZES=("64k" "256k" "1m" "4m")
EXE="elbencho"

if [[ -d "$EXP_NAME" ]]; then
	echo "WARNING $EXP_NAME folder exits"
	tarfn="${EXP_NAME}_$(xxd -u -l 8 -p /dev/urandom)".tar.gz
	echo "compressing to $tarfn"
	tar cfvz $tarfn $EXP_NAME
	rm -r $EXP_NAME
fi

mkdir $EXP_NAME

for r in $(seq "$RUNS"); do
	for g in "${GPU_IDS[@]}"; do
		for c in "${CPU_WORKERS[@]}"; do
			for b in "${BUFFER_SIZES[@]}"; do
				echo "run_$r-gpu_$g-workers_$c-buffer_$b"
				fn="gpu_$g-workers_$c-buffer_$b-run_$r.txt"
				"$EXE" -r -s 1G -b "$b" -t "$c" --gpuids "$g" $USE_GDS $METRICS "$FILE_NAME" >"$EXP_NAME"/"$fn"
			done
		done
	done
done
