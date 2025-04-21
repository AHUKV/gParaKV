<h1 align="center">gParaKV</h1>
<p align="center">
  <b>GPGPU‑accelerated key–value store with bitmap‑aided compaction &amp; garbage collection.</b><br>
  <i>Source code and artifact scripts for the SC ’25 paper.</i>
</p>


<p align="center">
  <!-- Replace AFTER publishing -->
  <a href="https://doi.org/10.5281/zenodo.FIXME"><img alt="DOI" src="https://img.shields.io/badge/doi-10.5281/zenodo.FIXME-blue.svg"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/github/license/AHUKV/gParaKV.svg"></a>
</p>


---

## 1 Overview

This repository contains:

1. **Modified LevelDB 1.23** implementation (“gParaKV”) with CUDA 12.3 kernels.  
2. **Benchmarks & scripts** to reproduce the throughput/latency and space‑amplification results in our SC ’25 paper.

All experiments were validated on **Ubuntu 22.04** with kernel **6.8.0‑52‑generic** and an **NVIDIA Tesla P100 GPGPU**.

---

## 2 System Requirements

| Component     | Version tested   | Notes                    |
| ------------- | ---------------- | ------------------------ |
| Ubuntu        | 22.04 LTS        |                          |
| Linux kernel  | 6.8.0‑52‑generic | stock                    |
| GPU driver    | ≥ 550.xx         | SM 6.0 (Pascal) or newer |
| CUDA Toolkit  | 12.3             | required for `nvcc`      |
| gcc / g++     | ≥ 11             | C++17                    |
| CMake         | ≥ 3.26           |                          |
| libsnappy-dev | latest           | optional but recommended |

Install the prerequisites:

```bash
sudo apt update
sudo apt install build-essential cmake git libsnappy-dev
# GPU driver & CUDA
sudo apt install nvidia-driver-550
sudo apt install nvidia-cuda-toolkit
```

------

## 3 Getting Started

```bash
# 1. Clone
git clone https://github.com/AHUKV/gParaKV.git
cd gParaKV
git submodule update --init --recursive
```

### 3.1 Build gParaKV

```bash
mkdir build && cd build
cmake ..
cd ..
```

#### Compile targets

| Target       | Command                                     | Purpose          |
| ------------ | ------------------------------------------- | ---------------- |
| **db_bench** | `cmake --build build --target db_bench -j8` | micro‑benchmarks |
| **ycsbc**    | `cmake --build build --target ycsbc  -j8`   | YCSB‑C client    |

------

## 4 Running Benchmarks

### 4.1 db_bench

```bash
./build/db_bench \
  --benchmarks=fillrandom \
  --value_size=1024 \
  --num=10000000 \
  --db=/tmp/test
```

### 4.2 YCSB‑C

```bash
./build/ycsbc \
  -filename /tmp/test \
  -db leveldb \
  -configpath 0 \
  -P ./workloads/100/workloadb.spec
```

Results (CSV) are written to `results/` and can be plotted with:

```bash
python tools/plot_results.py --input results --out fig9.pdf
```

------

## 5 Repository Layout

```
gParaKV/
├── src/          # core library + CUDA kernels
├── bench/        # db_bench / ycsb‑c sources
├── workloads/    # YCSB‑C *.spec files
├── tools/        # plotting & helper scripts
├── pictures/     # architecture diagrams, paper draft
├── evaluation/   # test script
└── CMakeLists.txt
```

