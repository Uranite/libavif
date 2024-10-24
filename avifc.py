import argparse
import os
import subprocess
import time
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor, as_completed
from tqdm import tqdm

def get_file_size(path: Path) -> int:
    return path.stat().st_size

def convert_to_avif(args) -> tuple:
    input_path, output_path, crf, speed = args
    try:
        input_size = get_file_size(input_path)
        
        command = [
            'avifenc',
            '-d', '10',
            '-y', '444',
            '-s', str(speed),
            '-a', f'cq-level={crf}',
            '-a', 'tune=ssim',
            '-a', 'tune-content=default',
            '-a', 'deltaq-mode=2',
            str(input_path),
            '-o', str(output_path)
        ]
        
        result = subprocess.run(command, capture_output=True, text=True)
        if result.returncode == 0:
            output_size = get_file_size(output_path)
            return (True, input_path, output_path, input_size, output_size)
        return (False, input_path, output_path, input_size, 0)
    except Exception as e:
        print(f"Error converting {input_path}: {str(e)}")
        return (False, input_path, output_path, 0, 0)

def process_files(input_path: Path, output_path: Path, crf: int, speed: int):
    start_time = time.time()
    
    # Handle single file conversion
    if input_path.is_file():
        if input_path.suffix.lower() != '.png':
            print(f"Input file must be a PNG file: {input_path}")
            return
        
        if output_path.suffix.lower() != '.avif':
            output_path = output_path.with_suffix('.avif')
            
        result = convert_to_avif((input_path, output_path, crf, speed))
        if result[0]:
            print_statistics([result], time.time() - start_time)
        return

    # Handle directory conversion
    input_files = list(input_path.rglob("*.png"))
    if not input_files:
        print(f"No PNG files found in {input_path}")
        return

    # Create output directory if it doesn't exist
    output_path.mkdir(parents=True, exist_ok=True)

    # Prepare conversion tasks
    conversion_tasks = []
    for input_file in input_files:
        relative_path = input_file.relative_to(input_path)
        output_file = output_path / relative_path.with_suffix('.avif')
        output_file.parent.mkdir(parents=True, exist_ok=True)
        conversion_tasks.append((input_file, output_file, crf, speed))

    # Process files in parallel with progress bar
    results = []
    with ProcessPoolExecutor() as executor:
        futures = []
        for task in conversion_tasks:
            future = executor.submit(convert_to_avif, task)
            futures.append(future)

        # Show progress bar
        with tqdm(total=len(futures), desc="Converting files") as pbar:
            for future in as_completed(futures):
                result = future.result()
                results.append(result)
                pbar.update(1)
                if not result[0]:
                    pbar.write(f"Warning: Failed to convert {result[1]}")

    print_statistics(results, time.time() - start_time)

def print_statistics(results: list, elapsed_time: float):
    successful = [r for r in results if r[0]]
    failed = [r for r in results if not r[0]]
    
    total_input_size = sum(r[3] for r in successful)
    total_output_size = sum(r[4] for r in successful)
    
    if not successful:
        print("\nNo successful conversions.")
        return
    
    avg_reduction = ((total_input_size - total_output_size) / total_input_size) * 100
    
    print("\nConversion Statistics:")
    print(f"Time taken: {elapsed_time:.2f} seconds")
    print(f"Files processed: {len(results)}")
    print(f"Successful conversions: {len(successful)}")
    print(f"Failed conversions: {len(failed)}")
    print(f"Total input size: {total_input_size / 1024 / 1024:.2f} MB")
    print(f"Total output size: {total_output_size / 1024 / 1024:.2f} MB")
    print(f"Average size reduction: {avg_reduction:.2f}%")
    
    if failed:
        print("\nFailed files:")
        for f in failed:
            print(f"- {f[1]}")

def main():
    parser = argparse.ArgumentParser(description='Convert PNG files to AVIF format in parallel')
    parser.add_argument('input', type=str, help='Input PNG file or directory')
    parser.add_argument('output', type=str, help='Output AVIF file or directory')
    parser.add_argument('--crf', type=int, default=5, help='Constant Rate Factor (0-63, default: 5)')
    parser.add_argument('--speed', type=int, default=4, help='Encoding speed (0-10, default: 4)')
    
    args = parser.parse_args()
    
    # Validate CRF and speed values
    if not 0 <= args.crf <= 63:
        parser.error("CRF must be between 0 and 63")
    if not 0 <= args.speed <= 10:
        parser.error("Speed must be between 0 and 10")
    
    input_path = Path(args.input).resolve()
    output_path = Path(args.output).resolve()
    
    if not input_path.exists():
        parser.error(f"Input path does not exist: {input_path}")
    
    process_files(input_path, output_path, args.crf, args.speed)

if __name__ == "__main__":
    main()